import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'homescreen.dart';
import 'signup.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;

  final _email = TextEditingController();
  final _password = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool loading = false;
  bool obscure = true;
  String? error;

  late AnimationController _anim;
  late Animation<double> _fade;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _googleSignIn.initialize();

    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _fade = CurvedAnimation(parent: _anim, curve: Curves.easeOut);
    _slide =
        Tween(begin: const Offset(0, .08), end: Offset.zero).animate(_anim);

    _anim.forward();
  }

  @override
  void dispose() {
    _anim.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  // ---------------- EMAIL LOGIN ----------------

  Future<void> _loginEmail() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      loading = true;
      error = null;
    });

    try {
      final cred = await _auth.signInWithEmailAndPassword(
        email: _email.text.trim(),
        password: _password.text.trim(),
      );

      final user = cred.user!;
      if (!user.emailVerified) {
        await user.sendEmailVerification();
        await _auth.signOut();
        setState(() => error = "Verify your email to continue.");
        return;
      }

      await _saveUser(user, "password");
      Get.offAll(() => const BankingHomeScreen());
    } catch (e) {
      setState(() => error = "Invalid credentials");
    } finally {
      setState(() => loading = false);
    }
  }

  // ---------------- GOOGLE LOGIN ----------------

  Future<void> _loginGoogle() async {
    try {
      setState(() => loading = true);

      final googleUser = await _googleSignIn.authenticate();
      if (googleUser == null) return;

      final googleAuth = await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.idToken,
        idToken: googleAuth.idToken,
      );

      final user =
      (await _auth.signInWithCredential(credential)).user!;

      await _saveUser(user, "google");
      Get.offAll(() => const BankingHomeScreen());
    } catch (_) {
      setState(() => error = "Google sign-in failed");
    } finally {
      setState(() => loading = false);
    }
  }

  Future<void> _saveUser(User user, String provider) async {
    await FirebaseFirestore.instance
        .collection("users")
        .doc(user.email)
        .set({
      "email": user.email,
      "uid": user.uid,
      "provider": provider,
      "lastLogin": FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  // ---------------- UI ----------------

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF141E30), Color(0xFF243B55)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: SlideTransition(
            position: _slide,
            child: FadeTransition(
              opacity: _fade,
              child: Center(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(20.w),
                  child: Container(
                    padding: EdgeInsets.all(24.w),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(.08),
                      borderRadius: BorderRadius.circular(22.r),
                      border:
                      Border.all(color: Colors.white.withOpacity(.12)),
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Welcome back 👋",
                              style: TextStyle(
                                  fontSize: 24.sp,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white)),

                          SizedBox(height: 6.h),

                          Text("Login to manage your finances",
                              style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14.sp)),

                          SizedBox(height: 26.h),

                          _input(
                            "Email",
                            Icons.mail_outline,
                            _email,
                            false,
                          ),
                          _input(
                            "Password",
                            Icons.lock_outline,
                            _password,
                            obscure,
                            suffix: IconButton(
                              icon: Icon(
                                  obscure
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                  color: Colors.white70),
                              onPressed: () =>
                                  setState(() => obscure = !obscure),
                            ),
                          ),

                          if (error != null)
                            Padding(
                              padding: EdgeInsets.only(bottom: 10.h),
                              child: Text(error!,
                                  style: TextStyle(
                                      color: Colors.redAccent,
                                      fontSize: 13.sp)),
                            ),

                          SizedBox(
                            width: double.infinity,
                            height: 52.h,
                            child: ElevatedButton(
                              onPressed: loading ? null : _loginEmail,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: scheme.primary,
                                shape: RoundedRectangleBorder(
                                    borderRadius:
                                    BorderRadius.circular(14.r)),
                              ),
                              child: loading
                                  ? const CircularProgressIndicator(
                                  color: Colors.white)
                                  : const Text("Login"),
                            ),
                          ),

                          SizedBox(height: 18.h),

                          Row(children: const [
                            Expanded(child: Divider(color: Colors.white24)),
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 12),
                              child: Text("OR",
                                  style: TextStyle(color: Colors.white60)),
                            ),
                            Expanded(child: Divider(color: Colors.white24)),
                          ]),

                          SizedBox(height: 18.h),

                          SizedBox(
                            width: double.infinity,
                            height: 52.h,
                            child: OutlinedButton.icon(
                              onPressed:
                              loading ? null : _loginGoogle,
                              // icon: Image.asset(
                              //   "assets/google.png",
                              //   height: 20,
                              // ),
                              label: const Text("Continue with Google"),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.white,
                                side: const BorderSide(
                                    color: Colors.white24),
                                shape: RoundedRectangleBorder(
                                  borderRadius:
                                  BorderRadius.circular(14.r),
                                ),
                              ),
                            ),
                          ),

                          SizedBox(height: 22.h),

                          Center(
                            child: GestureDetector(
                              onTap: () =>
                                  Get.to(() => const AuthScreen()),
                              child: Text(
                                "Create a new account",
                                style: TextStyle(
                                    color: scheme.primary,
                                    fontWeight: FontWeight.w600),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _input(
      String label,
      IconData icon,
      TextEditingController controller,
      bool obscure, {
        Widget? suffix,
      }) {
    return Padding(
      padding: EdgeInsets.only(bottom: 14.h),
      child: TextFormField(
        controller: controller,
        obscureText: obscure,
        style: const TextStyle(color: Colors.white),
        validator: (v) => v == null || v.isEmpty ? "Required" : null,
        decoration: InputDecoration(
          hintText: label,
          hintStyle: const TextStyle(color: Colors.white54),
          prefixIcon: Icon(icon, color: Colors.white70),
          suffixIcon: suffix,
          filled: true,
          fillColor: Colors.white.withOpacity(.08),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14.r),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }
}
