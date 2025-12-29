package com.example.nfc_radio

import io.flutter.embedding.android.FlutterActivity
import android.content.Intent
import android.nfc.NfcAdapter

class MainActivity : FlutterActivity() {
    
    override fun onNewIntent(intent: Intent) {
        // Handle NFC intents - this ensures NFC tags are processed by Flutter
        intent?.let { nonNullIntent ->
            val action = nonNullIntent.action
            if (action == NfcAdapter.ACTION_TECH_DISCOVERED || 
                action == NfcAdapter.ACTION_NDEF_DISCOVERED ||
                action == NfcAdapter.ACTION_TAG_DISCOVERED) {
                // The NFC tag will be handled by the nfc_manager plugin
                // This method ensures the intent doesn't get consumed by other apps
                setIntent(nonNullIntent)
            }
            // Call super with the non-null intent
            super.onNewIntent(nonNullIntent)
        }
    }
    
    override fun onResume() {
        super.onResume()
        // Ensure NFC is properly handled when app comes to foreground
        val intent = intent
        val action = intent.action
        if (action == NfcAdapter.ACTION_TECH_DISCOVERED || 
            action == NfcAdapter.ACTION_NDEF_DISCOVERED ||
            action == NfcAdapter.ACTION_TAG_DISCOVERED) {
            setIntent(intent)
        }
    }
}
