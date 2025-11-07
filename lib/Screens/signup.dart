import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:money_control/Components/methods.dart';
import 'package:money_control/Screens/loginscreen.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({Key? key}) : super(key: key);

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final Color mainGreen = const Color(0xFF147C6C);
  final Color lightGreen = const Color(0xFF2681CC);

  final FirebaseAuth _auth = FirebaseAuth.instance;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;

  String? _errorMessage;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _togglePasswordVisibility() {
    setState(() {
      _obscurePassword = !_obscurePassword;
    });
  }

  void _toggleConfirmPasswordVisibility() {
    setState(() {
      _obscureConfirmPassword = !_obscureConfirmPassword;
    });
  }

  String? _validateName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Name is required';
    }
    if (value.length < 2) {
      return 'Name must be at least 2 characters';
    }
    return null;
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) {
      return 'Enter a valid email address';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }
    if (value != _passwordController.text) {
      return 'Passwords do not match';
    }
    return null;
  }

  // Sign up with Email and Password
  Future<void> _signUpWithEmailAndPassword() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      await userCredential.user!.updateDisplayName(_nameController.text.trim());

      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        Get.snackbar(
          'Success',
          'Account created! Please verify your email.',
          backgroundColor: mainGreen,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
          margin: EdgeInsets.all(16.w),
        );

        // Wait 2 seconds then go back to login
        await Future.delayed(const Duration(seconds: 2));
        goBack();
      }
    } on FirebaseAuthException catch (e) {
      setState(() {
        switch (e.code) {
          case 'email-already-in-use':
            _errorMessage = 'This email is already registered';
            break;
          case 'invalid-email':
            _errorMessage = 'Invalid email address';
            break;
          case 'weak-password':
            _errorMessage = 'Password is too weak';
            break;
          case 'operation-not-allowed':
            _errorMessage = 'Email/password accounts are not enabled';
            break;
          default:
            _errorMessage = e.message ?? 'An error occurred during sign up';
        }
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'An unexpected error occurred';
        _isLoading = false;
      });
    }
  }

  // Placeholder for Google Sign-in (shows message)
  Future<void> _signUpWithGoogle() async {
    setState(() {
      _isLoading = true;
    });

    await Future.delayed(const Duration(milliseconds: 500));

    if (mounted) {
      setState(() {
        _isLoading = false;
      });

      Get.snackbar(
        'Info',
        'Google sign-in will be implemented with backend',
        backgroundColor: Colors.blue,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
        margin: EdgeInsets.all(16.w),
      );
    }
  }

  // Placeholder for Apple Sign-in (shows message)
  Future<void> _signUpWithApple() async {
    setState(() {
      _isLoading = true;
    });

    await Future.delayed(const Duration(milliseconds: 500));

    if (mounted) {
      setState(() {
        _isLoading = false;
      });

      Get.snackbar(
        'Info',
        'Apple sign-in will be implemented with backend',
        backgroundColor: Colors.black,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
        margin: EdgeInsets.all(16.w),
      );
    }
  }

  Widget inputField({
    required String label,
    required IconData icon,
    bool obscure = false,
    required TextEditingController controller,
    required String? Function(String?)? validator,
    Widget? suffixIcon,
    TextInputType? keyboardType,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: 15.h),
      child: TextFormField(
        controller: controller,
        obscureText: obscure,
        keyboardType: keyboardType ?? TextInputType.text,
        validator: validator,
        style: const TextStyle(color: Colors.black),
        decoration: InputDecoration(
          labelText: label,
          hintText: 'Enter your ${label.toLowerCase()}',
          prefixIcon: Icon(icon, color: Colors.grey),
          suffixIcon: suffixIcon,
          filled: true,
          fillColor: const Color(0xFFF8F9FC),
          labelStyle: const TextStyle(color: Colors.grey),
          hintStyle: const TextStyle(color: Colors.grey),
          errorStyle: TextStyle(fontSize: 12.sp),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14.r),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14.r),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14.r),
            borderSide: BorderSide(color: mainGreen, width: 1.5),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14.r),
            borderSide: const BorderSide(color: Colors.red, width: 1.5),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14.r),
            borderSide: const BorderSide(color: Colors.red, width: 1.5),
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
              // Green gradient header with logo
              Container(
                width: double.infinity,
                height: 170.h,
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
                    child: Icon(
                      Icons.account_balance_sharp,
                      color: mainGreen,
                      size: 36.sp,
                    ),
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 24.w),
                child: Column(
                  children: [
                    SizedBox(height: 24.h),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "Create Account",
                        style: TextStyle(
                          fontSize: 20.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    SizedBox(height: 7.h),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "Start your journey with us",
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 13.sp,
                        ),
                      ),
                    ),
                    SizedBox(height: 20.h),
                    inputField(
                      label: "Full Name",
                      icon: Icons.person_outline,
                      controller: _nameController,
                      validator: _validateName,
                      keyboardType: TextInputType.name,
                    ),
                    inputField(
                      label: "Email",
                      icon: Icons.mail_outline,
                      controller: _emailController,
                      validator: _validateEmail,
                      keyboardType: TextInputType.emailAddress,
                    ),
                    inputField(
                      label: "Password",
                      icon: Icons.lock_outline,
                      obscure: _obscurePassword,
                      controller: _passwordController,
                      validator: _validatePassword,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                          color: Colors.grey,
                        ),
                        onPressed: _togglePasswordVisibility,
                      ),
                    ),
                    inputField(
                      label: "Confirm Password",
                      icon: Icons.lock_outline,
                      obscure: _obscureConfirmPassword,
                      controller: _confirmPasswordController,
                      validator: _validateConfirmPassword,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureConfirmPassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                          color: Colors.grey,
                        ),
                        onPressed: _toggleConfirmPasswordVisibility,
                      ),
                    ),
                    if (_errorMessage != null) ...[
                      SizedBox(height: 10.h),
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(12.w),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(10.r),
                          border: Border.all(color: Colors.red.shade200),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.error_outline,
                                color: Colors.red, size: 20.sp),
                            SizedBox(width: 8.w),
                            Expanded(
                              child: Text(
                                _errorMessage!,
                                style: TextStyle(
                                  color: Colors.red.shade700,
                                  fontSize: 13.sp,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    SizedBox(height: 20.h),
                    SizedBox(
                      width: double.infinity,
                      height: 50.h,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _signUpWithEmailAndPassword,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: mainGreen,
                          disabledBackgroundColor: mainGreen.withOpacity(0.6),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(13.r),
                          ),
                        ),
                        child: _isLoading
                            ? SizedBox(
                          height: 24.h,
                          width: 24.h,
                          child: const CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                            : Text(
                          "Sign Up",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 16.sp,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 22.h),
                    Row(
                      children: [
                        const Expanded(child: Divider()),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 10.w),
                          child: Text(
                            "Or",
                            style: TextStyle(
                              fontSize: 13.sp,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                        const Expanded(child: Divider()),
                      ],
                    ),
                    SizedBox(height: 12.h),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _isLoading ? null : _signUpWithGoogle,
                            icon: Icon(
                              Icons.g_mobiledata,
                              size: 24.sp,
                              color: _isLoading ? Colors.grey : Colors.black,
                            ),
                            label: Text(
                              "Google",
                              style: TextStyle(
                                fontSize: 15.sp,
                                color: _isLoading ? Colors.grey : Colors.black,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              padding: EdgeInsets.symmetric(vertical: 13.h),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(13.r),
                              ),
                              side: BorderSide(
                                color: _isLoading
                                    ? Colors.grey.shade300
                                    : Colors.grey.shade400,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 10.w),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _isLoading ? null : _signUpWithApple,
                            icon: Icon(
                              Icons.apple,
                              size: 22.sp,
                              color: _isLoading ? Colors.grey : Colors.black,
                            ),
                            label: Text(
                              "Apple",
                              style: TextStyle(
                                fontSize: 15.sp,
                                color: _isLoading ? Colors.grey : Colors.black,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              padding: EdgeInsets.symmetric(vertical: 13.h),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(13.r),
                              ),
                              side: BorderSide(
                                color: _isLoading
                                    ? Colors.grey.shade300
                                    : Colors.grey.shade400,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 18.h),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Already have an account?",
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 13.sp,
                          ),
                        ),
                        GestureDetector(
                          onTap: () => Get.off(() => const LoginScreen(), curve: Curves.easeIn, transition: Transition.rightToLeft, duration: const Duration(milliseconds: 500)),
                          child: Text(
                            " Log In",
                            style: TextStyle(
                              color: mainGreen,
                              fontWeight: FontWeight.w600,
                              fontSize: 13.sp,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 20.h),
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
