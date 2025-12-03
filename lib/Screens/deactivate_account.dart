import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:money_control/Components/bottom_nav_bar.dart';
import 'package:money_control/Components/colors.dart';
import 'package:money_control/Screens/loginscreen.dart';

class DeactivateAccountScreen extends StatefulWidget {
  const DeactivateAccountScreen({super.key});

  @override
  State<DeactivateAccountScreen> createState() => _DeactivateAccountScreenState();
}

class _DeactivateAccountScreenState extends State<DeactivateAccountScreen> {
  bool processing = false;
  String? error;
  String? success;

  Future<void> _deactivateAccount() async {
    setState(() {
      processing = true;
      error = null;
      success = null;
    });

    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() {
        error = "No user logged in.";
        processing = false;
      });
      return;
    }

    try {
      // Soft deactivate: flag user as deactivated in Firestore
      await FirebaseFirestore.instance.collection('users').doc(user.email).set({
        "deactivated": true,
        "deactivatedAt": DateTime.now(),
      }, SetOptions(merge: true));

      // Optionally, also disable sign-in (for strict deactivation)
      // Note: Disabling user in Firebase Auth can only be done server-side (Cloud Functions/Admin SDK).
      // As a client, best you can do is sign the user out here:
      await FirebaseAuth.instance.signOut();

      setState(() {
        success = "Your account has been deactivated. You have been logged out.";
        processing = false;
      });

      // Redirect to login after a short delay
      Future.delayed(const Duration(seconds: 2), () {
        Get.offAll(() => const LoginScreen());
      });
    } catch (e) {
      setState(() {
        error = "Failed to deactivate account: $e";
        processing = false;
      });
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
            "Deactivate Account",
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
          padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 20.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: EdgeInsets.all(20.w),
                decoration: BoxDecoration(
                  color: surface,
                  borderRadius: BorderRadius.circular(16.r),
                  border: Border.all(color: border, width: 1),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.016),
                      blurRadius: 4,
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Icon(Icons.warning_amber_rounded, color: scheme.error, size: 37.sp),
                    SizedBox(height: 8.h),
                    Text(
                      "Are you sure you want to deactivate your account?",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: scheme.onSurface,
                        fontWeight: FontWeight.bold,
                        fontSize: 17.sp,
                      ),
                    ),
                    SizedBox(height: 13.h),
                    Text(
                      "Your account will be deactivated and you will be logged out. "
                          "Your data will be retained for record and audit purposes. You can contact support to reactivate.",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: secondaryText,
                        fontSize: 13.5.sp,
                        height: 1.42,
                      ),
                    ),
                    if (error != null) ...[
                      SizedBox(height: 13.h),
                      Text(error!, style: TextStyle(color: scheme.error, fontSize: 13.sp)),
                    ],
                    if (success != null) ...[
                      SizedBox(height: 13.h),
                      Text(success!, style: TextStyle(color: Colors.green, fontSize: 13.sp)),
                    ],
                    SizedBox(height: 25.h),
                    SizedBox(
                      width: double.infinity,
                      height: 50.h,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: scheme.error,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30.r),
                          ),
                        ),
                        onPressed: processing
                            ? null
                            : () {
                          showDialog(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text("Confirm Deactivation"),
                              content: const Text(
                                  "Are you sure you want to deactivate your account? This cannot be undone from the app."),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx),
                                  child: const Text("Cancel"),
                                ),
                                TextButton(
                                  onPressed: () async {
                                    Navigator.pop(ctx);
                                    await _deactivateAccount();
                                  },
                                  child: Text("Deactivate", style: TextStyle(color: scheme.error)),
                                ),
                              ],
                            ),
                          );
                        },
                        child: processing
                            ? const CircularProgressIndicator(strokeWidth: 2, color: Colors.white)
                            : Text("Deactivate My Account", style: const TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 26.h),
              Text(
                "Questions?",
                style: TextStyle(
                  color: secondaryText,
                  fontWeight: FontWeight.w600,
                  fontSize: 13.sp,
                ),
              ),
              SizedBox(height: 7.h),
              Container(
                decoration: BoxDecoration(
                  color: surface,
                  borderRadius: BorderRadius.circular(16.r),
                  border: Border.all(color: border, width: 1),
                ),
                padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
                child: Text(
                  "Contact support at support@moneycontrol.app if you change your mind or need help reactivating your account.",
                  style: TextStyle(color: scheme.onSurface, fontSize: 13.sp),
                ),
              ),
            ],
          ),
        ),
        bottomNavigationBar: BottomNavBar(
          currentIndex: 3,
        ),
      ),
    );
  }
}
