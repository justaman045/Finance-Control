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
  String _appVersion = "Loading...";

  @override
  void initState() {
    super.initState();
    _loadAppVersion();
  }

  Future<void> _loadAppVersion() async {
    final info = await PackageInfo.fromPlatform();
    setState(() => _appVersion = info.version);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isLight = scheme.brightness == Brightness.light;

    final gradientTop = isLight ? kLightGradientTop : kDarkGradientTop;
    final gradientBottom = isLight ? kLightGradientBottom : kDarkGradientBottom;
    final surface = scheme.surface;
    final border = isLight ? kLightBorder : kDarkBorder;
    final secondary = isLight ? kLightTextSecondary : kDarkTextSecondary;

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
            icon: Icon(Icons.arrow_back_ios,
                color: scheme.onBackground, size: 20.sp),
            onPressed: () => Navigator.pop(context),
          ),
          toolbarHeight: 64.h,
        ),
        body: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 8.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // APP HEADER CARD
              _AppInfoCard(
                surface: surface,
                border: border,
                scheme: scheme,
                version: _appVersion,
                secondary: secondary,
              ),
              SizedBox(height: 22.h),

              _SectionLabel("Developer", secondary),
              SizedBox(height: 8.h),
              _DeveloperTile(surface, border, scheme, secondary),

              SizedBox(height: 22.h),

              _SectionLabel("Acknowledgements", secondary),
              SizedBox(height: 8.h),
              _AcknowledgementCard(surface, border, scheme, secondary),

              SizedBox(height: 30.h),
            ],
          ),
        ),
        bottomNavigationBar: const BottomNavBar(currentIndex: 2),
      ),
    );
  }

  Widget _SectionLabel(String title, Color color) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 13.5.sp,
          color: color,
        ),
      ),
    );
  }

  // ---------------- APP INFO CARD ----------------
  Widget _AppInfoCard({
    required Color surface,
    required Color border,
    required ColorScheme scheme,
    required String version,
    required Color secondary,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(color: border, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 7,
          ),
        ],
      ),
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 18.h),
      child: Column(
        children: [
          CircleAvatar(
            radius: 40.r,
            backgroundColor: scheme.primary.withOpacity(0.15),
            backgroundImage: const AssetImage("assets/app_logo.png"),
          ),
          SizedBox(height: 14.h),
          Text(
            "Money Control",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 20.sp,
              color: scheme.onSurface,
            ),
          ),
          SizedBox(height: 6.h),
          AnimatedOpacity(
            duration: const Duration(milliseconds: 300),
            opacity: version == "Loading..." ? 0.5 : 1,
            child: Text(
              "Version $version",
              style: TextStyle(color: secondary, fontSize: 13.sp),
            ),
          ),
          SizedBox(height: 14.h),
          Divider(color: border),
          SizedBox(height: 12.h),
          Text(
            "Money Control helps you effortlessly manage expenses, track income, view analytics, monitor savings goals, and understand your financial habits — all in one beautiful place.",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: scheme.onSurface.withOpacity(0.85),
              fontSize: 13.5.sp,
              height: 1.35,
            ),
          ),
          SizedBox(height: 18.h),
        ],
      ),
    );
  }

  // ---------------- DEVELOPER TILE ----------------
  Widget _DeveloperTile(
      Color surface, Color border, ColorScheme scheme, Color secondary) {
    return Container(
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: border, width: 1),
      ),
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 6.h),
        leading: CircleAvatar(
          radius: 24.r,
          backgroundColor: scheme.primary.withOpacity(0.12),
          child: const Icon(Icons.code_rounded, color: Colors.teal),
        ),
        title: Text(
          "Developed by Aman",
          style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15.5.sp,
              color: scheme.onSurface),
        ),
        subtitle: Text(
          "QA Analyst • Full-stack Developer",
          style: TextStyle(
            fontSize: 12.sp,
            color: secondary,
          ),
        ),
      ),
    );
  }

  // ---------------- ACKNOWLEDGEMENT CARD ----------------
  Widget _AcknowledgementCard(
      Color surface, Color border, ColorScheme scheme, Color secondary) {
    return Container(
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: border, width: 1),
      ),
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "This app uses open-source and ecosystem packages:",
            style: TextStyle(
              fontSize: 13.5.sp,
              fontWeight: FontWeight.w600,
              color: secondary,
            ),
          ),
          SizedBox(height: 10.h),

          _Bullet("Flutter Framework"),
          _Bullet("Firebase Authentication & Firestore"),
          _Bullet("GetX – State Management & Routing"),
          _Bullet("flutter_screenutil – Responsive UI"),
          _Bullet("package_info_plus"),
          _Bullet("share_plus, printing, and more"),

          SizedBox(height: 16.h),
          Row(
            children: [
              Icon(Icons.copyright,
                  size: 16.sp, color: secondary.withOpacity(0.9)),
              SizedBox(width: 6.w),
              Text(
                "2025 Money Control",
                style: TextStyle(color: secondary, fontSize: 13.sp),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _Bullet(String text) {
    return Padding(
      padding: EdgeInsets.only(bottom: 6.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("•  ",
              style: TextStyle(fontSize: 14.sp, color: Colors.grey.shade500)),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13.5.sp,
                color: Colors.white.withOpacity(0.8),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
