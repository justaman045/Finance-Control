import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:money_control/Models/recurring_payment_model.dart';
import 'package:money_control/Services/recurring_service.dart';
import 'package:uuid/uuid.dart';
import 'package:money_control/Screens/subscription_details.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RecurringPaymentsScreen extends StatefulWidget {
  const RecurringPaymentsScreen({super.key});

  @override
  State<RecurringPaymentsScreen> createState() =>
      _RecurringPaymentsScreenState();
}

class _RecurringPaymentsScreenState extends State<RecurringPaymentsScreen> {
  final RecurringService _service = RecurringService();
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Premium Gradient Background
    final gradientColors = isDark
        ? [
            const Color(0xFF1A1A2E), // Midnight Void
            const Color(0xFF16213E).withOpacity(0.95),
          ]
        : [
            const Color(0xFFF5F7FA), // Premium Light
            const Color(0xFFC3CFE2),
          ];

    final textColor = isDark ? Colors.white : const Color(0xFF1A1A2E);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text(
            "Subscriptions",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 20.sp,
              color: textColor,
            ),
          ),
          centerTitle: true,
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(
              Icons.arrow_back_ios_new_rounded,
              color: textColor,
              size: 20,
            ),
            onPressed: () => Get.back(),
          ),
        ),
        floatingActionButton: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            gradient: const LinearGradient(
              colors: [Color(0xFF00E5FF), Color(0xFF00B8D4)], // Cyan Gradient
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF00E5FF).withOpacity(0.4),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: FloatingActionButton.extended(
            onPressed: () => _showAddDialog(context, isDark),
            backgroundColor: Colors.transparent,
            elevation: 0,
            label: const Text(
              "Add Subscription",
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
            icon: const Icon(Icons.add_rounded, color: Colors.black),
          ),
        ),
        body: Column(
          children: [
            // Monthly Summary Card
            StreamBuilder<double>(
              stream: _service.getMonthlyTotal(),
              builder: (context, snapshot) {
                final total = snapshot.data ?? 0;
                return Container(
                  width: double.infinity,
                  margin: EdgeInsets.fromLTRB(20.w, 10.h, 20.w, 10.h),
                  padding: EdgeInsets.all(20.w),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E1E2C) : Colors.white,
                    borderRadius: BorderRadius.circular(20.r),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Text(
                        "Monthly Commitment",
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: textColor.withOpacity(0.6),
                        ),
                      ),
                      SizedBox(height: 8.h),
                      Text(
                        "₹${total.toStringAsFixed(0)}",
                        style: TextStyle(
                          fontSize: 32.sp,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),

            Expanded(
              child: StreamBuilder<List<RecurringPayment>>(
                stream: _service.getPayments(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: EdgeInsets.all(30.w),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withOpacity(0.05),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(
                                    isDark ? 0.2 : 0.05,
                                  ),
                                  blurRadius: 20,
                                  spreadRadius: 5,
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.subscriptions_outlined,
                              size: 60.sp,
                              color: textColor.withOpacity(0.3),
                            ),
                          ),
                          SizedBox(height: 24.h),
                          Text(
                            "No subscriptions yet",
                            style: TextStyle(
                              color: textColor.withOpacity(0.6),
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          SizedBox(height: 8.h),
                          Text(
                            "Track Netflix, Rent, Spotify, etc.",
                            style: TextStyle(
                              color: textColor.withOpacity(0.4),
                              fontSize: 12.sp,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  final list = snapshot.data!;
                  return ListView.separated(
                    padding: EdgeInsets.all(20.w),
                    itemCount: list.length,
                    separatorBuilder: (c, i) => SizedBox(height: 16.h),
                    itemBuilder: (context, index) {
                      final item = list[index];
                      return GestureDetector(
                        onTap: () => Get.to(
                          () => SubscriptionDetailsScreen(payment: item),
                        ),
                        child: _buildCard(item, isDark, textColor, context),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard(
    RecurringPayment item,
    bool isDark,
    Color textColor,
    BuildContext context, // Added context param
  ) {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withOpacity(0.05)
            : Colors.white.withOpacity(0.8),
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.08)
              : Colors.white.withOpacity(0.5),
          width: 1,
        ),
        gradient: isDark
            ? LinearGradient(
                colors: [
                  Colors.white.withOpacity(0.05),
                  Colors.white.withOpacity(0.01),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.05),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(14.w),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  Color(0xFF6C63FF),
                  Color(0xFF4834D4),
                ], // Blurple Gradient
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(18.r),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF6C63FF).withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(
              Icons.receipt_long_rounded,
              color: Colors.white,
              size: 22.sp,
            ),
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                    letterSpacing: 0.3,
                  ),
                ),
                SizedBox(height: 6.h),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: textColor.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(6.r),
                  ),
                  child: Text(
                    "${item.frequency.name.capitalizeFirst} • Due ${DateFormat('MMM dd').format(item.nextDueDate)}",
                    style: TextStyle(
                      fontSize: 11.sp,
                      color: textColor.withOpacity(0.6),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                "₹${item.amount.toStringAsFixed(0)}",
                style: TextStyle(
                  fontSize: 17.sp,
                  fontWeight: FontWeight.w800,
                  color: textColor,
                  letterSpacing: 0.5,
                ),
              ),
              SizedBox(height: 8.h),
              // Edit only
              GestureDetector(
                onTap: () => _showAddDialog(context, isDark, payment: item),
                child: Container(
                  padding: EdgeInsets.all(6.w),
                  decoration: BoxDecoration(
                    color: textColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.edit_rounded,
                    color: textColor.withOpacity(0.7),
                    size: 16.sp,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showAddDialog(
    BuildContext context,
    bool isDark, {
    RecurringPayment? payment,
  }) {
    final titleCtrl = TextEditingController(text: payment?.title);
    final amountCtrl = TextEditingController(text: payment?.amount.toString());
    RecurringFrequency freq = payment?.frequency ?? RecurringFrequency.monthly;
    DateTime nextPaymentDate =
        payment?.nextDueDate ?? DateTime.now().add(const Duration(days: 30));
    String category = payment?.category ?? 'Utilities';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? const Color(0xFF1A1A2E) : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(
                24.w,
                24.h,
                24.w,
                MediaQuery.of(context).viewInsets.bottom + 24.h,
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      payment == null
                          ? "New Subscription"
                          : "Edit Subscription",
                      style: TextStyle(
                        fontSize: 20.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 20.h),
                    TextFormField(
                      controller: titleCtrl,
                      decoration: const InputDecoration(
                        labelText: "Name (e.g. Netflix)",
                      ),
                      validator: (v) => v!.isEmpty ? "Required" : null,
                    ),
                    SizedBox(height: 16.h),
                    TextFormField(
                      controller: amountCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: "Amount"),
                      validator: (v) => v!.isEmpty ? "Required" : null,
                    ),
                    SizedBox(height: 16.h),

                    // Frequency
                    DropdownButtonFormField<RecurringFrequency>(
                      value: freq,
                      items: RecurringFrequency.values
                          .map(
                            (f) => DropdownMenuItem(
                              value: f,
                              child: Text(f.name.capitalizeFirst!),
                            ),
                          )
                          .toList(),
                      onChanged: (v) => setModalState(() => freq = v!),
                      decoration: const InputDecoration(labelText: "Frequency"),
                    ),

                    SizedBox(height: 16.h),

                    // Next Payment Date Picker
                    GestureDetector(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: nextPaymentDate,
                          firstDate: DateTime.now().subtract(
                            const Duration(days: 365),
                          ),
                          lastDate: DateTime.now().add(
                            const Duration(days: 365 * 2),
                          ),
                        );
                        if (picked != null) {
                          setModalState(() => nextPaymentDate = picked);
                        }
                      },
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 12.w,
                          vertical: 16.h,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(4.r),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Next Payment: ${DateFormat('MMM dd, yyyy').format(nextPaymentDate)}",
                              style: TextStyle(fontSize: 16.sp),
                            ),
                            const Icon(Icons.calendar_today, size: 20),
                          ],
                        ),
                      ),
                    ),

                    SizedBox(height: 24.h),

                    SizedBox(
                      width: double.infinity,
                      height: 50.h,
                      child: ElevatedButton(
                        onPressed: () async {
                          if (_formKey.currentState!.validate()) {
                            final userId =
                                FirebaseAuth.instance.currentUser?.uid ?? '';
                            final newPayment = RecurringPayment(
                              id: payment?.id ?? const Uuid().v4(),
                              userId: userId,
                              title: titleCtrl.text,
                              amount: double.tryParse(amountCtrl.text) ?? 0,
                              category: category,
                              frequency: freq,
                              startDate: payment?.startDate ?? DateTime.now(),
                              nextDueDate: nextPaymentDate,
                              isActive: true,
                            );

                            if (payment == null) {
                              await _service.addPayment(newPayment);
                            } else {
                              await _service.updatePayment(newPayment);
                            }

                            if (context.mounted) Navigator.pop(context);
                          }
                        },
                        child: const Text("Save"),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
