package com.fismatik.app

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider
import android.util.Log

class FismatikWidget : HomeWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        appWidgetIds.forEach { widgetId ->
            try {
                Log.d("FismatikWidget", "Start Updating Widget $widgetId")
                
                val options = appWidgetManager.getAppWidgetOptions(widgetId)
                val minHeight = options?.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_HEIGHT) ?: 0
                
                // --- SAFE FEATURE LOGIC ---
                // If height > 150dp, use Large Layout. Otherwise Standard.
                val layoutId = if (minHeight > 150) R.layout.widget_layout_large else R.layout.widget_layout
                
                Log.d("FismatikWidget", "Selected Layout: ${if (layoutId == R.layout.widget_layout_large) "LARGE" else "SMALL"} (h: $minHeight)")

                val views = RemoteViews(context.packageName, layoutId).apply {
                    val totalSpending = widgetData.getString("total_spending", "₺0,00")
                    val remainingBudget = widgetData.getString("remaining_budget", "₺0,00")
                    
                    setTextViewText(R.id.tv_total_spending, totalSpending)
                    setTextViewText(R.id.tv_remaining_budget, remainingBudget)

                    // Large Layout Extras
                    if (layoutId == R.layout.widget_layout_large) {
                         val percent = widgetData.getInt("usage_percent", 0)
                         val currentDate = widgetData.getString("current_date", "Bugün")
                         
                         // Try-catch specific to large layout features
                         try {
                             setTextViewText(R.id.tv_percent, "%$percent Kullanıldı")
                             setTextViewText(R.id.tv_date, currentDate)
                             setProgressBar(R.id.pb_budget, 100, percent, false)
                         } catch (e: Exception) {
                             Log.e("FismatikWidget", "Error setting large specific fields", e)
                         }
                    }

                    // Open App on Click
                    val intent = context.packageManager.getLaunchIntentForPackage(context.packageName)
                    if (intent != null) {
                        intent.addFlags(android.content.Intent.FLAG_ACTIVITY_NEW_TASK)
                        val pendingIntent = android.app.PendingIntent.getActivity(
                            context, 0, intent, android.app.PendingIntent.FLAG_UPDATE_CURRENT or android.app.PendingIntent.FLAG_IMMUTABLE
                        )
                        setOnClickPendingIntent(R.id.widget_container, pendingIntent)
                    }
                }

                appWidgetManager.updateAppWidget(widgetId, views)
                Log.d("FismatikWidget", "Widget Updated Successfully")
            } catch (e: Exception) {
                Log.e("FismatikWidget", "CRITICAL ERROR: Widget Update Failed", e)
            }
        }
    }

    override fun onAppWidgetOptionsChanged(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetId: Int,
        newOptions: android.os.Bundle
    ) {
        try {
            val widgetData = es.antonborri.home_widget.HomeWidgetPlugin.getData(context)
            onUpdate(context, appWidgetManager, intArrayOf(appWidgetId), widgetData)
        } catch (e: Exception) {
             Log.e("FismatikWidget", "Error in onAppWidgetOptionsChanged", e)
        }
        super.onAppWidgetOptionsChanged(context, appWidgetManager, appWidgetId, newOptions)
    }
}
