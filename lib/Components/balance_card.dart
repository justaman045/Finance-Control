import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:money_control/Models/transaction.dart';
import 'package:money_control/Components/action_chip.dart';
import 'package:money_control/Screens/add_transaction.dart';
import 'package:money_control/Components/methods.dart';

class BalanceCard extends StatefulWidget {
  const BalanceCard({super.key});

  @override
  State<BalanceCard> createState() => _BalanceCardState();
}

class _BalanceCardState extends State<BalanceCard> {
  Future<double> _calculateBalance(String uid) async {
    double balance = 0;

    final sentSnaps = await FirebaseFirestore.instance
        .collection('users').doc(FirebaseAuth.instance.currentUser?.email).collection('transactions')
        .where('senderId', isEqualTo: uid)
        .get();

    for (final doc in sentSnaps.docs) {
      final txn = TransactionModel.fromMap(doc.id, doc.data());
      balance -= txn.amount;
      balance -= txn.tax;
    }

    final receivedSnaps = await FirebaseFirestore.instance
        .collection('users').doc(FirebaseAuth.instance.currentUser?.email).collection('transactions')
        .where('recipientId', isEqualTo: uid)
        .get();

    for (final doc in receivedSnaps.docs) {
      final txn = TransactionModel.fromMap(doc.id, doc.data());
      balance += txn.amount;
    }
    return balance;
  }

  Future<String> _getPhoneNumber(String email) async {
    final userSnap = await FirebaseFirestore.instance
        .collection('users')
        .doc(email)
        .get();
    if (userSnap.exists && userSnap.data()?['phone'] != null) {
      return userSnap.data()!['phone'] as String;
    }
    return "--";
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final user = FirebaseAuth.instance.currentUser;
    final List<Color> gradientColors = scheme.brightness == Brightness.light
        ? [const Color(0xFFF2F7FF), const Color(0xFFEFF3FE)]
        : [scheme.surface.withOpacity(0.96), scheme.surface.withOpacity(0.88)];

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
      padding: EdgeInsets.fromLTRB(14.w, 16.h, 14.w, 16.h),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24.r),
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.06),
            blurRadius: 16.r,
            offset: Offset(0, 8.h),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Current Balance',
            style: TextStyle(
              color: scheme.onSurface.withOpacity(0.65),
              fontSize: 12.sp,
            ),
          ),
          SizedBox(height: 8.h),
          if (user != null)
            FutureBuilder<double>(
              future: _calculateBalance(user.uid),
              builder: (context, balanceSnapshot) {
                if (balanceSnapshot.connectionState == ConnectionState.waiting) {
                  return _balanceShimmer(scheme);
                }
                if (balanceSnapshot.hasError || !balanceSnapshot.hasData) {
                  return _balanceLabel('--', scheme);
                }
                String formattedBalance =
                    '₹ ${balanceSnapshot.data!.toStringAsFixed(2)}';

                // Nested FutureBuilder for phone number
                return FutureBuilder<String>(
                  future: _getPhoneNumber(user.email!),
                  builder: (context, userSnapshot) {
                    final phone = userSnapshot.data ?? "--";
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        _balanceLabel(formattedBalance, scheme),
                        const Spacer(),
                        Text(
                          phone,
                          style: TextStyle(
                            color: scheme.onSurface.withOpacity(0.52),
                            fontSize: 11.sp,
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
            )
          else
            _balanceLabel('--', scheme),
          SizedBox(height: 16.h),
          Row(
            children: [
              ActionCChip(
                color: scheme.primary,
                label: 'Send',
                icon: Icons.north_east,
                onTap: () {
                  gotoPage(PaymentScreen(type: PaymentType.send));
                },
              ),
              SizedBox(width: 8.w),
              ActionCChip(
                color: scheme.secondary,
                label: 'Receive',
                icon: Icons.south_west,
                onTap: () {
                  gotoPage(PaymentScreen(type: PaymentType.receive));
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _balanceLabel(String text, ColorScheme scheme) => Text(
    text,
    style: TextStyle(
      fontWeight: FontWeight.w800,
      fontSize: 24.sp,
      color: scheme.onSurface,
    ),
  );

  Widget _balanceShimmer(ColorScheme scheme) => Container(
    width: 120.w,
    height: 36.h,
    decoration: BoxDecoration(
      color: scheme.onSurface.withOpacity(0.16),
      borderRadius: BorderRadius.circular(12.r),
    ),
    margin: EdgeInsets.symmetric(vertical: 4.h),
  );
}
