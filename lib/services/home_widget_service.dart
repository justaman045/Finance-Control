import 'package:home_widget/home_widget.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:money_control/Models/transaction.dart';
import 'package:intl/intl.dart';

/// Service to manage Android Home Screen Widget
/// 
/// This service handles:
/// - Updating widget data
/// - Calculating and displaying balance
/// - Handling widget button clicks
/// - Background updates
class HomeWidgetService {
  static const String _widgetName = 'MoneyControlWidget';
  static const String _androidWidgetName = 'MoneyControlWidgetProvider';
  
  // Data keys for widget
  static const String _balanceKey = 'balance';
  static const String _lastUpdatedKey = 'lastUpdated';
  static const String _usernameKey = 'username';

  /// Initialize the home widget
  static Future<void> initialize() async {
    try {
      await HomeWidget.setAppGroupId('YOUR_GROUP_ID'); // iOS only
      await registerInteractivity();
    } catch (e) {
      print('Error initializing home widget: $e');
    }
  }

  /// Register widget button click handlers
  static Future<void> registerInteractivity() async {
    await HomeWidget.registerBackgroundCallback(backgroundCallback);
  }

  /// Background callback for widget interactions
  static Future<void> backgroundCallback(Uri? uri) async {
    if (uri == null) return;

    // Handle different button actions
    switch (uri.host) {
      case 'refresh':
        await updateWidget();
        break;
      case 'send':
        // Open app to send money screen
        await HomeWidget.initiallyLaunchedFromHomeWidget();
        break;
      case 'receive':
        // Open app to receive money screen
        await HomeWidget.initiallyLaunchedFromHomeWidget();
        break;
    }
  }

  /// Calculate current balance from transactions
  static Future<double> calculateBalance() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return 0.0;

      double balance = 0;

      // Get all sent transactions
      final sentSnaps = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.email)
          .collection('transactions')
          .where('senderId', isEqualTo: user.uid)
          .get();

      for (final doc in sentSnaps.docs) {
        final txn = TransactionModel.fromMap(doc.id, doc.data());
        balance -= txn.amount;
        balance -= txn.tax;
      }

      // Get all received transactions
      final receivedSnaps = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.email)
          .collection('transactions')
          .where('recipientId', isEqualTo: user.uid)
          .get();

      for (final doc in receivedSnaps.docs) {
        final txn = TransactionModel.fromMap(doc.id, doc.data());
        balance += txn.amount;
      }

      return balance;
    } catch (e) {
      print('Error calculating balance: $e');
      return 0.0;
    }
  }

  /// Update widget with latest data
  static Future<bool> updateWidget() async {
    try {
      // Calculate balance
      final balance = await calculateBalance();
      
      // Get user info
      final user = FirebaseAuth.instance.currentUser;
      final username = user?.displayName ?? user?.email?.split('@').first ?? 'User';
      
      // Format balance
      final formattedBalance = '₹ ${balance.toStringAsFixed(2)}';
      
      // Get current time
      final now = DateTime.now();
      final timeFormat = DateFormat('hh:mm a');
      final lastUpdated = 'Updated ${timeFormat.format(now)}';

      // Save data to widget
      await HomeWidget.saveWidgetData<String>(_balanceKey, formattedBalance);
      await HomeWidget.saveWidgetData<String>(_lastUpdatedKey, lastUpdated);
      await HomeWidget.saveWidgetData<String>(_usernameKey, username);

      // Update widget
      await HomeWidget.updateWidget(
        name: _widgetName,
        androidName: _androidWidgetName,
      );

      return true;
    } catch (e) {
      print('Error updating widget: $e');
      return false;
    }
  }

  /// Get launch action from widget click
  static Future<Uri?> getWidgetLaunchAction() async {
    try {
      final uri = await HomeWidget.initiallyLaunchedFromHomeWidget();
      return uri;
    } catch (e) {
      print('Error getting launch action: $e');
      return null;
    }
  }

  /// Schedule periodic widget updates
  static Future<void> scheduleWidgetUpdates() async {
    // Widget updates are handled by WorkManager or similar
    // Update every 30 minutes
    // Implementation depends on your app's requirements
  }

  /// Clear widget data
  static Future<void> clearWidgetData() async {
    try {
      await HomeWidget.saveWidgetData<String>(_balanceKey, '₹ 0.00');
      await HomeWidget.saveWidgetData<String>(_lastUpdatedKey, 'Not logged in');
      await HomeWidget.saveWidgetData<String>(_usernameKey, 'Guest');
      
      await HomeWidget.updateWidget(
        name: _widgetName,
        androidName: _androidWidgetName,
      );
    } catch (e) {
      print('Error clearing widget data: $e');
    }
  }

  /// Update widget after transaction
  static Future<void> updateAfterTransaction() async {
    // Wait a moment for Firestore to sync
    await Future.delayed(Duration(seconds: 1));
    await updateWidget();
  }
}
