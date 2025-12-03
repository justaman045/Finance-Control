import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:money_control/Components/bottom_nav_bar.dart';
import 'package:money_control/Components/colors.dart';
import 'package:money_control/Components/methods.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'about_application.dart';
import 'budget.dart';
import 'deactivate_account.dart';
import 'help_faq.dart';
import 'loginscreen.dart';
import 'notifications.dart';
import 'edit_profile.dart';
import 'terms_and_policy.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final User? currentUser = FirebaseAuth.instance.currentUser;

  bool darkMode = false;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _loadDarkModeSetting();
  }

  /// Load theme setting from Firestore
  Future<void> _loadDarkModeSetting() async {
    if (currentUser == null) return;

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser!.email)
          .get();

      bool savedDarkMode = doc.data()?['darkMode'] ?? false;

      setState(() {
        darkMode = savedDarkMode;
        loading = false;
      });

      // Apply theme globally
      Get.changeThemeMode(savedDarkMode ? ThemeMode.dark : ThemeMode.light);
    } catch (e) {
      debugPrint("Error loading dark mode: $e");
      loading = false;
    }
  }

  /// Update theme & Firestore
  Future<void> _updateDarkModeSetting(bool value) async {
    if (currentUser == null) return;

    await FirebaseFirestore.instance.collection('users').doc(currentUser!.email)
        .set({'darkMode': value}, SetOptions(merge: true));

    setState(() => darkMode = value);

    Get.changeThemeMode(value ? ThemeMode.dark : ThemeMode.light);
  }

  Future<void> _sendPasswordResetEmail() async {
    if (currentUser == null) return;

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: currentUser!.email!);
      Get.snackbar("Password Reset", "Email sent to ${currentUser!.email}");
    } catch (e) {
      Get.snackbar("Password Reset", "Failed: $e");
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

    if (loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

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
          toolbarHeight: 64.h,
        ),

        body: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 8.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// PROFILE CARD
              _profileCard(surface, border, scheme),

              SizedBox(height: 20.h),
              Text("Other settings",
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13.sp,
                    color: secondaryText,
                  )),
              SizedBox(height: 12.h),

              /// MAIN OPTIONS
              _settingsGroup(surface, border, [
                _SettingsTile(
                  icon: Icons.person_outline,
                  title: "Profile details",
                  onTap: () => gotoPage(const EditProfileScreen()),
                ),
                _divider(border),
                _SettingsTile(
                  icon: Icons.lock_outline,
                  title: "Change Password",
                  onTap: _sendPasswordResetEmail,
                ),
                _divider(border),
                _SettingsTile(
                  icon: Icons.monetization_on_outlined,
                  title: "Set Budget",
                  onTap: () => gotoPage(const CategoryBudgetScreen()),
                ),
                _divider(border),
                _SettingsTile(
                  icon: Icons.notifications_none,
                  title: "Notifications",
                  onTap: () => gotoPage(const NotificationsScreen()),
                ),
                _divider(border),
                _SwitchSettingsTile(
                  icon: Icons.nights_stay_outlined,
                  title: "Dark mode",
                  value: darkMode,
                  onChanged: _updateDarkModeSetting,
                ),
              ]),

              SizedBox(height: 20.h),

              /// ABOUT / HELP / SIGN OUT
              _settingsGroup(surface, border, [
                _SettingsTile(
                  icon: Icons.info_outline,
                  title: "About application",
                  onTap: () => gotoPage(const AboutApplicationScreen()),
                ),
                _divider(border),
                _SettingsTile(
                  icon: Icons.help_outline,
                  title: "Help / FAQ",
                  onTap: () => gotoPage(const HelpFAQScreen()),
                ),
                _divider(border),
                _SettingsTile(
                  icon: Icons.privacy_tip_outlined,
                  title: "Privacy & Policies",
                  onTap: () => gotoPage(const LegalTrustPage()),
                ),
                _divider(border),
                _SettingsTile(
                  icon: Icons.logout,
                  title: "Sign Out",
                  iconColor: scheme.error,
                  textColor: scheme.error,
                  onTap: () {
                    FirebaseAuth.instance.signOut();
                    gotoPage(const LoginScreen());
                  },
                ),
                _divider(border),
                _SettingsTile(
                  icon: Icons.delete_outline,
                  title: "Deactivate my account",
                  iconColor: scheme.error,
                  textColor: scheme.error,
                  onTap: () => gotoPage(const DeactivateAccountScreen()),
                ),
              ]),
              SizedBox(height: 30.h),
            ],
          ),
        ),

        bottomNavigationBar: const BottomNavBar(currentIndex: 3),
      ),
    );
  }

  /// Helper Methods
  Widget _divider(Color border) => Divider(height: 0, color: border);

  Widget _settingsGroup(Color surface, Color border, List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: border),
      ),
      child: Column(children: children),
    );
  }

  Widget _profileCard(Color surface, Color border, ColorScheme scheme) {
    return Container(
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: border),
      ),
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
        leading: CircleAvatar(
          backgroundColor: surface,
          radius: 26.r,
          backgroundImage: const AssetImage("assets/profile.png"),
        ),
        title: Text(
          currentUser?.displayName ?? "User",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16.sp,
            color: scheme.onSurface,
          ),
        ),
        trailing: Icon(Icons.chevron_right, color: scheme.onSurface.withOpacity(0.6)),
        onTap: () => gotoPage(const EditProfileScreen()),
      ),
    );
  }
}

/// GENERAL SETTING TILE
class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color? iconColor;
  final Color? textColor;
  final VoidCallback? onTap;

  const _SettingsTile({
    required this.icon,
    required this.title,
    this.iconColor,
    this.textColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return ListTile(
      leading: Icon(icon, color: iconColor ?? scheme.onSurface.withOpacity(0.7)),
      title: Text(title, style: TextStyle(color: textColor ?? scheme.onSurface, fontSize: 14.5.sp)),
      trailing: Icon(Icons.chevron_right, color: scheme.onSurface.withOpacity(0.5)),
      onTap: onTap,
      dense: true,
      minLeadingWidth: 0,
    );
  }
}

/// SWITCH TILE
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

    return ListTile(
      leading: Icon(icon, color: scheme.onSurface.withOpacity(0.7)),
      title: Text(
        title,
        style: TextStyle(fontSize: 14.5.sp, color: scheme.onSurface),
      ),
      trailing: Switch(
        value: value,
        activeColor: scheme.primary,
        onChanged: onChanged,
      ),
      dense: true,
      minLeadingWidth: 0,
    );
  }
}
