import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:money_control/Components/bottom_nav_bar.dart';
import 'package:money_control/Components/colors.dart';

class HelpFAQScreen extends StatelessWidget {
  const HelpFAQScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isLight = scheme.brightness == Brightness.light;

    final gradientTop = isLight ? kLightGradientTop : kDarkGradientTop;
    final gradientBottom = isLight ? kLightGradientBottom : kDarkGradientBottom;
    final surface = scheme.surface;
    final border = isLight ? kLightBorder : kDarkBorder;
    final secondaryText = isLight ? kLightTextSecondary : kDarkTextSecondary;

    final List<Map<String, String>> faqs = [
      {
        "q": "How do I add a new transaction?",
        "a":
        "Tap on the '+' or 'Add Transaction' button on the Home screen or the quick send row. Fill in the details and press 'Save'."
      },
      {
        "q": "How do I edit or delete an existing transaction?",
        "a":
        "Tap any transaction in your history to view details. From the detail page, use edit or delete icons in the corner."
      },
      {
        "q": "How do I manage or add custom categories?",
        "a":
        "You can add a new category while adding/editing a transaction using the dropdown menu on the transaction form."
      },
      {
        "q": "Will my data sync if I lose connection?",
        "a":
        "Yes, Money Control supports offline mode. Your changes will be saved locally and synced to the cloud once you reconnect."
      },
      {
        "q": "How do I switch between dark and light modes?",
        "a":
        "Go to Settings > Dark Mode to toggle between appearance modes."
      },
      {
        "q": "Can I export or share my transactions?",
        "a":
        "You can share screenshots for individual transactions from the details view. Data export features are coming soon."
      },
      {
        "q": "How do I reset my password?",
        "a":
        "Go to Settings > Change Password. Enter your email address to receive a password reset link."
      },
      // Add more FAQs as needed!
    ];

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
          centerTitle: true,
          title: Text(
            "Help / FAQ",
            style: TextStyle(
              color: scheme.onBackground,
              fontWeight: FontWeight.bold,
              fontSize: 18.sp,
            ),
          ),
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios, color: scheme.onBackground, size: 20.sp),
            onPressed: () => Navigator.of(context).pop(),
          ),
          toolbarHeight: 64.h,
        ),
        body: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 8.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ...faqs.map((faq) => Padding(
                padding: EdgeInsets.only(bottom: 17.h),
                child: Container(
                  decoration: BoxDecoration(
                    color: surface,
                    borderRadius: BorderRadius.circular(16.r),
                    border: Border.all(color: border, width: 1),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.017),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                  padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 13.h),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        faq["q"] ?? "",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15.sp,
                          color: scheme.primary,
                        ),
                      ),
                      SizedBox(height: 5.h),
                      Text(
                        faq["a"] ?? "",
                        style: TextStyle(
                          color: scheme.onSurface.withOpacity(0.91),
                          fontSize: 13.5.sp,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              )),
              SizedBox(height: 30.h),
              Center(
                child: Text(
                  "Still have questions?\nContact support at support@moneycontrol.app",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: secondaryText,
                    fontSize: 13.sp,
                  ),
                ),
              ),
              SizedBox(height: 24.h),
            ],
          ),
        ),
        bottomNavigationBar: BottomNavBar(
          currentIndex: 2,
        ),
      ),
    );
  }
}
