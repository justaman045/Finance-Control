import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:money_control/Models/wealth_data.dart';

class WealthTarget {
  final double effective;
  final double formula;
  final bool isOverridden;

  WealthTarget({
    required this.effective,
    required this.formula,
    required this.isOverridden,
  });
}

class WealthService {
  // ... (db, auth, refs, getPortfolio, updateAsset, updateAssetTarget, streamPortfolio, calculateBankBalance, generateSmartInsights remain SAME)
  static final FirebaseFirestore _db = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  static DocumentReference get _portfolioRef {
    final user = _auth.currentUser;
    if (user == null) throw Exception("User not logged in");
    return _db
        .collection('users')
        .doc(user.email)
        .collection('wealth')
        .doc('portfolio');
  }

  /// Fetch the current portfolio, or return a default empty one if not found.
  static Future<WealthPortfolio> getPortfolio() async {
    try {
      final doc = await _portfolioRef.get();
      if (doc.exists && doc.data() != null) {
        return WealthPortfolio.fromMap(doc.data() as Map<String, dynamic>);
      }
    } catch (e) {
      print("Error fetching portfolio: $e");
    }
    return WealthPortfolio(lastUpdated: DateTime.now());
  }

  /// Update a specific asset value (e.g., 'sip', 'fd', etc.)
  static Future<void> updateAsset(String key, double value) async {
    try {
      await _portfolioRef.set({
        key: value,
        'lastUpdated': Timestamp.now(),
      }, SetOptions(merge: true));
    } catch (e) {
      print("Error updating asset $key: $e");
      rethrow;
    }
  }

  /// Update a specific asset's target value manually
  static Future<void> updateAssetTarget(String key, double targetValue) async {
    try {
      await _portfolioRef.set({
        'targets': {key: targetValue},
        'lastUpdated': Timestamp.now(),
      }, SetOptions(merge: true));
    } catch (e) {
      print("Error updating asset target $key: $e");
      rethrow;
    }
  }

  /// Update the monthly expense override value
  static Future<void> updateMonthlyExpenseOverride(double? value) async {
    try {
      final data = <String, dynamic>{'lastUpdated': Timestamp.now()};
      if (value == null || value <= 0) {
        data['monthly_expense_override'] = FieldValue.delete();
      } else {
        data['monthly_expense_override'] = value;
      }
      await _portfolioRef.set(data, SetOptions(merge: true));
    } catch (e) {
      print("Error updating monthly expense override: $e");
      rethrow;
    }
  }

  /// Update the list of hidden assets
  static Future<void> updateHiddenAssets(List<String> keys) async {
    try {
      await _portfolioRef.set({
        'hiddenKeys': keys,
        'lastUpdated': Timestamp.now(),
      }, SetOptions(merge: true));
    } catch (e) {
      print("Error updating hidden assets: $e");
      rethrow;
    }
  }

  /// Stream portfolio for real-time updates
  static Stream<WealthPortfolio> streamPortfolio() {
    final user = _auth.currentUser;
    if (user == null) return const Stream.empty();

    return _db
        .collection('users')
        .doc(user.email)
        .collection('wealth')
        .doc('portfolio')
        .snapshots()
        .map((doc) {
          if (doc.exists && doc.data() != null) {
            return WealthPortfolio.fromMap(doc.data() as Map<String, dynamic>);
          }
          return WealthPortfolio(lastUpdated: DateTime.now());
        });
  }

  /// Calculate current bank balance from transaction history
  static Future<double> calculateBankBalance() async {
    final user = _auth.currentUser;
    if (user == null) return 0;

    double balance = 0;

    try {
      final sentSnaps = await _db
          .collection('users')
          .doc(user.email)
          .collection('transactions')
          .where('senderId', isEqualTo: user.uid)
          .get();

      for (final doc in sentSnaps.docs) {
        final data = doc.data();
        final amount = (data['amount'] ?? 0).toDouble().abs();
        final tax = (data['tax'] ?? 0).toDouble();
        balance -= amount;
        balance -= tax;
      }

      final receivedSnaps = await _db
          .collection('users')
          .doc(user.email)
          .collection('transactions')
          .where('recipientId', isEqualTo: user.uid)
          .get();

      for (final doc in receivedSnaps.docs) {
        final data = doc.data();
        final amount = (data['amount'] ?? 0).toDouble().abs();
        balance += amount;
      }
    } catch (e) {
      print("Error calculating bank balance: $e");
    }
    return balance;
  }

