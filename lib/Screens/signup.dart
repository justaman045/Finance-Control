import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'package:money_control/Components/methods.dart';
import 'package:money_control/Screens/loginscreen.dart';
import 'package:money_control/Screens/homescreen.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final Color mainGreen = const Color(0xFF147C6C);
  final Color lightGreen = const Color(0xFF2681CC);

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
    // REQUIRED for Google Sign-In v7+
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

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.email)
          .set({
        'name': _nameController.text.trim(),
        'email': user.email,
        'provider': 'email',
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      setState(() => _isLoading = false);

      Get.snackbar(
        'Success',
        'Account created! Please verify your email.',
        backgroundColor: mainGreen,
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
      // Open Google account picker
      await _googleSignIn.authenticate();

      // Wait for authentication event
      final event = await _googleSignIn.authenticationEvents.first;

      if (event is! GoogleSignInAuthenticationEventSignIn) {
        throw Exception('Google sign-in cancelled');
      }

      final googleUser = event.user;
      final googleAuth = await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );

      final userCredential =
      await _auth.signInWithCredential(credential);

      final user = userCredential.user!;

      // Save user to Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.email)
          .set({
        'name': user.displayName ?? 'Google User',
        'email': user.email,
        'photoUrl': user.photoURL,
        'provider': 'google',
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      setState(() => _isLoading = false);
      Get.offAll(() => BankingHomeScreen());
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Google sign-up failed or cancelled';
      });
    }
  }

  // ================= INPUT FIELD =================

  Widget _input({
    required String label,
    required IconData icon,
    required TextEditingController controller,
    required String? Function(String?) validator,
    bool obscure = false,
    Widget? suffixIcon,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: 16.h),
      child: TextFormField(
        controller: controller,
        obscureText: obscure,
        validator: validator,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          suffixIcon: suffixIcon,
          filled: true,
          fillColor: const Color(0xFFF8F9FC),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14.r),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  // ================= UI =================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildHeader(),
            Transform.translate(
              offset: Offset(0, -40.h),
              child: _buildCard(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      height: 230.h,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [mainGreen, lightGreen],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(36.r),
          bottomRight: Radius.circular(36.r),
        ),
      ),
      child: const Center(
        child: Icon(Icons.person_add_alt_1, color: Colors.white, size: 40),
      ),
    );
  }

  Widget _buildCard() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: Form(
        key: _formKey,
        child: Container(
          padding: EdgeInsets.all(22.w),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22.r),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            children: [
              _input(
                label: "Full Name",
                icon: Icons.person_outline,
                controller: _nameController,
                validator: (v) =>
                v != null && v.length >= 2 ? null : 'Invalid name',
              ),
              _input(
                label: "Email",
                icon: Icons.mail_outline,
                controller: _emailController,
                validator: (v) =>
                v != null && v.contains('@') ? null : 'Invalid email',
              ),
              _input(
                label: "Password",
                icon: Icons.lock_outline,
                controller: _passwordController,
                validator: (v) =>
                v != null && v.length >= 6 ? null : 'Min 6 chars',
                obscure: _obscurePassword,
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_off
                        : Icons.visibility,
                  ),
                  onPressed: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                ),
              ),
              _input(
                label: "Confirm Password",
                icon: Icons.lock_outline,
                controller: _confirmPasswordController,
                validator: (v) =>
                v == _passwordController.text
                    ? null
                    : 'Passwords do not match',
                obscure: _obscureConfirmPassword,
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureConfirmPassword
                        ? Icons.visibility_off
                        : Icons.visibility,
                  ),
                  onPressed: () => setState(() =>
                  _obscureConfirmPassword =
                  !_obscureConfirmPassword),
                ),
              ),

              if (_errorMessage != null)
                Padding(
                  padding: EdgeInsets.only(bottom: 10.h),
                  child: Text(_errorMessage!,
                      style: const TextStyle(color: Colors.red)),
                ),

              SizedBox(height: 12.h),

              // EMAIL SIGN UP
              SizedBox(
                width: double.infinity,
                height: 52.h,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _signUpWithEmail,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: mainGreen,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14.r),
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(
                      color: Colors.white)
                      : const Text("Sign Up"),
                ),
              ),

              SizedBox(height: 16.h),

              // GOOGLE SIGN UP
              OutlinedButton.icon(
                onPressed: _isLoading ? null : _signUpWithGoogle,
                icon: const Icon(Icons.g_mobiledata),
                label: const Text("Continue with Google"),
              ),

              SizedBox(height: 18.h),

              GestureDetector(
                onTap: () => Get.off(() => const LoginScreen()),
                child: Text(
                  "Already have an account? Log In",
                  style: TextStyle(
                    color: mainGreen,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
