import 'package:cloud_firestore/cloud_firestore.dart';

class AttendanceModel {
  final String id;
  final String gymId;
  final String memberId;
  final DateTime date;
  final DateTime checkInTime;
  final DateTime? checkOutTime;

  AttendanceModel({
    required this.id,
    required this.gymId,
    required this.memberId,
    required this.date,
    required this.checkInTime,
    this.checkOutTime,
  });

  factory AttendanceModel.fromMap(Map<String, dynamic> map, String documentId) {
    return AttendanceModel(
      id: documentId,
      gymId: map['gymId'] ?? '',
      memberId: map['memberId'] ?? '',
      date: (map['date'] as Timestamp).toDate(),
      checkInTime: (map['checkInTime'] as Timestamp).toDate(),
      checkOutTime: map['checkOutTime'] != null ? (map['checkOutTime'] as Timestamp).toDate() : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'gymId': gymId,
      'memberId': memberId,
      'date': Timestamp.fromDate(date),
      'checkInTime': Timestamp.fromDate(checkInTime),
      if (checkOutTime != null) 'checkOutTime': Timestamp.fromDate(checkOutTime!),
    };
  }
}
