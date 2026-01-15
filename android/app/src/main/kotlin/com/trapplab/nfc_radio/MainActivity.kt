package com.trapplab.nfc_radio

import android.app.Activity
import android.content.Intent
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

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL_NAME)
        methodChannel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "pickAudio" -> {
                    val filterAudioOnly = call.argument<Boolean>("filterAudioOnly") ?: false
                    pickAudio(filterAudioOnly)
                    result.success("started")
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun pickAudio(filterAudioOnly: Boolean) {
        val intent = Intent(Intent.ACTION_GET_CONTENT).apply {
            type = if (filterAudioOnly) "audio/*" else "*/*"
            addCategory(Intent.CATEGORY_OPENABLE)
        }
        startActivityForResult(Intent.createChooser(intent, "Select Audio App"), REQUEST_CODE_PICK_AUDIO)
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        
        if (requestCode == REQUEST_CODE_PICK_AUDIO && resultCode == Activity.RESULT_OK) {
            data?.data?.let { uri ->
                copyFileToInternalStorage(uri)
            }
        }
    }

    private fun copyFileToInternalStorage(uri: Uri) {
        try {
            val inputStream = contentResolver.openInputStream(uri)
            val originalFileName = getFileName(uri) ?: "audio"
            val fileName = "${System.currentTimeMillis()}_$originalFileName"
            
            // Create audio directory if it doesn't exist
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
            val result = mapOf(
                "filePath" to destFile.absolutePath,
                "displayName" to originalFileName
            )
            methodChannel?.invokeMethod("onAudioPicked", result)
            
        } catch (e: Exception) {
            Log.e(TAG, "Error copying file", e)
            // Fallback to original URI if copy fails
            methodChannel?.invokeMethod("onAudioPicked", uri.toString())
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
