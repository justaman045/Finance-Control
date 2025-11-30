import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:money_control/Components/bottom_nav_bar.dart';

class LegalTrustPage extends StatefulWidget {
  const LegalTrustPage({Key? key}) : super(key: key);

  @override
  State<LegalTrustPage> createState() => _LegalTrustPageState();
}

class _LegalTrustPageState extends State<LegalTrustPage> {
  bool consentDataProcessing = false;
  bool consentMarketing = false;
  bool deletingData = false;
  String? message;

  void _toggleConsent(String key, bool value) {
    setState(() {
      if (key == 'data') consentDataProcessing = value;
      else if (key == 'marketing') consentMarketing = value;
    });
    // Save consent state to preferences or backend here
  }

  Future<void> _requestDataDeletion() async {
    setState(() {
      deletingData = true;
      message = null;
    });

    // Simulate network call to backend or trigger
    await Future.delayed(const Duration(seconds: 2));

    // Here you would call your backend to delete user's data upon request

    setState(() {
      deletingData = false;
      message = "Your data deletion request has been submitted. This may take up to 30 days.";
    });

    Get.snackbar(
      "Data Deletion Requested",
      "Your request is in process. You will receive an update soon.",
      backgroundColor: Colors.blue,
      colorText: Colors.white,
      snackPosition: SnackPosition.TOP,
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Legal & Privacy",
          style: TextStyle(
            color: scheme.onBackground,
            fontWeight: FontWeight.bold,
            fontSize: 18.sp,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: BackButton(color: scheme.onBackground),
      ),
      backgroundColor: scheme.background,
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Terms of Service",
                style: TextStyle(
                    fontSize: 17.sp, fontWeight: FontWeight.bold, color: scheme.onSurface)),
            SizedBox(height: 8.h),
            Text(
              _termsOfServiceText,
              style: TextStyle(fontSize: 14.sp, color: scheme.onSurfaceVariant),
              textAlign: TextAlign.justify,
            ),
            SizedBox(height: 20.h),
            Text("Privacy Policy",
                style: TextStyle(
                    fontSize: 17.sp, fontWeight: FontWeight.bold, color: scheme.onSurface)),
            SizedBox(height: 8.h),
            Text(
              _privacyPolicyText,
              style: TextStyle(fontSize: 14.sp, color: scheme.onSurfaceVariant),
              textAlign: TextAlign.justify,
            ),
            SizedBox(height: 20.h),
            Text("Consents", style: TextStyle(fontSize: 17.sp, fontWeight: FontWeight.bold, color: scheme.onSurface)),
            SizedBox(height: 10.h),
            SwitchListTile(
              title: Text("Consent to Data Processing"),
              subtitle: Text(
                "Allow the app to process your personal data for improving services.",
                style: TextStyle(fontSize: 13.sp),
              ),
              value: consentDataProcessing,
              onChanged: (v) => _toggleConsent('data', v),
            ),
            SwitchListTile(
              title: Text("Consent to Marketing Communications"),
              subtitle: Text(
                "Receive promotional emails and notifications.",
                style: TextStyle(fontSize: 13.sp),
              ),
              value: consentMarketing,
              onChanged: (v) => _toggleConsent('marketing', v),
            ),
            SizedBox(height: 30.h),
            Center(
              child: ElevatedButton(
                onPressed: deletingData ? null : _requestDataDeletion,
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 30.w, vertical: 14.h),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30.r)),
                ),
                child: deletingData
                    ? SizedBox(
                  width: 24.w,
                  height: 24.w,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
                )
                    : Text("Request Data Deletion"),
              ),
            ),
            if (message != null) ...[
              SizedBox(height: 12.h),
              Center(
                child: Text(
                  message!,
                  style: TextStyle(fontSize: 14.sp, color: scheme.primary),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
            SizedBox(height: 40.h),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavBar(currentIndex: 3),
    );
  }

  final String _termsOfServiceText = '''
This app is provided "as-is" without any warranties. By using this app, you agree to our terms and conditions described here. Please use it responsibly and securely.
''';

  final String _privacyPolicyText = '''
We respect your privacy. Personal data including transactions and budgets are securely stored and processed only to improve your experience. We do not share data with third parties without consent except as required by law.
Your data rights include access, correction, and deletion upon request as per applicable data protection regulations.
''';
}
