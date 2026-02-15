package com.trapplab.nfc_radio

import android.app.Activity
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileOutputStream

class MainActivity : FlutterActivity() {
    companion object {
        const val CHANNEL_NAME = "com.trapplab.nfc_radio/audio_picker"
        private const val REQUEST_CODE_PICK_AUDIO = 1001
        private const val TAG = "MainActivity"
    }

    private var methodChannel: MethodChannel? = null
    private var pendingPickResult: MethodChannel.Result? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL_NAME)
        methodChannel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "pickAudio" -> {
                    val filterAudioOnly = call.argument<Boolean>("filterAudioOnly") ?: false
                    pendingPickResult = result
                    pickAudio(filterAudioOnly)
                    // result will be resolved in onActivityResult
                }
                "openApp" -> {
                    val packageName = call.argument<String>("packageName")
                    if (packageName != null) {
                        val success = openApp(packageName)
                        result.success(success)
                    } else {
                        result.error("INVALID_ARGUMENT", "Package name is null", null)
                    }
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun openApp(packageName: String): Boolean {
        return try {
            val pm = packageManager
            
            // Check if package is installed first
            try {
                pm.getPackageInfo(packageName, 0)
            } catch (e: PackageManager.NameNotFoundException) {
                return false
            }

            // Try to get launch intent
            val launchIntent = pm.getLaunchIntentForPackage(packageName)
            
            if (launchIntent != null) {
                startActivity(launchIntent)
                true
            } else {
                false
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error opening app: $packageName", e)
            false
        }
    }

    private fun pickAudio(filterAudioOnly: Boolean) {
        val intent = Intent(Intent.ACTION_GET_CONTENT).apply {
            type = if (filterAudioOnly) "audio/*" else "*/*"
            addCategory(Intent.CATEGORY_OPENABLE)
            putExtra(Intent.EXTRA_ALLOW_MULTIPLE, true)
        }
        startActivityForResult(Intent.createChooser(intent, "Select Audio App"), REQUEST_CODE_PICK_AUDIO)
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)

        if (requestCode == REQUEST_CODE_PICK_AUDIO) {
            if (resultCode == Activity.RESULT_OK) {
                val files = mutableListOf<Map<String, String>>()
                val clipData = data?.clipData
                if (clipData != null) {
                    // Multiple files selected
                    for (i in 0 until clipData.itemCount) {
                        copyFileToInternalStorage(clipData.getItemAt(i).uri)?.let { files.add(it) }
                    }
                } else {
                    // Single file selected
                    data?.data?.let { uri ->
                        copyFileToInternalStorage(uri)?.let { files.add(it) }
                    }
                }
                pendingPickResult?.success(files)
            } else {
                // Cancelled or failed
                pendingPickResult?.success(emptyList<Map<String, String>>())
            }
            pendingPickResult = null
        }
    }

    private fun copyFileToInternalStorage(uri: Uri): Map<String, String>? {
        return try {
            val inputStream = contentResolver.openInputStream(uri)
            val originalFileName = getFileName(uri) ?: "audio"
            val fileName = "${System.currentTimeMillis()}_$originalFileName"

            val audioDir = File(filesDir, "audio")
            if (!audioDir.exists()) {
                audioDir.mkdirs()
            }

            val destFile = File(audioDir, fileName)
            val outputStream = FileOutputStream(destFile)

            inputStream?.use { input ->
                outputStream.use { output ->
                    input.copyTo(output)
                }
            }

            Log.d(TAG, "File copied to: ${destFile.absolutePath}")
            mapOf("filePath" to destFile.absolutePath, "displayName" to originalFileName)

        } catch (e: Exception) {
            Log.e(TAG, "Error copying file", e)
            null
        }
    }

    private fun getFileName(uri: Uri): String? {
        var name: String? = null
        contentResolver.query(uri, null, null, null, null)?.use { cursor ->
            val nameIndex = cursor.getColumnIndex(android.provider.OpenableColumns.DISPLAY_NAME)
            if (nameIndex >= 0 && cursor.moveToFirst()) {
                name = cursor.getString(nameIndex)
            }
        }
        if (name == null) {
            name = uri.path?.substringAfterLast('/')
        }
        return name
    }
}
