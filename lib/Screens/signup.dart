// ignore_for_file: use_build_context_synchronously

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'package:money_control/Screens/loginscreen.dart';
import 'package:money_control/Screens/homescreen.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final Color primary = const Color(0xFF147C6C);
  final Color secondary = const Color(0xFF0FA287);

  final _formKey = GlobalKey<FormState>();

  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();

  bool loading = false;
  bool showPassword = false;
  bool showConfirm = false;

  String? error;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  // --------------------------
  // GOOGLE SIGNUP
  // --------------------------
  Future<void> googleSignup() async {
    try {
      setState(() => loading = true);

      final GoogleSignIn google = GoogleSignIn.instance;
      final account = await google.authenticate();

      if (account == null) {
        setState(() => loading = false);
        return;
      }

      final auth = await account.authentication;

      final credential = GoogleAuthProvider.credential(
        // accessToken: auth.accessToken,
        idToken: auth.idToken,
      );

      final userCred =
      await FirebaseAuth.instance.signInWithCredential(credential);

      await FirebaseFirestore.instance
          .collection("users")
          .doc(userCred.user!.email)
          .set(
        {
          "name": userCred.user?.displayName ?? "",
          "email": userCred.user?.email,
          "createdAt": FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      Get.offAll(() => const BankingHomeScreen());
    } catch (e) {
      Get.snackbar("Google Sign-In Failed", e.toString(),
          backgroundColor: Colors.red, colorText: Colors.white);
    } finally {
      setState(() => loading = false);
    }
  }

  // --------------------------
  // EMAIL SIGNUP
  // --------------------------
  Future<void> emailSignup() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) return;

    try {
      setState(() => loading = true);

      final cred = await _auth.createUserWithEmailAndPassword(
        email: _email.text.trim(),
        password: _password.text.trim(),
      );

      await cred.user!.updateDisplayName(_name.text.trim());
      await cred.user!.sendEmailVerification();

      await FirebaseFirestore.instance
          .collection("users")
          .doc(cred.user!.email)
          .set(
        {
          "name": _name.text.trim(),
          "email": _email.text.trim(),
          "createdAt": DateTime.now().toIso8601String(),
        },
        SetOptions(merge: true),
      );

      Get.snackbar(
        "Almost there!",
        "Check your inbox and verify your email to continue.",
        backgroundColor: primary,
        colorText: Colors.white,
      );

      await Future.delayed(const Duration(seconds: 1));
      Get.off(() => const LoginScreen());
    } catch (e) {
      setState(() => error = e.toString());
    } finally {
      setState(() => loading = false);
    }
  }

  // --------------------------
  // MODERN INPUT FIELD
  // --------------------------
  Widget input({
    required String label,
    required IconData icon,
    required TextEditingController controller,
    bool obscure = false,
    Widget? suffix,
    String? Function(String?)? validator,
  }) {
    return Column(
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Text(label,
              style:
              TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w500)),
        ),
        SizedBox(height: 6.h),
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.9),
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: TextFormField(
            controller: controller,
            obscureText: obscure,
            validator: validator,
            decoration: InputDecoration(
              prefixIcon: Icon(icon, color: Colors.grey.shade600),
              suffixIcon: suffix,
              border: InputBorder.none,
              contentPadding:
              EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
            ),
          ),
        ),
        SizedBox(height: 14.h),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF5F7F9),
      body: Stack(
        children: [
          // --------------------------
          // BACKGROUND GRADIENT
          // --------------------------
          Container(
            height: 260.h,
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [primary, secondary],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(40.r),
                bottomRight: Radius.circular(40.r),
              ),
            ),
          ),

          // --------------------------
          // FOREGROUND CARD
          // --------------------------
          SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w),
              child: Column(
                children: [
                  SizedBox(height: 100.h),

                  Text(
                    "Create Your Account",
                    style: TextStyle(
                        fontSize: 26.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.white),
                  ),

                  SizedBox(height: 14.h),

                  Text(
                    "Track expenses, automate budgeting,\nand control your finances easily.",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white70, fontSize: 13.sp),
                  ),

                  SizedBox(height: 40.h),

                  // Floating white card
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(
                        horizontal: 22.w, vertical: 28.h),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24.r),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 20,
                          offset: const Offset(0, 12),
                        )
                      ],
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          input(
                            label: "Full Name",
                            icon: Icons.person,
                            controller: _name,
                            validator: (v) =>
                            v == null || v.isEmpty ? "Required" : null,
                          ),
                          input(
                            label: "Email",
                            icon: Icons.email_outlined,
                            controller: _email,
                            validator: (v) =>
                            v == null || !v.contains("@")
                                ? "Enter valid email"
                                : null,
                          ),
                          input(
                            label: "Password",
                            icon: Icons.lock_outline,
                            controller: _password,
                            obscure: !showPassword,
                            suffix: IconButton(
                              icon: Icon(
                                showPassword
                                    ? Icons.visibility
                                    : Icons.visibility_off,
                                color: Colors.grey,
                              ),
                              onPressed: () =>
                                  setState(() => showPassword = !showPassword),
                            ),
                            validator: (v) => v != null && v.length >= 6
                                ? null
                                : "Min 6 characters",
                          ),
                          input(
                            label: "Confirm Password",
                            icon: Icons.lock_outline,
                            controller: _confirm,
                            obscure: !showConfirm,
                            suffix: IconButton(
                              icon: Icon(
                                showConfirm
                                    ? Icons.visibility
                                    : Icons.visibility_off,
                                color: Colors.grey,
                              ),
                              onPressed: () =>
                                  setState(() => showConfirm = !showConfirm),
                            ),
                            validator: (v) =>
                            v == _password.text ? null : "Passwords mismatch",
                          ),

                          if (error != null)
                            Text(error!,
                                style: TextStyle(
                                    color: Colors.red,
                                    fontSize: 12.sp)),

                          SizedBox(height: 20.h),

                          // SIGNUP BUTTON
                          SizedBox(
                            width: double.infinity,
                            height: 50.h,
                            child: ElevatedButton(
                              onPressed: loading ? null : emailSignup,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primary,
                                shape: RoundedRectangleBorder(
                                  borderRadius:
                                  BorderRadius.circular(16.r),
                                ),
                              ),
                              child: loading
                                  ? const CircularProgressIndicator(
                                  color: Colors.white)
                                  : Text("Create Account",
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16.sp,
                                      fontWeight: FontWeight.w600)),
                            ),
                          ),

                          SizedBox(height: 22.h),

                          // OR DIVIDER
                          Row(
                            children: [
                              Expanded(child: Divider()),
                              Padding(
                                padding:
                                EdgeInsets.symmetric(horizontal: 12.w),
                                child: Text("Or continue with",
                                    style: TextStyle(color: Colors.grey)),
                              ),
                              Expanded(child: Divider()),
                            ],
                          ),

                          SizedBox(height: 20.h),

                          // GOOGLE SIGNUP BUTTON (MODERN)
                          GestureDetector(
                            onTap: loading ? null : googleSignup,
                            child: Container(
                              height: 50.h,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16.r),
                                border:
                                Border.all(color: Colors.grey.shade300),
                              ),
                              padding: EdgeInsets.symmetric(horizontal: 16.w),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  // Image.asset("assets/google.png",
                                  //     height: 24.h),
                                  SizedBox(width: 12.w),
                                  Text(
                                    "Sign up with Google",
                                    style: TextStyle(
                                      fontSize: 15.sp,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          SizedBox(height: 28.h),

                          GestureDetector(
                            onTap: () => Get.off(() => const LoginScreen()),
                            child: Text.rich(
                              TextSpan(
                                text: "Already have an account? ",
                                style: TextStyle(color: Colors.grey),
                                children: [
                                  TextSpan(
                                    text: "Log In",
                                    style: TextStyle(
                                        color: primary,
                                        fontWeight: FontWeight.w600),
                                  )
                                ],
                              ),
                            ),
                          )
                        ],
                      ),
                    ),
                  ),

                  SizedBox(height: 40.h),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
