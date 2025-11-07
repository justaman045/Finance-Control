import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:money_control/Models/transaction.dart';
import 'package:money_control/Components/tx_tile.dart';

class CategoryTransactionsScreen extends StatefulWidget {
  final String categoryName; // Name or id of category to filter
  const CategoryTransactionsScreen({
    super.key,
    required this.categoryName,
  });

  @override
  State<CategoryTransactionsScreen> createState() =>
      _CategoryTransactionsScreenState();
}

class _CategoryTransactionsScreenState extends State<CategoryTransactionsScreen> {
  DateTime get _startOfMonth {
    final now = DateTime.now();
    return DateTime(now.year, now.month, 1);
  }

  DateTime get _endOfMonth {
    final now = DateTime.now();
    return DateTime(now.year, now.month + 1, 1).subtract(const Duration(seconds: 1));
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return Scaffold(
        body: Center(
          child: Text("User not logged in", style: TextStyle(color: scheme.error)),
        ),
      );
    }

    // Firestore requires composite index for multiple where clauses + orderBy.
    // If you see persistent loading, check your console for Firestore error and create index as per URL.

    return Scaffold(
      backgroundColor: scheme.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          "Transactions: ${widget.categoryName}",
          style: TextStyle(
            color: scheme.onBackground,
            fontWeight: FontWeight.bold,
            fontSize: 17.sp,
          ),
        ),
        centerTitle: true,
        leading: BackButton(color: scheme.onBackground),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(user.email)
            .collection('transactions')
            .where('category', isEqualTo: widget.categoryName)
            .where('date', isGreaterThanOrEqualTo: _startOfMonth)
            .where('date', isLessThanOrEqualTo: _endOfMonth)
            .orderBy('date', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;
          if (docs.isEmpty) {
            return Center(
              child: Text(
                "No transactions found in this category.",
                style: TextStyle(
                  color: scheme.onSurface.withOpacity(0.6),
                  fontSize: 14.sp,
                ),
                textAlign: TextAlign.center,
              ),
            );
          }

          final txs = docs
              .map((doc) => TransactionModel.fromMap(
            doc.id,
            doc.data() as Map<String, dynamic>,
          ))
              .toList();

          return ListView.separated(
            padding: EdgeInsets.all(12.w),
            itemCount: txs.length,
            separatorBuilder: (_, __) =>
                Divider(color: scheme.onSurface.withOpacity(0.1), height: 1),
            itemBuilder: (context, index) {
              final tx = txs[index];
              final received = tx.recipientId == user.uid;
              return TxTile(
                tx: tx,
                received: received,
                textColor: scheme.onSurface,
                receivedColor: const Color(0xFF0FA958),
                sentColor: scheme.error,
              );
            },
          );
        },
      ),
    );
  }
}
