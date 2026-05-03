import 'package:cloud_firestore/cloud_firestore.dart';

class PaymentModel {
  final String id;
  final String gymId;
  final String memberId;
  final double amount;
  final DateTime paymentDate;
  final String paymentMethod;
  final DateTime createdAt;

  PaymentModel({
    required this.id,
    required this.gymId,
    required this.memberId,
    required this.amount,
    required this.paymentDate,
    required this.paymentMethod,
    required this.createdAt,
  });

  factory PaymentModel.fromMap(Map<String, dynamic> map, String documentId) {
    return PaymentModel(
      id: documentId,
      gymId: map['gymId'] ?? '',
      memberId: map['memberId'] ?? '',
      amount: (map['amount'] ?? 0.0).toDouble(),
      paymentDate: (map['paymentDate'] as Timestamp).toDate(),
      paymentMethod: map['paymentMethod'] ?? 'Cash',
      createdAt: (map['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'gymId': gymId,
      'memberId': memberId,
      'amount': amount,
      'paymentDate': Timestamp.fromDate(paymentDate),
      'paymentMethod': paymentMethod,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
