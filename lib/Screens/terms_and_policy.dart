import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:money_control/Components/bottom_nav_bar.dart';
import 'package:money_control/Services/local_backup_service.dart';

class LegalTrustPage extends StatefulWidget {
  const LegalTrustPage({Key? key}) : super(key: key);

  @override
  State<LegalTrustPage> createState() => _LegalTrustPageState();
}

class _LegalTrustPageState extends State<LegalTrustPage> {
  bool consentDataProcessing = false;
  bool consentMarketing = false;
  bool deletingData = false;
  bool downloadingData = false;

  String? message;

  @override
  void initState() {
    super.initState();
    _loadUserConsents();
  }

  Future<void> _loadUserConsents() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final doc = await FirebaseFirestore.instance
        .collection("users")
        .doc(user.email)
        .get();

    setState(() {
      consentDataProcessing = doc.data()?["consent_data"] ?? false;
      consentMarketing = doc.data()?["consent_marketing"] ?? false;
    });
  }

  Future<void> _toggleConsent(String key, bool value) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() {
      if (key == 'data') consentDataProcessing = value;
      if (key == 'marketing') consentMarketing = value;
    });

    await FirebaseFirestore.instance
        .collection("users")
        .doc(user.email)
        .update({
      "consent_data": consentDataProcessing,
      "consent_marketing": consentMarketing
    });
  }

  /// -------------------------------------------------------
  /// 🔥 DELETE ALL USER DATA EXCEPT EMAIL
  /// -------------------------------------------------------
  Future<void> _requestDataDeletion() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() {
      deletingData = true;
      message = null;
    });

    try {
      final userDoc =
      FirebaseFirestore.instance.collection("users").doc(user.email);

      /// Delete transactions collection
      final txSnap = await userDoc.collection("transactions").get();
      for (var doc in txSnap.docs) {
        await doc.reference.delete();
      }

      /// Delete categories
      final catSnap = await userDoc.collection("categories").get();
      for (var doc in catSnap.docs) {
        await doc.reference.delete();
      }

      /// Delete offline backups
      final backupSnap = await userDoc.collection("backups").get();
      for (var doc in backupSnap.docs) {
        await doc.reference.delete();
      }

      /// Delete insights, preferences, logs etc.
      final anySubCollections = ["insights", "preferences", "logs"];
      for (String name in anySubCollections) {
        final coll = await userDoc.collection(name).get();
        for (var doc in coll.docs) {
          await doc.reference.delete();
        }
      }

      /// DO NOT DELETE MAIN USER DOC
      /// Just clear fields except email.
      await userDoc.update({
        "createdAt": FieldValue.serverTimestamp(),
        "consent_data": false,
        "consent_marketing": false,
      });

      setState(() {
        deletingData = false;
        message =
        "Your data deletion request is successful. All financial & personal data has been erased except your account email.";
      });

      Get.snackbar(
        "Data Cleared",
        "All your data (except email) has been deleted.",
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      setState(() {
        deletingData = false;
        message = "Error deleting data: $e";
      });
      Get.snackbar("Error", e.toString(),
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.red,
          colorText: Colors.white);
    }
  }

  /// -------------------------------------------------------
  /// 📄 DOWNLOAD USER DATA AS JSON
  /// -------------------------------------------------------
  Future<void> _downloadMyData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => downloadingData = true);

    try {
      final userDoc =
      FirebaseFirestore.instance.collection("users").doc(user.email);

      final txSnap = await userDoc.collection("transactions").get();
      final catSnap = await userDoc.collection("categories").get();

      final export = {
        "email": user.email,
        "transactions":
        txSnap.docs.map((e) => {"id": e.id, ...e.data()}).toList(),
        "categories":
        catSnap.docs.map((e) => {"id": e.id, ...e.data()}).toList(),
      };

      /// TODO: use your LocalBackupService.exportJSON(export);
      await LocalBackupService.exportBackupFile(FirebaseAuth.instance.currentUser!.email!);

      setState(() => downloadingData = false);

      Get.snackbar(
        "Data Ready",
        "Your data export file has been created.",
        backgroundColor: Colors.blue,
        colorText: Colors.white,
      );
    } catch (e) {
      setState(() => downloadingData = false);
      Get.snackbar("Error", e.toString(),
          backgroundColor: Colors.red, colorText: Colors.white);
    }
  }

  /// -------------------------------------------------------
  /// UI
  /// -------------------------------------------------------
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
      bottomNavigationBar: const BottomNavBar(currentIndex: 3),
      body: _buildBody(scheme),
    );
  }

  Widget _buildBody(ColorScheme scheme) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(20.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _title("Terms of Service", scheme),
          _body(_termsOfServiceText, scheme),

          SizedBox(height: 26.h),

          _title("Privacy Policy", scheme),
          _body(_privacyPolicyText, scheme),

          SizedBox(height: 30.h),
          _title("Your Consents", scheme),
          _consentSwitches(),

          SizedBox(height: 30.h),
          _title("Download My Data", scheme),
          _downloadSection(),

          SizedBox(height: 30.h),
          _title("Request Permanent Data Deletion", scheme),
          _deleteSection(),

          SizedBox(height: 40.h),
        ],
      ),
    );
  }

  Widget _title(String text, ColorScheme scheme) => Text(
    text,
    style: TextStyle(
        fontSize: 17.sp, fontWeight: FontWeight.bold, color: scheme.primary),
  );

  Widget _body(String text, ColorScheme scheme) => AnimatedOpacity(
    duration: const Duration(milliseconds: 400),
    opacity: 1,
    child: Text(
      text,
      style: TextStyle(
        fontSize: 14.sp,
        height: 1.45,
        color: scheme.onSurfaceVariant,
      ),
      textAlign: TextAlign.justify,
    ),
  );

  Widget _consentSwitches() {
    return Column(
      children: [
        SwitchListTile(
          title: Text("Consent to Data Processing"),
          subtitle: Text("Allow the app to process data to improve services."),
          value: consentDataProcessing,
          onChanged: (v) => _toggleConsent('data', v),
        ),
        SwitchListTile(
          title: Text("Consent to Marketing Communication"),
          subtitle: Text("Receive optional promotional updates."),
          value: consentMarketing,
          onChanged: (v) => _toggleConsent('marketing', v),
        ),
      ],
    );
  }

  Widget _downloadSection() {
    return Center(
      child: ElevatedButton.icon(
        onPressed: downloadingData ? null : _downloadMyData,
        icon: downloadingData
            ? SizedBox(
          width: 20.w,
          height: 20.w,
          child: CircularProgressIndicator(color: Colors.white),
        )
            : Icon(Icons.download),
        label:
        Text(downloadingData ? "Preparing..." : "Download My Data (JSON)"),
        style: ElevatedButton.styleFrom(
            padding: EdgeInsets.symmetric(horizontal: 28.w, vertical: 14.h)),
      ),
    );
  }

  Widget _deleteSection() {
    return Column(
      children: [
        Center(
          child: ElevatedButton(
            onPressed: deletingData ? null : _requestDataDeletion,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              padding: EdgeInsets.symmetric(horizontal: 32.w, vertical: 14.h),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28.r)),
            ),
            child: deletingData
                ? SizedBox(
              width: 24.w,
              height: 24.w,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 3,
              ),
            )
                : Text("Delete My Data Permanently"),
          ),
        ),
        if (message != null) ...[
          SizedBox(height: 15.h),
          Text(
            message!,
            style: TextStyle(
                color: Colors.redAccent,
                fontSize: 14.sp,
                fontWeight: FontWeight.w500),
            textAlign: TextAlign.center,
          ),
        ]
      ],
    );
  }

  /// -------------------------------------------------------
  /// TEXTS
  /// -------------------------------------------------------
  final String _termsOfServiceText = '''
By using this application, you agree to the following Terms of Service:

• You are responsible for the accuracy of the data you enter.
• The app provides financial insights but is not a substitute for professional financial advice.
• We reserve the right to update features, pricing, or terms at any time.
• Any misuse, abuse, or unauthorized activities may result in restricted access.
• You must not use the app for illegal, harmful, or fraudulent activities.

Continued use of this app means you accept the latest version of our Terms.
''';

  final String _privacyPolicyText = '''
We are committed to protecting your personal data.

What We Collect:
• Basic profile information (email)
• Financial transactions that you manually add
• Categories and notes you create
• App usage data to improve features

How Your Data is Used:
• To provide budgeting & analytics features
• To personalize insights
• To improve app performance

Your Rights:
• You can request your data at any time
• You may update, correct, or delete your data
• You may request permanent deletion (except your email used for login)
• You can withdraw your consent at any time

We NEVER:
• Sell your data
• Share with third parties without consent
• Read your actual banking credentials or SMS content without permission

Your data is securely stored with industry-standard encryption.
''';
}
