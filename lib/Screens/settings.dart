import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:money_control/Components/bottom_nav_bar.dart';
import 'package:money_control/Components/colors.dart';
import 'package:money_control/Components/methods.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:money_control/Screens/about_application.dart';
import 'package:money_control/Screens/budget.dart';
import 'package:money_control/Screens/deactivate_account.dart';
import 'package:money_control/Screens/help_faq.dart';
import 'package:money_control/Screens/loginscreen.dart';
import 'package:money_control/Screens/notifications.dart';
import 'package:money_control/Screens/edit_profile.dart';
import 'package:money_control/Screens/terms_and_policy.dart'; // import your notification screen here

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool darkMode = false;
  final User? currentUser = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    _loadDarkModeSetting();
  }

  Future<void> _loadDarkModeSetting() async {
    if (currentUser == null) return;
    final doc = await FirebaseFirestore.instance.collection('users').doc(currentUser!.email).get();
    if (doc.exists) {
      final data = doc.data();
      debugPrint('Dark mode setting loaded: ${data?["darkMode"]}');
      setState(() {
        darkMode = data?['darkMode'] ?? false;
      });
    }
  }

  Future<void> _updateDarkModeSetting(bool value) async {
    if (currentUser == null) return;
    await FirebaseFirestore.instance.collection('users').doc(currentUser!.email).set(
      {'darkMode': value},
      SetOptions(merge: true),
    );
    setState(() {
      darkMode = value;
    });
    // Integrate your app's theme management logic here:
    // For example, if you use GetX:
    // if (darkMode) Get.changeTheme(ThemeData.dark()) else Get.changeTheme(ThemeData.light())
  }

  Future<void> _sendPasswordResetEmail() async {
    if (currentUser == null) return;
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: currentUser!.email!);
      Get.snackbar("Password Reset","Password reset email sent to ${currentUser!.email}");
    } catch (e) {
      Get.snackbar("Password Reset","Failed to send password reset email: $e");
    }
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
            "Settings",
            style: TextStyle(
              color: scheme.onBackground,
              fontWeight: FontWeight.bold,
              fontSize: 18.sp,
            ),
          ),
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios, color: scheme.onBackground, size: 20.sp),
            onPressed: () {
              goBack();
            },
          ),
          toolbarHeight: 64.h,
        ),
        body: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 8.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Profile Card
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
                padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: surface,
                    radius: 26.r,
                    backgroundImage: const AssetImage("assets/profile.png"),
                  ),
                  title: Text(
                    FirebaseAuth.instance.currentUser!.displayName ?? "User",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16.sp, color: scheme.onSurface),
                  ),
                  // subtitle: Text(
                  //   "Product/UI Designer",
                  //   style: TextStyle(fontSize: 12.sp, color: secondaryText),
                  // ),
                  trailing: Icon(Icons.chevron_right, color: secondaryText, size: 24.sp),
                  contentPadding: EdgeInsets.zero,
                  onTap: () {
                    gotoPage(const EditProfileScreen());
                  },
                ),
              ),
              SizedBox(height: 19.h),
              Text(
                "Other settings",
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13.sp,
                  color: secondaryText,
                ),
              ),
              SizedBox(height: 11.h),
              // Main Settings section
              Container(
                decoration: BoxDecoration(
                  color: surface,
                  borderRadius: BorderRadius.circular(16.r),
                  border: Border.all(color: border, width: 1),
                ),
                child: Column(
                  children: [
                    _SettingsTile(
                      Icons.person_outline,
                      "Profile details",
                      onTap: () {
                        gotoPage(const EditProfileScreen());
                      },
                    ),
                    Divider(height: 0, color: border),
                    _SettingsTile(
                      Icons.lock_outline,
                      "Change Password",
                      onTap: _sendPasswordResetEmail,
                    ),
                    Divider(height: 0, color: border),
                    _SettingsTile(
                      Icons.monetization_on_outlined,
                      "Set Budget",
                      onTap: () {
                        gotoPage(const CategoryBudgetScreen());
                      },
                    ),
                    Divider(height: 0, color: border),
                    _SettingsTile(
                      Icons.notifications_none,
                      "Notifications",
                      onTap: () {
                        gotoPage(const NotificationsScreen()); // create NotificationScreen accordingly
                      },
                    ),
                    Divider(height: 0, color: border),
                    _SwitchSettingsTile(
                      icon: Icons.nights_stay_outlined,
                      title: "Dark mode",
                      value: darkMode,
                      onChanged: (bool v) => _updateDarkModeSetting(v),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 19.h),
              // About / FAQ / Deactivate
              Container(
                decoration: BoxDecoration(
                  color: surface,
                  borderRadius: BorderRadius.circular(16.r),
                  border: Border.all(color: border, width: 1),
                ),
                child: Column(
                  children: [
                    _SettingsTile(
                      Icons.info_outline,
                      "About application",
                      onTap: () {
                        gotoPage(const AboutApplicationScreen());
                      },
                    ),
                    Divider(height: 0, color: border),
                    _SettingsTile(
                      Icons.help_outline,
                      "Help / FAQ",
                      onTap: () {
                        gotoPage(const HelpFAQScreen());
                      },
                    ),
                    Divider(height: 0, color: border),
                    _SettingsTile(
                      Icons.privacy_tip_outlined,
                      "Privacy and Policies",
                      onTap: () {
                        gotoPage(const LegalTrustPage());
                      },
                    ),
                    Divider(height: 0, color: border),
                    Padding(
                      padding: EdgeInsetsGeometry.only(left: 4.w),
                      child: _SettingsTile(
                        Icons.logout,
                        "Sign Out",
                        onTap: () {
                          FirebaseAuth.instance.signOut();
                          gotoPage(const LoginScreen());
                        },
                        iconColor: scheme.error,
                        textColor: scheme.error,
                      ),
                    ),
                    Divider(height: 0, color: border),
                    _SettingsTile(
                      Icons.delete_outline,
                      "Deactivate my account",
                      onTap: () {
                        gotoPage(const DeactivateAccountScreen());
                      },
                      iconColor: scheme.error,
                      textColor: scheme.error,
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

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final Color? iconColor;
  final String title;
  final VoidCallback? onTap;
  final Color? textColor;

  const _SettingsTile(
      this.icon,
      this.title, {
        this.iconColor,
        this.onTap,
        this.textColor,
      });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final secondaryText = scheme.brightness == Brightness.light ? kLightTextSecondary : kDarkTextSecondary;
    return ListTile(
      leading: Icon(icon, color: iconColor ?? secondaryText, size: 23.sp),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 14.5.sp,
          color: textColor ?? scheme.onSurface,
        ),
      ),
      trailing: Icon(Icons.chevron_right, color: secondaryText, size: 23.sp),
      contentPadding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 0),
      horizontalTitleGap: 12.w,
      minVerticalPadding: 0,
      dense: true,
      onTap: onTap,
    );
  }
}

class _SwitchSettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SwitchSettingsTile({
    required this.icon,
    required this.title,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final secondaryText = scheme.brightness == Brightness.light ? kLightTextSecondary : kDarkTextSecondary;
    return ListTile(
      leading: Icon(icon, color: secondaryText, size: 23.sp),
      title: Text(title, style: TextStyle(fontSize: 14.5.sp, color: scheme.onSurface)),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: scheme.primary,
      ),
      contentPadding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 0),
      horizontalTitleGap: 12.w,
      minVerticalPadding: 0,
      dense: true,
    );
  }
}
