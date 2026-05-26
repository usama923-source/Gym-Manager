import 'package:cloud_firestore/cloud_firestore.dart';

/// Transaction types for member payment ledger.
class TransactionType {
  static const String duePaid = 'due_paid';
  static const String refund = 'refund';
}

class MemberTransactionModel {
  final String id;
  final String gymId;
  final String memberId;

  /// Either [TransactionType.duePaid] or [TransactionType.refund].
  final String type;

  final double amount;
  final DateTime date;
  final String? paymentMethod; // Cash, Card, Online, Other
  final String? notes;
  final DateTime createdAt;

  MemberTransactionModel({
    required this.id,
    required this.gymId,
    required this.memberId,
    required this.type,
    required this.amount,
    required this.date,
    this.paymentMethod,
    this.notes,
    required this.createdAt,
  });

  bool get isDuePaid => type == TransactionType.duePaid;
  bool get isRefund => type == TransactionType.refund;

  factory MemberTransactionModel.fromMap(
      Map<String, dynamic> map, String documentId) {
    return MemberTransactionModel(
      id: documentId,
      gymId: map['gymId'] ?? '',
      memberId: map['memberId'] ?? '',
      type: map['type'] ?? TransactionType.duePaid,
      amount: (map['amount'] ?? 0.0).toDouble(),
      date: (map['date'] as Timestamp).toDate(),
      paymentMethod: map['paymentMethod'],
      notes: map['notes'],
      createdAt: (map['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'gymId': gymId,
      'memberId': memberId,
      'type': type,
      'amount': amount,
      'date': Timestamp.fromDate(date),
      if (paymentMethod != null) 'paymentMethod': paymentMethod,
      if (notes != null && notes!.isNotEmpty) 'notes': notes,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
