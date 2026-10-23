package com.example.pa_app

import android.content.pm.PackageManager
import android.net.Uri
import android.provider.Telephony
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val channelName = "pa_app/sms"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "getInboxSms" -> {
                        if (checkSelfPermission(android.Manifest.permission.READ_SMS)
                            != PackageManager.PERMISSION_GRANTED
                        ) {
                            result.error("PERMISSION_DENIED", "READ_SMS not granted", null)
                            return@setMethodCallHandler
                        }
                        val limit = (call.argument<Int>("limit")) ?: 500
                        try {
                            result.success(readInbox(limit))
                        } catch (e: Exception) {
                            result.error("SMS_ERROR", e.message, null)
                        }
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private fun readInbox(limit: Int): List<Map<String, Any?>> {
        val messages = ArrayList<Map<String, Any?>>()
        val uri: Uri = Telephony.Sms.Inbox.CONTENT_URI
        val projection = arrayOf(
            Telephony.Sms._ID,
            Telephony.Sms.ADDRESS,
            Telephony.Sms.BODY,
            Telephony.Sms.DATE,
            Telephony.Sms.READ,
        )
        val cursor = contentResolver.query(
            uri,
            projection,
            null,
            null,
            "${Telephony.Sms.DATE} DESC LIMIT $limit",
        )
        cursor?.use { c ->
            val idIdx = c.getColumnIndexOrThrow(Telephony.Sms._ID)
            val addrIdx = c.getColumnIndexOrThrow(Telephony.Sms.ADDRESS)
            val bodyIdx = c.getColumnIndexOrThrow(Telephony.Sms.BODY)
            val dateIdx = c.getColumnIndexOrThrow(Telephony.Sms.DATE)
            val readIdx = c.getColumnIndexOrThrow(Telephony.Sms.READ)
            while (c.moveToNext()) {
                messages.add(
                    mapOf(
                        "id" to c.getString(idIdx),
                        "address" to (c.getString(addrIdx) ?: ""),
                        "body" to (c.getString(bodyIdx) ?: ""),
                        "date" to c.getLong(dateIdx),
                        "read" to (c.getInt(readIdx) == 1),
                    )
                )
            }
        }
        return messages
    }
}
