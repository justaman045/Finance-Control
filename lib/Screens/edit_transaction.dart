import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:money_control/Models/transaction.dart';

class TransactionEditScreen extends StatefulWidget {
  final TransactionModel transaction;

  const TransactionEditScreen({super.key, required this.transaction});

  @override
  State<TransactionEditScreen> createState() => _TransactionEditScreenState();
}

class _TransactionEditScreenState extends State<TransactionEditScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _recipientNameController;
  late TextEditingController _amountController;
  late TextEditingController _taxController;
  late TextEditingController _noteController;

  List<String> _categories = [];
  String? _selectedCategory;
  bool _loadingCategories = true;

  @override
  void initState() {
    super.initState();
    _recipientNameController = TextEditingController(text: widget.transaction.recipientName);
    _amountController = TextEditingController(text: widget.transaction.amount.toString());
    _taxController = TextEditingController(text: widget.transaction.tax.toString());
    _noteController = TextEditingController(text: widget.transaction.note ?? '');
    _loadCategories();
  }

  @override
  void dispose() {
    _recipientNameController.dispose();
    _amountController.dispose();
    _taxController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    setState(() {
      _loadingCategories = true;
    });
    try {
      final userEmail = FirebaseAuth.instance.currentUser?.email;
      if (userEmail == null) return;

      final catSnap = await FirebaseFirestore.instance
          .collection('users')
          .doc(userEmail)
          .collection('categories')
          .get();

      final fetchedCategories = <String>{}; // Use Set to avoid duplicates
      for (var doc in catSnap.docs) {
        final name = doc.data()['name'] ?? '';
        if (name.isNotEmpty) {
          fetchedCategories.add(name);
        }
      }

      setState(() {
        _categories = fetchedCategories.toList();
        _selectedCategory = _categories.contains(widget.transaction.category) ? widget.transaction.category : null;
        _loadingCategories = false;
      });
    } catch (e) {
      setState(() {
        _categories = [];
        _loadingCategories = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load categories: $e')));
    }
  }

  Future<void> _addNewCategoryDialog() async {
    final newCategoryController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Category'),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: newCategoryController,
            decoration: const InputDecoration(
              labelText: 'Category Name',
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Category name cannot be empty';
              }
              if (_categories.contains(value.trim())) {
                return 'Category already exists';
              }
              return null;
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(context, newCategoryController.text.trim());
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      try {
        final userEmail = FirebaseAuth.instance.currentUser?.email;
        if (userEmail == null) return;
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userEmail)
            .collection('categories')
            .add({'name': result});
        await _loadCategories();
        setState(() {
          _selectedCategory = result;
        });
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to add category: $e')));
      }
    }
  }

  Future<void> _saveTransaction() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedCategory == null || _selectedCategory!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select or add a category')));
      return;
    }

    final updatedTransaction = TransactionModel(
      id: widget.transaction.id,
      senderId: widget.transaction.senderId,
      recipientId: widget.transaction.recipientId,
      recipientName: _recipientNameController.text.trim(),
      amount: double.tryParse(_amountController.text.trim()) ?? 0.0,
      currency: widget.transaction.currency,
      tax: double.tryParse(_taxController.text.trim()) ?? 0.0,
      note: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
      category: _selectedCategory,
      date: widget.transaction.date,
      attachmentUrl: widget.transaction.attachmentUrl,
      status: widget.transaction.status,
      createdAt: widget.transaction.createdAt,
    );

    try {
      final userEmail = FirebaseAuth.instance.currentUser?.email;
      if (userEmail == null) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('User not logged in')));
        return;
      }

      await FirebaseFirestore.instance
          .collection('users')
          .doc(userEmail)
          .collection('transactions')
          .doc(updatedTransaction.id)
          .set(updatedTransaction.toMap());

      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Transaction updated successfully')));
        Navigator.of(context).pop(true); // Indicate success
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Failed to save transaction: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Transaction'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: scheme.onBackground),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(24.w),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: _recipientNameController,
                  decoration: const InputDecoration(
                    labelText: 'Recipient Name',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) =>
                  (value == null || value.trim().isEmpty)
                      ? 'Recipient name required'
                      : null,
                ),
                SizedBox(height: 16.h),
                TextFormField(
                  controller: _amountController,
                  keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Amount',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Amount is required';
                    }
                    final amt = double.tryParse(value);
                    if (amt == null || amt <= 0) {
                      return 'Enter a valid amount greater than zero';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 16.h),
                TextFormField(
                  controller: _taxController,
                  keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Tax',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value != null && value.trim().isNotEmpty) {
                      final taxVal = double.tryParse(value);
                      if (taxVal == null || taxVal < 0) {
                        return 'Enter a valid tax amount';
                      }
                    }
                    return null;
                  },
                ),
                SizedBox(height: 16.h),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      flex: 4,
                      child: _loadingCategories
                          ? const Center(child: CircularProgressIndicator())
                          : DropdownButtonFormField<String>(
                        decoration: const InputDecoration(
                          labelText: 'Category',
                          border: OutlineInputBorder(),
                        ),
                        value: _selectedCategory,
                        items: _categories
                            .map((category) => DropdownMenuItem<String>(
                          value: category,
                          child: Text(category),
                        ))
                            .toList(),
                        onChanged: (val) {
                          setState(() {
                            _selectedCategory = val;
                          });
                        },
                        validator: (val) =>
                        (val == null || val.isEmpty)
                            ? 'Please select a category'
                            : null,
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      flex: 1,
                      child: ElevatedButton.icon(
                        onPressed: _addNewCategoryDialog,
                        icon: const Icon(Icons.add),
                        label: const Text('Add'),
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 20.h),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16.h),
                TextFormField(
                  controller: _noteController,
                  maxLines: null,
                  decoration: const InputDecoration(
                    labelText: 'Note',
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 32.h),
                SizedBox(
                  width: double.infinity,
                  height: 52.h,
                  child: ElevatedButton(
                    onPressed: _saveTransaction,
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(34.r),
                      ),
                    ),
                    child: Text(
                      'Save',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18.sp,
                      ),
                    ),
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
