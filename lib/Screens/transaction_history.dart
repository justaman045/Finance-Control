import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:money_control/Models/transaction.dart';
import 'package:money_control/Components/methods.dart';
import 'package:money_control/Screens/transaction_details.dart';

class TransactionHistoryScreen extends StatefulWidget {
  const TransactionHistoryScreen({super.key});

  @override
  State<TransactionHistoryScreen> createState() =>
      _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState extends State<TransactionHistoryScreen> {
  int selectedTab = 0;
  final List<String> tabs = ["All", "Income", "Outcome"];

  String formatDateLabel(DateTime date) {
    final now = DateTime.now();

    final today = DateTime(now.year, now.month, now.day);
    final txDay = DateTime(date.year, date.month, date.day);

    final diff = today.difference(txDay).inDays;

    if (diff == 0) return "Today";
    if (diff == 1) return "Yesterday";

    return "${date.day} ${_monthAbbr(date.month)}";
  }


  String _monthAbbr(int month) {
    const months = [
      "Jan", "Feb", "Mar", "Apr", "May", "Jun",
      "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"
    ];
    return months[month - 1];
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isLight = scheme.brightness == Brightness.light;
    final colorIncome = const Color(0xFF0FA958);
    final colorOutcome = scheme.error;
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return Scaffold(
        body: Center(
          child: Text("Not logged in", style: TextStyle(color: scheme.error)),
        ),
      );
    }

    return Scaffold(
      backgroundColor: scheme.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          "Transaction History",
          style: TextStyle(
            color: scheme.onBackground,
            fontWeight: FontWeight.bold,
            fontSize: 17.sp,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: scheme.onBackground, size: 19.sp),
          onPressed: () => goBack(),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(user.email)
            .collection('transactions')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final docs = snapshot.data!.docs;
          final txs = docs
              .map((doc) => TransactionModel.fromMap(doc.id, doc.data() as Map<String, dynamic>))
              .where((tx) => tx.senderId == user.uid || tx.recipientId == user.uid)
              .toList();

          final filteredTxs = (selectedTab == 0)
              ? txs
              : (selectedTab == 1)
              ? txs.where((tx) => tx.recipientId == user.uid).toList()
              : txs.where((tx) => tx.senderId == user.uid).toList();

          final grouped = <DateTime, List<TransactionModel>>{};

          for (var tx in filteredTxs) {
            final day = DateTime(tx.date.year, tx.date.month, tx.date.day);
            grouped.putIfAbsent(day, () => []).add(tx);
          }

          // sort dates DESC (latest first)
          final sections = grouped.keys.toList()
            ..sort((a, b) => b.compareTo(a));


          return SingleChildScrollView(
            child: Container(
              margin: EdgeInsets.fromLTRB(12.w, 10.h, 12.w, 10.h),
              padding: EdgeInsets.all(10.w),
              decoration: BoxDecoration(
                color: scheme.surface,
                borderRadius: BorderRadius.circular(26.r),
                boxShadow: [
                  BoxShadow(
                    color: scheme.onBackground.withOpacity(0.015),
                    blurRadius: 24.r,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 12.h),
                  // Tab selector
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(tabs.length, (i) {
                      final isSelected = i == selectedTab;
                      return GestureDetector(
                        onTap: () => setState(() => selectedTab = i),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          height: 38.h,
                          width: 90.w,
                          margin: EdgeInsets.symmetric(horizontal: 3.w),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? scheme.primary
                                : (isLight ? const Color(0xFFF6F4FB) : scheme.surface),
                            borderRadius: BorderRadius.circular(15.r),
                          ),
                          child: Center(
                            child: Text(
                              tabs[i],
                              style: TextStyle(
                                color: isSelected ? Colors.white : scheme.primary,
                                fontWeight: FontWeight.w700,
                                fontSize: 14.5.sp,
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                  SizedBox(height: 22.h),
                  // Grouped transaction sections
                  ...sections.map((sectionDate) {
                    final txns = grouped[sectionDate]!;
                    final label = formatDateLabel(sectionDate);

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (sections.first != sectionDate) SizedBox(height: 17.h),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              label,
                              style: TextStyle(
                                color: scheme.onBackground.withOpacity(0.76),
                                fontWeight: FontWeight.w600,
                                fontSize: 14.sp,
                              ),
                            ),
                            Text(
                              "${sectionDate.day.toString().padLeft(2, '0')} "
                                  "${_monthAbbr(sectionDate.month)}, "
                                  "${sectionDate.year}",
                              style: TextStyle(
                                color: scheme.onBackground.withOpacity(0.38),
                                fontWeight: FontWeight.w400,
                                fontSize: 12.sp,
                              ),
                            ),
                          ],
                        ),

                        SizedBox(height: 13.h),
                        ...txns.map((tx) {
                          final received = tx.recipientId == user.uid;
                          final amountColor = received ? colorIncome : colorOutcome;

                          return GestureDetector(
                            onTap: () {
                              Get.to(() => TransactionResultScreen(type: getTransactionTypeFromStatus(tx.status), transaction: tx), curve: curve, transition: transition, duration: duration);
                            },
                            child: Container(
                              margin: EdgeInsets.symmetric(vertical: 6.h),
                              padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 10.w),
                              decoration: BoxDecoration(
                                color: scheme.background,
                                borderRadius: BorderRadius.circular(16.r),
                                boxShadow: [
                                  BoxShadow(
                                    color: scheme.onBackground.withOpacity(0.05),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 22.r,
                                    backgroundColor: amountColor.withOpacity(0.15),
                                    child: Text(
                                      received ? '+' : '-',
                                      style: TextStyle(
                                        color: amountColor,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 20.sp,
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 12.w),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          tx.recipientName,
                                          style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 15.sp,
                                            color: scheme.onSurface,
                                          ),
                                        ),
                                        SizedBox(height: 4.h),
                                        Text(
                                          tx.category ?? 'No category',
                                          style: TextStyle(
                                            color: scheme.onSurface.withOpacity(0.6),
                                            fontSize: 12.sp,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Text(
                                    '₹${tx.amount.toStringAsFixed(2)}',
                                    style: TextStyle(
                                      color: amountColor,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16.sp,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ],
                    );
                  }).toList(),
                  SizedBox(height: 10.h),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
