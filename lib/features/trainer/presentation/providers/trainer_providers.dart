import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gym/features/auth/presentation/providers/auth_provider.dart';
import 'package:gym/features/gym_owner/domain/models/member_model.dart';
import 'package:gym/features/gym_owner/domain/models/workout_model.dart';
import 'package:gym/features/trainer/data/repositories/trainer_repository.dart';

final assignedMembersProvider = StreamProvider<List<MemberModel>>((ref) {
  final authState = ref.watch(authControllerProvider);
  final trainerId = authState.value?.id;
  
  if (trainerId == null) return const Stream.empty();
  
  return ref.watch(trainerRepositoryProvider).getAssignedMembers(trainerId);
});

final memberWorkoutsProvider = StreamProvider.family<List<WorkoutModel>, String>((ref, memberId) {
  return ref.watch(trainerRepositoryProvider).getMemberWorkouts(memberId);
});

final trainerControllerProvider = Provider<TrainerController>((ref) {
  return TrainerController(ref.watch(trainerRepositoryProvider));
});

class TrainerController {
  final TrainerRepository repository;
  
  TrainerController(this.repository);
  
  Future<void> createWorkout(WorkoutModel workout) async {
    await repository.createWorkoutPlan(workout);
  }
}
