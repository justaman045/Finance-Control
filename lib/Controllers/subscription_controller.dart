import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:money_control/main.dart'; // For rootScaffoldMessengerKey
import 'package:money_control/Services/notification_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum SubscriptionStatus { free, pending, pro }

class SubscriptionController extends GetxController {
  static SubscriptionController get to => Get.find();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Observable subscription status
  Rx<SubscriptionStatus> subscriptionStatus = SubscriptionStatus.free.obs;

  // Computed property for easy access
  bool get isPro => subscriptionStatus.value == SubscriptionStatus.pro;
  bool get isPending => subscriptionStatus.value == SubscriptionStatus.pending;

  @override
  void onInit() {
    super.onInit();
    checkSubscriptionStatus();
  }

  /// Check subscription status from Firestore
  void checkSubscriptionStatus() {
    final user = _auth.currentUser;
    if (user != null) {
      _firestore.collection('users').doc(user.email).snapshots().listen((
        snapshot,
      ) async {
        if (snapshot.exists) {
          final data = snapshot.data();
          if (data != null) {
            SubscriptionStatus newStatus = SubscriptionStatus.free;

            // Admin Override
            bool isAdmin = user.email == "developerlife69@gmail.com";
            if (isAdmin) {
              newStatus = SubscriptionStatus.pro;
            }
            // Check for 'status' string first
            else if (data.containsKey('subscriptionStatus')) {
              final statusStr = data['subscriptionStatus'] as String;
              newStatus = _parseStatus(statusStr);
            }
            // Fallback for backward compatibility
            else if (data.containsKey('isPro') && data['isPro'] == true) {
              newStatus = SubscriptionStatus.pro;
            }

            // check expiry (Skip for admin to prevent loop)
            if (!isAdmin &&
                newStatus == SubscriptionStatus.pro &&
                data.containsKey('expiryDate')) {
              final expiry = (data['expiryDate'] as Timestamp).toDate();
              if (DateTime.now().isAfter(expiry)) {
                // Expired!
                newStatus = SubscriptionStatus.free;
                _expireSubscription(user.email!);
              }
            }

            // --- NOTIFICATION LOGIC ---
            // We use SharedPreferences to check if the status changed while the app was closed.
            final prefs = await SharedPreferences.getInstance();
            final lastStatusStr = prefs.getString('last_sub_status');
            final lastStatus = lastStatusStr != null
                ? _parseStatus(lastStatusStr)
                : SubscriptionStatus.free;

            // If this is the very first check (lastStatusStr is null) and we are pro,
            // we might not want to notify (restoring session), OR maybe we do?
            // Let's notify only if there is a detected change from what we last knew.

            // Allow notification if we have a stored status OR if it's a runtime update (not first load)
            // But actually, just comparing stored vs new is the robust way.
            if (newStatus != lastStatus) {
              // Special case: If installing for first time (lastStatusStr == null) and Free, don't notify.
              // If first time and Pro, maybe notify "Welcome Back".
              // For now, let's treat "no record" as "free".

              if (lastStatusStr != null ||
                  newStatus != SubscriptionStatus.free) {
                _handleStatusChange(lastStatus, newStatus);
              }

              // Update storage
              await prefs.setString('last_sub_status', newStatus.name);
            }

            subscriptionStatus.value = newStatus;
          }
        } else {
          subscriptionStatus.value = SubscriptionStatus.free;
        }
      });
    } else {
      subscriptionStatus.value = SubscriptionStatus.free;
      // Listen for auth changes to re-check
      _auth.authStateChanges().listen((user) {
        if (user != null) {
          checkSubscriptionStatus();
        } else {
          subscriptionStatus.value = SubscriptionStatus.free;
        }
      });
    }
  }