  /// Generate smart financial insights based on transaction history and current portfolio
  static Future<List<Map<String, dynamic>>> generateSmartInsights(
    WealthPortfolio portfolio,
  ) async {
    final user = _auth.currentUser;
    if (user == null) return [];

    List<Map<String, dynamic>> insights = [];

    try {
      final now = DateTime.now();
      final threeMonthsAgo = now.subtract(const Duration(days: 90));

      final txSnaps = await _db
          .collection('users')
          .doc(user.email)
          .collection('transactions')
          .where(
            'date',
            isGreaterThanOrEqualTo: Timestamp.fromDate(threeMonthsAgo),
          )
          .get();

      double totalIncome = 0;
      double totalExpense = 0;
      Map<String, double> categoryExpenses = {};

      for (var doc in txSnaps.docs) {
        final data = doc.data();
        final amount = (data['amount'] ?? 0)
            .toDouble()
            .abs(); // Ensure positive for calcs

        final senderId = data['senderId'];
        final recipientId = data['recipientId'];

        if (recipientId == user.uid) {
          totalIncome += amount;
        } else if (senderId == user.uid) {
          totalExpense += amount;
          final cat = data['category'] as String? ?? 'Uncategorized';
          categoryExpenses[cat] = (categoryExpenses[cat] ?? 0) + amount;
        }
      }

      final avgMonthlyIncome = totalIncome / 3;
      final avgMonthlyExpense = totalExpense / 3;
      final avgMonthlySavings = avgMonthlyIncome - avgMonthlyExpense;
      final savingsRate = avgMonthlyIncome > 0
          ? (avgMonthlySavings / avgMonthlyIncome)
          : 0.0;

      if (savingsRate < 0.2 && avgMonthlyIncome > 0) {
        insights.add({
          'type': 'warning',
          'message':
              "⚠️ Low Savings Rate: You're saving only ${(savingsRate * 100).toStringAsFixed(1)}% of income. Aim for at least 20%.",
        });
      } else if (savingsRate > 0.4) {
        insights.add({
          'type': 'success',
          'message':
              "🌟 Great Savings! You're saving ${(savingsRate * 100).toStringAsFixed(0)}% of income. Consider boosting SIPs.",
        });
      }

      double getVisible(String key, double val) =>
          portfolio.hiddenKeys.contains(key) ? 0.0 : val;

      final visibleTotal =
          getVisible('sip', portfolio.sip) +
          getVisible('fd', portfolio.fd) +
          getVisible('stocks', portfolio.stocks) +
          getVisible('pf', portfolio.pf) +
          getVisible('crypto', portfolio.crypto) +
          getVisible('gold', portfolio.gold) +
          getVisible('realEstate', portfolio.realEstate) +
          getVisible('nps', portfolio.nps) +
          getVisible('etf', portfolio.etf) +
          getVisible('reit', portfolio.reit) +
          getVisible('p2p', portfolio.p2p) +
          portfolio.custom.entries.fold(
            0,
            (sum, e) =>
                portfolio.hiddenKeys.contains(e.key) ? sum : sum + e.value,
          );

      final totalInvested = visibleTotal;
      if (avgMonthlySavings > 5000 &&
          totalInvested < avgMonthlySavings * 6 &&
          !portfolio.hiddenKeys.contains('sip')) {
        insights.add({
          'type': 'info',
          'message':
              "📈 Idle Cash? You save ~₹${avgMonthlySavings.toStringAsFixed(0)}/mo. Consider starting a new SIP of ₹${(avgMonthlySavings * 0.4).toStringAsFixed(0)}.",
        });
      }

      if (categoryExpenses.isNotEmpty) {
        final sortedCats = categoryExpenses.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));
        final topCat = sortedCats.first;
        final topCatShare = avgMonthlyExpense > 0
            ? (topCat.value / 3) / avgMonthlyExpense
            : 0;

        if (topCatShare > 0.25 &&
            topCat.key != 'Rent' &&
            topCat.key != 'Bills' &&
            !portfolio.hiddenKeys.contains('gold')) {
          insights.add({
            'type': 'alert',
            'message':
                "✂️ High Spending: '${topCat.key}' is ${(topCatShare * 100).toStringAsFixed(0)}% of your expenses. Cutting this could fund a Gold ETF.",
          });
        }
      }

      if (visibleTotal > 0) {
        if (!portfolio.hiddenKeys.contains('crypto') &&
            portfolio.crypto / visibleTotal > 0.15) {
          insights.add({
            'type': 'warning',
            'message':
                "⚠️ Crypto Alert: Crypto is ${(portfolio.crypto / visibleTotal * 100).toStringAsFixed(0)}% of assets. High risk!",
          });
        }
        if (!portfolio.hiddenKeys.contains('fd') &&
            portfolio.fd / visibleTotal > 0.60) {
          insights.add({
            'type': 'info',
            'message':
                "🔒 Low Growth: Heavy FD allocation. Stocks/Mutual Funds might beat inflation better.",
          });
        }
      }

