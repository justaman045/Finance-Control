// lib/Screens/add_transaction.dart

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:money_control/Components/methods.dart';
import 'package:money_control/Models/cateogary.dart';
import 'package:money_control/Models/transaction.dart';
import 'package:money_control/Screens/add_transaction_from_recipt.dart';
import 'package:money_control/Services/local_backup_service.dart';
import 'package:money_control/Services/offline_queue.dart';
import 'package:money_control/Controllers/currency_controller.dart';
import 'package:money_control/Services/budget_service.dart';

enum PaymentType { send, receive }

class PaymentScreen extends StatefulWidget {
  final PaymentType type;
  final String? cateogary;

  const PaymentScreen({super.key, required this.type, this.cateogary});

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

      final data = snapshot.docs
          .map((d) => CategoryModel.fromMap(d.id, d.data()))
          .toList();

      if (widget.cateogary != null) {
        data.sort(
          (a, b) => a.name == widget.cateogary
              ? -1
              : b.name == widget.cateogary
              ? 1
              : 0,
        );
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
      barrierColor: Colors.black.withOpacity(0.8),
      builder: (_) => Dialog(
        backgroundColor: const Color(0xFF1E1E2C), // Fallback
        elevation: 0,
        insetPadding: EdgeInsets.all(20.w),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24.r),
          side: BorderSide(color: Colors.white.withOpacity(0.1)),
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24.r),
            gradient: const LinearGradient(
              colors: [Color(0xFF1A1A2E), Color(0xFF16213E)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF6C63FF).withOpacity(0.2),
                blurRadius: 20,
                spreadRadius: 2,
              ),
            ],
          ),
          padding: EdgeInsets.all(24.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "New Category",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20.sp,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              SizedBox(height: 20.h),

              // Custom Glass Input
              Container(
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(16.r),
                  border: Border.all(color: Colors.white.withOpacity(0.1)),
                ),
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                child: TextField(
                  controller: _newCategory,
                  autofocus: true,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: "Category Name",
                    hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
                  ),
                ),
              ),
              SizedBox(height: 24.h),

              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      "Cancel",
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.6),
                        fontSize: 16.sp,
                      ),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  GestureDetector(
                    onTap: () async {
                      final text = _newCategory.text.trim();

                      if (text.isEmpty) {
                        Get.snackbar(
                          "Error",
                          "Category name cannot be empty",
                          backgroundColor: Colors.white10,
                          colorText: Colors.white,
                        );
                        return;
                      }
                      if (_categories.any(
                        (c) => c.name.toLowerCase() == text.toLowerCase(),
                      )) {
                        Get.snackbar(
                          "Error",
                          "Category already exists",
                          backgroundColor: Colors.white10,
                          colorText: Colors.white,
                        );
                        return;
                      }

                      try {
                        final doc = await _firestore
                            .collection("users")
                            .doc(_auth.currentUser!.email)
                            .collection("categories")
                            .add({"name": text});

                        setState(() {
                          _categories.add(
                            CategoryModel(id: doc.id, name: text),
                          );
                          selectedCategory = text;
                        });

                        Navigator.pop(context);
                      } catch (e) {
                        debugPrint('Add category error: $e');
                        Get.snackbar("Error", "Failed to add category");
                      }
                    },
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 24.w,
                        vertical: 12.h,
                      ),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF6C63FF), Color(0xFF00E5FF)],
                        ),
                        borderRadius: BorderRadius.circular(12.r),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF6C63FF).withOpacity(0.4),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                      child: Text(
                        "Add",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16.sp,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
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

    // Negate amount if it's an expense (send)
    final finalAmount = widget.type == PaymentType.send ? -amount : amount;

    final tx = TransactionModel(
      id: "",
      senderId: widget.type == PaymentType.send ? user.uid : "",
      recipientId: widget.type == PaymentType.send ? "" : user.uid,
      recipientName: _name.text.trim(),
      amount: finalAmount,
      currency: CurrencyController.to.currencyCode.value,
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

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          "₹${amount.toStringAsFixed(2)} ${widget.type == PaymentType.send ? 'sent' : 'received'}",
        ),
        backgroundColor: Colors.green,
      ),
    );

    // Check Budget Limit (Only for Expenses)
    if (widget.type == PaymentType.send &&
        selectedCategory != null &&
        user.email != null) {
      BudgetService.checkBudgetExceeded(
        userId: user.email!,
        category: selectedCategory!,
        newAmount: amount, // Pass positive amount for check logic
      );
    }

    _saving = false;
    goBack();
  }

  // ——————————————————————————————————————
  //  UI BUILD
  // ——————————————————————————————————————
  @override
  Widget build(BuildContext context) {
    final title = widget.type == PaymentType.send
        ? "Send Money"
        : "Receive Money";
    final nameLabel = widget.type == PaymentType.send ? "Recipient" : "Sender";

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: _buildAppBar(title),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xFF1A1A2E), // Midnight Void Top
              const Color(0xFF16213E).withOpacity(0.95), // Deep Blue Bottom
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 20.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _FieldLabel("Amount"),
                _AmountField(_amount),

                _FieldLabel(nameLabel),
                _InputField(controller: _name, hint: "Enter name"),

                _FieldLabel("Select Category"),
                _CategorySelector(),

                _FieldLabel("Note"),
                _InputField(
                  controller: _note,
                  hint: "Add a note...",
                  maxLines: 2,
                ),

                _FieldLabel("Date"),
                _DateSelector(),

                SizedBox(height: 40.h),
                _SubmitButton(
                  label: widget.type == PaymentType.send ? "Send" : "Receive",
                  onTap: saveTransaction,
                ),

                SizedBox(height: 20.h),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ——————————————————————————————————————
  //  WIDGETS
  // ——————————————————————————————————————

  AppBar _buildAppBar(String title) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      title: Text(
        title,
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 18.sp,
        ),
      ),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
        onPressed: goBack,
      ),
      actions: [
        if (widget.type == PaymentType.send)
          IconButton(
            icon: const Icon(Icons.qr_code_scanner, color: Colors.white),
            onPressed: () {
              Get.to(() => const ReceiptScanPage());
            },
          ),
      ],
    );
  }

  Widget _FieldLabel(String text) {
    return Padding(
      padding: EdgeInsets.only(top: 20.h, bottom: 10.h),
      child: Text(
        text,
        style: TextStyle(
          color: Colors.white70,
          fontSize: 14.sp,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _AmountField(TextEditingController c) {
    return _GlassBox(
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
            decoration: BoxDecoration(
              color: const Color(0xFF6C63FF).withOpacity(0.2),
              borderRadius: BorderRadius.circular(8.r),
              border: Border.all(
                color: const Color(0xFF6C63FF).withOpacity(0.3),
              ),
            ),
            child: Obx(
              () => Text(
                CurrencyController.to.currencyCode.value,
                style: TextStyle(
                  color: const Color(0xFF6C63FF), // Blurple
                  fontWeight: FontWeight.w800,
                  fontSize: 15.sp,
                ),
              ),
            ),
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: TextField(
              controller: c,
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: "0.00",
                hintStyle: TextStyle(color: Colors.white24, fontSize: 22.sp),
              ),
              style: TextStyle(
                fontSize: 22.sp,
                color: Colors.white,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _InputField({
    required TextEditingController controller,
    required String hint,
    int maxLines = 1,
  }) {
    return _GlassBox(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 18.h),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: hint,
          hintStyle: TextStyle(
            color: Colors.white24,
            fontSize: 18.sp,
            fontWeight: FontWeight.w500,
          ),
          contentPadding: EdgeInsets.zero,
        ),
        style: TextStyle(
          fontSize: 18.sp,
          color: Colors.white,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _CategorySelector() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          ..._categories.map((cat) {
            final isSelected = selectedCategory == cat.name;
            final catColor = cat.color != null
                ? Color(cat.color!)
                : const Color(0xFF00E5FF);
            final borderColor = isSelected ? catColor : Colors.white12;

            return Padding(
              padding: EdgeInsets.only(right: 12.w),
              child: GestureDetector(
                onTap: () => setState(() => selectedCategory = cat.name),
                onLongPress: () => _deleteCategory(cat),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: EdgeInsets.symmetric(
                    horizontal: 16.w,
                    vertical: 12.h,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? catColor.withOpacity(0.25)
                        : Colors.white.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(24.r),
                    border: Border.all(color: borderColor, width: 1.5),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: catColor.withOpacity(0.3),
                              blurRadius: 12,
                              spreadRadius: -2,
                            ),
                          ]
                        : null,
                  ),
                  child: Row(
                    children: [
                      if (cat.iconCode != null) ...[
                        Icon(
                          IconData(cat.iconCode!, fontFamily: 'MaterialIcons'),
                          size: 18.sp,
                          color: isSelected ? catColor : Colors.white60,
                        ),
                        SizedBox(width: 8.w),
                      ],
                      Text(
                        cat.name,
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.white60,
                          fontWeight: FontWeight.w600,
                          fontSize: 15.sp,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),

          // ADD BUTTON
          GestureDetector(
            onTap: _addCategoryDialog,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 14.h),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.08),
                borderRadius: BorderRadius.circular(24.r),
                border: Border.all(color: Colors.white12),
              ),
              child: Row(
                children: [
                  Icon(Icons.add, color: Colors.white70, size: 20.sp),
                  SizedBox(width: 6.w),
                  Text(
                    "Add",
                    style: TextStyle(color: Colors.white70, fontSize: 15.sp),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _DateSelector() {
    return GestureDetector(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: selectedDate,
          firstDate: DateTime(2015),
          lastDate: DateTime(2100),
          builder: (context, child) {
            return Theme(
              data: Theme.of(context).copyWith(
                colorScheme: const ColorScheme.dark(
                  primary: Color(0xFF6C63FF),
                  onPrimary: Colors.white,
                  surface: Color(0xFF1E1E2C),
                  onSurface: Colors.white,
                ),
                dialogBackgroundColor: const Color(0xFF1E1E2C),
              ),
              child: child!,
            );
          },
        );
        if (picked != null) setState(() => selectedDate = picked);
      },
      child: _GlassBox(
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 18.h),
        child: Row(
          children: [
            Text(
              "${selectedDate.day}/${selectedDate.month}/${selectedDate.year}",
              style: TextStyle(
                fontSize: 18.sp,
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
            const Spacer(),
            const Icon(Icons.calendar_today_outlined, color: Color(0xFF6C63FF)),
          ],
        ),
      ),
    );
  }

  Widget _SubmitButton({required String label, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 54.h,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF6C63FF), Color(0xFF00E5FF)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(27.r),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF6C63FF).withOpacity(0.4),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: Text(
          label.toUpperCase(),
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16.sp,
            letterSpacing: 1.5,
          ),
        ),
      ),
    );
  }

  Widget _GlassBox({required Widget child, EdgeInsetsGeometry? padding}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      padding:
          padding ?? EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
      child: child,
    );
  }
}
