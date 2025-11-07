import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:money_control/Components/colors.dart';
import 'package:money_control/Models/transaction.dart';
import 'package:money_control/Screens/edit_transaction.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';
import 'package:printing/printing.dart';

enum TransactionResultType { success, failed, inProgress }

class TransactionResultScreen extends StatefulWidget {
  final TransactionResultType type;
  final TransactionModel transaction;
  final VoidCallback? onAction;

  const TransactionResultScreen({
    super.key,
    required this.type,
    required this.transaction,
    this.onAction,
  });

  @override
  State<TransactionResultScreen> createState() =>
      _TransactionResultScreenState();
}

class _TransactionResultScreenState extends State<TransactionResultScreen> {
  final ScreenshotController _ssController = ScreenshotController();

  Future<void> _shareScreenshot() async {
    try {
      final Uint8List? image = await _ssController.capture();
      if (image != null) {
        await Share.shareXFiles([
          XFile.fromData(image, mimeType: 'image/png', name: 'transaction.png'),
        ]);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to share screenshot: $e')));
      }
    }
  }

  Future<void> _printScreenshot() async {
    try {
      final Uint8List? image = await _ssController.capture();
      if (image != null) {
        await Printing.layoutPdf(onLayout: (_) => Future.value(image));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to print: $e')));
      }
    }
  }

