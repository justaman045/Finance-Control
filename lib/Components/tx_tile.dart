import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:money_control/Components/cateogary_initial_icon.dart';
import 'package:money_control/Components/methods.dart';
import 'package:money_control/Models/transaction.dart';
import 'package:money_control/Screens/transaction_details.dart';

class TxTile extends StatelessWidget {
  final TransactionModel tx;
  final bool received; // tx.recipientId == currentUser.uid
  final Color? textColor;
  final Color? receivedColor;
  final Color? sentColor;

  const TxTile({
    Key? key,
    required this.tx,
    required this.received,
    this.textColor,
    this.receivedColor,
    this.sentColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final Color amtColor = received
        ? (receivedColor ?? const Color(0xFF0FA958))
        : (sentColor ?? scheme.error);

    return GestureDetector(
      onTap: () {
        debugPrint(_getTxnType(tx.status).toString());
        gotoPage(
          TransactionResultScreen(
            type: _getTxnType(tx.status),
            transaction: tx,
          ),
        );
      },
      child: Padding(
        padding: EdgeInsets.only(bottom: 14.h),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(18.r),
              child: CategoryInitialsIcon(categoryName: tx.recipientName, size: 40.r,),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          tx.recipientName, // or senderName for received
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14.sp,
                            color: textColor ?? scheme.onSurface,
                          ),
                        ),
                      ),
                      Text(
                        _formatDate(tx.date),
                        style: TextStyle(
                          color: scheme.onSurface.withOpacity(0.6),
                          fontSize: 11.sp,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 4.h),
                  Row(
                    children: [
                      Text(
                        (received ? "+" : "-") + tx.amount.toStringAsFixed(2),
                        style: TextStyle(
                          color: amtColor,
                          fontWeight: FontWeight.w700,
                          fontSize: 13.sp,
                        ),
                      ),
                      SizedBox(width: 6.w),
                      Text(
                        received ? "Received" : "Sent",
                        style: TextStyle(
                          color: textColor ?? scheme.onSurface.withOpacity(0.7),
                          fontSize: 12.sp,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return "${date.day.toString().padLeft(2, '0')} ${_monthAbbr(date.month)}, ${date.year}";
  }

  String _monthAbbr(int month) {
    const months = [
      "Jan", "Feb", "Mar", "Apr", "May", "Jun",
      "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"
    ];
    return months[month - 1];
  }

  TransactionResultType _getTxnType(String? status) {
    if (status == null || status == 'success') {
      return TransactionResultType.success;
    } else if (status == 'failed') {
      return TransactionResultType.failed;
    } else {
      return TransactionResultType.inProgress;
    }
  }
}
