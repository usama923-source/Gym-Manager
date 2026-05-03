import 'package:cloud_firestore/cloud_firestore.dart';

class ExpenseModel {
  final String id;
  final String gymId;
  final String title;
  final String description;
  final double amount;
  final DateTime date;
  final DateTime createdAt;

  ExpenseModel({
    required this.id,
    required this.gymId,
    required this.title,
    this.description = '',
    required this.amount,
    required this.date,
    required this.createdAt,
  });

  factory ExpenseModel.fromMap(Map<String, dynamic> map, String documentId) {
    return ExpenseModel(
      id: documentId,
      gymId: map['gymId'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      amount: (map['amount'] ?? 0.0).toDouble(),
      date: (map['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'gymId': gymId,
      'title': title,
      'description': description,
      'amount': amount,
      'date': Timestamp.fromDate(date),
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
