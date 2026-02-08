import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:money_control/main.dart'; // For rootScaffoldMessengerKey
import 'package:money_control/Services/notification_service.dart';

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

  bool _isFirstLoad = true;

  /// Check subscription status from Firestore
  void checkSubscriptionStatus() {
    final user = _auth.currentUser;
    if (user != null) {
      _firestore.collection('users').doc(user.email).snapshots().listen((
        snapshot,
      ) {
        if (snapshot.exists) {
          final data = snapshot.data();
          if (data != null) {
            SubscriptionStatus newStatus = SubscriptionStatus.free;

            // Admin Override
            if (user.email == "developerlife69@gmail.com") {
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

            // check expiry
            if (newStatus == SubscriptionStatus.pro &&
                data.containsKey('expiryDate')) {
              final expiry = (data['expiryDate'] as Timestamp).toDate();
              if (DateTime.now().isAfter(expiry)) {
                // Expired!
                newStatus = SubscriptionStatus.free;
                _expireSubscription(user.email!);
              }
            }

            // Handle Status Change Notification
            if (!_isFirstLoad && subscriptionStatus.value != newStatus) {
              _handleStatusChange(subscriptionStatus.value, newStatus);
            }

            subscriptionStatus.value = newStatus;
            _isFirstLoad = false;
          }
        } else {
          subscriptionStatus.value = SubscriptionStatus.free;
          _isFirstLoad = false;
        }
      });
    } else {
      subscriptionStatus.value = SubscriptionStatus.free;
      _isFirstLoad = false;
      // Listen for auth changes to re-check
      _auth.authStateChanges().listen((user) {
        if (user != null) {
          _isFirstLoad = true; // Reset for new user
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
