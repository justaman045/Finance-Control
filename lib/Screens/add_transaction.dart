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

enum PaymentType { send, receive }

class PaymentScreen extends StatefulWidget {
  final PaymentType type;
  final String? cateogary;
  // Removed recipientId

  const PaymentScreen({super.key, required this.type, this.cateogary});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _personController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  final TextEditingController _newCategoryController = TextEditingController();

  List<CategoryModel> _categories = [];
  String? selectedCategory;

  DateTime selectedDate = DateTime(
    DateTime.now().year,
    DateTime.now().month,
    DateTime.now().day,
    DateTime.now().hour,
    DateTime.now().minute,
    DateTime.now().second,
    DateTime.now().millisecond,
  );

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(FirebaseAuth.instance.currentUser!.email)
          .collection("categories")
          .get();

      List<CategoryModel> fetchedCategories = snapshot.docs
          .map((doc) => CategoryModel.fromMap(doc.id, doc.data()))
          .toList();

      // Reorder so widget.cateogary comes first, if present
      if (widget.cateogary != null && widget.cateogary!.isNotEmpty) {
        final idx = fetchedCategories.indexWhere(
              (cat) => cat.name == widget.cateogary,
        );
        if (idx != -1) {
          // Remove and insert at front
          final cat = fetchedCategories.removeAt(idx);
          fetchedCategories.insert(0, cat);
        }
      }

