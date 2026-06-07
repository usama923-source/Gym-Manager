import 'package:cloud_firestore/cloud_firestore.dart';

class WeightEntry {
  final DateTime date;
  final double weight;

  WeightEntry({required this.date, required this.weight});

  factory WeightEntry.fromMap(Map<String, dynamic> map) {
    return WeightEntry(
      date: (map['date'] as Timestamp).toDate(),
      weight: (map['weight'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'date': Timestamp.fromDate(date),
      'weight': weight,
    };
  }
}

class InjuryEntry {
  final DateTime date;
  final String description;
  final String notes;

  InjuryEntry({required this.date, required this.description, this.notes = ''});

  factory InjuryEntry.fromMap(Map<String, dynamic> map) {
    return InjuryEntry(
      date: (map['date'] as Timestamp).toDate(),
      description: map['description'] ?? '',
      notes: map['notes'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'date': Timestamp.fromDate(date),
      'description': description,
      'notes': notes,
    };
  }
}

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
  final bool? isDeleted;
  final DateTime? deletedAt;

  // Progress/History fields
  final List<WeightEntry> weightHistory;
  final List<InjuryEntry> injuryHistory;

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
    this.isDeleted,
    this.deletedAt,
    this.weightHistory = const [],
    this.injuryHistory = const [],
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
      isDeleted: map['isDeleted'],
      deletedAt: map['deletedAt'] != null ? (map['deletedAt'] as Timestamp).toDate() : null,
      weightHistory: (map['weightHistory'] as List?)
              ?.map((e) => WeightEntry.fromMap(Map<String, dynamic>.from(e)))
              .toList() ??
          const [],
      injuryHistory: (map['injuryHistory'] as List?)
              ?.map((e) => InjuryEntry.fromMap(Map<String, dynamic>.from(e)))
              .toList() ??
          const [],
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
      if (isDeleted != null) 'isDeleted': isDeleted,
      if (deletedAt != null) 'deletedAt': Timestamp.fromDate(deletedAt!),
      'weightHistory': weightHistory.map((e) => e.toMap()).toList(),
      'injuryHistory': injuryHistory.map((e) => e.toMap()).toList(),
    };
  }

  MemberModel copyWith({
    String? id,
    String? gymId,
    String? name,
    String? phone,
    String? email,
    String? membershipType,
    DateTime? startDate,
    DateTime? expiryDate,
    String? trainerId,
    bool? isActive,
    DateTime? createdAt,
    String? profilePhotoUrl,
    String? gender,
    String? memberId,
    double? monthlyPlanAmount,
    DateTime? paymentDate,
    double? paidAmount,
    String? paymentMethod,
    double? admissionFee,
    DateTime? dateOfBirth,
    String? address,
    bool? isDeleted,
    DateTime? deletedAt,
    List<WeightEntry>? weightHistory,
    List<InjuryEntry>? injuryHistory,
  }) {
    return MemberModel(
      id: id ?? this.id,
      gymId: gymId ?? this.gymId,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      membershipType: membershipType ?? this.membershipType,
      startDate: startDate ?? this.startDate,
      expiryDate: expiryDate ?? this.expiryDate,
      trainerId: trainerId ?? this.trainerId,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      profilePhotoUrl: profilePhotoUrl ?? this.profilePhotoUrl,
      gender: gender ?? this.gender,
      memberId: memberId ?? this.memberId,
      monthlyPlanAmount: monthlyPlanAmount ?? this.monthlyPlanAmount,
      paymentDate: paymentDate ?? this.paymentDate,
      paidAmount: paidAmount ?? this.paidAmount,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      admissionFee: admissionFee ?? this.admissionFee,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      address: address ?? this.address,
      isDeleted: isDeleted ?? this.isDeleted,
      deletedAt: deletedAt ?? this.deletedAt,
      weightHistory: weightHistory ?? this.weightHistory,
      injuryHistory: injuryHistory ?? this.injuryHistory,
    );
  }
}
