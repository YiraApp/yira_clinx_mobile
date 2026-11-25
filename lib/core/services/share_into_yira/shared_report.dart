import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

enum SharedFileKind { pdf, photo, unsupported }

/// A file shared into Yira from another app (WhatsApp, Files, Gallery, Gmail),
/// already copied into the app's own storage by the platform side.
class SharedReportFile {
  const SharedReportFile({required this.path, this.mimeType});

  final String path;
  final String? mimeType;

  static const photoExtensions = {'jpg', 'jpeg', 'png', 'heic', 'heif'};
  static const _photoMimeTypes = {'image/jpeg', 'image/jpg', 'image/pjpeg', 'image/png', 'image/heic', 'image/heif'};
  static const _vagueMimeTypes = {'', '*/*', 'image/*', 'application/*', 'application/octet-stream', 'binary/octet-stream'};

  File get file => File(path);

  String get name => path.split(RegExp(r'[\\/]')).last;

  String get _extension => name.contains('.') ? name.substring(name.lastIndexOf('.') + 1).toLowerCase() : '';

  SharedFileKind get kind => kindOf(name, mimeType);

  /// PDFs and photos (JPG, PNG, HEIC) can be uploaded. The type the sending
  /// app gave wins; the file name decides only when that type is vague.
  static SharedFileKind kindOf(String name, String? mimeType) {
    final mime = (mimeType ?? '').trim().toLowerCase();
    if (mime == 'application/pdf') return SharedFileKind.pdf;
    if (_photoMimeTypes.contains(mime)) return SharedFileKind.photo;
    if (!_vagueMimeTypes.contains(mime)) return SharedFileKind.unsupported;
    final ext = name.contains('.') ? name.substring(name.lastIndexOf('.') + 1).toLowerCase() : '';
    if (ext == 'pdf') return SharedFileKind.pdf;
    if (photoExtensions.contains(ext)) return SharedFileKind.photo;
    return SharedFileKind.unsupported;
  }

  /// Android does not copy files over 50 MB. It passes an empty stand-in from
  /// a `too_large` folder instead, so the app can say why it was left out.
  bool get tooLarge {
    final parts = path.split(RegExp(r'[\\/]'));
    if (parts.length < 2 || parts[parts.length - 2] != 'too_large') return false;
    try {
      return file.lengthSync() == 0;
    } catch (_) {
      return true;
    }
  }

  bool get exists {
    try {
      return file.existsSync();
    } catch (_) {
      return false;
    }
  }

  /// The upload names parts by extension, so a PDF must end in .pdf.
  Future<File> fileForUpload() async {
    if (kind != SharedFileKind.pdf || _extension == 'pdf') return file;
    final copy = File('$path.pdf');
    return file.copy(copy.path);
  }
}

/// One share: the files another app sent in a single go.
class SharedReport {
  SharedReport(List<SharedReportFile> files) : files = List.unmodifiable(files);

  final List<SharedReportFile> files;

  /// Still there, a PDF or photo, and not over the copy limit.
  List<SharedReportFile> get usable =>
      [for (final f in files) if (f.exists && !f.tooLarge && f.kind != SharedFileKind.unsupported) f];

  bool get hasUsable => usable.isNotEmpty;

  /// Everything was removed already, for example after Android restored the
  /// app with a share it had handled before.
  bool get isGone => files.every((f) => !f.exists);

  /// Why some files can't be uploaded, in the patient's words, or null.
  String? get problem {
    final unsupported = [for (final f in files) if (f.exists && !f.tooLarge && f.kind == SharedFileKind.unsupported) f.name];
    final tooLarge = [for (final f in files) if (f.tooLarge) f.name];
    final parts = <String>[];
    if (unsupported.isNotEmpty) {
      parts.add('${_names(unsupported)} can\'t be uploaded. Yira takes PDFs and photos (JPG, PNG, HEIC).');
    }
    if (tooLarge.isNotEmpty) {
      parts.add('${_names(tooLarge)} ${tooLarge.length == 1 ? 'is' : 'are'} too large to upload. A PDF can be up to 10 MB.');
    }
    return parts.isEmpty ? null : parts.join('\n');
  }

  static String _names(List<String> names) {
    if (names.length == 1) return '"${names.single}"';
    final shown = names.take(3).map((n) => '"$n"').join(', ');
    return names.length > 3 ? '$shown and ${names.length - 3} more' : shown;
  }

  /// Deletes the app's own copies of the shared files: Android's share folder
  /// in the cache, the temp folder, or the iOS app group container. Files
  /// anywhere else are left alone.
  Future<void> discard() async {
    String? temp;
    try {
      temp = (await getTemporaryDirectory()).absolute.path.replaceAll(r'\', '/');
    } catch (_) {}
    final shareDirs = <Directory>{};
    for (final f in files) {
      try {
        final path = f.file.absolute.path.replaceAll(r'\', '/');
        if (!isOwnCopy(path, tempDir: temp)) continue;
        for (final p in [f.path, if (f.kind == SharedFileKind.pdf && f._extension != 'pdf') '${f.path}.pdf']) {
          final file = File(p);
          if (await file.exists()) await file.delete();
        }
        if (path.contains('/$androidShareDir/')) {
          final dir = f.file.parent;
          shareDirs.add(dir.path.replaceAll(r'\', '/').endsWith('/too_large') ? dir.parent : dir);
        }
      } catch (e) {
        debugPrint('[ShareIntoYira] Could not delete ${f.name}: $e');
      }
    }
    // Android keeps each share in a folder of its own under shared_into_yira.
    for (final dir in shareDirs) {
      try {
        if (dir.parent.path.replaceAll(r'\', '/').endsWith('/$androidShareDir') && await dir.exists()) {
          await dir.delete(recursive: true);
        }
      } catch (e) {
        debugPrint('[ShareIntoYira] Could not remove ${dir.path}: $e');
      }
    }
  }

  /// The cache folder ShareIntoYiraActivity.kt copies shared files into.
  static const androidShareDir = 'shared_into_yira';

  @visibleForTesting
  static bool isOwnCopy(String path, {String? tempDir}) {
    final p = path.replaceAll(r'\', '/');
    return p.contains('/$androidShareDir/') ||
        (tempDir != null && tempDir.isNotEmpty && p.startsWith(tempDir.endsWith('/') ? tempDir : '$tempDir/')) ||
        p.contains('/Shared/AppGroup/');
  }
}
