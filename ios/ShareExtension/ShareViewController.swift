import UIKit
import UniformTypeIdentifiers

/// "Yira Health" in the iOS share sheet, for PDFs and photos shared from Mail, WhatsApp, Files,
/// Photos and other apps. It copies the shared files into the app group container, leaves their
/// list where receive_sharing_intent looks for it, and opens Yira, which shows the report upload
/// sheet with the files attached (lib/features/presentation/patient/documents/share_into_yira.dart).
///
/// The hand-off is the one the plugin's own RSIShareViewController writes: a JSON list under
/// "ShareKey" in the app group's UserDefaults, then the "ShareMedia-<app id>:share" link. This
/// extension does not link the plugin. It looks for PDFs by their own type, which Mail and
/// WhatsApp use, where the plugin only takes files offered as file links.
///
/// The app group is group.<app id> (group.com.paccore.yiralife), the plugin's default, so no
/// AppGroupId key is needed. Both targets list it in their entitlements.
class ShareViewController: UIViewController {

    /// Files over this size are not copied. The app checks the real limits (10 MB for a PDF)
    /// and says why a file was left out. Same as SharedFiles in ShareIntoYiraActivity.kt.
    private let maxCopyBytes: Int64 = 50 * 1024 * 1024

    /// The plugin's SharedMediaFile as JSON. `type` is "image" or "file".
    private struct SharedFile: Codable {
        let path: String
        let mimeType: String?
        let type: String
    }

    /// com.paccore.yiralife for com.paccore.yiralife.ShareExtension.
    private lazy var hostBundleId: String = {
        let id = Bundle.main.bundleIdentifier ?? ""
        guard let dot = id.lastIndex(of: ".") else { return id }
        return String(id[..<dot])
    }()

    private lazy var appGroupId: String = {
        (Bundle.main.object(forInfoDictionaryKey: "AppGroupId") as? String).flatMap { $0.isEmpty ? nil : $0 }
            ?? "group.\(hostBundleId)"
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .clear
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // No sheet of our own: clear the system container so the sending app shows through
        // until Yira opens.
        var ancestor = view.superview
        while let current = ancestor {
            current.backgroundColor = .clear
            current.isOpaque = false
            ancestor = current.superview
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        collect { [weak self] files in
            guard let self = self else { return }
            if !files.isEmpty { self.handOff(files) }
            self.extensionContext?.completeRequest(returningItems: [], completionHandler: nil)
        }
    }

    // MARK: - Copying the shared files

    private func collect(_ done: @escaping ([SharedFile]) -> Void) {
        guard let container = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupId) else {
            NSLog("[ShareIntoYira] App group \(appGroupId) is not available")
            done([])
            return
        }
        // One folder per share, like the Android side. Flutter deletes it once the sheet closes.
        let root = container.appendingPathComponent("shared_into_yira", isDirectory: true)
        removeOldShares(in: root)
        let dir = root.appendingPathComponent(String(Int64(Date().timeIntervalSince1970 * 1000)), isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)

        let providers = (extensionContext?.inputItems as? [NSExtensionItem] ?? []).flatMap { $0.attachments ?? [] }
        var results = [SharedFile?](repeating: nil, count: providers.count)
        var usedNames = Set<String>()
        let lock = NSLock()
        let group = DispatchGroup()
        for (index, provider) in providers.enumerated() {
            guard let typeId = Self.reportType(of: provider) else { continue }
            group.enter()
            copyAttachment(provider, typeId: typeId, index: index, into: dir, claim: { name in
                lock.lock()
                defer { lock.unlock() }
                return Self.unique(name, in: &usedNames)
            }) { file in
                lock.lock()
                results[index] = file
                lock.unlock()
                group.leave()
            }
        }
        group.notify(queue: .main) {
            let files = results.compactMap { $0 }
            if files.isEmpty { try? FileManager.default.removeItem(at: dir) }
            done(files)
        }
    }

    /// The attachment's PDF or image type, or nil for anything else. Images Yira can't take
    /// (GIF, WebP) still come through, so the app can name them and say why.
    private static func reportType(of provider: NSItemProvider) -> String? {
        let types = provider.registeredTypeIdentifiers
        if let pdf = types.first(where: { UTType($0)?.conforms(to: .pdf) == true }) { return pdf }
        return types.first(where: { UTType($0)?.conforms(to: .image) == true })
    }

    private func copyAttachment(
        _ provider: NSItemProvider,
        typeId: String,
        index: Int,
        into dir: URL,
        claim: @escaping (String) -> String,
        done: @escaping (SharedFile?) -> Void
    ) {
        let type = UTType(typeId)
        let isPdf = type?.conforms(to: .pdf) == true
        let ext = type?.preferredFilenameExtension ?? (isPdf ? "pdf" : "jpg")
        let mime = type?.preferredMIMEType ?? (isPdf ? "application/pdf" : "image/jpeg")

        // The file is only readable inside this handler, so it is copied here.
        _ = provider.loadFileRepresentation(forTypeIdentifier: typeId) { [weak self] url, _ in
            guard let self = self else { return done(nil) }
            if let url = url {
                let base = provider.suggestedName ?? url.deletingPathExtension().lastPathComponent
                let name = claim(Self.fileName(base, ext: ext, isPdf: isPdf, index: index))
                return done(self.place(file: url, name: name, mime: mime, isPdf: isPdf, dir: dir))
            }
            // Some apps offer only an image object, raw data or a link.
            provider.loadItem(forTypeIdentifier: typeId, options: nil) { item, _ in
                if let url = item as? URL {
                    let base = provider.suggestedName ?? url.deletingPathExtension().lastPathComponent
                    let name = claim(Self.fileName(base, ext: ext, isPdf: isPdf, index: index))
                    let scoped = url.startAccessingSecurityScopedResource()
                    defer { if scoped { url.stopAccessingSecurityScopedResource() } }
                    done(self.place(file: url, name: name, mime: mime, isPdf: isPdf, dir: dir))
                } else if let data = item as? Data {
                    let name = claim(Self.fileName(provider.suggestedName, ext: ext, isPdf: isPdf, index: index))
                    done(self.place(data: data, name: name, mime: mime, isPdf: isPdf, dir: dir))
                } else if let image = item as? UIImage, let data = image.jpegData(compressionQuality: 0.92) {
                    let name = claim(Self.fileName(provider.suggestedName, ext: "jpg", isPdf: false, index: index))
                    done(self.place(data: data, name: name, mime: "image/jpeg", isPdf: false, dir: dir))
                } else {
                    done(nil)
                }
            }
        }
    }

