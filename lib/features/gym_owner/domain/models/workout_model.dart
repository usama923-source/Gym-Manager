import 'package:cloud_firestore/cloud_firestore.dart';

class Exercise {
  final String name;
  final int sets;
  final int reps;

  Exercise({required this.name, required this.sets, required this.reps});

  factory Exercise.fromMap(Map<String, dynamic> map) {
    return Exercise(
      name: map['name'] ?? '',
      sets: map['sets'] ?? 0,
      reps: map['reps'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'sets': sets,
      'reps': reps,
    };
  }
}

class WorkoutModel {
  final String id;
  final String gymId;
  final String memberId;
  final String trainerId;
  final List<Exercise> exercises;
  final String notes;
  final DateTime createdAt;

  WorkoutModel({
    required this.id,
    required this.gymId,
    required this.memberId,
    required this.trainerId,
    required this.exercises,
    required this.notes,
    required this.createdAt,
  });

  factory WorkoutModel.fromMap(Map<String, dynamic> map, String documentId) {
    var list = map['exercises'] as List? ?? [];
    return WorkoutModel(
      id: documentId,
      gymId: map['gymId'] ?? '',
      memberId: map['memberId'] ?? '',
      trainerId: map['trainerId'] ?? '',
      exercises: list.map((e) => Exercise.fromMap(e)).toList(),
      notes: map['notes'] ?? '',
      createdAt: (map['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'gymId': gymId,
      'memberId': memberId,
      'trainerId': trainerId,
      'exercises': exercises.map((e) => e.toMap()).toList(),
      'notes': notes,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
