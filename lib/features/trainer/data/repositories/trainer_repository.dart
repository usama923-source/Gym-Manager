import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gym/features/gym_owner/domain/models/member_model.dart';
import 'package:gym/features/gym_owner/domain/models/workout_model.dart';

final trainerRepositoryProvider = Provider<TrainerRepository>((ref) {
  return TrainerRepository(FirebaseFirestore.instance);
});

class TrainerRepository {
  final FirebaseFirestore _firestore;

  TrainerRepository(this._firestore);

  // Get members assigned to this trainer
  Stream<List<MemberModel>> getAssignedMembers(String trainerId) {
    return _firestore
        .collection('members')
        .where('trainerId', isEqualTo: trainerId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => MemberModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  // Get workouts for a specific member created by this trainer (or generally)
  Stream<List<WorkoutModel>> getMemberWorkouts(String memberId) {
    return _firestore
        .collection('workouts')
        .where('memberId', isEqualTo: memberId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => WorkoutModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  Future<void> createWorkoutPlan(WorkoutModel workout) async {
    await _firestore.collection('workouts').doc().set(workout.toMap());
  }
}
