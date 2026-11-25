package com.paccore.yiralife

import android.app.Activity
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.os.Parcelable
import android.provider.OpenableColumns
import android.util.Log
import android.webkit.MimeTypeMap
import android.widget.Toast
import java.io.File

/**
 * "Yira Health" in the system share list, for PDFs and photos shared from WhatsApp, Files,
 * Gallery, Gmail and other apps. It copies the shared files into the app's cache and hands them
 * to MainActivity, where receive_sharing_intent passes them to Flutter.
 *
 * The sending app only lets this activity read its content:// links, and only while it is open,
 * so the files are copied here. The copy uses that read grant and nothing else: the app holds no
 * storage or media permission (Play's photo policy).
 *
 * MainActivity is opened in the app's own task. Putting the share filters on MainActivity itself
 * (singleTop) would start a second copy of the app inside the sending app's task, and a share
 * would never reach the copy that is already running.
 */
class ShareIntoYiraActivity : Activity() {

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        val uris = SharedFiles.urisOf(intent)
        if (uris.isEmpty()) {
            finish()
            return
        }
        val types = intent.getStringArrayExtra(Intent.EXTRA_MIME_TYPES)
        val shareType = intent.type
        Thread {
            val copies = SharedFiles.copy(this, uris, types, shareType)
            Handler(Looper.getMainLooper()).post {
                // Not when the patient backed out while the files were copying.
                if (!isDestroyed) {
                    if (copies.isNotEmpty()) {
                        startActivity(SharedFiles.handOffIntent(this, copies))
                    } else {
                        Toast.makeText(applicationContext, "Yira Health couldn't open the shared file. Please try sharing it again.", Toast.LENGTH_LONG).show()
                    }
                }
                finish()
            }
        }.start()
    }
}

/** Copies shared files into the cache and builds the hand-off to MainActivity. */
object SharedFiles {
    private const val TAG = "ShareIntoYira"

    /** Cache folder for shared files. Flutter deletes each share's folder once it is handled. */
    private const val DIR = "shared_into_yira"

    /** Files over this size are not copied. The app checks the real limits (10 MB for a PDF). */
    private const val MAX_COPY_BYTES = 50L * 1024 * 1024

    /** Stand-ins for files over [MAX_COPY_BYTES] go in this folder, empty, so the app can say so. */
    private const val TOO_LARGE_DIR = "too_large"

    data class Copy(val file: File, val mimeType: String)

    fun urisOf(intent: Intent?): List<Uri> {
        if (intent == null) return emptyList()
        val uris = when (intent.action) {
            Intent.ACTION_SEND -> listOfNotNull(intent.parcelable<Uri>(Intent.EXTRA_STREAM))
            Intent.ACTION_SEND_MULTIPLE -> intent.parcelableList<Uri>(Intent.EXTRA_STREAM).orEmpty()
            else -> return emptyList()
        }
        if (uris.isNotEmpty()) return uris
        val clip = intent.clipData ?: return emptyList()
        return (0 until clip.itemCount).mapNotNull { clip.getItemAt(it).uri }
    }

    fun copy(context: Context, uris: List<Uri>, types: Array<String>?, shareType: String?): List<Copy> {
        val root = File(context.cacheDir, DIR)
        removeOldShares(root)
        val dir = File(root, System.currentTimeMillis().toString()).apply { mkdirs() }
        val used = mutableSetOf<String>()
        val copies = uris.mapIndexedNotNull { index, uri ->
            try {
                copyOne(context, uri, types?.getOrNull(index) ?: shareType, dir, index, used)
            } catch (e: Exception) {
                Log.w(TAG, "Could not copy a shared file", e)
                null
            }
        }
        if (copies.isEmpty()) dir.deleteRecursively()
        return copies
    }

    private fun copyOne(context: Context, uri: Uri, typeHint: String?, dir: File, index: Int, used: MutableSet<String>): Copy? {
        // Only links the sender grants. A file:// path, or a link to one of this app's own
        // providers, would read the app's private files with the app's own access.
        if (uri.scheme != "content") return null
        val authority = uri.authority ?: return null
        if (context.packageManager.resolveContentProvider(authority, 0)?.packageName == context.packageName) return null

        val resolver = context.contentResolver
        var name: String? = null
        var size: Long? = null
        resolver.query(uri, arrayOf(OpenableColumns.DISPLAY_NAME, OpenableColumns.SIZE), null, null, null)?.use { c ->
            if (c.moveToFirst()) {
                val n = c.getColumnIndex(OpenableColumns.DISPLAY_NAME)
                val s = c.getColumnIndex(OpenableColumns.SIZE)
                if (n >= 0 && !c.isNull(n)) name = c.getString(n)
                if (s >= 0 && !c.isNull(s)) size = c.getLong(s)
            }
        }
        val mimeType = resolver.getType(uri)?.takeIf { it.contains('/') && !it.endsWith("/*") }
            ?: typeHint?.takeIf { it.contains('/') && !it.endsWith("/*") }
            ?: guessType(name)
            ?: typeHint
            ?: "application/octet-stream"
        val fileName = uniqueName(safeName(name, mimeType, index), used)

        if ((size ?: 0L) > MAX_COPY_BYTES) return tooLarge(dir, fileName, mimeType)
        val target = File(dir, fileName)
        var copied = 0L
        resolver.openInputStream(uri)?.use { input ->
            target.outputStream().use { output ->
                val buffer = ByteArray(64 * 1024)
                while (true) {
                    val read = input.read(buffer)
                    if (read < 0) break
                    copied += read
                    if (copied > MAX_COPY_BYTES) break
                    output.write(buffer, 0, read)
                }
            }
        } ?: return null
        if (copied > MAX_COPY_BYTES) {
            target.delete()
            return tooLarge(dir, fileName, mimeType)
        }
        return Copy(target, mimeType)
    }

