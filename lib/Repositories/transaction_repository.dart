import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:money_control/Models/transaction.dart';
import 'package:money_control/Models/cateogary.dart';

class TransactionRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get _userEmail => _auth.currentUser?.email;
  String? get _userId => _auth.currentUser?.uid;

  // Collection References
  CollectionReference get _userTransactionsRef {
    if (_userEmail == null) throw Exception("User not logged in");
    return _firestore
        .collection('users')
        .doc(_userEmail)
        .collection('transactions');
  }

  CollectionReference get _userCategoriesRef {
    if (_userEmail == null) throw Exception("User not logged in");
    return _firestore
        .collection('users')
        .doc(_userEmail)
        .collection('categories');
  }

  // ——————————————————————————————————————
  // Transactions
  // ——————————————————————————————————————

  Future<DocumentReference> addTransaction(TransactionModel transaction) async {
    return await _userTransactionsRef.add(transaction.toMap());
  }

  Future<void> updateTransaction(TransactionModel transaction) async {
    if (transaction.id.isEmpty) throw Exception("Transaction ID is empty");
    await _userTransactionsRef.doc(transaction.id).update(transaction.toMap());
  }

  Future<void> deleteTransaction(String id) async {
    await _userTransactionsRef.doc(id).delete();
  }

  Stream<List<TransactionModel>> getTransactionsStream() {
    return _userTransactionsRef
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return TransactionModel.fromMap(
              doc.id,
              doc.data() as Map<String, dynamic>,
            );
          }).toList();
        });
  }

  // ——————————————————————————————————————
  // Categories
  // ——————————————————————————————————————

  Future<List<CategoryModel>> fetchCategories() async {
    final snapshot = await _userCategoriesRef.get();
    return snapshot.docs.map((doc) {
      return CategoryModel.fromMap(doc.id, doc.data() as Map<String, dynamic>);
    }).toList();
  }

  Future<DocumentReference> addCategory(String name) async {
    return await _userCategoriesRef.add({"name": name});
  }

  Stream<List<CategoryModel>> getCategoriesStream() {
    return _userCategoriesRef.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return CategoryModel.fromMap(
          doc.id,
          doc.data() as Map<String, dynamic>,
        );
      }).toList();
    });
  }

  Future<void> deleteCategory(String id) async {
    await _userCategoriesRef.doc(id).delete();
  }

  // ——————————————————————————————————————
  // Stats & Helpers
  // ——————————————————————————————————————

  Future<List<String>> fetchCategoriesSortedByUsage() async {
    try {
      // 1. Fetch all available categories
      final allCategories = await fetchCategories();
      final allCategoryNames = allCategories.map((c) => c.name).toSet();

      // 2. Fetch transactions for usage stats
      final snapshot = await _userTransactionsRef.get();
      Map<String, int> categoryCounts = {};

      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final category = data['category'] as String?;
        if (category != null && category.isNotEmpty) {
          categoryCounts[category] = (categoryCounts[category] ?? 0) + 1;
        }
      }

      // 3. Sort used categories
      final sortedUsedCategories = categoryCounts.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      final usedCategoryNames = sortedUsedCategories.map((e) => e.key).toList();

      // 4. Append unused categories
      // Filter allCategoryNames that are NOT in usedCategoryNames
      final unusedCategoryNames = allCategoryNames
          .where((name) => !usedCategoryNames.contains(name))
          .toList();

      return [...usedCategoryNames, ...unusedCategoryNames];
    } catch (e) {
      print("Error fetching sorted categories: $e");
      return [];
    }
  }
}
