package app.vercel.justaman045.money_control

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.widget.RemoteViews
import android.app.PendingIntent
import android.content.SharedPreferences
import android.os.Build

/**
 * Money Control Home Screen Widget
 * Displays current balance and provides quick access to add transactions
 */
class MoneyControlWidget : AppWidgetProvider() {

    companion object {
        private const val PREFS_NAME = "MoneyControlWidgetPrefs"
        private const val PREF_BALANCE = "balance"
        private const val ACTION_ADD_TRANSACTION = "app.vercel.justaman045.money_control.ACTION_ADD_TRANSACTION"
        private const val ACTION_REFRESH = "app.vercel.justaman045.money_control.ACTION_REFRESH"
    }

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        // Update all widgets
        for (appWidgetId in appWidgetIds) {
            updateAppWidget(context, appWidgetManager, appWidgetId)
        }
    }

    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)
        
        when (intent.action) {
            ACTION_ADD_TRANSACTION -> {
                // Open the main app to add transaction screen
                val launchIntent = context.packageManager.getLaunchIntentForPackage(context.packageName)
                launchIntent?.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                launchIntent?.putExtra("open_add_transaction", true)
                context.startActivity(launchIntent)
            }
            ACTION_REFRESH -> {
                // Refresh all widgets
                val appWidgetManager = AppWidgetManager.getInstance(context)
                val appWidgetIds = appWidgetManager.getAppWidgetIds(
                    android.content.ComponentName(context, MoneyControlWidget::class.java)
                )
                onUpdate(context, appWidgetManager, appWidgetIds)
            }
        }
    }

    override fun onEnabled(context: Context) {
        // Called when the first widget is created
    }

    override fun onDisabled(context: Context) {
        // Called when the last widget is removed
    }

    private fun updateAppWidget(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetId: Int
    ) {
        // Get the current balance from SharedPreferences
        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        val balance = prefs.getFloat(PREF_BALANCE, 0.0f)
        
        // Create RemoteViews
        val views = RemoteViews(context.packageName, R.layout.widget_money_control)
        
        // Update balance text
        views.setTextViewText(R.id.widget_balance, "₹ ${String.format("%.2f", balance)}")
        
        // Set up click listeners
        
        // Click on widget opens the app
        val openAppIntent = context.packageManager.getLaunchIntentForPackage(context.packageName)
        openAppIntent?.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        val openAppPendingIntent = PendingIntent.getActivity(
            context,
            0,
            openAppIntent,
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            } else {
                PendingIntent.FLAG_UPDATE_CURRENT
            }
        )
        views.setOnClickPendingIntent(R.id.widget_container, openAppPendingIntent)
        
        // Add transaction button
        val addIntent = Intent(context, MoneyControlWidget::class.java).apply {
            action = ACTION_ADD_TRANSACTION
        }
        val addPendingIntent = PendingIntent.getBroadcast(
            context,
            1,
            addIntent,
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            } else {
                PendingIntent.FLAG_UPDATE_CURRENT
            }
        )
        views.setOnClickPendingIntent(R.id.widget_add_button, addPendingIntent)
        
        // Refresh button
        val refreshIntent = Intent(context, MoneyControlWidget::class.java).apply {
            action = ACTION_REFRESH
        }
        val refreshPendingIntent = PendingIntent.getBroadcast(
            context,
            2,
            refreshIntent,
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            } else {
                PendingIntent.FLAG_UPDATE_CURRENT
            }
        )
        views.setOnClickPendingIntent(R.id.widget_refresh_button, refreshPendingIntent)
        
        // Update the widget
        appWidgetManager.updateAppWidget(appWidgetId, views)
    }
}

/**
 * Helper class to update widget data from Flutter
 */
class WidgetHelper {
    companion object {
        private const val PREFS_NAME = "MoneyControlWidgetPrefs"
        private const val PREF_BALANCE = "balance"
        
        fun updateBalance(context: Context, balance: Float) {
            // Save balance to SharedPreferences
            val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            prefs.edit().putFloat(PREF_BALANCE, balance).apply()
            
            // Update all widgets
            val appWidgetManager = AppWidgetManager.getInstance(context)
            val appWidgetIds = appWidgetManager.getAppWidgetIds(
                android.content.ComponentName(context, MoneyControlWidget::class.java)
            )
            
            val updateIntent = Intent(context, MoneyControlWidget::class.java).apply {
                action = AppWidgetManager.ACTION_APPWIDGET_UPDATE
                putExtra(AppWidgetManager.EXTRA_APPWIDGET_IDS, appWidgetIds)
            }
            context.sendBroadcast(updateIntent)
        }
    }
}
