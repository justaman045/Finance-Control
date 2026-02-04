// lib/Screens/add_transaction.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:pattern_formatter/pattern_formatter.dart';
import 'package:money_control/l10n/app_localizations.dart';
import 'package:money_control/Components/colors.dart';
import 'package:money_control/Components/glass_container.dart';
import 'package:money_control/Controllers/currency_controller.dart';
import 'package:money_control/Controllers/transaction_controller.dart';
import 'package:money_control/Models/cateogary.dart';
import 'package:money_control/Screens/add_transaction_from_recipt.dart';
import 'package:money_control/Utils/icon_helper.dart';

enum PaymentType { send, receive }

class PaymentScreen extends StatefulWidget {
  final PaymentType type;
  final String? cateogary;

  const PaymentScreen({super.key, required this.type, this.cateogary});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final TransactionController _transactionController = Get.put(
    TransactionController(),
  );
  final TextEditingController _amount = TextEditingController();
  final TextEditingController _name = TextEditingController();
  final TextEditingController _note = TextEditingController();
  final TextEditingController _newCategory = TextEditingController();

  String? selectedCategory;
  DateTime selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    // Initialize selected category if passed from widget
    if (widget.cateogary != null) {
      selectedCategory = widget.cateogary;
    }
  }

  Future<void> _addCategoryDialog() async {
    _newCategory.clear();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    await showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.8),
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        insetPadding: EdgeInsets.all(20.w),
        child: GlassContainer(
          padding: EdgeInsets.all(24.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppLocalizations.of(context)!.newCategory,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                  color: isDark ? Colors.white : AppColors.lightTextPrimary,
                ),
              ),
              SizedBox(height: 20.h),
              GlassContainer(
                margin: EdgeInsets.zero,
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                borderRadius: BorderRadius.circular(16.r),
                child: TextField(
                  controller: _newCategory,
                  autofocus: true,
                  style: theme.textTheme.bodyLarge,
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    hintText: AppLocalizations.of(context)!.categoryNameHint,
                    hintStyle: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.textTheme.bodyMedium?.color?.withValues(
                        alpha: 0.5,
                      ),
                    ),
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
                      AppLocalizations.of(context)!.cancel,
                      style: TextStyle(
                        color: theme.textTheme.bodyMedium?.color?.withValues(
                          alpha: 0.7,
                        ),
                        fontSize: 16.sp,
                      ),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  GestureDetector(
                    onTap: () async {
                      final success = await _transactionController.addCategory(
                        _newCategory.text.trim(),
                      );
                      if (success) {
                        setState(() {
                          selectedCategory = _newCategory.text.trim();
                        });
                        if (mounted) Navigator.pop(context);
                      }
                    },
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 24.w,
                        vertical: 12.h,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(12.r),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.4),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                      child: Text(
                        AppLocalizations.of(context)!.add,
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

  Future<void> _deleteCategory(CategoryModel category) async {
    final theme = Theme.of(context);
    final confirm = await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: theme.scaffoldBackgroundColor,
        title: Text(
          AppLocalizations.of(context)!.deleteCategoryTitle,
          style: theme.textTheme.titleLarge,
        ),
        content: Text(
          AppLocalizations.of(context)!.deleteCategoryContent(category.name),
          style: theme.textTheme.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: Text(
              AppLocalizations.of(context)!.delete,
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final success = await _transactionController.deleteCategory(category);
    if (success && selectedCategory == category.name) {
      setState(() {
        selectedCategory = null;
        if (_transactionController.categories.isNotEmpty) {
          selectedCategory = _transactionController.categories.first.name;
        }
      });
    }
  }

  Future<void> saveTransaction() async {
    if (selectedCategory == null) {
      Get.snackbar(
        AppLocalizations.of(context)!.error,
        AppLocalizations.of(context)!.selectCategoryError,
      );
      return;
    }

    final amountVal = double.tryParse(_amount.text.trim()) ?? 0;

    final success = await _transactionController.saveTransaction(
      amount: amountVal,
      name: _name.text.trim(),
      note: _note.text.trim(),
      category: selectedCategory!,
      date: selectedDate,
      type: widget.type == PaymentType.send ? 'send' : 'receive',
      currency: CurrencyController.to.currencyCode.value,
    );

    if (success) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.transactionSaved),
            backgroundColor: AppColors.success,
          ),
        );
      }
      Get.back();
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.type == PaymentType.send
        ? AppLocalizations.of(context)!.sendMoney
        : AppLocalizations.of(context)!.receiveMoney;
    final nameLabel = widget.type == PaymentType.send
        ? AppLocalizations.of(context)!.recipient
        : AppLocalizations.of(context)!.sender;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: _buildAppBar(title, theme, isDark),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDark ? AppColors.darkGradient : AppColors.lightGradient,
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
                _fieldLabel(AppLocalizations.of(context)!.amount, theme),
                _amountField(_amount, theme),
                _fieldLabel(nameLabel, theme),
                _inputField(
                  controller: _name,
                  hint: AppLocalizations.of(context)!.enterNameHint,
                  theme: theme,
                ),
                _fieldLabel(
                  AppLocalizations.of(context)!.selectCategory,
                  theme,
                ),
                _categorySelector(theme),
                _fieldLabel(AppLocalizations.of(context)!.note, theme),
                _inputField(
                  controller: _note,
                  hint: AppLocalizations.of(context)!.addNoteHint,
                  maxLines: 2,
                  theme: theme,
                ),
                _fieldLabel(AppLocalizations.of(context)!.date, theme),
                _dateSelector(theme),
                SizedBox(height: 40.h),
                _submitButton(
                  label: widget.type == PaymentType.send
                      ? AppLocalizations.of(context)!.send
                      : AppLocalizations.of(context)!.receive,
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

  AppBar _buildAppBar(String title, ThemeData theme, bool isDark) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      title: Text(
        title,
        style: theme.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.bold,
          color: theme.colorScheme.onSurface,
        ),
      ),
      leading: IconButton(
        icon: Icon(
          Icons.arrow_back_ios_new,
          color: theme.colorScheme.onSurface,
        ),
        onPressed: () => Get.back(),
      ),
      actions: [
        if (widget.type == PaymentType.send)
          IconButton(
            icon: Icon(
              Icons.qr_code_scanner,
              color: theme.colorScheme.onSurface,
            ),
            onPressed: () {
              Get.to(() => const ReceiptScanPage());
            },
          ),
      ],
    );
  }

  Widget _fieldLabel(String text, ThemeData theme) {
    return Padding(
      padding: EdgeInsets.only(top: 20.h, bottom: 10.h),
      child: Text(
        text,
        style: theme.textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _amountField(TextEditingController c, ThemeData theme) {
    return GlassContainer(
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8.r),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.3),
              ),
            ),
            child: Obx(
              () => Text(
                CurrencyController.to.currencyCode.value,
                style: TextStyle(
                  color: AppColors.primary,
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
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [ThousandsFormatter(allowFraction: true)],
              decoration: InputDecoration(
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                hintText: "0.00",
                hintStyle: TextStyle(
                  color: theme.textTheme.bodyMedium?.color?.withValues(
                    alpha: 0.4,
                  ),
                  fontSize: 22.sp,
                ),
              ),
              style: TextStyle(
                fontSize: 22.sp,
                color: theme.textTheme.bodyLarge?.color,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _inputField({
    required TextEditingController controller,
    required String hint,
    required ThemeData theme,
    int maxLines = 1,
  }) {
    return GlassContainer(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 18.h),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        decoration: InputDecoration(
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          hintText: hint,
          hintStyle: TextStyle(
            color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.4),
            fontSize: 18.sp,
            fontWeight: FontWeight.w500,
          ),
          contentPadding: EdgeInsets.zero,
        ),
        style: TextStyle(
          fontSize: 18.sp,
          color: theme.textTheme.bodyLarge?.color,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _categorySelector(ThemeData theme) {
    return Obx(() {
      final categories = _transactionController.categories;

      // Auto-select first category if none selected and categories exist
      if (selectedCategory == null && categories.isNotEmpty) {
        // Defer state update to next frame to avoid build error
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && selectedCategory == null) {
            setState(() => selectedCategory = categories.first.name);
          }
        });
      }

      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            ...categories.map((cat) {
              final isSelected = selectedCategory == cat.name;
              final catColor = cat.color != null
                  ? Color(cat.color!)
                  : AppColors.secondary;
              final borderColor = isSelected
                  ? catColor
                  : theme.dividerColor.withValues(alpha: 0.3);

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
                          ? catColor.withValues(alpha: 0.25)
                          : theme.cardColor.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(24.r),
                      border: Border.all(color: borderColor, width: 1.5),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: catColor.withValues(alpha: 0.3),
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
                            IconHelper.getIconFromCode(cat.iconCode),
                            size: 18.sp,
                            color: isSelected
                                ? catColor
                                : theme.textTheme.bodyMedium?.color,
                          ),
                          SizedBox(width: 8.w),
                        ],
                        Text(
                          cat.name,
                          style: TextStyle(
                            color: isSelected
                                ? theme.textTheme.bodyLarge?.color
                                : theme.textTheme.bodyMedium?.color,
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
                  color: theme.cardColor.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(24.r),
                  border: Border.all(
                    color: theme.dividerColor.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.add,
                      color: theme.textTheme.bodyMedium?.color,
                      size: 20.sp,
                    ),
                    SizedBox(width: 6.w),
                    Text(
                      AppLocalizations.of(context)!.add,
                      style: TextStyle(
                        color: theme.textTheme.bodyMedium?.color,
                        fontSize: 15.sp,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _dateSelector(ThemeData theme) {
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
      child: GlassContainer(
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 18.h),
        child: Row(
          children: [
            Text(
              "${selectedDate.day}/${selectedDate.month}/${selectedDate.year}",
              style: TextStyle(
                fontSize: 18.sp,
                color: theme.textTheme.bodyLarge?.color,
                fontWeight: FontWeight.w500,
              ),
            ),
            const Spacer(),
            Icon(Icons.calendar_today_outlined, color: AppColors.primary),
          ],
        ),
      ),
    );
  }

  Widget _submitButton({required String label, required VoidCallback onTap}) {
    return Obx(
      () => GestureDetector(
        onTap: _transactionController.isSaving.value
            ? null
            : () {
                HapticFeedback.mediumImpact();
                onTap();
              },
        child: Container(
          width: double.infinity,
          height: 54.h,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.primary, AppColors.secondary],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(27.r),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.4),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: _transactionController.isSaving.value
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : Text(
                  label.toUpperCase(),
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16.sp,
                    letterSpacing: 1.5,
                  ),
                ),
        ),
      ),
    );
  }
}
