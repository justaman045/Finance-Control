import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:money_control/Screens/homescreen.dart';
import 'package:money_control/Screens/signup.dart'; // replace with your signup screen path

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final Color mainGreen = const Color(0xFF147C6C);
  final Color lightGreen = const Color(0xFF2681CC);
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _isLoading = false;
  bool _obscureText = true;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Toggle password visibility
  void _togglePasswordVisibility() {
    setState(() {
      _obscureText = !_obscureText;
    });
  }

  // Email validation
  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter your email';
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value.trim())) {
      return 'Invalid email format';
    }
    return null;
  }

  // Password validation
  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your password';
    }
    if (value.length < 6) {
      return 'Password too short';
    }
    return null;
  }

  Future<void> _signInWithEmailAndPassword() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Sign In Attempt
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      User? user = userCredential.user;
      if (user == null) {
        throw FirebaseAuthException(
            code: 'user-not-found', message: 'No user found with this email.');
      }

      // Email Verification Check
      if (!user.emailVerified) {
        try {
          await user.sendEmailVerification();
          // Print/log user info before signing out
          debugPrint('Verification email sent to: ${user.email}');
        } on FirebaseAuthException catch (e) {
          debugPrint(e.message);
        }

        setState(() {
          _isLoading = false;
          _errorMessage =
          'Please verify your email before logging in. A verification link has been sent to ${user.email}.';
        });

        Get.snackbar(
          'Email Verification Required',
          'We’ve sent a verification link to your email.',
          backgroundColor: Colors.orangeAccent,
          snackPosition: SnackPosition.BOTTOM,
          colorText: Colors.white,
          margin: const EdgeInsets.all(16),
        );

        // Sign out after all actions needing the user instance
        await _auth.signOut();
        return;
      }

      // Proceed to main app (Email verified)
      Get.snackbar(
        'Login Successful',
        'Welcome back!',
        backgroundColor: mainGreen,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(16),
      );

      await FirebaseFirestore.instance.collection('users').doc(user.email).set(
        {'darkMode': ThemeMode.system == ThemeMode.dark ? true : false},
        SetOptions(merge: true),
      );

      setState(() => _isLoading = false);

      // Navigate to your home screen
      Get.offAll(() => BankingHomeScreen());
    } on FirebaseAuthException catch (e) {
      setState(() {
        _isLoading = false;
        switch (e.code) {
          case 'user-not-found':
            _errorMessage = 'No user found with this email.';
            break;
          case 'wrong-password':
            _errorMessage = 'Incorrect password.';
            break;
          case 'invalid-email':
            _errorMessage = 'Invalid email format.';
            break;
          default:
            _errorMessage = e.message ?? 'An error occurred.';
        }
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Unexpected error: $e';
        _isLoading = false;
      });
    }
  }

  Widget inputField({
    required String label,
    required IconData icon,
    bool obscure = false,
    required TextEditingController controller,
    required String? Function(String?)? validator,
    Widget? suffixIcon,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: 15.h),
      child: TextFormField(
        controller: controller,
        obscureText: obscure,
        validator: validator,
        style: TextStyle(color: Colors.black),
        decoration: InputDecoration(
          labelText: label,
          hintText: 'Enter your ${label.toLowerCase()}',
          prefixIcon: Icon(icon, color: Colors.grey),
          suffixIcon: suffixIcon,
          filled: true,
          fillColor: const Color(0xFFF8F9FC),
          labelStyle: const TextStyle(color: Colors.grey),
          hintStyle: const TextStyle(color: Colors.grey),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14.r),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: mainGreen, width: 1.5),
            borderRadius: BorderRadius.circular(14.r),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Header
              Container(
                width: double.infinity,
                height: 200.h,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [mainGreen, lightGreen],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(28.r),
                    bottomRight: Radius.circular(28.r),
                  ),
                ),
                child: Center(
                  child: Container(
                    width: 58.w,
                    height: 58.w,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15.r),
                    ),
                    child: Icon(Icons.account_circle, color: mainGreen, size: 36.sp),
                  ),
                ),
              ),

              // Content
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 24.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 50.h),
                    Text(
                      "Welcome Back",
                      style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.bold, color: Colors.black),
                    ),
                    SizedBox(height: 6.h),
                    Text(
                      "Log in to continue your journey.",
                      style: TextStyle(color: Colors.grey, fontSize: 13.sp),
                    ),
                    SizedBox(height: 20.h),

                    // Input Fields
                    inputField(
                      label: "Email",
                      icon: Icons.mail_outline,
                      controller: _emailController,
                      validator: _validateEmail,
                    ),
                    inputField(
                      label: "Password",
                      icon: Icons.lock_outline,
                      obscure: _obscureText,
                      controller: _passwordController,
                      validator: _validatePassword,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureText ? Icons.visibility_off : Icons.visibility,
                          color: Colors.grey,
                        ),
                        onPressed: _togglePasswordVisibility,
                      ),
                    ),

                    // Error Message
                    if (_errorMessage != null) ...[
                      Container(
                        margin: EdgeInsets.only(top: 8.h, bottom: 8.h),
                        padding: EdgeInsets.all(10.w),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(10.r),
                          border: Border.all(color: Colors.red),
                        ),
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(color: Colors.red, fontSize: 13.sp),
                        ),
                      ),
                    ],

                    SizedBox(height: 10.h),

                    // Login Button
                    SizedBox(
                      width: double.infinity,
                      height: 50.h,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _signInWithEmailAndPassword,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: mainGreen,
                          disabledBackgroundColor: mainGreen.withOpacity(0.6),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(13.r),
                          ),
                        ),
                        child: _isLoading
                            ? const CircularProgressIndicator(color: Colors.white)
                            : Text(
                          "Log In",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),

                    SizedBox(height: 18.h),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text("Don’t have an account?", style: TextStyle(color: Colors.grey, fontSize: 13.sp)),
                        GestureDetector(
                          onTap: () => Get.to(() => const AuthScreen(),
                              transition: Transition.rightToLeft,
                              duration: const Duration(milliseconds: 500)),
                          child: Text(
                            " Sign Up",
                            style: TextStyle(color: mainGreen, fontWeight: FontWeight.w600, fontSize: 13.sp),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 25.h),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
