// lib/Screens/feedback_screen.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';

class FeedbackScreen extends StatefulWidget {
  const FeedbackScreen({super.key});

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  final _formKey = GlobalKey<FormState>();
  String _appVersion = "Loading...";

  Future<void> _loadAppVersion() async {
    final info = await PackageInfo.fromPlatform();
    setState(() => _appVersion = info.version);
  }

  @override
  void initState() {
    super.initState();
    _loadAppVersion();
  }

  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _feedbackCtrl = TextEditingController();
  late final _appVersionCtrl = TextEditingController(text: _appVersion);
  final _deviceModelCtrl = TextEditingController();
  final _osVersionCtrl = TextEditingController();

  bool _submitting = false;

  // === GOOGLE FORM CONFIG ===
  // This is the "formResponse" URL you saw in DevTools
  static const String _formUrl =
      "https://docs.google.com/forms/d/e/1FAIpQLSdf0mRQBB1mcwIIGpOPaHRhONYjGNLPRNy11fYyfHylK2mitg/formResponse";

  // These entry IDs come from the payload (Network tab → Payload → Form Data)
  static const String _entryName = "entry.1368653212";
  static const String _entryEmail = "entry.1731016817";
  static const String _entryFeedback = "entry.773676350";
  static const String _entryAppVersion = "entry.123699386";
  static const String _entryDeviceModel = "entry.1615870811";
  static const String _entryOsVersion = "entry.1846805458";

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _feedbackCtrl.dispose();
    _appVersionCtrl.dispose();
    _deviceModelCtrl.dispose();
    _osVersionCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_submitting) return;
    if (!_formKey.currentState!.validate()) return;

    setState(() => _submitting = true);

    try {
      final body = {
        _entryName: _nameCtrl.text.trim(),
        _entryEmail: FirebaseAuth.instance.currentUser!.email,
        _entryFeedback: _feedbackCtrl.text.trim(),
        _entryAppVersion: _appVersionCtrl.text.trim(),
        _entryDeviceModel: "${DateTime.now().hour}:${DateTime.now().minute}:${DateTime.now().second}",
        _entryOsVersion: "${DateTime.now().day} - ${DateTime.now().month} - ${DateTime.now().year}",
        // Optional extra fields like "fvv", "pageHistory" are not required
      };

      final resp = await http.post(
        Uri.parse(_formUrl),
        headers: {
          "Content-Type": "application/x-www-form-urlencoded;charset=utf-8",
        },
        body: body,
      );

      // Google Forms usually returns 200 or 302 on success
      if (resp.statusCode >= 200 && resp.statusCode < 400) {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Thanks! Your feedback has been submitted 🙌"),
          ),
        );

        _feedbackCtrl.clear();
      } else {
        if (!mounted) return;
        debugPrint(resp.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
            Text("Failed to submit feedback (code ${resp.statusCode})."),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error submitting feedback: $e")),
      );
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Feedback",
          style: TextStyle(
            color: scheme.onBackground,
            fontWeight: FontWeight.bold,
            fontSize: 18.sp,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: scheme.onBackground),
      ),
      backgroundColor: scheme.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(20.w),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Help me improve Money Control",
                  style: TextStyle(
                    fontSize: 17.sp,
                    fontWeight: FontWeight.w600,
                    color: scheme.onSurface,
                  ),
                ),
                SizedBox(height: 6.h),
                Text(
                  "Share bugs, feature requests, or general feedback. "
                      "This goes straight to my inbox via Google Forms.",
                  style: TextStyle(
                    fontSize: 13.sp,
                    color: scheme.onSurface.withOpacity(0.7),
                  ),
                ),
                SizedBox(height: 20.h),

                // Name
                TextFormField(
                  controller: _nameCtrl,
                  decoration: const InputDecoration(
                    labelText: "Name",
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) =>
                  v == null || v.trim().isEmpty ? "Name is required" : null,
                ),
                SizedBox(height: 14.h),

                // Feedback
                TextFormField(
                  controller: _feedbackCtrl,
                  maxLines: 5,
                  decoration: const InputDecoration(
                    labelText: "Your feedback",
                    alignLabelWithHint: true,
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) => v == null || v.trim().isEmpty
                      ? "Feedback cannot be empty"
                      : null,
                ),
                SizedBox(height: 20.h),

                SizedBox(
                  width: double.infinity,
                  height: 48.h,
                  child: ElevatedButton(
                    onPressed: _submitting ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(26.r),
                      ),
                    ),
                    child: _submitting
                        ? SizedBox(
                      width: 22.w,
                      height: 22.w,
                      child: const CircularProgressIndicator(
                        strokeWidth: 2.4,
                        valueColor:
                        AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                        : const Text("Submit Feedback"),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
