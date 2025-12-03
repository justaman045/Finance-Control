// lib/Screens/add_transaction.dart

import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:money_control/Components/colors.dart';
import 'package:money_control/Components/methods.dart';
import 'package:money_control/Models/cateogary.dart';
import 'package:money_control/Models/transaction.dart';
import 'package:money_control/Screens/add_transaction_from_recipt.dart';
import 'package:money_control/Services/local_backup_service.dart';
import 'package:money_control/Services/offline_queue.dart';

enum PaymentType { send, receive }

class PaymentScreen extends StatefulWidget {
  final PaymentType type;
  final String? cateogary;

  const PaymentScreen({
    super.key,
    required this.type,
    this.cateogary,
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  final TextEditingController _amount = TextEditingController();
  final TextEditingController _name = TextEditingController();
  final TextEditingController _note = TextEditingController();
  final TextEditingController _newCategory = TextEditingController();

  List<CategoryModel> _categories = [];
  String? selectedCategory;

  DateTime selectedDate = DateTime.now();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    loadCategories();
  }

  // ——————————————————————————————————————
  //  LOAD CATEGORIES
  // ——————————————————————————————————————
  Future<void> loadCategories() async {
    try {
      final snapshot = await _firestore
          .collection("users")
          .doc(_auth.currentUser!.email)
          .collection("categories")
          .get();

      final data =
      snapshot.docs.map((d) => CategoryModel.fromMap(d.id, d.data())).toList();

      if (widget.cateogary != null) {
        data.sort((a, b) =>
        a.name == widget.cateogary ? -1 : b.name == widget.cateogary ? 1 : 0);
      }

      setState(() {
        _categories = data;
        selectedCategory =
            widget.cateogary ?? (data.isNotEmpty ? data.first.name : null);
      });
    } catch (e) {
      debugPrint("Error loading categories: $e");
    }
  }

  // ——————————————————————————————————————
  //  ADD CATEGORY
  // ——————————————————————————————————————
  Future<void> _addCategoryDialog() async {
    _newCategory.clear();

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Add New Category"),
        content: TextField(
          controller: _newCategory,
          decoration: const InputDecoration(hintText: "Category name"),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              final text = _newCategory.text.trim();

              if (text.isEmpty) {
                Get.snackbar("Error", "Category name cannot be empty");
                return;
              }
              if (_categories
                  .any((c) => c.name.toLowerCase() == text.toLowerCase())) {
                Get.snackbar("Error", "Category already exists");
                return;
              }

              try {
                final doc = await _firestore
                    .collection("users")
                    .doc(_auth.currentUser!.email)
                    .collection("categories")
                    .add({"name": text});

                setState(() {
                  _categories.add(CategoryModel(id: doc.id, name: text));
                  selectedCategory = text;
                });

                Navigator.pop(context);
              } catch (e) {
                debugPrint('Add category error: $e');
                Get.snackbar("Error", "Failed to add category");
              }
            },
            child: const Text("Add"),
          ),
        ],
      ),
    );
  }

  // ——————————————————————————————————————
  //  DELETE CATEGORY (long press)
  // ——————————————————————————————————————
  Future<void> _deleteCategory(CategoryModel category) async {
    final user = _auth.currentUser;
    if (user == null) return;

    if (_categories.length == 1) {
      Get.snackbar("Action blocked", "At least one category must exist.");
      return;
    }

    final confirm = await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Delete Category"),
        content: Text(
          "Do you want to delete '${category.name}'?\n\n"
              "• This will NOT delete existing transactions.\n"
              "• Category will simply be removed from your list.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Delete"),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await _firestore
          .collection("users")
          .doc(user.email)
          .collection("categories")
          .doc(category.id)
          .delete();

      setState(() {
        _categories.removeWhere((c) => c.id == category.id);

        if (selectedCategory == category.name) {
          selectedCategory = _categories.first.name;
        }
      });

      Get.snackbar(
        "Deleted",
        "'${category.name}' removed successfully",
        snackPosition: SnackPosition.BOTTOM,
        colorText: Colors.white,
        backgroundColor: Colors.redAccent,
        icon: const Icon(Icons.delete, color: Colors.white),
      );
    } catch (e) {
      Get.snackbar("Error", "Failed to delete category");
    }
  }

  // ——————————————————————————————————————
  //  SAVE TRANSACTION  +  JSON BACKUP
  // ——————————————————————————————————————
  Future<void> saveTransaction() async {
    if (_saving) return;
    _saving = true;

    final user = _auth.currentUser;
    if (user == null) {
      _saving = false;
      return;
    }

    final amount = double.tryParse(_amount.text.trim()) ?? 0;
    if (amount <= 0) {
      _saving = false;
      Get.snackbar("Error", "Enter valid amount");
      return;
    }

    if (_name.text.trim().isEmpty) {
      _saving = false;
      Get.snackbar("Error", "Enter valid name");
      return;
    }

    if (selectedCategory == null) {
      _saving = false;
      Get.snackbar("Error", "Select a category");
      return;
    }

    final tx = TransactionModel(
      id: "",
      senderId: widget.type == PaymentType.send ? user.uid : "",
      recipientId: widget.type == PaymentType.send ? "" : user.uid,
      recipientName: _name.text.trim(),
      amount: amount,
      currency: "INR",
      tax: 0.0,
      note: _note.text.trim(),
      category: selectedCategory,
      date: selectedDate,
      status: "success",
      createdAt: Timestamp.now(),
    );

    final txMap = tx.toMap();

    try {
      // 🔥 FIRESTORE WRITE WITH TIMEOUT FIX
      await FirebaseFirestore.instance
          .collection("users")
          .doc(user.email)
          .collection("transactions")
          .add(txMap)
          .timeout(const Duration(seconds: 5)); // <<<<<< IMPORTANT

    } on TimeoutException catch (e) {
      print("Firebase error: $e");
      await OfflineQueueService.savePending(txMap);
      Get.snackbar("Offline", "Saved locally. Will sync later.");
    }

    // Backup JSON
    LocalBackupService.backupUserTransactions(user.email!);

    Get.snackbar(
      "Success",
      "₹${amount.toStringAsFixed(2)} ${widget.type == PaymentType.send ? 'sent' : 'received'}",
      snackPosition: SnackPosition.BOTTOM,
      colorText: Colors.white,
      icon: const Icon(Icons.check_circle, color: Colors.white),
    );

    _saving = false;
    goBack();
  }


  // ——————————————————————————————————————
  //  UI BUILD
  // ——————————————————————————————————————
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isLight = scheme.brightness == Brightness.light;

    final gradientTop = isLight ? kLightGradientTop : kDarkGradientTop;
    final gradientBottom = isLight ? kLightGradientBottom : kDarkGradientBottom;

    final title =
    widget.type == PaymentType.send ? "Send Money" : "Receive Money";
    final nameLabel =
    widget.type == PaymentType.send ? "Recipient" : "Sender";

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [gradientTop, gradientBottom],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildAppBar(scheme, title),
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(horizontal: 18.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _FieldLabel("Amount", scheme),
                      _AmountField(_amount, scheme),

                      _FieldLabel(nameLabel, scheme),
                      _InputField(
                        controller: _name,
                        hint: "Enter name",
                        scheme: scheme,
                      ),

                      _FieldLabel("Select Category", scheme),
                      _CategorySelector(),

                      _FieldLabel("Note", scheme),
                      _InputField(
                        controller: _note,
                        hint: "Add a note...",
                        scheme: scheme,
                        maxLines: 2,
                      ),

                      _FieldLabel("Date", scheme),
                      _DateSelector(),

                      SizedBox(height: 32.h),
                      _SubmitButton(
                        label:
                        widget.type == PaymentType.send ? "Send" : "Receive",
                        onTap: saveTransaction,
                        scheme: scheme,
                      ),

                      SizedBox(height: 20.h),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ——————————————————————————————————————
  //  WIDGETS
  // ——————————————————————————————————————

  Widget _buildAppBar(ColorScheme scheme, String title) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      title: Text(
        title,
        style: TextStyle(
          color: scheme.onBackground,
          fontWeight: FontWeight.w600,
          fontSize: 17.sp,
        ),
      ),
      leading: IconButton(
        icon: Icon(Icons.arrow_back_ios, color: scheme.onBackground),
        onPressed: goBack,
      ),
      actions: [
        if (widget.type == PaymentType.send)
          IconButton(
            icon: Icon(Icons.qr_code_scanner, color: scheme.onBackground),
            onPressed: () {
              Get.to(
                    () => ReceiptScanPage(),
                curve: curve,
                transition: transition,
                duration: duration,
              );
            },
          ),
      ],
    );
  }

  Widget _FieldLabel(String text, ColorScheme scheme) {
    return Padding(
      padding: EdgeInsets.only(top: 20.h, bottom: 6.h),
      child: Text(
        text,
        style: TextStyle(
          color: scheme.onSurface,
          fontSize: 13.sp,
        ),
      ),
    );
  }

  Widget _AmountField(TextEditingController c, ColorScheme scheme) {
    return _Box(
      scheme,
      Row(
        children: [
          Text(
            "INR",
            style: TextStyle(
              color: scheme.primary,
              fontWeight: FontWeight.w700,
              fontSize: 15.sp,
            ),
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: TextField(
              controller: c,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(border: InputBorder.none),
              style: TextStyle(
                fontSize: 18.sp,
                color: scheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _InputField({
    required TextEditingController controller,
    required String hint,
    required ColorScheme scheme,
    int maxLines = 1,
  }) {
    return _Box(
      scheme,
      TextField(
        controller: controller,
        maxLines: maxLines,
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: hint,
          hintStyle: TextStyle(color: scheme.onSurface.withOpacity(0.4)),
        ),
        style: TextStyle(fontSize: 15.sp, color: scheme.onSurface),
      ),
    );
  }

  Widget _CategorySelector() {
    final scheme = Theme.of(context).colorScheme;
    final isLight = scheme.brightness == Brightness.light;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          ..._categories.map(
                (cat) => Padding(
              padding: EdgeInsets.only(right: 8.w),
              child: GestureDetector(
                onLongPress: () => _deleteCategory(cat),
                child: ChoiceChip(
                  label: Text(cat.name),
                  selected: selectedCategory == cat.name,
                  onSelected: (_) =>
                      setState(() => selectedCategory = cat.name),
                  selectedColor: scheme.primary,
                  labelStyle: TextStyle(
                    color: selectedCategory == cat.name
                        ? scheme.onPrimary
                        : scheme.onSurface,
                  ),
                  backgroundColor: scheme.surface,
                  shape: StadiumBorder(
                    side: BorderSide(
                      color: selectedCategory == cat.name
                          ? scheme.primary
                          : (isLight ? kLightBorder : kDarkBorder),
                    ),
                  ),
                ),
              ),
            ),
          ),
          ActionChip(
            label: Row(
              children: [
                Icon(Icons.add, color: scheme.primary, size: 17),
                Text(" Add", style: TextStyle(color: scheme.primary)),
              ],
            ),
            backgroundColor: scheme.surface,
            onPressed: _addCategoryDialog,
          )
        ],
      ),
    );
  }

  Widget _DateSelector() {
    final scheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: selectedDate,
          firstDate: DateTime(2015),
          lastDate: DateTime(2100),
        );
        if (picked != null) setState(() => selectedDate = picked);
      },
      child: _Box(
        scheme,
        Row(
          children: [
            Text(
              "${selectedDate.day}/${selectedDate.month}/${selectedDate.year}",
              style: TextStyle(fontSize: 15.sp, color: scheme.onSurface),
            ),
            const Spacer(),
            Icon(Icons.calendar_today_outlined, color: scheme.primary),
          ],
        ),
      ),
    );
  }

  Widget _SubmitButton({
    required String label,
    required VoidCallback onTap,
    required ColorScheme scheme,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 52.h,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: scheme.primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24.r),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: scheme.onPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 16.sp,
          ),
        ),
      ),
    );
  }

  Widget _Box(ColorScheme scheme, Widget child) {
    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(14.r),
      ),
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
      child: child,
    );
  }
}
