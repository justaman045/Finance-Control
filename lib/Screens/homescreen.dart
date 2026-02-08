import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' as rendering;
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart'; // Animations
import 'package:money_control/Components/balance_card.dart';
import 'package:money_control/Components/bottom_nav_bar.dart';
import 'package:money_control/l10n/app_localizations.dart';

import 'package:money_control/Components/methods.dart';

import 'package:money_control/Controllers/profile_controller.dart';
import 'package:money_control/Components/quick_send.dart';
import 'package:money_control/Components/recent_payment_list.dart';
import 'package:money_control/Components/section_title.dart';
import 'package:money_control/Screens/cateogaries_history.dart';
import 'package:money_control/Screens/edit_profile.dart';
import 'package:money_control/Screens/forecast_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:money_control/Models/user_model.dart';
import 'package:money_control/Screens/transaction_history.dart';
import 'package:money_control/Screens/transaction_search.dart';
import 'package:money_control/Screens/recurring_payments_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

// 🔥 import background worker
import 'package:money_control/Services/background_worker.dart';
import 'package:money_control/Controllers/tutorial_controller.dart';
import 'package:money_control/Controllers/transaction_controller.dart';
import 'package:get/get.dart';
import 'package:money_control/Components/colors.dart';
import 'package:money_control/Components/glass_container.dart';
import 'package:money_control/Controllers/subscription_controller.dart';
import 'package:money_control/Screens/subscription_screen.dart';

class BankingHomeScreen extends StatefulWidget {
  const BankingHomeScreen({super.key});

  @override
  State<BankingHomeScreen> createState() => _BankingHomeScreenState();
}

class _BankingHomeScreenState extends State<BankingHomeScreen> {
  final ProfileController _profileController = Get.put(ProfileController());

  final TransactionController _transactionController = Get.put(
    TransactionController(),
  );

  final ValueNotifier<bool> _isBottomBarVisible = ValueNotifier(true);

  final GlobalKey _keyTransactionList = GlobalKey();
  final GlobalKey _keyNavBar = GlobalKey();

  @override
  void dispose() {
    _isBottomBarVisible.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _updateLastOpenedLocal();

    // Start WorkManager & Tutorial
    WidgetsBinding.instance.addPostFrameCallback((_) {
      BackgroundWorker.init();
      TutorialController.showHomeTutorial(
        context,
        keyTransactionList: _keyTransactionList,
        keyNavBar: _keyNavBar,
      );
    });
  }

  /// Save last time the home screen was opened AND user email for background tasks
  Future<void> _updateLastOpenedLocal() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt("lastOpened", DateTime.now().millisecondsSinceEpoch);

