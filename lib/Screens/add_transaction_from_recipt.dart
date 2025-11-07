import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:money_control/Models/transaction.dart';
import 'package:money_control/Components/bottom_nav_bar.dart';

class ReceiptScanPage extends StatefulWidget {
  const ReceiptScanPage({Key? key}) : super(key: key);

  @override
  State<ReceiptScanPage> createState() => _ReceiptScanPageState();
}

class _ReceiptScanPageState extends State<ReceiptScanPage> {
  File? _imageFile;
  String? _recognizedText;
  bool _scanning = false;

  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage(ImageSource source) async {
    final pickedFile = await _picker.pickImage(source: source, imageQuality: 80);
    if (pickedFile == null) return;

    setState(() {
      _imageFile = File(pickedFile.path);
      _recognizedText = null;
      _scanning = true;
    });

    await _performTextRecognition(_imageFile!);
  }

  Future<void> _performTextRecognition(File imageFile) async {
    final inputImage = InputImage.fromFile(imageFile);
    final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);

    try {
      final RecognizedText recognizedText = await textRecognizer.processImage(inputImage);
      setState(() {
        _recognizedText = recognizedText.text;
        _scanning = false;
      });
    } catch (e) {
      setState(() {
        _recognizedText = "Failed to recognize text: $e";
        _scanning = false;
      });
    } finally {
      textRecognizer.close();
    }
  }

  void _onSave() async {
    if (_recognizedText == null || _recognizedText!.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("No scanned text to save.")));
      return;
    }

    double? amount = _extractAmount(_recognizedText!);
    String category = _extractCategory(_recognizedText!) ?? 'General';
    DateTime date = _extractDate(_recognizedText!) ?? DateTime.now();
    String note = _recognizedText!;

    if (amount == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Unable to extract amount. Please edit manually.")));
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final docRef = FirebaseFirestore.instance
          .collection('users')
          .doc(user.email)
          .collection('transactions')
          .doc();

      final transaction = TransactionModel(
        id: docRef.id,
        senderId: user.uid,  // assuming user is sender (expense)
        recipientId: '',     // unknown recipient
        recipientName: 'Transaction Added from Receipt',
        amount: amount,
        currency: 'INR',
        tax: 0,
        note: note,
        category: category,
        date: date,
      );

      await docRef.set(transaction.toMap());

      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Transaction saved successfully.")));

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Failed to save transaction: $e")));
    }
  }

  // Helper parsers:

  double? _extractAmount(String text) {
    final amtRegex = RegExp(r'((?:Rs\.?|INR)?\s?[\d,]+(?:\.\d{1,2})?)');
    final match = amtRegex.firstMatch(text);
    if (match != null) {
      String amtStr = match.group(1)!.replaceAll(RegExp(r'[^\d.]'), '');
      return double.tryParse(amtStr);
    }
    return null;
  }

  String? _extractCategory(String text) {
    final lower = text.toLowerCase();
    if (lower.contains('grocery')) return 'Groceries';
    if (lower.contains('fuel') || lower.contains('petrol')) return 'Fuel';
    if (lower.contains('restaurant') || lower.contains('dining')) return 'Dining';
    if (lower.contains('rent')) return 'Rent';
    if (lower.contains('shopping')) return 'Shopping';
    return null;
  }

  DateTime? _extractDate(String text) {
    final dateRegex = RegExp(r'(\d{2}[\/\-]\d{2}[\/\-]\d{2,4})');
    final match = dateRegex.firstMatch(text);
    if (match != null) {
      try {
        final parts = match.group(1)!.split(RegExp(r'[\/\-]'));
        int day = int.parse(parts[0]);
        int month = int.parse(parts[1]);
        int year = int.parse(parts[2].length == 2 ? '20${parts[2]}' : parts[2]);
        return DateTime(year, month, day);
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Receipt Scanner",
          style: TextStyle(color: scheme.onBackground, fontWeight: FontWeight.bold, fontSize: 18.sp),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: BackButton(color: scheme.onBackground),
      ),
      backgroundColor: scheme.background,
      body: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _imageFile == null
                ? Container(
              height: 250.h,
              decoration: BoxDecoration(
                border: Border.all(color: scheme.onSurface.withOpacity(0.3)),
                borderRadius: BorderRadius.circular(14.r),
              ),
              child: const Center(child: Text("No image selected")),
            )
                : ClipRRect(
              borderRadius: BorderRadius.circular(14.r),
              child: Image.file(_imageFile!, height: 250.h, fit: BoxFit.cover),
            ),
            SizedBox(height: 16.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  icon: const Icon(Icons.camera_alt),
                  label: const Text("Take Photo"),
                  onPressed: () => _pickImage(ImageSource.camera),
                ),
                SizedBox(width: 12.w),
                ElevatedButton.icon(
                  icon: const Icon(Icons.photo_library),
                  label: const Text("Choose from Gallery"),
                  onPressed: () => _pickImage(ImageSource.gallery),
                ),
              ],
            ),
            SizedBox(height: 24.h),
            Expanded(
              child: _scanning
                  ? const Center(child: CircularProgressIndicator())
                  : SingleChildScrollView(
                child: Text(
                  _recognizedText ?? "Scanned text will appear here.",
                  style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 14.sp),
                ),
              ),
            ),
            ElevatedButton(
              onPressed: _onSave,
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 14.h),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30.r)),
              ),
              child: const Text("Save Transaction from Text"),
            )
          ],
        ),
      ),
      bottomNavigationBar: const BottomNavBar(currentIndex: 4),
    );
  }
}
