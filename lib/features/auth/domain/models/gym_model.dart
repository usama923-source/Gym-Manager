import 'package:cloud_firestore/cloud_firestore.dart';

class GymModel {
  final String id;
  final String gymName;
  final String ownerId;
  final DateTime subscriptionStart;
  final DateTime subscriptionEnd;
  final String subscriptionPlan;
  final double subscriptionPrice;
  final bool isActive;
  final DateTime createdAt;

  GymModel({
    required this.id,
    required this.gymName,
    required this.ownerId,
    required this.subscriptionStart,
    required this.subscriptionEnd,
    required this.subscriptionPlan,
    required this.subscriptionPrice,
    required this.isActive,
    required this.createdAt,
  });

  bool get isSubscriptionActive => DateTime.now().isBefore(subscriptionEnd);

  factory GymModel.fromMap(Map<String, dynamic> map, String documentId) {
    return GymModel(
      id: documentId,
      gymName: map['gymName'] ?? '',
      ownerId: map['ownerId'] ?? '',
      subscriptionStart: (map['subscriptionStart'] as Timestamp).toDate(),
      subscriptionEnd: (map['subscriptionEnd'] as Timestamp).toDate(),
      subscriptionPlan: map['subscriptionPlan'] ?? 'Basic',
      subscriptionPrice: (map['subscriptionPrice'] ?? 0.0).toDouble(),
      isActive: map['isActive'] ?? false,
      createdAt: (map['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'gymName': gymName,
      'ownerId': ownerId,
      'subscriptionStart': Timestamp.fromDate(subscriptionStart),
      'subscriptionEnd': Timestamp.fromDate(subscriptionEnd),
      'subscriptionPlan': subscriptionPlan,
      'subscriptionPrice': subscriptionPrice,
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