      if (insights.isEmpty) {
        insights.add({
          'type': 'success',
          'message':
              "✅ Your financial health looks stable based on recent activity.",
        });
      }
    } catch (e) {
      print("Error generating insights: $e");
    }

    return insights;
  }

  /// Calculate target values based on User Formulas OR Custom Overrides
  static Future<Map<String, WealthTarget>> calculateAssetTargets(
    WealthPortfolio portfolio,
  ) async {
    final user = _auth.currentUser;
    if (user == null) return {};

    try {
      final now = DateTime.now();
      final threeMonthsAgo = now.subtract(const Duration(days: 90));

      final txSnaps = await _db
          .collection('users')
          .doc(user.email)
          .collection('transactions')
          .where(
            'date',
            isGreaterThanOrEqualTo: Timestamp.fromDate(threeMonthsAgo),
          )
          .get();

      double totalExpense = 0;
      for (var doc in txSnaps.docs) {
        final data = doc.data();
        if (data['senderId'] == user.uid) {
          totalExpense += (data['amount'] ?? 0).toDouble().abs();
        }
      }

      final monthlyExpense = totalExpense / 3;

      // Fetch user profile for age
      final userDoc = await _db.collection('users').doc(user.email).get();
      final userAge = userDoc.data()?['age'];
      final int age = (userAge is int && userAge > 0) ? userAge : 30;

      // Fetch portfolio settings for override
      final portfolioDoc = await _portfolioRef.get();
      double? expenseOverride;
      if (portfolioDoc.exists && portfolioDoc.data() is Map) {
        final data = portfolioDoc.data() as Map<String, dynamic>;
        if (data.containsKey('monthly_expense_override')) {
          expenseOverride = (data['monthly_expense_override'] as num?)
              ?.toDouble();
        }
      }

      final effectiveMonthlyExpense = expenseOverride ?? monthlyExpense;
      final annualExpense = effectiveMonthlyExpense * 12;

      final double P = portfolio.totalAssets;

      // Age-Based Multiplier for Cash
      int cashMultiplier = 6;
      if (age < 30) {
        cashMultiplier = 3; // Aggressive, less cash needed
      } else if (age > 50) {
        cashMultiplier = 12; // Conservative, higher safety net
      }

      // Age-Based Multiplier for SIP (Financial Freedom Milestones)
      // < 30 : 1x Annual Expense (Foundation)
      // 30-40: 3x Annual Expense
      // 40-50: 8x Annual Expense
      // 50-60: 15x Annual Expense
      // 60+  : 25x Annual Expense (Retirement)
      int sipMultiplier = 25;
      if (age < 30) {
        sipMultiplier = 1;
      } else if (age < 40) {
        sipMultiplier = 3;
      } else if (age < 50) {
        sipMultiplier = 8;
      } else if (age < 60) {
        sipMultiplier = 15;
      }

      // Default Formula Targets
      final formulaTargets = {
        'bank': effectiveMonthlyExpense * cashMultiplier,
        'fd': effectiveMonthlyExpense * 3,
        'sip': annualExpense * sipMultiplier,
        'stocks': P > 0 ? P * ((100 - age) / 100) : 0.0,
        'pf': P > 0 ? P * 0.20 : 0.0,
        'gold': P > 0 ? P * 0.10 : 0.0,
        'crypto': P > 0 ? P * 0.05 : 0.0,
        'realEstate': P > 0 ? P * 0.35 : 0.0,
        'nps': P > 0 ? P * 0.10 : 0.0,
        'etf': P > 0 ? P * 0.10 : 0.0,
        'reit': P > 0 ? P * 0.05 : 0.0,
        'p2p': P > 0 ? P * 0.05 : 0.0,
        'loans': 0.0, // Goal is debt free
      };

      final result = <String, WealthTarget>{};

      formulaTargets.forEach((key, formulaVal) {
        // STRICTLY FORMULA DRIVEN: Ignore overrides as per new requirement
        const isOverridden = false;
        final effectiveVal = formulaVal;

        result[key] = WealthTarget(
          effective: effectiveVal,
          formula: formulaVal,
          isOverridden: isOverridden,
        );
      });

      return result;
    } catch (e) {
      print("Error calculating targets: $e");
      return {};
    }
  }
}
