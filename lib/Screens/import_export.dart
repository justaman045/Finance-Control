import 'dart:io';
import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:path_provider/path_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ExportImportPage extends StatefulWidget {
  const ExportImportPage({super.key});

  @override
  State<ExportImportPage> createState() => _ExportImportPageState();
}

class _ExportImportPageState extends State<ExportImportPage> {
  bool loadingExport = false;
  bool loadingImport = false;
  String? message;

  Future<void> _exportCSV() async {
    setState(() {
      loadingExport = true;
      message = null;
    });

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() {
        loadingExport = false;
        message = "User not logged in";
      });
      return;
    }

    try {
      // Fetch transactions
      final txSnap = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.email)
          .collection('transactions')
          .get();

      // Fetch budgets
      final budgetSnap = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.email)
          .collection('budgets')
          .get();

      // Prepare transaction CSV data
      List<List<dynamic>> txCsvData = [
        ['id', 'senderId', 'recipientId', 'recipientName', 'amount', 'currency', 'tax', 'note', 'category', 'date', 'attachmentUrl', 'status']
      ];

      for (var doc in txSnap.docs) {
        final tx = doc.data();
        txCsvData.add([
          doc.id,
          tx['senderId'],
          tx['recipientId'],
          tx['recipientName'],
          tx['amount'],
          tx['currency'],
          tx['tax'],
          tx['note'],
          tx['category'],
          tx['date'] is Timestamp ? (tx['date'] as Timestamp).toDate().toIso8601String() : tx['date'].toString(),
          tx['attachmentUrl'],
          tx['status'],
        ]);
      }

      String txCsv = const ListToCsvConverter().convert(txCsvData);

      // Prepare budget CSV data
      List<List<dynamic>> budgetCsvData = [
        ['categoryId', 'amount']
      ];
      for (var doc in budgetSnap.docs) {
        final data = doc.data();
        budgetCsvData.add([doc.id, data['amount']]);
      }
      String budgetCsv = const ListToCsvConverter().convert(budgetCsvData);

      // Save files to device
      final directory = await getApplicationDocumentsDirectory();

      final txFile = File('${directory.path}/transactions_export.csv');
      await txFile.writeAsString(txCsv);

      final budgetFile = File('${directory.path}/budgets_export.csv');
      await budgetFile.writeAsString(budgetCsv);

      setState(() {
        loadingExport = false;
        message = "Export done. Saved to app documents folder.";
      });
    } catch (e) {
      setState(() {
        loadingExport = false;
        message = "Export failed: $e";
      });
    }
  }

  Future<void> _importCSV() async {
    setState(() {
      loadingImport = true;
      message = null;
    });

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() {
        loadingImport = false;
        message = "User not logged in";
      });
      return;
    }

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
      );
      if (result == null || result.files.isEmpty) {
        setState(() {
          loadingImport = false;
          message = "No file selected";
        });
        return;
      }

      final file = File(result.files.single.path!);
      final content = await file.readAsString();

      List<List<dynamic>> rows = const CsvToListConverter().convert(content);

      // Check header for transactions or budgets and parse accordingly
      if (rows.isNotEmpty && rows[0].contains('senderId')) {
        // Transactions file
        for (int i = 1; i < rows.length; i++) {
          var row = rows[i];
          String id = row[0].toString();
          String senderId = row[1].toString();
          String recipientId = row[2].toString();
          String recipientName = row[3].toString();
          double amount = double.tryParse(row[4].toString()) ?? 0;
          String currency = row[5].toString();
          double tax = double.tryParse(row[6].toString()) ?? 0;
          String? note = row[7].toString();
          String? category = row[8].toString();
          DateTime date = DateTime.tryParse(row[9].toString()) ?? DateTime.now();
          String? attachmentUrl = row[10].toString();
          String status = row.length > 11 ? row[11].toString() : 'success';

          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.email)
              .collection('transactions')
              .doc(id)
              .set({
            'senderId': senderId,
            'recipientId': recipientId,
            'recipientName': recipientName,
            'amount': amount,
            'currency': currency,
            'tax': tax,
            'note': note,
            'category': category,
            'date': Timestamp.fromDate(date),
            'attachmentUrl': attachmentUrl,
            'status': status,
            'createdAt': FieldValue.serverTimestamp(),
          });
        }
      } else if (rows.isNotEmpty && rows[0].contains('categoryId')) {
        // Budgets file
        for (int i = 1; i < rows.length; i++) {
          var row = rows[i];
          String categoryId = row[0].toString();
          double amount = double.tryParse(row[1].toString()) ?? 0;
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.email)
              .collection('budgets')
              .doc(categoryId)
              .set({'amount': amount});
        }
      }

      setState(() {
        loadingImport = false;
        message = "Import completed successfully.";
      });
    } catch (e) {
      setState(() {
        loadingImport = false;
        message = "Import failed: $e";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text(
          "Export / Import Data",
          style: TextStyle(color: scheme.onBackground, fontWeight: FontWeight.bold, fontSize: 18.sp),
        ),
      ),
      backgroundColor: scheme.background,
      body: Padding(
        padding: EdgeInsets.all(20.w),
        child: Column(
          children: [
            ElevatedButton.icon(
              onPressed: loadingExport ? null : _exportCSV,
              icon: loadingExport ? CircularProgressIndicator(color: Colors.white) : Icon(Icons.file_upload),
              label: Text("Export Transactions and Budgets"),
            ),
            SizedBox(height: 16.h),
            ElevatedButton.icon(
              onPressed: loadingImport ? null : _importCSV,
              icon: loadingImport ? CircularProgressIndicator(color: Colors.white) : Icon(Icons.file_download),
              label: Text("Import Transactions or Budgets (CSV)"),
            ),
            SizedBox(height: 20.h),
            if (message != null) Text(
              message!,
              style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 14.sp),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
