import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String email;
  final String role;                 // "student", "employer", "admin"
  final String fullName;
  final String address;
  final String profilePictureUrl;
  final String pictureRecognition;
  final List<String> skills;
  final List<double> vector;
  final DateTime? createdAt;

  UserModel({
    required this.uid,
    required this.email,
    required this.role,
    required this.fullName,
    this.address = '',
    this.profilePictureUrl = '',
    this.pictureRecognition = '',
    this.skills = const [],
    this.vector = const [],
    this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'role': role,
      'fullName': fullName,
      'address': address,
      'profilePictureUrl': profilePictureUrl,
      'pictureRecognition': pictureRecognition,
      'skills': skills,
      'vector': vector,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }

  factory UserModel.fromMap(String uid, Map<String, dynamic> map) {
    return UserModel(
      uid: uid,
      email: map['email'] ?? '',
      role: map['role'] ?? 'student',
      fullName: map['fullName'] ?? '',
      address: map['address'] ?? '',
      profilePictureUrl: map['profilePictureUrl'] ?? '',
      pictureRecognition: map['pictureRecognition'] ?? '',
      skills: List<String>.from(map['skills'] ?? []),
      vector: List<double>.from(map['vector'] ?? []),
      createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  UserModel copyWith({
  String? email,
  String? role,
  String? fullName,
  String? address,
  String? profilePictureUrl,
  String? pictureRecognition,
  List<String>? skills,
  List<double>? vector,
  DateTime? createdAt,
  }) {
    return UserModel(
      uid: uid,
      email: email ?? this.email,
      role: role ?? this.role,
      fullName: fullName ?? this.fullName,
      address: address ?? this.address,
      profilePictureUrl: profilePictureUrl ?? this.profilePictureUrl,
      pictureRecognition: pictureRecognition ?? this.pictureRecognition,
      skills: skills ?? this.skills,
      vector: vector ?? this.vector,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}