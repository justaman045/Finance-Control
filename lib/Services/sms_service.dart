import 'package:flutter_sms_inbox/flutter_sms_inbox.dart';
import 'dart:developer';
import 'package:permission_handler/permission_handler.dart';

class SmsTransaction {
  final String sender;
  final String body;
  final DateTime date;
  final double amount;
  final String merchant;
  final bool isDebit; // true for Debit, false for Credit
  final String category;

  SmsTransaction({
    required this.sender,
    required this.body,
    required this.date,
    required this.amount,
    this.merchant = 'Unknown',
    required this.isDebit,
    this.category = 'Uncategorized',
  });
}

class SmsService {
  final SmsQuery _query = SmsQuery();

  String _getCategory(String merchant, String body) {
    final lowerBody = body.toLowerCase();
    final lowerMerchant = merchant.toLowerCase();

    final Map<String, List<String>> categories = {
      'Food': [
        'zomato',
        'swiggy',
        'kfc',
        'mcdonald',
        'pizza',
        'burger',
        'restaurant',
        'cafe',
        'dining',
        'starbucks',
        'domino',
        'biryani',
        'food',
      ],
      'Travel': [
        'uber',
        'ola',
        'rapido',
        'irctc',
        'railway',
        'flight',
        'indigo',
        'airasia',
        'petrol',
        'fuel',
        'shell',
        'hpcl',
        'bpcl',
        'toll',
        'fastag',
        'metro',
      ],
      'Shopping': [
        'amazon',
        'flipkart',
        'myntra',
        'jiomart',
        'retail',
        'store',
        'mall',
        'mart',
        'fashion',
        'clothing',
        'ajio',
        'trends',
        'zudio',
        'decathlon',
      ],
      'Groceries': [
        'bigbasket',
        'blinkit',
        'instamart',
        'zepto',
        'dmart',
        'reliance fresh',
        'vegetable',
        'fruit',
        'grocery',
        'milk',
        'dairy',
      ],
      'Entertainment': [
        'netflix',
        'spotify',
        'prime',
        'cinema',
        'movie',
        'pvr',
        'inox',
        'hotstar',
        'youtube',
        'subscription',
        'game',
        'steam',
      ],
      'Health': [
        'pharmacy',
        'hospital',
        'clinic',
        'medical',
        'dr ',
        'health',
        'medplus',
        'apollo',
        '1mg',
        'pharmeasy',
        'medicine',
      ],
      'Utilities': [
        'bill',
        'electricity',
        'water',
        'gas',
        'broadband',
        'wifi',
        'airtel',
        'jio',
        'vi',
        'bsnl',
        'recharge',
        'dth',
        'mobile',
      ],
      'Investment': [
        'zerodha',
        'groww',
        'upstox',
        'sip',
        'mutual fund',
        'stock',
        'invest',
      ],
    };

    for (var entry in categories.entries) {
      for (var keyword in entry.value) {
        if (lowerMerchant.contains(keyword) || lowerBody.contains(keyword)) {
          return entry.key;
        }
      }
    }
    return 'Uncategorized';
  }

  /// Request permissions and fetch SMS. Returns parsed transactions.
  Future<List<SmsTransaction>> scanMessages({int limit = 50}) async {
    var status = await Permission.sms.status;
    if (!status.isGranted) {
      status = await Permission.sms.request();
      if (!status.isGranted) {
        return [];
      }
    }

    try {
      final messages = await _query.querySms(
        kinds: [SmsQueryKind.inbox],
        count: limit,
      );

      final List<SmsTransaction> transactions = [];
      for (final msg in messages) {
        if (_isBankSms(msg.body ?? '')) {
          final tx = _parseSms(msg);
          if (tx != null) {
            transactions.add(tx);
          }
        }
      }
      return transactions;
    } catch (e) {
      log("Error scanning SMS: $e");
      return [];
    }
  }

  bool _isBankSms(String body) {
    if (body.isEmpty) return false;
    final lower = body.toLowerCase();
    if (lower.contains('otp')) return false;
    return lower.contains('debited') ||
        lower.contains('credited') ||
        lower.contains('spent') ||
        lower.contains('sent') ||
        lower.contains('paid') ||
        lower.contains('received') ||
        lower.contains('txn') ||
        lower.contains('withdraw') ||
        lower.contains('purchase') ||
        lower.contains('alert') ||
        lower.contains('transferred');
  }

