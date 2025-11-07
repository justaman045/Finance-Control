import 'package:cloud_firestore/cloud_firestore.dart';

class TransactionModel {
  final String id;
  final String senderId;
  final String recipientId;
  final String recipientName;
  final double amount;
  final String currency;
  final double tax;
  final String? note;
  final String? category;
  final DateTime date;
  final String? attachmentUrl; // Could be avatar url or similar
  final String? status;
  final Timestamp? createdAt;

  TransactionModel({
    required this.id,
    required this.senderId,
    required this.recipientId,
    required this.recipientName,
    required this.amount,
    required this.currency,
    required this.tax,
    this.note,
    this.category,
    required this.date,
    this.attachmentUrl,
    this.status,
    this.createdAt,
  });

  double get total => amount + tax;

  String? get recipientAvatar => attachmentUrl;

  factory TransactionModel.fromMap(String id, Map<String, dynamic> map) {
    return TransactionModel(
      id: id,
      senderId: map['senderId'],
      recipientId: map['recipientId'],
      recipientName: map['recipientName'] ?? '',
      amount: (map['amount'] ?? 0).toDouble(),
      currency: map['currency'] ?? '',
      tax: (map['tax'] ?? 0).toDouble(),
      note: map['note'],
      category: map['category'],
      date: (map['date'] as Timestamp).toDate(),
      attachmentUrl: map['attachmentUrl'],
      status: map['status'] ?? 'success',
      createdAt: map['createdAt'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'senderId': senderId,
      'recipientId': recipientId,
      'recipientName': recipientName,
      'amount': amount,
      'currency': currency,
      'tax': tax,
      'note': note,
      'category': category,
      'date': Timestamp.fromDate(date),
      'attachmentUrl': attachmentUrl,
      'status': status ?? 'success',
      'createdAt': createdAt ?? FieldValue.serverTimestamp(),
    };
  }
}
