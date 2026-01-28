import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String? firstName;
  final String? lastName;
  final String? email;
  final String? phone;
  final String? address;
  final String? role;
  final String? profileImage;
  final double? currentBalance;
  final int? age; // Added age field
  final Timestamp? createdAt;
  final Timestamp? updatedAt;

  UserModel({
    required this.uid,
    this.firstName,
    this.lastName,
    this.email,
    this.phone,
    this.address,
    this.role,
    this.profileImage,
    this.currentBalance,
    this.age,
    this.createdAt,
    this.updatedAt,
  });

  factory UserModel.fromMap(String uid, Map<String, dynamic>? map) {
    if (map == null) return UserModel(uid: uid);
    return UserModel(
      uid: uid,
      firstName: map['firstName'],
      lastName: map['lastName'],
      email: map['email'],
      phone: map['phone'],
      address: map['address'],
      role: map['role'],
      profileImage: map['profileImage'],
      currentBalance: map['currentBalance'] != null
          ? (map['currentBalance'] as num).toDouble()
          : null,
      age: map['age'] != null ? (map['age'] as num).toInt() : null,
      createdAt: map['createdAt'],
      updatedAt: map['updatedAt'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'firstName': firstName ?? '',
      'lastName': lastName ?? '',
      'email': email ?? '',
      'phone': phone ?? '',
      'address': address ?? '',
      'role': role ?? '',
      'profileImage': profileImage ?? '',
      'currentBalance': currentBalance ?? 0.0,
      'age': age,
      'createdAt': createdAt,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}
