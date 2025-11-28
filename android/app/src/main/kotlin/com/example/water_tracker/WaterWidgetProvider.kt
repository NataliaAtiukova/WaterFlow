package com.example.water_tracker

import android.appwidget.AppWidgetManager
import android.content.Context
import android.net.Uri
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetBackgroundIntent
import es.antonborri.home_widget.HomeWidgetProvider

class WaterWidgetProvider : HomeWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: android.content.SharedPreferences
    ) {
        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.home_widget)
            val percent = widgetData.getInt("percent", 0)
            val remaining = widgetData.getInt("remaining", 0)

            views.setTextViewText(R.id.txtPercent, "$percent%")
            views.setTextViewText(R.id.txtRemaining, "Осталось: ${remaining} мл")

            val addIntent = HomeWidgetBackgroundIntent.getBroadcast(
                context,
                Uri.parse("waterwidget://add_200")
            )
            views.setOnClickPendingIntent(R.id.btnAdd, addIntent)

            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}
