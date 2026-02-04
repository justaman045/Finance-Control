import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:money_control/Models/recurring_payment_model.dart';
import 'package:uuid/uuid.dart';

class RecurringService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Add new subscription
  Future<void> addPayment(RecurringPayment payment) async {
    final user = _auth.currentUser;
    if (user == null) return;

    await _db
        .collection('users')
        .doc(user.email)
        .collection('recurring_payments')
        .doc(payment.id)
        .set(payment.toMap());
  }

  // Delete subscription
  Future<void> deletePayment(String id) async {
    final user = _auth.currentUser;
    if (user == null) return;

    await _db
        .collection('users')
        .doc(user.email)
        .collection('recurring_payments')
        .doc(id)
        .delete();
  }

  // Stream of subscriptions
  Stream<List<RecurringPayment>> getPayments() {
    final user = _auth.currentUser;
    if (user == null) return Stream.value([]);

    return _db
        .collection('users')
        .doc(user.email)
        .collection('recurring_payments')
        .snapshots()
        .map((snapshot) {
          final list = snapshot.docs.map((doc) {
            return RecurringPayment.fromMap(doc.id, doc.data());
          }).toList();

          list.sort((a, b) {
            int dateComp = a.nextDueDate.compareTo(b.nextDueDate);
            if (dateComp != 0) return dateComp;
            return b.amount.compareTo(a.amount);
          });

          return list;
        });
  }

  // Calculate total monthly commitment
  // Calculate total monthly commitment (remaining to pay this month)
  Stream<double> getMonthlyTotal() {
    return getPayments().map((payments) {
      double total = 0;
      final now = DateTime.now();
      for (var p in payments) {
        if (!p.isActive) continue;

        // Only count if the NEXT payment falls within the current month
        // This implies:
        // 1. If unpaid, date is in this month -> Counted
        // 2. If paid, date moved to next month -> Not counted
        if (p.nextDueDate.year == now.year &&
            p.nextDueDate.month == now.month) {
          total += p.amount;
        }
      }
      return total;
    });
  }

  // Update subscription details
  Future<void> updatePayment(RecurringPayment payment) async {
    final user = _auth.currentUser;
    if (user == null) return;

    await _db
        .collection('users')
        .doc(user.email)
        .collection('recurring_payments')
        .doc(payment.id)
        .update(payment.toMap());
  }

  // Toggle active status
  Future<void> togglePaymentStatus(
    String id,
    bool isActive, {
    DateTime? nextDueDate,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final Map<String, dynamic> updates = {'isActive': isActive};
    if (nextDueDate != null) {
      updates['nextDueDate'] = Timestamp.fromDate(nextDueDate);
    }

    await _db
        .collection('users')
        .doc(user.email)
        .collection('recurring_payments')
        .doc(id)
        .update(updates);
  }

  // Link an existing transaction to this payment
  Future<void> linkTransaction(String paymentId, String transactionId) async {
    final user = _auth.currentUser;
    if (user == null) return;

    await _db
        .collection('users')
        .doc(user.email)
        .collection('transactions')
        .doc(transactionId)
        .update({'recurringPaymentId': paymentId});
  }

  // Manually link/mark as paid -> Advance due date & optionally create txn
  Future<void> markAsPaid(
    RecurringPayment payment, {
    bool createTransaction = false,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return;

    // 1. Advance Date
    DateTime nextDate = payment.nextDueDate;
    if (payment.frequency == RecurringFrequency.monthly) {
      nextDate = DateTime(nextDate.year, nextDate.month + 1, nextDate.day);
    } else if (payment.frequency == RecurringFrequency.weekly) {
      nextDate = nextDate.add(const Duration(days: 7));
    } else if (payment.frequency == RecurringFrequency.yearly) {
      nextDate = DateTime(nextDate.year + 1, nextDate.month, nextDate.day);
    }

    await _db
        .collection('users')
        .doc(user.email)
        .collection('recurring_payments')
        .doc(payment.id)
        .update({'nextDueDate': Timestamp.fromDate(nextDate)});

    // 2. Create Transaction if requested
    if (createTransaction) {
      final txId = const Uuid().v4();
      final userDoc = await _db.collection('users').doc(user.email).get();
      final uid = userDoc.data()?['uid'] ?? '';

      final newTx = {
        'id': txId,
        'amount': payment.amount,
        'recipientName': payment.title,
        'recipientId': 'External',
        'senderId': uid,
        'date': Timestamp.now(),
        'category': payment.category,
        'status': 'success',
        'type': 'debit',
        'note': 'Manual payment for ${payment.title}',
        'recurringPaymentId': payment.id,
      };

      await _db
          .collection('users')
          .doc(user.email)
          .collection('transactions')
          .doc(txId)
          .set(newTx);
    }
  }

  // Process Due Payments (To be called by Background Worker mostly, but helper is here)
  static Future<void> processDuePayments(String userEmail) async {
    final db = FirebaseFirestore.instance;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final snapshot = await db
        .collection('users')
        .doc(userEmail)
        .collection('recurring_payments')
        .where('isActive', isEqualTo: true)
        .where('nextDueDate', isLessThanOrEqualTo: Timestamp.fromDate(today))
        .get();

    for (var doc in snapshot.docs) {
      final payment = RecurringPayment.fromMap(doc.id, doc.data());

      // 1. Create Transaction
      final txId = const Uuid().v4();

      // Need proper UID for 'senderId'
      final userDoc = await db.collection('users').doc(userEmail).get();
      final uid = userDoc.data()?['uid'];

      if (uid != null) {
        final newTx = {
          'id': txId,
          'amount': payment.amount,
          'recipientName': payment.title,
          'recipientId': 'External',
          'senderId': uid,
          'date': Timestamp.fromDate(DateTime.now()),
          'category': payment.category,
          'status': 'success',
          'type': 'debit',
          'note': 'Auto-payment for ${payment.title}',
          'recurringPaymentId': payment.id,
        };

        // Add to Transaction History
        await db
            .collection('users')
            .doc(userEmail)
            .collection('transactions')
            .doc(txId)
            .set(newTx);

        // 2. Update Next Due Date
        DateTime nextDate = payment.nextDueDate;
        if (payment.frequency == RecurringFrequency.monthly) {
          nextDate = DateTime(nextDate.year, nextDate.month + 1, nextDate.day);
        } else if (payment.frequency == RecurringFrequency.weekly) {
          nextDate = nextDate.add(const Duration(days: 7));
        } else if (payment.frequency == RecurringFrequency.yearly) {
          nextDate = DateTime(nextDate.year + 1, nextDate.month, nextDate.day);
        }

        await doc.reference.update({
          'nextDueDate': Timestamp.fromDate(nextDate),
        });
      }
    }
  }
}
