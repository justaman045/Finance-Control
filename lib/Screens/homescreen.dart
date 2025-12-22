import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:money_control/Components/balance_card.dart';
import 'package:money_control/Components/bottom_nav_bar.dart';
import 'package:money_control/Components/colors.dart';
import 'package:money_control/Components/methods.dart';
import 'package:money_control/Components/quick_send.dart';
import 'package:money_control/Components/recent_payment_list.dart';
import 'package:money_control/Components/section_title.dart';
import 'package:money_control/Screens/cateogaries_history.dart';
import 'package:money_control/Screens/edit_profile.dart';
import 'package:money_control/Screens/forcast.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:money_control/Models/user_model.dart';
import 'package:money_control/Screens/transaction_history.dart';
import 'package:money_control/Screens/transaction_search.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:money_control/Services/background_worker.dart';

// 🔥 Firebase Analytics
import 'package:firebase_analytics/firebase_analytics.dart';

class BankingHomeScreen extends StatefulWidget {
  const BankingHomeScreen({super.key});

  @override
  State<BankingHomeScreen> createState() => _BankingHomeScreenState();
}

class _BankingHomeScreenState extends State<BankingHomeScreen> {
  final FirebaseAnalytics analytics = FirebaseAnalytics.instance;

  Key _balanceKey = UniqueKey();
  Key _quickSendKey = UniqueKey();

