import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:money_control/Models/transaction.dart';
import 'package:money_control/Components/tx_tile.dart';

class RecentPaymentList extends StatelessWidget {
  final Color? cardColor;
  final Color? textColor;
  final Color? receivedColor;
  final Color? sentColor;

  const RecentPaymentList({
    super.key,
    this.cardColor,
    this.textColor,
    this.receivedColor,
    this.sentColor,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return Center(
        child: Text("Not logged in", style: TextStyle(color: scheme.error)),
      );
    }

    // Fetch all transactions involving this user (sent or received)
    final txStream = FirebaseFirestore.instance
        .collection('users').doc(FirebaseAuth.instance.currentUser?.email).collection('transactions')
        .orderBy('date', descending: true)
        //transaction for today's date only starting from midnight 12 AM
        // .where('createdAt', isGreaterThanOrEqualTo: DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day, 0, 0, 0))
        .snapshots();

    return StreamBuilder<QuerySnapshot>(
      stream: txStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _loadingList(scheme, cardColor);
        }
        if (snapshot.hasError) {
          return Center(
            child: Text(
              "Failed to load transactions",
              style: TextStyle(color: scheme.error),
            ),
          );
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Text(
              "You haven't made any Transaction today",
              style: TextStyle(
                color: scheme.onSurface.withOpacity(0.6),
                fontSize: 13.sp,
              ),
            ),
          );
        }

        // Map Firestore docs to TransactionModel instances for this user only, descending order
        final txs = snapshot.data!.docs
            .map((doc) => TransactionModel.fromMap(
          doc.id,
          doc.data() as Map<String, dynamic>,
        ))
            .where(
              (txn) => txn.senderId == user.uid || txn.recipientId == user.uid,
        )
            .toList();

        if (txs.isEmpty) {
          return Center(
            child: Text(
              "You have no transactions yet.",
              style: TextStyle(
                color: scheme.onSurface.withOpacity(0.6),
                fontSize: 13.sp,
              ),
            ),
          );
        }

        // Limit to N recent, or display all as needed (here: 8)
        final recentTxs = txs.take(8).toList();

        return Container(
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
          decoration: BoxDecoration(
            color: cardColor ?? scheme.surface,
            borderRadius: BorderRadius.circular(18.r),
          ),
          child: Column(
            children: recentTxs.map((tx) {
              final bool received = tx.recipientId == user.uid;
              return TxTile(
                tx: tx,
                received: received,
                textColor: textColor,
                receivedColor: receivedColor,
                sentColor: sentColor,
              );
            }).toList(),
          ),
        );
      },
    );
  }

  Widget _loadingList(ColorScheme scheme, Color? cardColor) => Container(
    padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
    decoration: BoxDecoration(
      color: cardColor ?? scheme.surface,
      borderRadius: BorderRadius.circular(18.r),
    ),
    child: Column(
      children: List.generate(
        3,
            (i) => Padding(
          padding: EdgeInsets.only(bottom: 10.h),
          child: Container(
            height: 52.h,
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12.r),
            ),
          ),
        ),
      ),
    ),
  );
}
