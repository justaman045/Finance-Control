import 'dart:io';
import 'dart:typed_data';

import 'package:csv/csv.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:money_control/Models/transaction.dart';
import 'package:money_control/Screens/transaction_details.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class ExportService {
  static Future<void> exportTransactionsCSV(List<TransactionModel> list) async {
    final rows = <List<dynamic>>[
      [
        "ID",
        "Date",
        "Recipient",
        "Amount",
        "Tax",
        "Total",
        "Currency",
        "Category",
        "Status",
        "Note"
      ],
      ...list.map((tx) => [
        tx.id,
        tx.date.toIso8601String(),
        tx.recipientName,
        tx.amount,
        tx.tax,
        tx.total,
        tx.currency,
        tx.category ?? '',
        tx.status ?? '',
        tx.note ?? '',
      ]),
    ];

    final csv = const ListToCsvConverter().convert(rows);

    final dir = await getApplicationDocumentsDirectory();
    final file = File("${dir.path}/transactions_export.csv");
    await file.writeAsString(csv);

    await OpenFilex.open(file.path);
  }

  static Future<void> exportAnalyticsPDF({
    required List<TransactionModel> filtered,
    required double totalIncome,
    required double totalExpense,
    required double netBalance,
    required String periodLabel,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (ctx) {
          return [
            pw.Text("Finance Control – Analytics Report",
                style: pw.TextStyle(
                    fontSize: 20, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 8),
            pw.Text("Period: $periodLabel"),
            pw.SizedBox(height: 16),

            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                _summaryBox("Total Income", totalIncome),
                _summaryBox("Total Expense", totalExpense),
                _summaryBox("Net Balance", netBalance),
              ],
            ),

            pw.SizedBox(height: 18),
            pw.Text("Transactions",
                style: pw.TextStyle(
                    fontSize: 14, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 6),

            pw.Table.fromTextArray(
              headers: [
                "Date",
                "Name",
                "Amount",
                "Category",
                "Type",
              ],
              data: filtered.map((tx) {
                final isIncome = tx.recipientId == FirebaseAuth.instance.currentUser?.uid; // optional convenience
                return [
                  tx.date.toIso8601String().split('T').first,
                  tx.recipientName,
                  "₹${tx.amount.toStringAsFixed(2)}",
                  tx.category ?? '',
                  isIncome ? "Income" : "Expense",
                ];
              }).toList(),
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              cellStyle: const pw.TextStyle(fontSize: 10),
            )
          ];
        },
      ),
    );

    final Uint8List bytes = await pdf.save();
    final dir = await getApplicationDocumentsDirectory();
    final file = File("${dir.path}/analytics_report.pdf");
    await file.writeAsBytes(bytes);

    await OpenFilex.open(file.path);
  }

  static pw.Widget _summaryBox(String label, double amount) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      margin: const pw.EdgeInsets.only(bottom: 10),
      decoration: pw.BoxDecoration(
        borderRadius: pw.BorderRadius.circular(6),
        border: pw.Border.all(width: 0.4),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(label, style: const pw.TextStyle(fontSize: 10)),
          pw.SizedBox(height: 4),
          pw.Text("₹${amount.toStringAsFixed(2)}",
              style:
              pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12)),
        ],
      ),
    );
  }
}