  Future<void> _deleteTransaction() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete Transaction'),
        content: Text('Are you sure you want to delete this transaction?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(FirebaseAuth.instance.currentUser?.email)
          .collection('transactions')
          .doc(widget.transaction.id)
          .delete();
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Transaction deleted')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isLight = scheme.brightness == Brightness.light;

    final type = widget.type;
    final transaction = widget.transaction;

    final isSuccess = type == TransactionResultType.success;
    final isFailed = type == TransactionResultType.failed;
    final isProgress = type == TransactionResultType.inProgress;

    final title = isSuccess
        ? "Transaction Success!"
        : isFailed
        ? "Transaction Failed!"
        : "Transaction is Processing...";

    final subtitle = isSuccess
        ? "Your payment is confirmed. Email confirmation sent."
        : isFailed
        ? "Your payment couldn’t be completed. Please try again later."
        : "Your payment is being processed. Please wait for confirmation email.";

    final gradColors = isFailed
        ? [Colors.red.shade200, Colors.red.shade400]
        : isProgress
        ? [Colors.orange.shade200, Colors.orange.shade400]
        : [const Color(0xFFF36C1D), const Color(0xFFFC48AD)];

    // Main page background: smoothly blend with scaffold in both modes
    final List<Color> bgGrad = isFailed
        ? [Colors.red.shade50.withOpacity(isLight ? 0.85 : 0.20), Colors.red.shade100.withOpacity(isLight ? 0.92 : 0.18)]
        : isProgress
        ? [Colors.orange.shade50.withOpacity(isLight ? 0.85 : 0.19), Colors.orange.shade100.withOpacity(isLight ? 0.92 : 0.172)]
        : [
      (isLight ? kLightGradientTop : kDarkGradientTop).withOpacity(isLight ? 0.3 : 0.5),
      (isLight ? kLightGradientBottom : kDarkGradientBottom).withOpacity(isLight ? 0.5 : 0.59),
    ];

    final icon = isSuccess
        ? Icons.check_circle_rounded
        : isFailed
        ? Icons.cancel_rounded
        : Icons.hourglass_empty_rounded;

    final iconColor = Colors.white;
    final actionLabel = isSuccess
        ? "Back"
        : isFailed
        ? "Try Again"
        : "Back Home";

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text("Transaction Details"),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => Get.to(
                    () => TransactionEditScreen(transaction: transaction),
                curve: Curves.easeOut,
                transition: Transition.cupertino,
                duration: const Duration(milliseconds: 250)),
            tooltip: "Edit Transaction",
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: _deleteTransaction,
            tooltip: "Delete Transaction",
          ),
        ],
      ),
      body: Screenshot(
        controller: _ssController,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: bgGrad,
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          width: double.infinity,
          child: SafeArea(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(height: 28.h),
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(height: 74.h),
                      if (isSuccess) ...[
                        Positioned(top: 7.h, left: 32.w, child: Icon(Icons.star, color: Colors.orangeAccent.shade100, size: 19.sp)),
                        Positioned(top: 0.h, right: 30.w, child: Icon(Icons.star, color: Colors.pinkAccent.shade100, size: 16.5.sp)),
                        Positioned(bottom: 8.h, left: 24.w, child: Icon(Icons.star, color: Colors.pinkAccent.shade100, size: 13.sp)),
                      ],
                      Container(
                        width: 66.r,
                        height: 66.r,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: gradColors,
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: gradColors.last.withOpacity(0.18),
                              blurRadius: 19,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: Center(
                          child: Icon(icon, color: iconColor, size: 46.sp),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 18.h),
                  Text(
                    title,
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18.sp, color: scheme.onBackground),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 7.h),
                  Text(
                    subtitle,
                    style: TextStyle(color: scheme.onBackground.withOpacity(0.7), fontSize: 13.5.sp),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 23.h),
                  if (isSuccess || isFailed)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _SuccessActionBtn(
                          icon: Icons.share_outlined,
                          label: "Share",
                          color: scheme.surface,
                          textColor: scheme.onSurface,
                          border: true,
                          onPressed: _shareScreenshot,
                        ),
                        SizedBox(width: 15.w),
                        _SuccessActionBtn(
                          icon: isSuccess ? Icons.print : Icons.error_outline_rounded,
                          label: isSuccess ? "Print" : "Report",
                          color: scheme.surface,
                          textColor: scheme.onSurface,
                          border: true,
                          onPressed: isSuccess ? _printScreenshot : null,
                        ),
                      ],
                    ),
                  if (isProgress) SizedBox(height: 5.h),
                  SizedBox(height: 23.h),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "Transaction Details",
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5.sp, color: scheme.onBackground),
                    ),
                  ),
                  SizedBox(height: 13.h),
                  _DetailRow(label: "Transaction Number", value: transaction.id),
                  _DetailRow(label: "Transaction Date", value: transaction.date.toLocal().toString()),
                  _DetailRow(label: "Recipient", value: transaction.recipientName),
                  _DetailRow(label: "Nominal", value: transaction.amount.toStringAsFixed(2)),
                  _DetailRow(label: "Tax", value: transaction.tax.toStringAsFixed(2)),
                  _DetailRow(label: "Total Payment", value: transaction.total.toStringAsFixed(2), bold: true),
                  _DetailRow(label: "Currency", value: transaction.currency),
                  _DetailRow(label: "Category", value: transaction.category ?? '-'),
                  if (transaction.note != null && transaction.note!.isNotEmpty)
                    SizedBox(height: 10.h, child: _DetailRow(label: "Note", value: transaction.note!)),
                  if (transaction.status != null)
                    _DetailRow(label: "Status", value: transaction.status!),
                  const Spacer(),
                  SizedBox(
                    width: double.infinity,
                    height: 52.h,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.zero,
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(34.r),
                        ),
                      ),
                      onPressed: widget.onAction ?? () => Get.back(),
                      child: Ink(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: bgGrad,
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                          borderRadius: BorderRadius.circular(34.r),
                        ),
                        child: Center(
                          child: Text(
                            actionLabel,
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 17.sp),
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 14.h),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SuccessActionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final Color textColor;
  final bool border;
  final VoidCallback? onPressed;

  const _SuccessActionBtn({
    required this.icon,
    required this.label,
    required this.color,
    required this.textColor,
    required this.border,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 120.w,
      height: 39.h,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: color,
          side: border ? BorderSide(color: textColor.withOpacity(0.09), width: 1.3) : BorderSide.none,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24.r),
          ),
          elevation: 0,
          foregroundColor: textColor,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 19.sp, color: textColor.withOpacity(0.84)),
            SizedBox(width: 7.w),
            Text(
              label,
              style: TextStyle(color: textColor, fontWeight: FontWeight.w600, fontSize: 15.sp),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final bool bold;

  const _DetailRow({
    required this.label,
    required this.value,
    this.bold = false,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            flex: 50,
            child: Text(
              label,
              style: TextStyle(color: scheme.onSurface.withOpacity(0.9), fontSize: 13.sp),
            ),
          ),
          Expanded(
            flex: 49,
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                color: scheme.onSurface,
                fontWeight: bold ? FontWeight.bold : FontWeight.normal,
                fontSize: bold ? 14.sp : 13.sp,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
