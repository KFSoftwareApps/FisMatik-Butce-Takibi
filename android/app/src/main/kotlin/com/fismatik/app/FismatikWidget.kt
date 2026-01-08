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
        val packageName = context.packageName
        val resources = context.resources

        appWidgetIds.forEach { widgetId ->
            try {
                Log.d("FismatikWidget", "Start Updating Widget $widgetId")
                
                val options = appWidgetManager.getAppWidgetOptions(widgetId)
                val minHeight = options?.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_HEIGHT) ?: 0
                
                // Dynamic Layout Selection
                val largeLayoutId = resources.getIdentifier("widget_layout_large", "layout", packageName)
                val smallLayoutId = resources.getIdentifier("widget_layout", "layout", packageName)
                
                // Fallback if large layout is missing (should not happen but safe check)
                val layoutId = if (minHeight > 150 && largeLayoutId != 0) largeLayoutId else smallLayoutId
                if (layoutId == 0) {
                    Log.e("FismatikWidget", "CRITICAL: Widget layout not found!")
                    return@forEach
                }

                Log.d("FismatikWidget", "Selected Layout ID: $layoutId (h: $minHeight)")

                val views = RemoteViews(packageName, layoutId).apply {
                    val totalSpending = widgetData.getString("total_spending", "₺0,00")
                    val remainingBudget = widgetData.getString("remaining_budget", "₺0,00")
                    
                    val tvTotalId = resources.getIdentifier("tv_total_spending", "id", packageName)
                    val tvRemainingId = resources.getIdentifier("tv_remaining_budget", "id", packageName)

                    if (tvTotalId != 0) setTextViewText(tvTotalId, totalSpending)
                    if (tvRemainingId != 0) setTextViewText(tvRemainingId, remainingBudget)

                    // Large Layout Extras
                    if (layoutId == largeLayoutId) {
                         val percent = widgetData.getInt("usage_percent", 0)
                         val currentDate = widgetData.getString("current_date", "Bugün")
                         
                         val tvPercentId = resources.getIdentifier("tv_percent", "id", packageName)
                         val tvDateId = resources.getIdentifier("tv_date", "id", packageName)
                         val pbBudgetId = resources.getIdentifier("pb_budget", "id", packageName)

                         try {
                             if (tvPercentId != 0) setTextViewText(tvPercentId, "%$percent Kullanıldı")
                             if (tvDateId != 0) setTextViewText(tvDateId, currentDate)
                             if (pbBudgetId != 0) setProgressBar(pbBudgetId, 100, percent, false)
                         } catch (e: Exception) {
                             Log.e("FismatikWidget", "Error setting large specific fields", e)
                         }
                    }

                    // Click Handling
                    val intent = context.packageManager.getLaunchIntentForPackage(packageName)
                    if (intent != null) {
                        intent.addFlags(android.content.Intent.FLAG_ACTIVITY_NEW_TASK)
                        val pendingIntent = android.app.PendingIntent.getActivity(
                            context, 0, intent, android.app.PendingIntent.FLAG_UPDATE_CURRENT or android.app.PendingIntent.FLAG_IMMUTABLE
                        )
                        
                        if (layoutId == smallLayoutId) {
                            val infoLayoutId = resources.getIdentifier("info_layout", "id", packageName)
                            if (infoLayoutId != 0) setOnClickPendingIntent(infoLayoutId, pendingIntent)
                        } else {
                            val headerLayoutId = resources.getIdentifier("header_layout", "id", packageName)
                            val contentLayoutId = resources.getIdentifier("content_layout", "id", packageName)
                            if (headerLayoutId != 0) setOnClickPendingIntent(headerLayoutId, pendingIntent)
                            if (contentLayoutId != 0) setOnClickPendingIntent(contentLayoutId, pendingIntent)
                        }
                    }

                    // Quick Scan Button
                    try {
                        val scanUri = widgetData.getString("scan_uri", "fismatik://scan") ?: "fismatik://scan"
                        val scanIntent = android.content.Intent(android.content.Intent.ACTION_VIEW, android.net.Uri.parse(scanUri)).apply {
                            setPackage(packageName)
                            addFlags(android.content.Intent.FLAG_ACTIVITY_NEW_TASK)
                        }
                        val scanPendingIntent = android.app.PendingIntent.getActivity(
                            context, 1, scanIntent, android.app.PendingIntent.FLAG_UPDATE_CURRENT or android.app.PendingIntent.FLAG_IMMUTABLE
                        )
                        
                        val btnQuickScanId = resources.getIdentifier("btn_quick_scan", "id", packageName)
                        if (btnQuickScanId != 0) {
                            setOnClickPendingIntent(btnQuickScanId, scanPendingIntent)
                            Log.d("FismatikWidget", "Scan Click Intent Set: $scanUri")
                        }
                    } catch (e: Exception) {
                        Log.e("FismatikWidget", "Error setting scan intent", e)
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
