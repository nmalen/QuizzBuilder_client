package com.quizzbuilder.mobile_client

import android.app.NotificationChannel
import android.app.NotificationManager
import android.os.Build
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        createDuelsNotificationChannel()
    }

    /**
     * Channel of the duel notifications ("X is waiting for you", invitation
     * accepted). Its name shows in the phone's notification settings. The
     * server sends [DUELS_CHANNEL_ID] as `channel_id`; the same id is the
     * default in AndroidManifest.xml.
     */
    private fun createDuelsNotificationChannel() {
        // Channels exist from Android 8 (API 26); minSdk is 24.
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val channel = NotificationChannel(
            DUELS_CHANNEL_ID,
            getString(R.string.notification_channel_duels),
            NotificationManager.IMPORTANCE_HIGH,
        )
        getSystemService(NotificationManager::class.java)
            .createNotificationChannel(channel)
    }

    companion object {
        const val DUELS_CHANNEL_ID = "duels"
    }
}
