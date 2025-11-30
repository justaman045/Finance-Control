import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:money_control/Components/bottom_nav_bar.dart';
import 'package:money_control/Components/colors.dart';
import 'package:package_info_plus/package_info_plus.dart';

class AboutApplicationScreen extends StatefulWidget {
  const AboutApplicationScreen({super.key});

  @override
  State<AboutApplicationScreen> createState() => _AboutApplicationScreenState();
}

class _AboutApplicationScreenState extends State<AboutApplicationScreen> {

  String _appVersion = 'Loading...';

  @override
  void initState() {
    _getAppVersion();
    super.initState();
  }

  Future<void> _getAppVersion() async {
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    debugPrint(packageInfo.version);
    setState(() {
      _appVersion = packageInfo.version;
    });
  }
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isLight = scheme.brightness == Brightness.light;

    final gradientTop = isLight ? kLightGradientTop : kDarkGradientTop;
    final gradientBottom = isLight ? kLightGradientBottom : kDarkGradientBottom;
    final surface = scheme.surface;
    final border = isLight ? kLightBorder : kDarkBorder;
    final secondaryText = isLight ? kLightTextSecondary : kDarkTextSecondary;

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
            "About Application",
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
              // App profile card
              Container(
                decoration: BoxDecoration(
                  color: surface,
                  borderRadius: BorderRadius.circular(16.r),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.02),
                      blurRadius: 4,
                    ),
                  ],
                  border: Border.all(color: border, width: 1),
                ),
                padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 16.h),
                child: Column(
                  children: [
                    CircleAvatar(
                      backgroundColor: scheme.primary.withOpacity(0.16),
                      radius: 36.r,
                      backgroundImage: const AssetImage("assets/app_logo.png"), // Place your app's logo in assets and update path
                    ),
                    SizedBox(height: 12.h),
                    Text(
                      "Money Control",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 20.sp,
                        color: scheme.onSurface,
                      ),
                    ),
                    SizedBox(height: 5.h),
                    Text(
                      "Version $_appVersion",
                      style: TextStyle(
                        color: secondaryText,
                        fontSize: 13.sp,
                      ),
                    ),
                    SizedBox(height: 11.h),
                    Divider(color: border),
                    SizedBox(height: 10.h),
                    Text(
                      "Money Control is your all-in-one personal finance and expense tracker app. "
                          "Easily manage expenses, track income, analyze spending patterns by category, "
                          "review transaction history, and stay motivated to budget and save.",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: scheme.onSurface.withOpacity(0.82),
                        fontSize: 13.5.sp,
                      ),
                    ),
                    SizedBox(height: 18.h),
                  ],
                ),
              ),
              SizedBox(height: 19.h),
              Text(
                "Developer",
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13.sp,
                  color: secondaryText,
                ),
              ),
              SizedBox(height: 7.h),
              // Developer info card
              Container(
                decoration: BoxDecoration(
                  color: surface,
                  borderRadius: BorderRadius.circular(16.r),
                  border: Border.all(color: border, width: 1),
                ),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: scheme.primary.withOpacity(0.10),
                    radius: 22.r,
                    child: const Icon(Icons.developer_mode, color: Colors.teal),
                  ),
                  title: Text(
                    "Developed by { Aman }",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15.sp, color: scheme.onSurface),
                  ),
                  subtitle: Text(
                    "QA Analyst & Full-stack Dev",
                    style: TextStyle(fontSize: 12.sp, color: secondaryText),
                  ),
                ),
              ),
              SizedBox(height: 19.h),
              // Open Source & Credits
              Text(
                "Acknowledgements",
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13.sp,
                  color: secondaryText,
                ),
              ),
              SizedBox(height: 7.h),
              Container(
                decoration: BoxDecoration(
                  color: surface,
                  borderRadius: BorderRadius.circular(16.r),
                  border: Border.all(color: border, width: 1),
                ),
                padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "This app uses open source components:",
                      style: TextStyle(fontSize: 13.5.sp, color: secondaryText, fontWeight: FontWeight.w600),
                    ),
                    SizedBox(height: 8.h),
                    Text("• Flutter\n• Firebase (Auth & Firestore)\n• GetX\n• flutter_screenutil\n• share_plus\n• printing package\n• package info",
                        style: TextStyle(fontSize: 13.sp, color: scheme.onSurface)),
                    SizedBox(height: 14.h),
                    Row(
                      children: [
                        Icon(Icons.copyright, size: 16, color: secondaryText),
                        SizedBox(width: 7.w),
                        Text(
                          "2025 Money Control",
                          style: TextStyle(color: secondaryText, fontSize: 13.sp),
                        ),
                      ],
                    ),
                  ],
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
