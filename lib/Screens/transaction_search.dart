import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:money_control/Models/transaction.dart';
import 'package:money_control/Screens/edit_transaction.dart';
import 'package:money_control/Components/methods.dart';
import 'package:money_control/Screens/transaction_details.dart';

class TransactionSearchPage extends StatefulWidget {
  const TransactionSearchPage({super.key});

  @override
  State<TransactionSearchPage> createState() => _TransactionSearchPageState();
}

class _TransactionSearchPageState extends State<TransactionSearchPage> {
  final TextEditingController _search = TextEditingController();
  List<TransactionModel> results = [];
  bool searching = false;

  /// Search Firestore for matching transactions
  Future<void> _performSearch(String query) async {
    if (query.trim().isEmpty) {
      setState(() => results = []);
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => searching = true);

    try {
      final snap = await FirebaseFirestore.instance
          .collection("users")
          .doc(user.email)
          .collection("transactions")
          .get();

      final List<TransactionModel> all = snap.docs
          .map((d) => TransactionModel.fromMap(d.id, d.data()))
          .toList();

      final q = query.toLowerCase();

      final matched = all.where((tx) {
        return (tx.recipientName.toLowerCase().contains(q)) ||
            (tx.category?.toLowerCase().contains(q) ?? false) ||
            tx.amount.toString().contains(q) ||
            (tx.note?.toLowerCase().contains(q) ?? false);
      }).toList();

      setState(() => results = matched);
    } catch (e) {
      debugPrint("Search error: $e");
    }

    setState(() => searching = false);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Search Transactions"),
        backgroundColor: scheme.surface,
      ),
      body: Column(
        children: [
          // 🔍 SEARCH FIELD
          Padding(
            padding: EdgeInsets.all(12.w),
            child: TextField(
              controller: _search,
              onChanged: _performSearch,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: "Search by name, amount, category, note…",
                filled: true,
                fillColor: scheme.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14.r),
                ),
              ),
            ),
          ),

          if (searching)
            Padding(
              padding: const EdgeInsets.all(16),
              child: CircularProgressIndicator(color: scheme.primary),
            ),

          // 📝 RESULTS LIST
          Expanded(
            child: results.isEmpty
                ? Center(
                    child: Text(
                      "No transactions found",
                      style: TextStyle(
                        color: scheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                  )
                : ListView.builder(
                    itemCount: results.length,
                    itemBuilder: (context, i) {
                      final tx = results[i];
                      final isIncome =
                          tx.recipientId ==
                          FirebaseAuth.instance.currentUser?.uid;

                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: isIncome ? Colors.green : Colors.red,
                          child: Icon(
                            isIncome ? Icons.south_west : Icons.north_east,
                            color: Colors.white,
                          ),
                        ),
                        title: Text(
                          tx.recipientName,
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Text(
                          "${tx.category ?? ''}  •  ₹${tx.amount}",
                          style: TextStyle(
                            color: scheme.onSurface.withOpacity(0.7),
                          ),
                        ),
                        trailing: Icon(
                          Icons.arrow_forward_ios,
                          size: 16.sp,
                          color: scheme.primary,
                        ),
                        onTap: () {
                          Get.to(
                                () => TransactionResultScreen(
                              type: getTransactionTypeFromStatus(tx.status),
                              transaction: tx,
                            ),
                            preventDuplicates: false,
                            curve: curve,
                            transition: transition,
                            duration: duration,
                          );
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
