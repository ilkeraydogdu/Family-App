package com.ilkeraydogdu.family_app

import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Context
import android.media.AudioAttributes
import android.media.MediaPlayer
import android.media.Ringtone
import android.media.RingtoneManager
import android.os.Build
import android.os.VibrationEffect
import android.os.Vibrator
import android.os.VibratorManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileOutputStream

class MainActivity : FlutterActivity() {
    private val WIDGET_CHANNEL = "com.ilkeraydogdu.family_app/home_widget"
    private val ALARM_CHANNEL = "com.ilkeraydogdu.family_app/alarm_audio"

    private var alarmMediaPlayer: MediaPlayer? = null
    private var fallbackRingtone: Ringtone? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, WIDGET_CHANNEL)
            .setMethodCallHandler { call, result ->
                if (call.method == "updateHomeWidget") {
                    val prefs = applicationContext.getSharedPreferences(
                        FamilySpiritualWidgetProvider.PREFS_NAME,
                        Context.MODE_PRIVATE
                    )
                    prefs.edit().apply {
                        putString("hadithText", call.argument<String>("hadithText"))
                        putString("hadithSource", call.argument<String>("hadithSource"))
                        putString("duaArabic", call.argument<String>("duaArabic"))
                        putString("duaTurkish", call.argument<String>("duaTurkish"))
                        putString("duaSource", call.argument<String>("duaSource"))
                        putString("zikir", call.argument<String>("zikir"))
                        putString("prayerSummary", call.argument<String>("prayerSummary"))
                        putString("nextPlanSummary", call.argument<String>("nextPlanSummary"))
                        putString("widgetStyle", call.argument<String>("widgetStyle"))
                        apply()
                    }
                    FamilySpiritualWidgetProvider.updateAllWidgets(applicationContext)

                    val requestPin = call.argument<Boolean>("requestPin") ?: false
                    if (requestPin && Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                        val appWidgetManager = AppWidgetManager.getInstance(applicationContext)
                        val myProvider = ComponentName(
                            applicationContext,
                            FamilySpiritualWidgetProvider::class.java
                        )
                        if (appWidgetManager.isRequestPinAppWidgetSupported) {
                            appWidgetManager.requestPinAppWidget(myProvider, null, null)
                        }
                    }
                    result.success(true)
                } else {
                    result.notImplemented()
                }
            }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, ALARM_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "startAlarmLoop" -> {
                        val wavBytes = call.argument<ByteArray>("wavBytes")
                        startNativeAlarm(wavBytes)
                        result.success(true)
                    }
                    "stopAlarmLoop" -> {
                        stopNativeAlarm()
                        result.success(true)
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private fun startNativeAlarm(wavBytes: ByteArray?) {
        stopNativeAlarm()
        try {
            triggerAlarmVibration()
            if (wavBytes != null && wavBytes.isNotEmpty()) {
                val wavFile = File(cacheDir, "active_alarm_melody.wav")
                FileOutputStream(wavFile).use { it.write(wavBytes) }
                val mp = MediaPlayer()
                mp.setAudioAttributes(
                    AudioAttributes.Builder()
                        .setUsage(AudioAttributes.USAGE_ALARM)
                        .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                        .build()
                )
                mp.setDataSource(wavFile.absolutePath)
                mp.isLooping = true
                mp.prepare()
                mp.start()
                alarmMediaPlayer = mp
                return
            }
        } catch (_: Exception) {
        }

        try {
            val uri = RingtoneManager.getDefaultUri(RingtoneManager.TYPE_ALARM)
                ?: RingtoneManager.getDefaultUri(RingtoneManager.TYPE_NOTIFICATION)
            val r = RingtoneManager.getRingtone(applicationContext, uri)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
                r?.isLooping = true
            }
            r?.play()
            fallbackRingtone = r
        } catch (_: Exception) {
        }
    }

    private fun triggerAlarmVibration() {
        try {
            val pattern = longArrayOf(0, 500, 300, 500, 300, 700)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                val vm = getSystemService(Context.VIBRATOR_MANAGER_SERVICE) as? VibratorManager
                vm?.defaultVibrator?.vibrate(
                    VibrationEffect.createWaveform(pattern, 0)
                )
            } else {
                @Suppress("DEPRECATION")
                val v = getSystemService(Context.VIBRATOR_SERVICE) as? Vibrator
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                    v?.vibrate(VibrationEffect.createWaveform(pattern, 0))
                }
            }
        } catch (_: Exception) {
        }
    }

    private fun stopNativeAlarm() {
        try {
            alarmMediaPlayer?.stop()
        } catch (_: Exception) {
        }
        try {
            alarmMediaPlayer?.release()
        } catch (_: Exception) {
        }
        alarmMediaPlayer = null

        try {
            fallbackRingtone?.stop()
        } catch (_: Exception) {
        }
        fallbackRingtone = null

        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                val vm = getSystemService(Context.VIBRATOR_MANAGER_SERVICE) as? VibratorManager
                vm?.defaultVibrator?.cancel()
            } else {
                @Suppress("DEPRECATION")
                val v = getSystemService(Context.VIBRATOR_SERVICE) as? Vibrator
                v?.cancel()
            }
        } catch (_: Exception) {
        }
    }
}
