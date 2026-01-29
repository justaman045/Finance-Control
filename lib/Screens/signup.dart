import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:money_control/Components/methods.dart';
import 'package:money_control/Screens/loginscreen.dart';
import 'package:money_control/Screens/onboarding_screen.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _googleSignIn.initialize();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // ================= EMAIL SIGN UP =================
  Future<void> _signUpWithEmail() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      final user = credential.user!;
      await user.updateDisplayName(_nameController.text.trim());
      await user.sendEmailVerification();

      await FirebaseFirestore.instance.collection('users').doc(user.email).set({
        'name': _nameController.text.trim(),
        'email': user.email,
        'provider': 'email',
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      setState(() => _isLoading = false);

      Get.snackbar(
        'Success',
        'Account created! Please verify your email.',
        backgroundColor: Colors.green,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );

      await Future.delayed(const Duration(seconds: 2));
      goBack();
    } on FirebaseAuthException catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.message ?? 'Sign up failed';
      });
    }
  }

  // ================= GOOGLE SIGN UP =================
  Future<void> _signUpWithGoogle() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await _googleSignIn.authenticate();
      final event = await _googleSignIn.authenticationEvents.first;

      if (event is! GoogleSignInAuthenticationEventSignIn) {
        throw Exception('Google sign-in cancelled');
      }

      final googleUser = event.user;
      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);
      final user = userCredential.user!;

      await FirebaseFirestore.instance.collection('users').doc(user.email).set({
        'name': user.displayName ?? 'Google User',
        'email': user.email,
        'photoUrl': user.photoURL,
        'provider': 'google',
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      setState(() => _isLoading = false);
      Get.offAll(() => const OnboardingScreen());
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Google sign-up failed or cancelled';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
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
    final hintColor = isDark
        ? Colors.white.withOpacity(0.5)
        : const Color(0xFF1A1A2E).withOpacity(0.5);

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
        body: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: 24.w),
            child: Column(
              children: [
                SizedBox(height: 40.h),
                _buildHeader(textColor),
                SizedBox(height: 30.h),
                _buildGlassCard(isDark, textColor, hintColor),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(Color textColor) {
    return Column(
      children: [
        Icon(Icons.person_add_outlined, size: 70.sp, color: textColor),
        SizedBox(height: 10.h),
        Text(
          "Create Account",
          style: TextStyle(
            fontSize: 26.sp,
            fontWeight: FontWeight.bold,
            color: textColor,
            letterSpacing: 0.5,
          ),
        ),
        SizedBox(height: 6.h),
        Text(
          "Join Money Control today",
          style: TextStyle(fontSize: 14.sp, color: textColor.withOpacity(0.6)),
        ),
      ],
    );
  }

  Widget _buildGlassCard(bool isDark, Color textColor, Color hintColor) {
    return Container(
      padding: EdgeInsets.all(24.w),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withOpacity(0.05)
            : Colors.white.withOpacity(0.6),
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.1)
              : Colors.white.withOpacity(0.4),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            _buildGlassInput(
              controller: _nameController,
              label: "Full Name",
              icon: Icons.person_outline,
              isDark: isDark,
              textColor: textColor,
              hintColor: hintColor,
              validator: (v) =>
                  v != null && v.length >= 2 ? null : 'Invalid name',
            ),
            _buildGlassInput(
              controller: _emailController,
              label: "Email",
              icon: Icons.email_outlined,
              isDark: isDark,
              textColor: textColor,
              hintColor: hintColor,
              validator: (v) =>
                  v != null && v.contains('@') ? null : 'Invalid email',
            ),
            _buildGlassInput(
              controller: _passwordController,
              label: "Password",
              icon: Icons.lock_outline,
              isDark: isDark,
              textColor: textColor,
              hintColor: hintColor,
              obscure: _obscurePassword,
              validator: (v) =>
                  v != null && v.length >= 6 ? null : 'Min 6 chars',
              onVisibilityPressed: () =>
                  setState(() => _obscurePassword = !_obscurePassword),
            ),
            _buildGlassInput(
              controller: _confirmPasswordController,
              label: "Confirm Password",
              icon: Icons.lock_outline,
              isDark: isDark,
              textColor: textColor,
              hintColor: hintColor,
              obscure: _obscureConfirmPassword,
              validator: (v) => v == _passwordController.text
                  ? null
                  : 'Passwords do not match',
              onVisibilityPressed: () => setState(
                () => _obscureConfirmPassword = !_obscureConfirmPassword,
              ),
            ),

            if (_errorMessage != null)
              Padding(
                padding: EdgeInsets.only(bottom: 12.h),
                child: Text(
                  _errorMessage!,
                  style: TextStyle(color: Colors.redAccent, fontSize: 13.sp),
                ),
              ),

            SizedBox(height: 10.h),

            // SIGN UP BUTTON
            Container(
              width: double.infinity,
              height: 52.h,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(26.r),
                gradient: LinearGradient(
                  colors: isDark
                      ? [const Color(0xFF6C63FF), const Color(0xFF4834D4)]
                      : [
                          const Color(0xFF6C63FF).withOpacity(0.8),
                          const Color(0xFF4834D4).withOpacity(0.8),
                        ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF6C63FF).withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: _isLoading ? null : _signUpWithEmail,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(26.r),
                  ),
                ),
                child: _isLoading
                    ? SizedBox(
                        width: 24.w,
                        height: 24.w,
                        child: const CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        "Sign Up",
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),

            SizedBox(height: 16.h),

            // GOOGLE SIGN UP
            SizedBox(
              width: double.infinity,
              height: 52.h,
              child: OutlinedButton.icon(
                onPressed: _isLoading ? null : _signUpWithGoogle,
                icon: const Icon(Icons.g_mobiledata, size: 28),
                label: Text(
                  "Continue with Google",
                  style: TextStyle(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: isDark
                      ? Colors.white
                      : const Color(0xFF1A1A2E),
                  side: BorderSide(
                    color: isDark
                        ? Colors.white.withOpacity(0.2)
                        : Colors.black.withOpacity(0.1),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(26.r),
                  ),
                ),
              ),
            ),

            SizedBox(height: 24.h),

            GestureDetector(
              onTap: () => Get.off(() => const LoginScreen()),
              child: RichText(
                text: TextSpan(
                  text: "Already have an account? ",
                  style: TextStyle(color: hintColor, fontSize: 13.5.sp),
                  children: [
                    TextSpan(
                      text: "Log In",
                      style: TextStyle(
                        color: isDark
                            ? const Color(0xFF6C63FF)
                            : Colors.deepPurple,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGlassInput({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required bool isDark,
    required Color textColor,
    required Color hintColor,
    required String? Function(String?) validator,
    bool obscure = false,
    VoidCallback? onVisibilityPressed,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: 16.h),
      child: Container(
        decoration: BoxDecoration(
          color: isDark
              ? Colors.black.withOpacity(0.2)
              : Colors.black.withOpacity(0.03),
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(
            color: isDark
                ? Colors.white.withOpacity(0.05)
                : Colors.black.withOpacity(0.05),
          ),
        ),
        child: TextFormField(
          controller: controller,
          obscureText: obscure,
          validator: validator,
          style: TextStyle(color: textColor),
          decoration: InputDecoration(
            labelText: label,
            labelStyle: TextStyle(color: hintColor),
            prefixIcon: Icon(icon, color: hintColor, size: 22.sp),
            suffixIcon: onVisibilityPressed != null
                ? IconButton(
                    icon: Icon(
                      obscure ? Icons.visibility_off : Icons.visibility,
                      color: hintColor,
                    ),
                    onPressed: onVisibilityPressed,
                  )
                : null,
            border: InputBorder.none,
            contentPadding: EdgeInsets.symmetric(
              horizontal: 16.w,
              vertical: 14.h,
            ),
          ),
        ),
      ),
    );
  }
}