  Future<void> _expireSubscription(String email) async {
    await _firestore.collection('users').doc(email).set({
      'subscriptionStatus': 'free',
      'isPro': false,
      'expiredAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    NotificationService.showNotification(
      title: "Subscription Expired",
      body:
          "Your Pro plan has expired. Renew now to restore access to features.",
    );
  }

  void _handleStatusChange(
    SubscriptionStatus oldStatus,
    SubscriptionStatus newStatus,
  ) {
    if (oldStatus == SubscriptionStatus.pending &&
        newStatus == SubscriptionStatus.pro) {
      // System Notification
      NotificationService.showNotification(
        title: "Upgrade Approved! 🎉",
        body: "Congratulations! You are now a Pro member.",
      );

      rootScaffoldMessengerKey.currentState?.showSnackBar(
        const SnackBar(
          content: Text(
            "Upgrade Approved! 🎉\nCongratulations! You are now a Pro member.",
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 5),
        ),
      );
    } else if (oldStatus == SubscriptionStatus.pending &&
        newStatus == SubscriptionStatus.free) {
      // System Notification
      NotificationService.showNotification(
        title: "Request Rejected",
        body: "Your upgrade request was rejected. Contact support for help.",
      );

      rootScaffoldMessengerKey.currentState?.showSnackBar(
        const SnackBar(
          content: Text("Request Updates\nYour upgrade request was rejected."),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 5),
        ),
      );
    } else if (newStatus == SubscriptionStatus.pro) {
      // System Notification
      NotificationService.showNotification(
        title: "You are now Pro! 💎",
        body: "Your subscription status has been updated to Pro.",
      );

      rootScaffoldMessengerKey.currentState?.showSnackBar(
        const SnackBar(
          content: Text("You are now Pro! 💎"),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 4),
        ),
      );
    } else if (oldStatus == SubscriptionStatus.pro &&
        newStatus == SubscriptionStatus.free) {
      // System Notification
      NotificationService.showNotification(
        title: "Subscription Ended ⚠️",
        body: "Your Pro subscription has ended. You are now on the Free plan.",
      );

      rootScaffoldMessengerKey.currentState?.showSnackBar(
        const SnackBar(
          content: Text("Subscription Ended ⚠️\nYou are now on the Free plan."),
          backgroundColor: Colors.orangeAccent,
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 5),
        ),
      );
    }
  }

  SubscriptionStatus _parseStatus(String status) {
    switch (status) {
      case 'pro':
        return SubscriptionStatus.pro;
      case 'pending':
        return SubscriptionStatus.pending;
      default:
        return SubscriptionStatus.free;
    }
  }

  /// User requests an upgrade (sets status to pending)
  Future<void> requestUpgrade(String transactionId, String planType) async {
    final user = _auth.currentUser;
    if (user != null && user.email != null) {
      await _firestore.collection('users').doc(user.email).set({
        'subscriptionStatus': 'pending',
        'lastUpgradeRequest': FieldValue.serverTimestamp(),
        'transactionId': transactionId,
        'requestedPlan': planType,
      }, SetOptions(merge: true));
    }
  }

  /// Admin approves an upgrade
  Future<void> approveUpgrade(String email) async {
    // 1. Get requested plan
    final doc = await _firestore.collection('users').doc(email).get();
    String plan = 'Monthly';
    if (doc.exists &&
        doc.data() != null &&
        doc.data()!.containsKey('requestedPlan')) {
      plan = doc.data()!['requestedPlan'];
    }

    // 2. Calculate Expiry
    DateTime now = DateTime.now();
    DateTime expiryDate = plan == 'Yearly'
        ? now.add(const Duration(days: 365))
        : now.add(const Duration(days: 30));

    await _firestore.collection('users').doc(email).set({
      'subscriptionStatus': 'pro',
      'isPro': true,
      'proSince': FieldValue.serverTimestamp(),
      'planType': plan,
      'expiryDate': Timestamp.fromDate(expiryDate),
    }, SetOptions(merge: true));
  }

  /// Admin rejects an upgrade
  Future<void> rejectUpgrade(String email) async {
    await _firestore.collection('users').doc(email).set({
      'subscriptionStatus': 'free',
      'isPro': false,
    }, SetOptions(merge: true));
  }

  /// Manually set pro status (for testing)
  Future<void> setProStatus(bool status) async {
    final user = _auth.currentUser;
    if (user != null && user.email != null) {
      await _firestore.collection('users').doc(user.email).set({
        'subscriptionStatus': status ? 'pro' : 'free',
        'isPro': status,
      }, SetOptions(merge: true));
    }
  }
}
