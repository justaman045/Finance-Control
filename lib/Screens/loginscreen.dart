import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:money_control/Screens/homescreen.dart';
import 'package:money_control/Screens/signup.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _googleSignIn.initialize();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _togglePasswordVisibility() {
    setState(() => _obscurePassword = !_obscurePassword);
  }

  // ================= EMAIL LOGIN =================
  Future<void> _loginWithEmail() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      final user = credential.user;
      if (user == null) throw Exception('User not found');

      if (!user.emailVerified) {
        await user.sendEmailVerification();
        await _auth.signOut();

        setState(() {
          _isLoading = false;
          _errorMessage =
              'Please verify your email. A verification link has been sent.';
        });
        return;
      }

      await FirebaseFirestore.instance.collection('users').doc(user.email).set({
        'email': user.email,
        'provider': 'email',
        'lastLogin': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      setState(() => _isLoading = false);
      Get.offAll(() => BankingHomeScreen());
    } on FirebaseAuthException catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.message ?? 'Login failed';
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Unexpected error occurred';
      });
    }
  }

  // ================= GOOGLE LOGIN =================
  Future<void> _loginWithGoogle() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Corrected for google_sign_in 7.x:
      // authenticate() returns the user directly.
      final GoogleSignInAccount? googleUser = await _googleSignIn
          .authenticate();

      if (googleUser == null) {
        // User cancelled
        setState(() {
          _isLoading = false;
        });
        return;
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);
      final user = userCredential.user;
      if (user == null) throw Exception('Firebase user null');

      await FirebaseFirestore.instance.collection('users').doc(user.email).set({
        'name': user.displayName,
        'email': user.email,
        'photoUrl': user.photoURL,
        'provider': 'google',
        'lastLogin': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      setState(() => _isLoading = false);
      Get.offAll(() => BankingHomeScreen());
    } on FirebaseAuthException catch (e) {
      debugPrint("FirebaseAuthException: ${e.code} - ${e.message}");
      setState(() {
        _isLoading = false;
        _errorMessage = e.message ?? 'Authentication failed.';
      });
    } catch (e) {
      debugPrint("Google Sign-In Error: $e");
      setState(() {
        _isLoading = false;
        _errorMessage = 'Google sign-in failed.';
      });
    }
  }

  // ================= UI =================
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
    final secondaryTextColor = isDark
        ? Colors.white.withOpacity(0.6)
        : const Color(0xFF1A1A2E).withOpacity(0.6);

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
                SizedBox(height: 50.h),
                // HEADER
                Column(
                  children: [
                    Container(
                      padding: EdgeInsets.all(16.w),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withOpacity(0.1)
                            : Colors.white.withOpacity(0.6),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.lock_outline,
                        size: 40.sp,
                        color: textColor,
                      ),
                    ),
                    SizedBox(height: 20.h),
                    Text(
                      "Welcome Back",
                      style: TextStyle(
                        fontSize: 26.sp,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                    SizedBox(height: 6.h),
                    Text(
                      "Sign in to continue",
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: secondaryTextColor,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 40.h),

                // GLASS CARD
                Container(
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
                        color: Colors.black.withOpacity(isDark ? 0.2 : 0.05),
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
                          label: "Email",
                          icon: Icons.email_outlined,
                          controller: _emailController,
                          isDark: isDark,
                          textColor: textColor,
                          hintColor: secondaryTextColor,
                          validator: (v) => v != null && v.contains('@')
                              ? null
                              : 'Invalid email',
                        ),
                        _buildGlassInput(
                          label: "Password",
                          icon: Icons.lock_outline,
                          controller: _passwordController,
                          isDark: isDark,
                          textColor: textColor,
                          hintColor: secondaryTextColor,
                          obscure: _obscurePassword,
                          validator: (v) => v != null && v.length >= 6
                              ? null
                              : 'Password too short',
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                              color: secondaryTextColor,
                            ),
                            onPressed: _togglePasswordVisibility,
                          ),
                        ),

                        if (_errorMessage != null) ...[
                          SizedBox(height: 10.h),
                          Text(
                            _errorMessage!,
                            style: TextStyle(
                              color: Colors.redAccent,
                              fontSize: 13.sp,
                            ),
                          ),
                        ],

                        SizedBox(height: 10.h),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () {
                              // Forgot Password Logic - could link to a dialog or page
                            },
                            child: const Text("Forgot Password?"),
                          ),
                        ),
                        SizedBox(height: 10.h),

                        // LOGIN BUTTON
                        Container(
                          width: double.infinity,
                          height: 52.h,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(26.r),
                            gradient: LinearGradient(
                              colors: isDark
                                  ? [
                                      const Color(0xFF6C63FF),
                                      const Color(0xFF4834D4),
                                    ]
                                  : [
                                      const Color(0xFF6C63FF).withOpacity(0.9),
                                      const Color(0xFF4834D4).withOpacity(0.9),
                                    ],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF6C63FF).withOpacity(0.3),
                                blurRadius: 10,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _loginWithEmail,
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
                                    "Log In",
                                    style: TextStyle(
                                      fontSize: 16.sp,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                          ),
                        ),

                        SizedBox(height: 20.h),

                        // DIVIDER
                        Row(
                          children: [
                            Expanded(
                              child: Divider(
                                color: secondaryTextColor.withOpacity(0.2),
                              ),
                            ),
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 10.w),
                              child: Text(
                                "OR",
                                style: TextStyle(
                                  color: secondaryTextColor,
                                  fontSize: 12.sp,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Divider(
                                color: secondaryTextColor.withOpacity(0.2),
                              ),
                            ),
                          ],
                        ),

                        SizedBox(height: 20.h),

                        // GOOGLE BUTTON
                        SizedBox(
                          width: double.infinity,
                          height: 52.h,
                          child: OutlinedButton.icon(
                            onPressed: _isLoading ? null : _loginWithGoogle,
                            icon: const Icon(Icons.g_mobiledata, size: 28),
                            label: Text(
                              "Continue with Google",
                              style: TextStyle(
                                fontSize: 15.sp,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: textColor,
                              side: BorderSide(
                                color: secondaryTextColor.withOpacity(0.3),
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(26.r),
                              ),
                            ),
                          ),
                        ),

                        SizedBox(height: 24.h),

                        GestureDetector(
                          onTap: () => Get.off(() => const AuthScreen()),
                          child: RichText(
                            text: TextSpan(
                              text: "Don’t have an account? ",
                              style: TextStyle(
                                color: secondaryTextColor,
                                fontSize: 13.5.sp,
                              ),
                              children: [
                                TextSpan(
                                  text: "Sign Up",
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
                ),
                SizedBox(height: 30.h),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGlassInput({
    required String label,
    required IconData icon,
    required TextEditingController controller,
    required bool isDark,
    required Color textColor,
    required Color hintColor,
    required String? Function(String?) validator,
    bool obscure = false,
    Widget? suffixIcon,
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
            suffixIcon: suffixIcon,
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