      setState(() {
        _categories = fetchedCategories;
        // Always set selectedCategory; cateogary will appear first if present
        selectedCategory = widget.cateogary ?? (_categories.isNotEmpty ? _categories.first.name : null);
      });
    } catch (e) {
      debugPrint("Failed to load categories: $e");
    }
  }


  Future<void> _showAddCategoryDialog() async {
    _newCategoryController.clear();
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Add New Category"),
        content: TextField(
          controller: _newCategoryController,
          decoration: const InputDecoration(hintText: "Category name"),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              final newName = _newCategoryController.text.trim();
              if (newName.isEmpty) {
                Get.snackbar("Validation", "Category name can't be empty");
                return;
              }
              if (_categories.any(
                (cat) => cat.name.toLowerCase() == newName.toLowerCase(),
              )) {
                Get.snackbar("Validation", "Category already exists");
                return;
              }
              try {
                final docRef = await _firestore.collection('users').doc(FirebaseAuth.instance.currentUser!.email).collection("categories").add({
                  'name': newName,
                });
                setState(() {
                  _categories.add(CategoryModel(id: docRef.id, name: newName));
                  selectedCategory = newName;
                });
                Navigator.of(ctx).pop();
              } catch (e) {
                Get.snackbar("Error", "Failed to add category");
              }
            },
            child: const Text("Add"),
          ),
        ],
      ),
    );
  }

  //TODO: Remove usage warning
  // Future<void> _deleteCategory(CategoryModel category) async {
  //   try {
  //     await _firestore.collection('categories').doc(category.id).delete();
  //     debugPrint("Category deleted successfully ${category.name}");
  //     setState(() {
  //       _categories.removeWhere((cat) => cat.id == category.id);
  //       if (selectedCategory == category.name) {
  //         selectedCategory = _categories.isNotEmpty
  //             ? _categories.first.name
  //             : null;
  //       }
  //     });
  //     Get.snackbar("Deleted", "Category removed successfully");
  //   } catch (e) {
  //     Get.snackbar("Error", "Failed to delete category");
  //   }
  // }

  Future<void> _saveTransaction() async {
    final user = _auth.currentUser;
    if (user == null) {
      Get.snackbar('Error', 'User not logged in');
      return;
    }

    final amount = double.tryParse(_amountController.text.trim()) ?? 0.0;
    if (amount <= 0) {
      Get.snackbar('Error', 'Enter a valid amount');
      return;
    }
    if (_personController.text.trim().isEmpty) {
      Get.snackbar('Error', 'Enter recipient/sender name');
      return;
    }
    if (selectedCategory == null || selectedCategory!.isEmpty) {
      Get.snackbar('Error', 'Select a category');
      return;
    }

    try {
      final transaction = TransactionModel(
        id: '',
        senderId: widget.type == PaymentType.send ? user.uid : '',
        recipientId: widget.type == PaymentType.send ? '' : user.uid,
        recipientName: _personController.text.trim(),
        amount: amount,
        currency: 'INR',
        tax: 0.0,
        note: _noteController.text.trim(),
        category: selectedCategory,
        date: selectedDate,
        status: 'success',
        createdAt: Timestamp.now(),
      );

      await _firestore.collection("users").doc(user.email).collection('transactions').add(transaction.toMap());

      // Show confirmation dialog after successful save
      // await showDialog(
      //   context: context,
      //   builder: (ctx) => AlertDialog(
      //     shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      //     title: Row(
      //       children: [
      //         Icon(Icons.check_circle, color: Colors.green, size: 30),
      //         SizedBox(width: 8),
      //         Text("Transaction Successful"),
      //       ],
      //     ),
      //     content: Column(
      //       mainAxisSize: MainAxisSize.min,
      //       children: [
      //         Text(
      //           "₹${amount.toStringAsFixed(2)} ${widget.type == PaymentType.send ? "sent to" : "received from"} ${_personController.text.trim()}",
      //           textAlign: TextAlign.center,
      //           style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
      //         ),
      //         SizedBox(height: 8),
      //         Text("Category: $selectedCategory"),
      //         Text("Date: ${selectedDate.day}/${selectedDate.month}/${selectedDate.year}"),
      //       ],
      //     ),
      //     actions: [
      //       TextButton(
      //         onPressed: () {
      //           Navigator.of(ctx).pop();
      //           goBack(); // Return to previous page after dismissing
      //         },
      //         child: const Text("Done", style: TextStyle(color: Colors.blue, fontSize: 15)),
      //       )
      //     ],
      //   ),
      // );
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Get.snackbar(
          "Transaction Successful",
          "₹${amount.toStringAsFixed(2)} ${widget.type == PaymentType.send ? "sent to" : "received from"} ${_personController.text.trim()}",
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
          borderRadius: 8,
          icon: Icon(Icons.check_circle, color: Colors.white),
          duration: Duration(seconds: 3),
        );
        // Optional: Delay navigation, or allow user to back manually
      });
      goBack();
    } catch (e) {
      debugPrint("Error saving transaction: $e");
      Get.snackbar('Error', 'Failed to save transaction');
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isLight = scheme.brightness == Brightness.light;

    final gradientTop = isLight ? kLightGradientTop : kDarkGradientTop;
    final gradientBottom = isLight ? kLightGradientBottom : kDarkGradientBottom;

    final title = widget.type == PaymentType.send
        ? "Send Money"
        : "Receive Money";
    final personLabel = widget.type == PaymentType.send
        ? "Recipient"
        : "Sender";
    final personHint = widget.type == PaymentType.send
        ? "Enter recipient name"
        : "Enter sender name";
    //TODO: Remove usage warning
    // final actionButtonLabel = widget.type == PaymentType.send
    //     ? "Send"
    //     : "Receive";

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
              AppBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
                title: Text(
                  title,
                  style: TextStyle(
                    color: scheme.onBackground,
                    fontWeight: FontWeight.w600,
                    fontSize: 17.sp,
                  ),
                ),
                centerTitle: true,
                leading: IconButton(
                  icon: Icon(
                    Icons.arrow_back_ios,
                    color: scheme.onBackground,
                    size: 20.sp,
                  ),
                  onPressed: () => goBack(),
                ),
                
                actions: [
                  if(widget.type == PaymentType.send) ...[
                    IconButton(
                      icon: Icon(
                        Icons.qr_code_scanner,
                        color: scheme.onBackground,
                      ), onPressed: () { Get.to(() => ReceiptScanPage(), curve: curve, transition: transition, duration: duration); },
                    )
                  ]
                ],
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(
                    horizontal: 18.w,
                    vertical: 8.h,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Amount",
                        style: TextStyle(
                          color: scheme.onSurface,
                          fontSize: 13.sp,
                        ),
                      ),
                      SizedBox(height: 8.h),
                      Container(
                        decoration: BoxDecoration(
                          color: scheme.surface,
                          borderRadius: BorderRadius.circular(13.r),
                        ),
                        padding: EdgeInsets.symmetric(
                          horizontal: 12.w,
                          vertical: 4.h,
                        ),
                        child: Row(
                          children: [
                            Text(
                              "INR",
                              style: TextStyle(
                                color: scheme.primary,
                                fontWeight: FontWeight.w700,
                                fontSize: 15.sp,
                              ),
                            ),
                            SizedBox(width: 8.w),
                            Expanded(
                              child: TextField(
                                controller: _amountController,
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  border: InputBorder.none,
                                  isCollapsed: true,
                                  hintText: "0",
                                  hintStyle: TextStyle(
                                    color: scheme.onSurface.withOpacity(0.4),
                                  ),
                                ),
                                style: TextStyle(
                                  color: scheme.onSurface,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18.sp,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 20.h),
                      Text(
                        personLabel,
                        style: TextStyle(
                          color: scheme.onSurface,
                          fontSize: 13.sp,
                        ),
                      ),
                      SizedBox(height: 8.h),
                      Container(
                        decoration: BoxDecoration(
                          color: scheme.surface,
                          borderRadius: BorderRadius.circular(13.r),
                        ),
                        padding: EdgeInsets.symmetric(
                          horizontal: 12.w,
                          vertical: 4.h,
                        ),
                        child: TextField(
                          controller: _personController,
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            isCollapsed: true,
                            hintText: personHint,
                            hintStyle: TextStyle(
                              color: scheme.onSurface.withOpacity(0.4),
                            ),
                          ),
                          style: TextStyle(
                            color: scheme.onSurface,
                            fontWeight: FontWeight.normal,
                            fontSize: 16.sp,
                          ),
                        ),
                      ),
                      SizedBox(height: 20.h),
                      Text(
                        "Select Category",
                        style: TextStyle(
                          color: scheme.onSurface,
                          fontSize: 13.sp,
                        ),
                      ),
                      SizedBox(height: 10.h),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            ..._categories.map(
                              (cat) => Padding(
                                padding: EdgeInsets.only(right: 8.w),
                                child: ChoiceChip(
                                  labelPadding: EdgeInsets.zero,
                                  label: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Padding(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 8.w,
                                        ),
                                        child: Text(
                                          cat.name,
                                          style: TextStyle(fontSize: 13.sp),
                                        ),
                                      ),
                                      Padding(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 6.w,
                                        ),
                                        child: Icon(
                                          Icons.close,
                                          size: 15.sp,
                                          color: selectedCategory == cat.name
                                              ? scheme.onPrimary
                                              : scheme.onSurface,
                                        ),
                                      ),
                                    ],
                                  ),
                                  selected: selectedCategory == cat.name,
                                  selectedColor: scheme.primary,
                                  backgroundColor: scheme.surface,
                                  labelStyle: TextStyle(
                                    color: selectedCategory == cat.name
                                        ? scheme.onPrimary
                                        : scheme.onSurface,
                                  ),
                                  onSelected: (sel) => setState(
                                    () => selectedCategory = cat.name,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(18.r),
                                    side: BorderSide(
                                      color: selectedCategory == cat.name
                                          ? scheme.primary
                                          : (isLight
                                                ? kLightBorder
                                                : kDarkBorder),
                                      width: 1.3,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Container(
                              margin: EdgeInsets.only(left: 2.w),
                              child: ActionChip(
                                labelPadding: EdgeInsets.symmetric(
                                  horizontal: 6,
                                ),
                                label: Row(
                                  children: [
                                    Icon(
                                      Icons.add,
                                      color: scheme.primary,
                                      size: 16,
                                    ),
                                    SizedBox(width: 4),
                                    Text(
                                      "Add category",
                                      style: TextStyle(
                                        color: scheme.primary,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                                backgroundColor: scheme.surface,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  side: BorderSide(
                                    color: scheme.primary.withOpacity(0.35),
                                  ),
                                ),
                                onPressed: _showAddCategoryDialog,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 20.h),
                      Text(
                        "Write Note",
                        style: TextStyle(
                          color: scheme.onSurface,
                          fontSize: 13.sp,
                        ),
                      ),
                      SizedBox(height: 10.h),
                      Container(
                        decoration: BoxDecoration(
                          color: scheme.surface,
                          borderRadius: BorderRadius.circular(13.r),
                        ),
                        padding: EdgeInsets.only(left: 12.w),
                        child: TextField(
                          controller: _noteController,
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            hintText: "Enter a note...",
                            hintStyle: TextStyle(
                              color: scheme.onSurface.withOpacity(0.4),
                            ),
                          ),
                          minLines: 1,
                          maxLines: 2,
                          style: TextStyle(
                            color: scheme.onSurface,
                            fontSize: 13.5.sp,
                          ),
                        ),
                      ),
                      SizedBox(height: 20.h),
                      Text(
                        "Set Date",
                        style: TextStyle(
                          color: scheme.onSurface,
                          fontSize: 13.sp,
                        ),
                      ),
                      SizedBox(height: 10.h),
                      GestureDetector(
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: selectedDate,
                            firstDate: DateTime(2015),
                            lastDate: DateTime(2101),
                          );
                          if (picked != null)
                            setState(() => selectedDate = picked);
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: scheme.surface,
                            borderRadius: BorderRadius.circular(13.r),
                          ),
                          padding: EdgeInsets.symmetric(
                            vertical: 13.h,
                            horizontal: 12.w,
                          ),
                          child: Row(
                            children: [
                              Text(
                                "${selectedDate.day.toString().padLeft(2, '0')} ${_monthAbbr(selectedDate.month)}, ${selectedDate.year}",
                                style: TextStyle(
                                  color: scheme.onSurface,
                                  fontSize: 14.sp,
                                ),
                              ),
                              const Spacer(),
                              Icon(
                                Icons.calendar_today_outlined,
                                color: scheme.primary,
                                size: 18.sp,
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: 40.h),
                      SizedBox(
                        width: double.infinity,
                        height: 52.h,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: scheme.primary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24.r),
                            ),
                          ),
                          onPressed: _saveTransaction,
                          child: Text(
                            widget.type == PaymentType.send
                                ? "Send"
                                : "Receive",
                            style: TextStyle(
                              color: scheme.onPrimary,
                              fontWeight: FontWeight.bold,
                              fontSize: 15.5.sp,
                            ),
                          ),
                        ),
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

  String _monthAbbr(int month) {
    const months = [
      "Jan",
      "Feb",
      "Mar",
      "Apr",
      "May",
      "Jun",
      "Jul",
      "Aug",
      "Sep",
      "Oct",
      "Nov",
      "Dec",
    ];
    return months[month - 1];
  }
}
