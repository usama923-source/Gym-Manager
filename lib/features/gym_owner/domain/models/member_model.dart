import 'package:cloud_firestore/cloud_firestore.dart';

class MemberModel {
  final String id; // document ID
  final String gymId;
  final String name;
  final String? phone;
  final String? email;
  final String? membershipType;
  final DateTime? startDate;
  final DateTime? expiryDate;
  final String? trainerId;
  final bool isActive;
  final DateTime createdAt;

  // New optional fields
  final String? profilePhotoUrl;
  final String? gender;
  final String? memberId; // e.g. MEM-001
  final double? monthlyPlanAmount;
  final DateTime? paymentDate;
  final double? paidAmount;
  final String? paymentMethod;
  final double? admissionFee;
  final DateTime? dateOfBirth;
  final String? address;

  MemberModel({
    required this.id,
    required this.gymId,
    required this.name,
    this.phone,
    this.email,
    this.membershipType,
    this.startDate,
    this.expiryDate,
    this.trainerId,
    required this.isActive,
    required this.createdAt,
    this.profilePhotoUrl,
    this.gender,
    this.memberId,
    this.monthlyPlanAmount,
    this.paymentDate,
    this.paidAmount,
    this.paymentMethod,
    this.admissionFee,
    this.dateOfBirth,
    this.address,
  });

  bool get isMembershipActive => expiryDate != null 
      ? DateTime.now().isBefore(expiryDate!) && isActive 
      : isActive;

  factory MemberModel.fromMap(Map<String, dynamic> map, String documentId) {
    return MemberModel(
      id: documentId,
      gymId: map['gymId'] ?? '',
      name: map['name'] ?? '',
      phone: map['phone'],
      email: map['email'],
      membershipType: map['membershipType'],
      startDate: map['startDate'] != null ? (map['startDate'] as Timestamp).toDate() : null,
      expiryDate: map['expiryDate'] != null ? (map['expiryDate'] as Timestamp).toDate() : null,
      trainerId: map['trainerId'],
      isActive: map['isActive'] ?? false,
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      profilePhotoUrl: map['profilePhotoUrl'],
      gender: map['gender'],
      memberId: map['memberId'],
      monthlyPlanAmount: (map['monthlyPlanAmount'] as num?)?.toDouble(),
      paymentDate: map['paymentDate'] != null ? (map['paymentDate'] as Timestamp).toDate() : null,
      paidAmount: (map['paidAmount'] as num?)?.toDouble(),
      paymentMethod: map['paymentMethod'],
      admissionFee: (map['admissionFee'] as num?)?.toDouble(),
      dateOfBirth: map['dateOfBirth'] != null ? (map['dateOfBirth'] as Timestamp).toDate() : null,
      address: map['address'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'gymId': gymId,
      'name': name,
      if (phone != null) 'phone': phone,
      if (email != null) 'email': email,
      if (membershipType != null) 'membershipType': membershipType,
      if (startDate != null) 'startDate': Timestamp.fromDate(startDate!),
      if (expiryDate != null) 'expiryDate': Timestamp.fromDate(expiryDate!),
      if (trainerId != null) 'trainerId': trainerId,
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
      if (profilePhotoUrl != null) 'profilePhotoUrl': profilePhotoUrl,
      if (gender != null) 'gender': gender,
      if (memberId != null) 'memberId': memberId,
      if (monthlyPlanAmount != null) 'monthlyPlanAmount': monthlyPlanAmount,
      if (paymentDate != null) 'paymentDate': Timestamp.fromDate(paymentDate!),
      if (paidAmount != null) 'paidAmount': paidAmount,
      if (paymentMethod != null) 'paymentMethod': paymentMethod,
      if (admissionFee != null) 'admissionFee': admissionFee,
      if (dateOfBirth != null) 'dateOfBirth': Timestamp.fromDate(dateOfBirth!),
      if (address != null) 'address': address,
    };
  }
}
