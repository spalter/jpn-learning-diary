package dev.jpnlearningdiary

import android.app.Activity
import android.content.ContentResolver
import android.content.Intent
import android.net.Uri
import android.provider.OpenableColumns
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileInputStream
import java.io.FileOutputStream

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.jpn_learning_diary/cloud_sync"
    private val PICK_FILE_REQUEST_CODE = 1001
    private var pendingResult: MethodChannel.Result? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "takePersistentPermission" -> {
                    val uri = call.argument<String>("uri")
                    if (uri != null) {
                        result.success(takePersistentPermission(uri))
                    } else {
                        result.error("INVALID_URI", "URI is null", null)
                    }
                }
                "releasePersistentPermission" -> {
                    val uri = call.argument<String>("uri")
                    if (uri != null) {
                        releasePersistentPermission(uri)
                        result.success(true)
                    } else {
                        result.error("INVALID_URI", "URI is null", null)
                    }
                }
                "copyFromUri" -> {
                    val uri = call.argument<String>("uri")
                    val destinationPath = call.argument<String>("destinationPath")
                    if (uri != null && destinationPath != null) {
                        result.success(copyFromUri(uri, destinationPath))
                    } else {
                        result.error("INVALID_ARGS", "URI or destination path is null", null)
                    }
                }
                "copyToUri" -> {
                    val uri = call.argument<String>("uri")
                    val sourcePath = call.argument<String>("sourcePath")
                    if (uri != null && sourcePath != null) {
                        result.success(copyToUri(uri, sourcePath))
                    } else {
                        result.error("INVALID_ARGS", "URI or source path is null", null)
                    }
                }
                "openFilePicker" -> {
                    pendingResult = result
                    openFilePicker()
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun takePersistentPermission(uriString: String): Boolean {
        return try {
            val uri = Uri.parse(uriString)
            val takeFlags = Intent.FLAG_GRANT_READ_URI_PERMISSION or Intent.FLAG_GRANT_WRITE_URI_PERMISSION
            contentResolver.takePersistableUriPermission(uri, takeFlags)
            true
        } catch (e: Exception) {
            e.printStackTrace()
            false
        }
    }

    private fun releasePersistentPermission(uriString: String) {
        try {
            val uri = Uri.parse(uriString)
            val releaseFlags = Intent.FLAG_GRANT_READ_URI_PERMISSION or Intent.FLAG_GRANT_WRITE_URI_PERMISSION
            contentResolver.releasePersistableUriPermission(uri, releaseFlags)
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    private fun copyFromUri(uriString: String, destinationPath: String): Boolean {
        return try {
            val uri = Uri.parse(uriString)
            val inputStream = contentResolver.openInputStream(uri) ?: return false
            
            inputStream.use { input ->
                val destFile = File(destinationPath)
                destFile.parentFile?.mkdirs()
                
                FileOutputStream(destFile).use { output ->
                    input.copyTo(output)
                }
            }
            true
        } catch (e: Exception) {
            e.printStackTrace()
            false
        }
    }

    private fun copyToUri(uriString: String, sourcePath: String): Boolean {
        return try {
            val uri = Uri.parse(uriString)
            val sourceFile = File(sourcePath)
            // Use "wt" mode to truncate and write (overwrite the file)
            contentResolver.openOutputStream(uri, "wt")?.use { outputStream ->
                FileInputStream(sourceFile).use { inputStream ->
                    inputStream.copyTo(outputStream)
                }
            }
            true
        } catch (e: Exception) {
            e.printStackTrace()
            false
        }
    }

    private fun openFilePicker() {
        val intent = Intent(Intent.ACTION_OPEN_DOCUMENT).apply {
            addCategory(Intent.CATEGORY_OPENABLE)
            type = "*/*"
            putExtra(Intent.EXTRA_MIME_TYPES, arrayOf("application/octet-stream", "application/x-sqlite3"))
            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
            addFlags(Intent.FLAG_GRANT_WRITE_URI_PERMISSION)
            addFlags(Intent.FLAG_GRANT_PERSISTABLE_URI_PERMISSION)
        }
        startActivityForResult(intent, PICK_FILE_REQUEST_CODE)
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)

        if (requestCode == PICK_FILE_REQUEST_CODE) {
            if (resultCode == Activity.RESULT_OK && data?.data != null) {
                val uri = data.data!!
                val displayName = getDisplayName(uri)
                pendingResult?.success(mapOf(
                    "uri" to uri.toString(),
                    "displayName" to displayName
                ))
            } else {
                pendingResult?.success(null)
            }
            pendingResult = null
        }
    }

    private fun getDisplayName(uri: Uri): String {
        var displayName = "database.db"
        contentResolver.query(uri, null, null, null, null)?.use { cursor ->
            if (cursor.moveToFirst()) {
                val nameIndex = cursor.getColumnIndex(OpenableColumns.DISPLAY_NAME)
                if (nameIndex >= 0) {
                    displayName = cursor.getString(nameIndex)
                }
            }
        }
        return displayName
    }
}
