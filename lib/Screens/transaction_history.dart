import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:money_control/Models/transaction.dart';
import 'package:money_control/Components/methods.dart';
import 'package:money_control/Screens/transaction_details.dart';
import 'package:money_control/Screens/sms_import_screen.dart';
import 'package:money_control/Components/empty_state.dart';
import 'package:money_control/Controllers/currency_controller.dart';

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
      "Jan",
      "Feb",
      "Mar",
      "Apr",
      "May",
      "Jun",
      "Jul",
      "Aug",
      "Sep",
      "Oct",
      "Nov",
      "Dec",
    ];
    return months[month - 1];
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final colorIncome = const Color(0xFF00E5FF); // Neon Cyan
    final colorOutcome = const Color(0xFFFF2975); // Neon Pink

    if (user == null) {
      return const Scaffold(body: Center(child: Text("Not logged in")));
    }

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF1A1A2E), // Midnight Void Top
            const Color(0xFF16213E).withValues(alpha: 0.95), // Deep Blue Bottom
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Text(
            "Transaction History",
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 17.sp,
              letterSpacing: 0.5,
            ),
          ),
          centerTitle: true,
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios, color: Colors.white, size: 19.sp),
            onPressed: () => goBack(),
          ),
          actions: [
            IconButton(
              icon: Icon(Icons.sms_rounded, color: Colors.white, size: 22.sp),
              tooltip: "Import from SMS",
              onPressed: () async {
                await Get.to(
                  () => const SmsImportScreen(),
                  transition: Transition.rightToLeftWithFade,
                );
              },
            ),
            SizedBox(width: 10.w),
          ],
        ),
        body: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(user.email)
              .collection('transactions')
              .orderBy('createdAt', descending: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(
                child: CircularProgressIndicator(color: Color(0xFF00E5FF)),
              );
            }

            final docs = snapshot.data!.docs;
            final txs = docs
                .map(
                  (doc) => TransactionModel.fromMap(
                    doc.id,
                    doc.data() as Map<String, dynamic>,
                  ),
                )
                .where(
                  (tx) => tx.senderId == user.uid || tx.recipientId == user.uid,
                )
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

            final sections = grouped.keys.toList()
              ..sort((a, b) => b.compareTo(a));

            return RefreshIndicator(
              color: const Color(0xFF00E5FF),
              backgroundColor: const Color(0xFF1A1A2E),
              onRefresh: () async {
                await Future.delayed(const Duration(milliseconds: 800));
                if (context.mounted) setState(() {});
              },
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  SizedBox(height: 10.h),
                  // Tab selector
                  Center(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(tabs.length, (i) {
                          final isSelected = i == selectedTab;
                          return GestureDetector(
                            onTap: () => setState(() => selectedTab = i),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              padding: EdgeInsets.symmetric(
                                horizontal: 24.w,
                                vertical: 10.h,
                              ),
                              margin: EdgeInsets.symmetric(horizontal: 5.w),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? const Color(
                                        0xFF6C63FF,
                                      ).withValues(alpha: 0.3)
                                    : Colors.white.withValues(alpha: 0.05),
                                borderRadius: BorderRadius.circular(30.r),
                                border: Border.all(
                                  color: isSelected
                                      ? const Color(0xFF6C63FF)
                                      : Colors.white.withValues(alpha: 0.1),
                                ),
                                boxShadow: isSelected
                                    ? [
                                        BoxShadow(
                                          color: const Color(
                                            0xFF6C63FF,
                                          ).withValues(alpha: 0.4),
                                          blurRadius: 12,
                                          spreadRadius: -2,
                                        ),
                                      ]
                                    : null,
                              ),
                              child: Text(
                                tabs[i],
                                style: TextStyle(
                                  color: isSelected
                                      ? Colors.white
                                      : Colors.white60,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14.sp,
                                ),
                              ),
                            ),
                          );
                        }),
                      ),
                    ),
                  ),
                  SizedBox(height: 20.h),

                  SizedBox(height: 20.h),

                  if (filteredTxs.isEmpty)
                    Container(
                      height: 0.6.sh,
                      alignment: Alignment.center,
                      child: EmptyStateWidget(
                        title: "No Transactions",
                        subtitle:
                            "You don't have any transactions in this category yet.",
                        icon: Icons.receipt_long_outlined,
                        color: Colors.white.withValues(alpha: 0.5),
                      ),
                    )
                  else
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20.w),
                      child: Column(
                        children: [
                          ...sections.map((sectionDate) {
                            final txns = grouped[sectionDate]!;
                            final label = formatDateLabel(sectionDate);

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: EdgeInsets.only(
                                    bottom: 12.h,
                                    top: 10.h,
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        label,
                                        style: TextStyle(
                                          color: Colors.white70,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14.sp,
                                        ),
                                      ),
                                      Text(
                                        "${sectionDate.day.toString().padLeft(2, '0')} "
                                        "${_monthAbbr(sectionDate.month)}, "
                                        "${sectionDate.year}",
                                        style: TextStyle(
                                          color: Colors.white38,
                                          fontWeight: FontWeight.w400,
                                          fontSize: 12.sp,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                ...txns.map((tx) {
                                  final received = tx.recipientId == user.uid;
                                  final amountColor = received
                                      ? colorIncome
                                      : colorOutcome;

                                  return GestureDetector(
                                    onTap: () {
                                      Get.to(
                                        () => TransactionResultScreen(
                                          type: getTransactionTypeFromStatus(
                                            tx.status,
                                          ),
                                          transaction: tx,
                                        ),
                                        curve: curve,
                                        transition: transition,
                                        duration: duration,
                                      );
                                    },
                                    child: Container(
                                      margin: EdgeInsets.only(bottom: 12.h),
                                      padding: EdgeInsets.all(16.w),
                                      decoration: BoxDecoration(
                                        color: const Color(
                                          0xFF1E1E2C,
                                        ).withValues(alpha: 0.6), // Dark Glass
                                        borderRadius: BorderRadius.circular(
                                          20.r,
                                        ),
                                        border: Border.all(
                                          color: Colors.white.withValues(
                                            alpha: 0.05,
                                          ),
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withValues(
                                              alpha: 0.2,
                                            ),
                                            blurRadius: 10,
                                            offset: const Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      child: Row(
                                        children: [
                                          Container(
                                            padding: EdgeInsets.all(10.w),
                                            decoration: BoxDecoration(
                                              color: amountColor.withValues(
                                                alpha: 0.1,
                                              ),
                                              shape: BoxShape.circle,
                                            ),
                                            child: Icon(
                                              received
                                                  ? Icons.arrow_downward_rounded
                                                  : Icons.arrow_upward_rounded,
                                              color: amountColor,
                                              size: 20.sp,
                                            ),
                                          ),
                                          SizedBox(width: 16.w),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  tx.recipientName.isEmpty
                                                      ? "Unknown"
                                                      : tx.recipientName,
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 15.sp,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                                SizedBox(height: 4.h),
                                                Text(
                                                  tx.category ??
                                                      'Uncategorized',
                                                  style: TextStyle(
                                                    color: Colors.white54,
                                                    fontSize: 12.sp,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Text(
                                            '${received ? '+' : '-'}${CurrencyController.to.currencySymbol.value}${tx.amount.toStringAsFixed(2)}',
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
                                }),
                              ],
                            );
                          }),
                          SizedBox(height: 20.h),
                        ],
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