  @override
  void initState() {
    super.initState();

    analytics.logEvent(name: "home_screen_loaded");

    _updateLastOpenedLocal();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await BackgroundWorker.init();
      analytics.logEvent(name: "background_worker_initialized");
    });
  }

  /// Save last opened timestamp
  Future<void> _updateLastOpenedLocal() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt("lastOpened", DateTime.now().millisecondsSinceEpoch);

    analytics.logEvent(name: "home_last_open_updated");
  }

  /// Refresh home screen
  Future<void> _onRefresh() async {
    analytics.logEvent(name: "home_refreshed");

    await _updateLastOpenedLocal();

    setState(() {
      _balanceKey = UniqueKey();
      _quickSendKey = UniqueKey();
    });

    await Future.delayed(const Duration(milliseconds: 400));
  }

  /// 🔥 Fetch categories sorted by usage WITH analytics logging
  Future<List<String>> fetchCategoriesSortedByUsage() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return [];

    final txRef = FirebaseFirestore.instance
        .collection('transactions')
        .doc(user.email)
        .collection('transactions');

    try {
      final snapshot = await txRef.get();

      Map<String, int> categoryCounts = {};

      for (var doc in snapshot.docs) {
        final category = doc['category'] as String?;
        if (category != null && category.isNotEmpty) {
          categoryCounts[category] = (categoryCounts[category] ?? 0) + 1;
        }
      }

      analytics.logEvent(
        name: "fetch_category_usage",
        parameters: {"category_count": categoryCounts.length},
      );

      final sortedCategories = categoryCounts.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      return sortedCategories.map((e) => e.key).toList();
    } catch (e) {
      analytics.logEvent(
        name: "fetch_category_usage_error",
        parameters: {"error": e.toString()},
      );
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    analytics.logEvent(name: "screen_view", parameters: {
    'firebase_screen': "BankingHomeScreen",
    'firebase_screen_class': "BankingHomeScreen",
    },);
    
    final scheme = Theme.of(context).colorScheme;
    final Color gradientTop =
    scheme.brightness == Brightness.light ? kLightGradientTop : kDarkGradientTop;
    final Color gradientBottom =
    scheme.brightness == Brightness.light ? kLightGradientBottom : kDarkGradientBottom;

    final user = FirebaseAuth.instance.currentUser;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [gradientTop, gradientBottom],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,

          // ------------------------
          // 🔥 PROFILE TAP LOGGING
          // ------------------------
          leading: Padding(
            padding: EdgeInsets.only(left: 16.w, top: 2.h, bottom: 2.h),
            child: GestureDetector(
              onTap: () {
                analytics.logEvent(name: "open_edit_profile");
                gotoPage(const EditProfileScreen());
              },
              child: CircleAvatar(
                radius: 17.w,
                backgroundColor: scheme.surface,
                child: Image.asset(
                  'assets/profile.png',
                  width: 28.w,
                  height: 28.w,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),

          title: GestureDetector(
            onTap: () {
              analytics.logEvent(name: "open_edit_profile");
              gotoPage(const EditProfileScreen());
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome back,',
                  style: TextStyle(
                    color: scheme.onBackground,
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w400,
                  ),
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
                      return shimmerText(scheme);
                    }

                    if (!snapshot.hasData || !snapshot.data!.exists) {
                      return blankText(scheme);
                    }

                    final userModel =
                    UserModel.fromMap(user!.uid, snapshot.data!.data());

                    return Text(
                      userModel.firstName != null && userModel.firstName!.isNotEmpty
                          ? userModel.firstName!
                          : (user.displayName ?? 'User'),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16.sp,
                        color: scheme.onBackground,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),

          actions: [
            // 🔍 SEARCH
            Container(
              decoration: BoxDecoration(
                color: scheme.surface,
                borderRadius: BorderRadius.circular(25.r),
              ),
              width: 45.w,
              height: 40.h,
              child: IconButton(
                icon: Icon(Icons.search,
                    color: scheme.onSurface.withOpacity(0.9), size: 22.sp),
                onPressed: () {
                  analytics.logEvent(name: "open_search_page");
                  gotoPage(const TransactionSearchPage());
                },
              ),
            ),
            SizedBox(width: 8.w),

            // 📈 FORECAST
            Container(
              decoration: BoxDecoration(
                color: scheme.surface,
                borderRadius: BorderRadius.circular(25.r),
              ),
              width: 45.w,
              height: 40.h,
              child: IconButton(
                icon: Icon(Icons.trending_up,
                    color: scheme.onSurface.withOpacity(0.8), size: 24.sp),
                onPressed: () {
                  analytics.logEvent(name: "open_forecast_page");
                  gotoPage(const ForecastScreen());
                },
              ),
            ),
            SizedBox(width: 6.w),
          ],

          toolbarHeight: 64.h,
        ),

        // ------------------------------------------------
        // BODY CONTENT
        // ------------------------------------------------
        body: SafeArea(
          child: Column(
            children: [
              BalanceCard(key: _balanceKey),

              Expanded(
                child: RefreshIndicator(
                  onRefresh: _onRefresh,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: EdgeInsets.fromLTRB(16.w, 4.h, 16.w, 16.h),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SectionTitle(
                          title: 'Quick Send',
                          color: scheme.onSurface,
                          accentColor: scheme.primary,
                          onTap: () {
                            analytics.logEvent(name: "tap_quick_send_section");
                            gotoPage(const CategoriesHistoryScreen());
                          },
                        ),

                        SizedBox(height: 12.h),

                        QuickSendRow(
                          key: _quickSendKey,
                          cardColor: scheme.surface,
                          textColor: scheme.onSurface,
                        ),

                        SizedBox(height: 18.h),

                        SectionTitle(
                          title: 'Recent Transactions',
                          color: scheme.onSurface,
                          accentColor: scheme.primary,
                          onTap: () {
                            analytics.logEvent(name: "open_recent_transactions");
                            gotoPage(TransactionHistoryScreen());
                          },
                        ),

                        SizedBox(height: 12.h),

                        RecentPaymentList(
                          cardColor: scheme.surface,
                          textColor: scheme.onSurface,
                          receivedColor: const Color(0xFF0FA958),
                          sentColor: scheme.error,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        bottomNavigationBar: const BottomNavBar(currentIndex: 0),
      ),
    );
  }

  Widget shimmerText(ColorScheme scheme) => Text(
    '...',
    style: TextStyle(
      fontWeight: FontWeight.bold,
      fontSize: 16.sp,
      color: scheme.onBackground.withOpacity(0.5),
    ),
  );

  Widget blankText(ColorScheme scheme) => Text(
    '',
    style: TextStyle(
      fontWeight: FontWeight.bold,
      fontSize: 16.sp,
      color: scheme.onBackground,
    ),
  );
}