    private func place(file url: URL, name: String, mime: String, isPdf: Bool, dir: URL) -> SharedFile? {
        let size = (try? FileManager.default.attributesOfItem(atPath: url.path)[.size] as? NSNumber)?.int64Value ?? 0
        if size > maxCopyBytes { return tooLarge(name: name, mime: mime, isPdf: isPdf, dir: dir) }
        let target = dir.appendingPathComponent(name)
        do {
            try FileManager.default.copyItem(at: url, to: target)
            return SharedFile(path: "file://\(target.path)", mimeType: mime, type: isPdf ? "file" : "image")
        } catch {
            NSLog("[ShareIntoYira] Could not copy \(name): \(error)")
            return nil
        }
    }

    private func place(data: Data, name: String, mime: String, isPdf: Bool, dir: URL) -> SharedFile? {
        if Int64(data.count) > maxCopyBytes { return tooLarge(name: name, mime: mime, isPdf: isPdf, dir: dir) }
        let target = dir.appendingPathComponent(name)
        do {
            try data.write(to: target)
            return SharedFile(path: "file://\(target.path)", mimeType: mime, type: isPdf ? "file" : "image")
        } catch {
            NSLog("[ShareIntoYira] Could not save \(name): \(error)")
            return nil
        }
    }

    /// An empty stand-in in a too_large folder, so the app can say the file was too large.
    private func tooLarge(name: String, mime: String, isPdf: Bool, dir: URL) -> SharedFile? {
        let folder = dir.appendingPathComponent("too_large", isDirectory: true)
        try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        let target = folder.appendingPathComponent(name)
        guard FileManager.default.createFile(atPath: target.path, contents: Data()) else { return nil }
        return SharedFile(path: "file://\(target.path)", mimeType: mime, type: isPdf ? "file" : "image")
    }

    /// The file name without folders, ending in an extension that matches its type.
    private static func fileName(_ base: String?, ext: String, isPdf: Bool, index: Int) -> String {
        var name = (base ?? "")
            .components(separatedBy: CharacterSet(charactersIn: "/\\:*?\"<>|").union(.controlCharacters))
            .joined(separator: "_")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        while name.hasPrefix(".") { name.removeFirst() }
        if name.isEmpty { name = "shared_\(index + 1)" }
        let current = (name as NSString).pathExtension.lowercased()
        if current.isEmpty || (isPdf && current != "pdf") { name += ".\(ext)" }
        return String(name.prefix(120))
    }

    private static func unique(_ name: String, in used: inout Set<String>) -> String {
        var candidate = name
        var n = 2
        let base = (name as NSString).deletingPathExtension
        let ext = (name as NSString).pathExtension
        while used.contains(candidate.lowercased()) {
            candidate = ext.isEmpty ? "\(base) (\(n))" : "\(base) (\(n)).\(ext)"
            n += 1
        }
        used.insert(candidate.lowercased())
        return candidate
    }

    /// Shares older than a day that the app never handled, for example when nobody signed in.
    private func removeOldShares(in root: URL) {
        let cutoff = Date().addingTimeInterval(-24 * 60 * 60)
        let folders = (try? FileManager.default.contentsOfDirectory(
            at: root, includingPropertiesForKeys: [.creationDateKey], options: [.skipsHiddenFiles])) ?? []
        for folder in folders {
            let created = (try? folder.resourceValues(forKeys: [.creationDateKey]))?.creationDate ?? .distantPast
            if created < cutoff { try? FileManager.default.removeItem(at: folder) }
        }
    }

    // MARK: - Handing over to Yira

    private func handOff(_ files: [SharedFile]) {
        guard let defaults = UserDefaults(suiteName: appGroupId),
              let data = try? JSONEncoder().encode(files) else { return }
        defaults.set(data, forKey: "ShareKey")
        defaults.removeObject(forKey: "ShareMessageKey")
        defaults.synchronize()
        if let url = URL(string: "ShareMedia-\(hostBundleId):share") { openHostApp(url) }
    }

    /// An extension can't call UIApplication.open, so this finds the application object in the
    /// responder chain and calls it through the Objective-C runtime, as the plugin does.
    private func openHostApp(_ url: URL) {
        var responder: UIResponder? = self
        if #available(iOS 18.0, *) {
            let selector = NSSelectorFromString("openURL:options:completionHandler:")
            typealias OpenURL = @convention(c) (AnyObject, Selector, NSURL, NSDictionary, AnyObject?) -> Void
            while let current = responder {
                if current.responds(to: selector), let imp = current.method(for: selector) {
                    unsafeBitCast(imp, to: OpenURL.self)(current, selector, url as NSURL, NSDictionary(), nil)
                    return
                }
                responder = current.next
            }
        } else {
            let selector = NSSelectorFromString("openURL:")
            while let current = responder {
                if current.responds(to: selector) {
                    _ = current.perform(selector, with: url)
                    return
                }
                responder = current.next
            }
        }
    }
}
