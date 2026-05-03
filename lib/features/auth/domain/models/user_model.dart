import 'package:cloud_firestore/cloud_firestore.dart';

enum UserRole { superAdmin, gymOwner, trainer, member }

class UserModel {
  final String id;
  final String name;
  final String email;
  final UserRole role;
  final String? gymId;
  final DateTime createdAt;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.gymId,
    required this.createdAt,
  });

  factory UserModel.fromMap(Map<String, dynamic> map, String documentId) {
    return UserModel(
      id: documentId,
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      role: UserRole.values.firstWhere(
        (e) => e.name == map['role'],
        orElse: () => UserRole.member,
      ),
      gymId: map['gymId'],
      createdAt: (map['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'role': role.name,
      'gymId': gymId,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