    final user = FirebaseAuth.instance.currentUser;
    if (user != null && user.email != null) {
      await prefs.setString("user_email", user.email!);
    }
  }

  Future<void> _onRefresh() async {
    HapticFeedback.mediumImpact();
    await _updateLastOpenedLocal();
    setState(() {}); // Simple rebuild
    await Future.delayed(const Duration(milliseconds: 400));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final user = FirebaseAuth.instance.currentUser;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark ? AppColors.darkGradient : AppColors.lightGradient,
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: Padding(
            padding: EdgeInsets.only(left: 16.w, top: 2.h, bottom: 2.h),
            child: GestureDetector(
              onTap: () => gotoPage(const EditProfileScreen()),
              child: Obx(() {
                final url = _profileController.photoURL.value;
                return Hero(
                  tag: 'profile_pic',
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.1),
                        width: 1.5,
                      ),
                      image: DecorationImage(
                        image: url.isNotEmpty
                            ? NetworkImage(url)
                            : const AssetImage('assets/profile.png')
                                  as ImageProvider,
                        fit: BoxFit.cover,
                      ),
                    ),
                    child: Container(
                      width: 34.w,
                      height: 34.w,
                      decoration: const BoxDecoration(shape: BoxShape.circle),
                    ),
                  ),
                );
              }),
            ),
          ),
          title: GestureDetector(
            onTap: () => gotoPage(const EditProfileScreen()),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalizations.of(context)!.welcomeBack,
                  style: theme.textTheme.bodyMedium,
                ),
                StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                  stream: user == null
                      ? null
                      : FirebaseFirestore.instance
                            .collection('users')
                            .doc(user.email)
                            .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return shimmerText(theme);
                    }
                    if (!snapshot.hasData || !snapshot.data!.exists) {
                      return blankText(theme);
                    }
                    final userModel = UserModel.fromMap(
                      user!.uid,
                      snapshot.data!.data(),
                    );
                    return Text(
                      userModel.firstName != null &&
                              userModel.firstName!.isNotEmpty
                          ? userModel.firstName!
                          : (user.displayName != null &&
                                    user.displayName!.isNotEmpty
                                ? user.displayName!
                                : 'User'),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 16.sp,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          actions: [
            // 💎 PRO STATUS
            if (FirebaseAuth.instance.currentUser?.email !=
                "developerlife69@gmail.com")
              Obx(() {
                final isPro = Get.find<SubscriptionController>().isPro;
                return _buildActionButton(
                  icon: isPro
                      ? Icons.verified_user_rounded
                      : Icons.diamond_outlined,
                  onTap: () => gotoPage(const SubscriptionScreen()),
                  theme: theme,
                  color: isPro ? Colors.cyanAccent : null, // Highlight if Pro
                );
              }),
            SizedBox(width: 8.w),

            // 🔍 NEW SEARCH BUTTON
            _buildActionButton(
              icon: Icons.search,
              onTap: () => gotoPage(const TransactionSearchPage()),
              theme: theme,
              heroTag: 'search_bar',
            ),
            SizedBox(width: 8.w),

            // 📅 SUBSCRIPTIONS BUTTON
            _buildActionButton(
              icon: Icons.event_repeat,
              onTap: () => gotoPage(const RecurringPaymentsScreen()),
              theme: theme,
            ),
            SizedBox(width: 8.w),

            // 📈 FORECAST BUTTON
            _buildActionButton(
              icon: Icons.trending_up,
              onTap: () => gotoPage(const ForecastScreen()),
              theme: theme,
            ),
            SizedBox(width: 6.w),
          ],

          toolbarHeight: 64.h,
        ),
        body: NotificationListener<UserScrollNotification>(
          onNotification: (notification) {
            if (notification.direction == rendering.ScrollDirection.reverse) {
              if (_isBottomBarVisible.value) _isBottomBarVisible.value = false;
            } else if (notification.direction ==
                rendering.ScrollDirection.forward) {
              if (!_isBottomBarVisible.value) _isBottomBarVisible.value = true;
            }
            return true;
          },
          child: SafeArea(
            bottom: false,
            child: RefreshIndicator(
              onRefresh: _onRefresh,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.fromLTRB(16.w, 4.h, 16.w, 100.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    BalanceCard()
                        .animate()
                        .fadeIn(duration: 600.ms)
                        .slideY(begin: -0.1, end: 0, curve: Curves.easeOutBack),
                    SizedBox(height: 12.h), // Added some spacing after card
                    SectionTitle(
                          title: AppLocalizations.of(context)!.quickSend,
                          color: scheme.onSurface,
                          accentColor: AppColors.primary,
                          onTap: () =>
                              gotoPage(const CategoriesHistoryScreen()),
                        )
                        .animate()
                        .fadeIn(delay: 200.ms, duration: 500.ms)
                        .slideX(begin: -0.1, end: 0, curve: Curves.easeOut),
                    SizedBox(height: 12.h),
                    QuickSendRow(
                          cardColor: isDark
                              ? AppColors.darkSurface.withValues(alpha: 0.5)
                              : AppColors.lightSurface.withValues(alpha: 0.6),
                          textColor: scheme.onSurface,
                        )
                        .animate()
                        .fadeIn(delay: 300.ms, duration: 500.ms)
                        .slideX(begin: 0.1, end: 0, curve: Curves.easeOut),
                    SizedBox(height: 18.h),
                    SectionTitle(
                          title: AppLocalizations.of(
                            context,
                          )!.recentTransactions,
                          color: scheme.onSurface,
                          accentColor: AppColors.primary,
                          onTap: () => gotoPage(TransactionHistoryScreen()),
                        )
                        .animate()
                        .fadeIn(delay: 400.ms, duration: 500.ms)
                        .slideY(begin: 0.2, end: 0, curve: Curves.easeOut),
                    SizedBox(height: 12.h),
                    RecentPaymentList(
                          key: _keyTransactionList,
                          cardColor: isDark
                              ? AppColors.darkSurface.withValues(alpha: 0.5)
                              : AppColors.lightSurface.withValues(alpha: 0.6),
                          textColor: scheme.onSurface,
                          receivedColor: AppColors.success,
                          sentColor: AppColors.error,
                        )
                        .animate()
                        .fadeIn(delay: 500.ms, duration: 600.ms)
                        .slideY(begin: 0.1, end: 0, curve: Curves.easeOut),
                  ],
                ),
              ),
            ),
          ),
        ),
        extendBody: true,
        bottomNavigationBar: ValueListenableBuilder<bool>(
          valueListenable: _isBottomBarVisible,
          builder: (context, visible, child) {
            return AnimatedSlide(
              duration: const Duration(milliseconds: 200),
              offset: visible ? Offset.zero : const Offset(0, 1),
              child: child,
            );
          },
          child: BottomNavBar(key: _keyNavBar, currentIndex: 0),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required VoidCallback onTap,
    required ThemeData theme,
    String? heroTag,
    Color? color,
  }) {
    Widget content = Icon(
      icon,
      color: color ?? theme.colorScheme.onSurface.withValues(alpha: 0.8),
      size: 22.sp,
    );

    if (heroTag != null) {
      content = Hero(tag: heroTag, child: content);
    }

    return GlassContainer(
      padding: EdgeInsets.zero,
      borderRadius: BorderRadius.circular(25.r),
      width: 45.w,
      height: 40.h,
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: content,
    );
  }

  Widget shimmerText(ThemeData theme) => Text(
    '...',
    style: theme.textTheme.bodyLarge?.copyWith(
      fontWeight: FontWeight.bold,
      fontSize: 16.sp,
    ),
  );

  Widget blankText(ThemeData theme) => Text(
    'User',
    style: theme.textTheme.bodyLarge?.copyWith(
      fontWeight: FontWeight.bold,
      fontSize: 16.sp,
    ),
  );
}