    private fun tooLarge(dir: File, fileName: String, mimeType: String): Copy {
        val stand = File(File(dir, TOO_LARGE_DIR).apply { mkdirs() }, fileName)
        stand.writeBytes(ByteArray(0))
        return Copy(stand, mimeType)
    }

    /** The file name without folders, with an extension that matches its type. */
    private fun safeName(name: String?, mimeType: String, index: Int): String {
        var base = name?.substringAfterLast('/')?.substringAfterLast('\\')?.trim()
            ?.replace(Regex("[\\u0000-\\u001f:*?\"<>|]"), "_")
            ?.trimStart('.')
            .orEmpty()
        if (base.isEmpty()) base = "shared_${index + 1}"
        val ext = MimeTypeMap.getSingleton().getExtensionFromMimeType(mimeType)
        val hasExt = base.contains('.') && base.substringAfterLast('.').isNotEmpty()
        if (ext != null && (!hasExt || (mimeType == "application/pdf" && !base.lowercase().endsWith(".pdf")))) {
            base = "$base.$ext"
        }
        return base.take(120)
    }

    private fun uniqueName(name: String, used: MutableSet<String>): String {
        var candidate = name
        var n = 2
        while (!used.add(candidate.lowercase())) {
            val dot = name.lastIndexOf('.')
            candidate = if (dot > 0) "${name.substring(0, dot)} ($n)${name.substring(dot)}" else "$name ($n)"
            n++
        }
        return candidate
    }

    private fun guessType(name: String?): String? {
        val ext = name?.substringAfterLast('.', "")?.lowercase().orEmpty()
        if (ext.isEmpty()) return null
        return MimeTypeMap.getSingleton().getMimeTypeFromExtension(ext)
    }

    /** Shares older than a day that the app never handled, for example when nobody signed in. */
    private fun removeOldShares(root: File) {
        val cutoff = System.currentTimeMillis() - 24L * 60 * 60 * 1000
        root.listFiles()?.forEach { if (it.lastModified() < cutoff) it.deleteRecursively() }
    }

    fun handOffIntent(context: Context, copies: List<Copy>): Intent =
        Intent(context, MainActivity::class.java).apply {
            action = Intent.ACTION_SEND_MULTIPLE
            type = "*/*"
            putParcelableArrayListExtra(Intent.EXTRA_STREAM, ArrayList<Uri>(copies.map { Uri.fromFile(it.file) }))
            putExtra(Intent.EXTRA_MIME_TYPES, copies.map { it.mimeType }.toTypedArray())
            // Reuse the running MainActivity (onNewIntent) instead of stacking a second one.
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP or Intent.FLAG_ACTIVITY_SINGLE_TOP)
        }

    /**
     * True for an intent MainActivity should hand to receive_sharing_intent: anything but a share,
     * or a share whose files are all copies made above. Other shares sent straight to MainActivity
     * are dropped, since the plugin would read their links with storage access the app lacks.
     */
    fun isSafeForMainActivity(context: Context, intent: Intent?): Boolean {
        if (intent == null) return true
        if (intent.action != Intent.ACTION_SEND && intent.action != Intent.ACTION_SEND_MULTIPLE) return true
        val root = File(context.cacheDir, DIR).canonicalPath + File.separator
        val uris = urisOf(intent)
        return uris.isNotEmpty() && uris.all { uri ->
            uri.scheme == "file" && uri.path?.let { File(it).canonicalPath.startsWith(root) } == true
        }
    }

    private inline fun <reified T : Parcelable> Intent.parcelable(key: String): T? =
        if (Build.VERSION.SDK_INT >= 33) getParcelableExtra(key, T::class.java)
        else @Suppress("DEPRECATION") (getParcelableExtra(key) as? T)

    private inline fun <reified T : Parcelable> Intent.parcelableList(key: String): List<T>? =
        if (Build.VERSION.SDK_INT >= 33) getParcelableArrayListExtra(key, T::class.java)
        else @Suppress("DEPRECATION") getParcelableArrayListExtra(key)
}