  SmsTransaction? _parseSms(SmsMessage msg) {
    final body = msg.body ?? '';
    final date = msg.date ?? DateTime.now();
    final sender = msg.sender ?? 'Unknown';
    final lower = body.toLowerCase();

    // 1. Extract Amount
    // Regex for: Rs. 500, INR 500, Rs 500, 500.00, Amt 500
    final amountRegex = RegExp(
      r'(?:Rs\.?|INR|MRP|Amt|Amount)\W*(\d+(?:,\d+)*(?:\.\d{1,2})?)',
      caseSensitive: false,
    );

    final match = amountRegex.firstMatch(body);
    if (match == null) return null;

    String amountStr = match.group(1) ?? '0';
    amountStr = amountStr.replaceAll(',', '');
    final double amount = double.tryParse(amountStr) ?? 0;
    if (amount == 0) return null;

    // 2. Determine Type
    bool isDebit = true;
    if (lower.contains('refund')) {
      isDebit = false;
    } else if (lower.contains('debited') ||
        lower.contains('spent') ||
        lower.contains('sent') ||
        lower.contains('paid') ||
        lower.contains('purchase') ||
        lower.contains('withdraw')) {
      isDebit = true;
    } else if (lower.contains('credited') ||
        lower.contains('received') ||
        lower.contains('deposit')) {
      isDebit = false;
    }

    // 3. Extract Merchant
    String merchant = 'Unknown';

    String? findEntity(
      List<String> prepositions, {
      bool allowGenerics = false,
    }) {
      // Look for text after preposition (or @) until a terminator
      final pattern =
          '(?:${prepositions.join('|')}|@)\\s+([A-Za-z0-9\\s\\.\\*\\-&]{3,25})(?:\\s+(?:on|via|using|ref)|\\.|\\,|\$|\\;)';
      final reg = RegExp(pattern, caseSensitive: false);
      final matches = reg.allMatches(body);

      for (final m in matches) {
        final val = m.group(1)?.trim();
        if (val != null &&
            !val.toLowerCase().contains('rs.') &&
            !val.toLowerCase().contains('inr') &&
            !val.startsWith(RegExp(r'[0-9]'))) {
          if (!allowGenerics) {
            // Avoid detecting "Credit Card", "Bank Account" as merchant in first pass
            if (val.toLowerCase().contains(' card') ||
                val.toLowerCase().contains(' account') ||
                val.toLowerCase().contains(' a/c') ||
                val.toLowerCase().contains(' bank')) {
              continue;
            }
          }
          return val;
        }
      }
      return null;
    }

    if (isDebit) {
      // Check for "[Merchant] credited" pattern first (e.g. "RSPL credited")
      final beneficiaryMatch = RegExp(
        r'([A-Za-z0-9\s\.\*\-&]{3,25})\s+(?:credited|received)',
        caseSensitive: false,
      ).firstMatch(body);
      if (beneficiaryMatch != null) {
        final candidate = beneficiaryMatch.group(1)?.trim();
        if (candidate != null &&
            !candidate.toLowerCase().contains('account') &&
            !candidate.toLowerCase().contains('acct') &&
            !candidate.toLowerCase().contains('you') &&
            !candidate.toLowerCase().contains('msg')) {
          merchant = candidate;
        }
      }

      if (merchant == 'Unknown') {
        // Pass 1: Look for "at", "to" without generics
        merchant =
            findEntity(['to', 'at', 'via', 'for'], allowGenerics: false) ??
            'Unknown';
      }

      if (merchant == 'Unknown') {
        // Pass 2: Fallback to "using" with generics (e.g. "using ICICI Bank Card")
        merchant =
            findEntity(['using', 'via'], allowGenerics: true) ?? 'Unknown';
      }

      // Fallback: Check for "Info: [Merchant]" or start of message
      if (merchant == 'Unknown') {
        final headerMatch = RegExp(
          r'^([A-Za-z0-9\s&]{3,20})[:\-]',
        ).firstMatch(body);
        if (headerMatch != null) {
          final val = headerMatch.group(1)?.trim();
          if (val != null &&
              !val.toLowerCase().contains('info') &&
              !val.toLowerCase().contains('alert') &&
              !val.toLowerCase().contains('txn')) {
            merchant = val;
          }
        }
      }
    } else {
      merchant = findEntity(['from', 'by'], allowGenerics: true) ?? 'Unknown';
    }

    // Cleanup Merchant
    if (merchant == 'Unknown' || merchant.toLowerCase().contains('unknown')) {
      if (!RegExp(r'\d').hasMatch(sender) && sender.length > 2) {
        merchant = sender;
      }
    }

    // Truncate if too long
    if (merchant.length > 20) merchant = merchant.substring(0, 20);

    // 4. Determine Category
    String category = 'Uncategorized';
    if (isDebit) {
      category = _getCategory(merchant, body);
    } else {
      category = 'Income';
    }

    return SmsTransaction(
      sender: sender,
      body: body,
      date: date,
      amount: amount,
      merchant: merchant,
      isDebit: isDebit,
      category: category,
    );
  }
}
