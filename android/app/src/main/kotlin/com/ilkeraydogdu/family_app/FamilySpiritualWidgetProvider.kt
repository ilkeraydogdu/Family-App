package com.ilkeraydogdu.family_app

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.widget.RemoteViews

class FamilySpiritualWidgetProvider : AppWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        for (appWidgetId in appWidgetIds) {
            updateWidgetInstance(context, appWidgetManager, appWidgetId)
        }
    }

    companion object {
        const val PREFS_NAME = "family_spiritual_widget_prefs"

        fun updateAllWidgets(context: Context) {
            val manager = AppWidgetManager.getInstance(context)
            val component = ComponentName(context, FamilySpiritualWidgetProvider::class.java)
            val ids = manager.getAppWidgetIds(component)
            for (id in ids) {
                updateWidgetInstance(context, manager, id)
            }
        }

        private fun updateWidgetInstance(
            context: Context,
            appWidgetManager: AppWidgetManager,
            appWidgetId: Int
        ) {
            val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            val style = prefs.getString("widgetStyle", "hadith_dua") ?: "hadith_dua"
            val hadithText = prefs.getString(
                "hadithText",
                "Ameller niyetlere göredir. Herkese ancak niyet ettiği şey vardır."
            ) ?: ""
            val hadithSource = prefs.getString("hadithSource", "Sahîh-i Buhârî") ?: ""
            val duaTurkish = prefs.getString(
                "duaTurkish",
                "Rabbimiz! Bize eşlerimizden ve çocuklarımızdan gözümüzün aydınlığı olacak insanlar ihsan et."
            ) ?: ""
            val duaSource = prefs.getString("duaSource", "Furkan Suresi, 74. Ayet") ?: ""
            val prayerSummary = prefs.getString(
                "prayerSummary",
                "Sabah 06:00 • Öğle 12:53 • İkindi 15:43 • Akşam 18:09"
            ) ?: ""
            val nextPlanSummary = prefs.getString("nextPlanSummary", "Sıradaki Plan: Günlük Ajanda") ?: ""

            val views = RemoteViews(context.packageName, R.layout.family_spiritual_widget)

            when (style) {
                "prayer_plan" -> {
                    views.setTextViewText(R.id.widget_badge_title, "NAMAZ VAKİTLERİ • GÜNÜN DUASI & PLAN")
                    views.setTextViewText(R.id.widget_main_text, duaTurkish)
                    views.setTextViewText(R.id.widget_sub_text, prayerSummary)
                    views.setTextViewText(R.id.widget_next_plan, nextPlanSummary)
                }
                "minimal_quote" -> {
                    views.setTextViewText(R.id.widget_badge_title, "GÜNÜN HADİS-İ ŞERİFİ")
                    views.setTextViewText(R.id.widget_main_text, hadithText)
                    views.setTextViewText(R.id.widget_sub_text, hadithSource)
                    views.setTextViewText(R.id.widget_next_plan, nextPlanSummary)
                }
                else -> {
                    views.setTextViewText(R.id.widget_badge_title, "GÜNÜN HADİSİ & DUASI • AÇIK KAYNAK")
                    views.setTextViewText(R.id.widget_main_text, "Hadis: $hadithText")
                    views.setTextViewText(R.id.widget_sub_text, "Dua: $duaTurkish ($duaSource)")
                    views.setTextViewText(R.id.widget_next_plan, "$prayerSummary • $nextPlanSummary")
                }
            }

            val launchIntent = Intent(context, MainActivity::class.java)
            val pendingIntent = PendingIntent.getActivity(
                context,
                0,
                launchIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            views.setOnClickPendingIntent(R.id.widget_root, pendingIntent)

            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}
