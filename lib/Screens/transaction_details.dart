// lib/Screens/transaction_details.dart

import 'dart:io';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:money_control/Models/transaction.dart';
import 'package:money_control/Screens/edit_transaction.dart';
import 'package:money_control/Services/offline_queue.dart';        // <── ADDED
import 'package:money_control/Services/local_backup_service.dart';  // <── ADDED
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import 'package:screenshot/screenshot.dart';

// ----------------------------------------------------------------------

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

// ----------------------------------------------------------------------

class _TransactionResultScreenState extends State<TransactionResultScreen> {
  final ScreenshotController _ssController = ScreenshotController();

  // ----------------------------------------------------------------------
  // DELETE TRANSACTION (OFFLINE SAFE)
  // ----------------------------------------------------------------------
  Future<void> _deleteTransaction() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Delete Transaction"),
        content: const Text("Are you sure you want to delete this transaction?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Delete"),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final txId = widget.transaction.id;

    try {
      // Try Firestore delete
      await FirebaseFirestore.instance
          .collection("users")
          .doc(user.email)
          .collection("transactions")
          .doc(txId)
          .delete()
      .timeout(const Duration(seconds: 5));

      LocalBackupService.backupUserTransactions(user.email!);

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      // Device offline → SAVE DELETE TO QUEUE
      final deleteJson = {
        "operation": "delete",
        "transactionId": txId,
        "user": user.email,
      };

      await OfflineQueueService.savePending(deleteJson);

      Get.snackbar(
        "Offline",
        "Delete queued and will sync when online",
        snackPosition: SnackPosition.BOTTOM,
        colorText: Colors.white,
      );

      if (mounted) {
        Navigator.pop(context);
      }
    }
  }

  // ----------------------------------------------------------------------
  // SHARE SCREENSHOT
  // ----------------------------------------------------------------------
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

  // ----------------------------------------------------------------------
  // PDF FILE GENERATION
  // ----------------------------------------------------------------------
  Future<void> _savePDF() async {
    final tx = widget.transaction;
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        margin: const pw.EdgeInsets.all(24),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text("Transaction Receipt",
                  style: pw.TextStyle(
                      fontSize: 22, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 8),
              pw.Divider(),
              pw.SizedBox(height: 12),
              _pdfRow("Transaction ID", tx.id),
              _pdfRow("Date", tx.date.toLocal().toString()),
              _pdfRow("Recipient", tx.recipientName),
              _pdfRow("Amount", "₹${tx.amount.toStringAsFixed(2)}"),
              _pdfRow("Tax", tx.tax.toStringAsFixed(2)),
              _pdfRow("Total", tx.total.toStringAsFixed(2)),
              _pdfRow("Currency", tx.currency),
              _pdfRow("Category", tx.category ?? "-"),
              if (tx.note != null && tx.note!.isNotEmpty)
                _pdfRow("Note", tx.note!),
              _pdfRow("Status", tx.status ?? "-"),
              pw.SizedBox(height: 24),
              pw.Text("Generated using Money Control App",
                  style:
                  pw.TextStyle(fontSize: 11, color: PdfColors.grey600)),
            ],
          );
        },
      ),
    );

    final directory = await getApplicationDocumentsDirectory();
    final file = File("${directory.path}/Transaction_${tx.id}.pdf");
    await file.writeAsBytes(await pdf.save());

    await Share.shareXFiles([
      XFile(file.path, mimeType: "application/pdf")
    ]);
  }

  pw.Widget _pdfRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 8),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label,
              style:
              pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 13)),
          pw.Text(value, style: const pw.TextStyle(fontSize: 13)),
        ],
      ),
    );
  }

  // ----------------------------------------------------------------------
  // BUILD UI
  // ----------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tx = widget.transaction;

    return Scaffold(
      backgroundColor:
      scheme.brightness == Brightness.light ? const Color(0xFFF5F7FB) : scheme.background,
      appBar: AppBar(
        title: const Text("Transaction Details"),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () async {
              // Navigate to Edit
              await Get.to(() => TransactionEditScreen(transaction: tx));
              if (mounted) setState(() {});
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: _deleteTransaction,
          ),
        ],
      ),

      body: Screenshot(
        controller: _ssController,
        child: _buildBody(context, tx, scheme),
      ),
    );
  }

  Widget _buildBody(BuildContext context, TransactionModel tx, ColorScheme scheme) {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: 22.w, vertical: 8.h),
      child: Column(
        children: [
          SizedBox(height: 18.h),
          _statusIcon(),
          SizedBox(height: 16.h),
          _titleText(),
          SizedBox(height: 6.h),
          _subtitleText(),
          SizedBox(height: 22.h),

          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _capsuleButton(
                icon: Icons.share_outlined,
                label: "Share",
                onTap: _shareScreenshot,
                scheme: scheme,
              ),
              SizedBox(width: 12.w),
              _capsuleButton(
                icon: Icons.picture_as_pdf,
                label: "Save PDF",
                onTap: _savePDF,
                scheme: scheme,
              ),
            ],
          ),

          SizedBox(height: 25.h),
          _detailsCard(tx, scheme),

          SizedBox(height: 25.h),
          SizedBox(
            width: double.infinity,
            height: 54.h,
            child: ElevatedButton(
              onPressed: () => Get.back(),
              style: ElevatedButton.styleFrom(
                backgroundColor: scheme.primary,
                shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(28.r)),
              ),
              child: Text("Back",
                  style: TextStyle(
                      color: scheme.onPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 16.sp)),
            ),
          ),
        ],
      ),
    );
  }

  // --------------------------- Icon + Title ---------------------------

  Widget _statusIcon() {
    final t = widget.type;

    final icon =
    t == TransactionResultType.success ? Icons.check_circle_rounded :
    t == TransactionResultType.failed  ? Icons.cancel_rounded :
    Icons.hourglass_empty_rounded;

    final colors =
    t == TransactionResultType.success ? [Colors.green.shade600, Colors.green.shade400] :
    t == TransactionResultType.failed  ? [Colors.red.shade600, Colors.red.shade400] :
    [Colors.orange.shade600, Colors.orange.shade400];

    return Container(
      width: 90.r,
      height: 90.r,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(colors: colors),
        boxShadow: [
          BoxShadow(
            blurRadius: 16,
            offset: const Offset(0, 4),
            color: colors.last.withOpacity(0.3),
          ),
        ],
      ),
      child: Icon(icon, size: 46.sp, color: Colors.white),
    );
  }

  Widget _titleText() {
    final t = widget.type;
    return Text(
      t == TransactionResultType.success
          ? "Transaction Success!"
          : t == TransactionResultType.failed
          ? "Transaction Failed!"
          : "Processing Transaction",
      style: TextStyle(
        fontSize: 18.sp,
        fontWeight: FontWeight.w700,
      ),
    );
  }

  Widget _subtitleText() {
    final t = widget.type;
    return Text(
      t == TransactionResultType.success
          ? "Your payment has been confirmed."
          : t == TransactionResultType.failed
          ? "Payment could not be completed."
          : "Your payment is being processed.",
      textAlign: TextAlign.center,
      style: TextStyle(fontSize: 14.sp, color: Colors.grey),
    );
  }

  // --------------------------- UI Components ---------------------------

  Widget _capsuleButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required ColorScheme scheme,
  }) {
    return Container(
      height: 40.h,
      width: 125.w,
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(24.r),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 6),
        ],
      ),
      child: TextButton.icon(
        onPressed: onTap,
        icon: Icon(icon, color: scheme.primary, size: 18.sp),
        label: Text(label,
            style: TextStyle(color: scheme.onSurface, fontWeight: FontWeight.w600)),
      ),
    );
  }

  Widget _detailsCard(TransactionModel tx, ColorScheme scheme) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 20.h),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(18.r),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.07),
              blurRadius: 12,
              offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Transaction Details",
              style: TextStyle(
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w700,
                  color: scheme.onSurface)),
          SizedBox(height: 12.h),
          Divider(),
          SizedBox(height: 12.h),
          _detailRow("Transaction ID", tx.id),
          _detailRow("Date", tx.date.toLocal().toString()),
          _detailRow("Recipient", tx.recipientName),
          _detailRow("Amount", tx.amount.toStringAsFixed(2)),
          _detailRow("Tax", tx.tax.toStringAsFixed(2)),
          _detailRow("Total", tx.total.toStringAsFixed(2), bold: true),
          _detailRow("Currency", tx.currency),
          _detailRow("Category", tx.category ?? "-"),
          if (tx.note != null && tx.note!.isNotEmpty)
            _detailRow("Note", tx.note!),
          _detailRow("Status", tx.status ?? "-"),
        ],
      ),
    );
  }

  Widget _detailRow(String name, String value, {bool bold = false}) {
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 6.h),
      child: Row(
        children: [
          Expanded(
            child: Text(name,
                style: TextStyle(
                    color: scheme.onSurface.withOpacity(0.75), fontSize: 13.sp)),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: bold ? 14.sp : 13.sp,
                fontWeight: bold ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
