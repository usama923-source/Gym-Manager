import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gym/features/auth/presentation/providers/auth_provider.dart';
import 'package:gym/features/gym_owner/domain/models/member_model.dart';
import 'package:gym/features/gym_owner/domain/models/workout_model.dart';
import 'package:gym/features/member/data/repositories/member_repository.dart';

final myDetailsProvider = StreamProvider<MemberModel?>((ref) {
  final authState = ref.watch(authControllerProvider);
  final memberId = authState.value?.id;
  
  if (memberId == null) return Stream.value(null);
  
  return ref.watch(memberRepositoryProvider).getMyDetails(memberId);
});

final myWorkoutsProvider = StreamProvider<List<WorkoutModel>>((ref) {
  final authState = ref.watch(authControllerProvider);
  final memberId = authState.value?.id;
  
  if (memberId == null) return const Stream.empty();
  
  return ref.watch(memberRepositoryProvider).getMyWorkouts(memberId);
});
