import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:money_control/Components/bottom_nav_bar.dart';
import 'package:money_control/Screens/loginscreen.dart';

class DeactivateAccountScreen extends StatefulWidget {
  const DeactivateAccountScreen({super.key});

  @override
  State<DeactivateAccountScreen> createState() =>
      _DeactivateAccountScreenState();
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

      await FirebaseAuth.instance.signOut();

      setState(() {
        success =
            "Your account has been deactivated. You have been logged out.";
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final gradientColors = isDark
        ? [
            const Color(0xFF1A1A2E), // Midnight Void
            const Color(0xFF16213E).withOpacity(0.95),
          ]
        : [
            const Color(0xFFF5F7FA), // Premium Light
            const Color(0xFFC3CFE2),
          ];

    final textColor = isDark ? Colors.white : const Color(0xFF1A1A2E);
    final secondaryTextColor = isDark
        ? Colors.white.withOpacity(0.6)
        : const Color(0xFF1A1A2E).withOpacity(0.6);

    final cardColor = isDark
        ? Colors.white.withOpacity(0.05)
        : Colors.white.withOpacity(0.6);

    final borderColor = isDark
        ? Colors.white.withOpacity(0.1)
        : Colors.white.withOpacity(0.4);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradientColors,
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
              color: textColor,
              fontWeight: FontWeight.bold,
              fontSize: 18.sp,
            ),
          ),
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios, color: textColor, size: 20.sp),
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
                padding: EdgeInsets.all(24.w),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(20.r),
                  border: Border.all(color: Colors.redAccent.withOpacity(0.3)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(isDark ? 0.2 : 0.05),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Container(
                      padding: EdgeInsets.all(16.w),
                      decoration: BoxDecoration(
                        color: Colors.redAccent.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.warning_amber_rounded,
                        color: Colors.redAccent,
                        size: 40.sp,
                      ),
                    ),
                    SizedBox(height: 16.h),
                    Text(
                      "Are you sure you want to deactivate?",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: textColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 18.sp,
                      ),
                    ),
                    SizedBox(height: 12.h),
                    Text(
                      "Your account will be deactivated and you will be logged out immediately. Your data is retained for audit purposes but will not be accessible.",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: secondaryTextColor,
                        fontSize: 13.5.sp,
                        height: 1.5,
                      ),
                    ),
                    if (error != null) ...[
                      SizedBox(height: 16.h),
                      Text(
                        error!,
                        style: TextStyle(
                          color: Colors.redAccent,
                          fontSize: 13.sp,
                        ),
                      ),
                    ],
                    if (success != null) ...[
                      SizedBox(height: 16.h),
                      Text(
                        success!,
                        style: TextStyle(
                          color: Colors.greenAccent,
                          fontSize: 13.sp,
                        ),
                      ),
                    ],
                    SizedBox(height: 30.h),
                    SizedBox(
                      width: double.infinity,
                      height: 52.h,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.redAccent,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(26.r),
                          ),
                          shadowColor: Colors.redAccent.withOpacity(0.4),
                        ),
                        onPressed: processing
                            ? null
                            : () {
                                showDialog(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    backgroundColor: isDark
                                        ? const Color(0xFF1E1E2C)
                                        : Colors.white,
                                    title: Text(
                                      "Confirm Deactivation",
                                      style: TextStyle(color: textColor),
                                    ),
                                    content: Text(
                                      "This action requires you to login again to reactivate. Proceed?",
                                      style: TextStyle(
                                        color: secondaryTextColor,
                                      ),
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(ctx),
                                        child: Text(
                                          "Cancel",
                                          style: TextStyle(
                                            color: secondaryTextColor,
                                          ),
                                        ),
                                      ),
                                      TextButton(
                                        onPressed: () async {
                                          Navigator.pop(ctx);
                                          await _deactivateAccount();
                                        },
                                        child: const Text(
                                          "Deactivate",
                                          style: TextStyle(
                                            color: Colors.redAccent,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                        child: processing
                            ? SizedBox(
                                width: 24.w,
                                height: 24.w,
                                child: const CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: Colors.white,
                                ),
                              )
                            : Text(
                                "Deactivate My Account",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15.sp,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 32.h),
              Center(
                child: Text(
                  "Need help?",
                  style: TextStyle(
                    color: secondaryTextColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 14.sp,
                  ),
                ),
              ),
              SizedBox(height: 8.h),
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(16.r),
                  border: Border.all(color: borderColor, width: 1),
                ),
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.email_outlined,
                      color: secondaryTextColor,
                      size: 20.sp,
                    ),
                    SizedBox(width: 8.w),
                    SelectableText(
                      "work.amanojha30@gmail.com",
                      style: TextStyle(
                        color: textColor,
                        fontSize: 13.5.sp,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        bottomNavigationBar: const BottomNavBar(currentIndex: 3),
      ),
    );
  }
}
