import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gym/features/auth/domain/models/gym_model.dart';
import 'package:gym/features/auth/domain/models/user_model.dart';
import 'package:gym/features/super_admin/data/super_admin_repository.dart';
import 'package:gym/features/auth/data/repositories/auth_repository.dart';

// Stream of all Gyms from Firestore
final allGymsProvider = StreamProvider<List<GymModel>>((ref) {
  final repository = ref.watch(superAdminRepositoryProvider);
  return repository.getAllGyms();
});

// Fetch Gym Owner details
final gymOwnerProvider = FutureProvider.family<UserModel?, String>((ref, ownerId) {
  final repository = ref.watch(authRepositoryProvider);
  return repository.getUserData(ownerId);
});

// Admin Actions Controller
final superAdminControllerProvider = Provider<SuperAdminController>((ref) {
  final repository = ref.watch(superAdminRepositoryProvider);
  return SuperAdminController(repository);
});

class SuperAdminController {
  final SuperAdminRepository _repository;

  SuperAdminController(this._repository);

  Future<void> toggleGymStatus(String gymId, bool currentStatus) async {
    await _repository.updateGymStatus(gymId, !currentStatus);
  }

  Future<void> extendSubscription(String gymId, int days) async {
    await _repository.extendSubscription(gymId, days);
  }

  Future<void> deleteGym(String gymId, String ownerId) async {
    await _repository.deleteGym(gymId, ownerId);
  }
}

// Derived states for the Dashboard Stats
final totalGymsProvider = Provider<int>((ref) {
  final gymsAsyncValue = ref.watch(allGymsProvider);
  return gymsAsyncValue.when(
    data: (gyms) => gyms.length,
    loading: () => 0,
    error: (_, __) => 0,
  );
});

final activeGymsProvider = Provider<int>((ref) {
  final gymsAsyncValue = ref.watch(allGymsProvider);
  return gymsAsyncValue.when(
    data: (gyms) => gyms.where((g) => g.isActive && g.isSubscriptionActive).length,
    loading: () => 0,
    error: (_, __) => 0,
  );
});

final expiredGymsProvider = Provider<int>((ref) {
  final gymsAsyncValue = ref.watch(allGymsProvider);
  return gymsAsyncValue.when(
    data: (gyms) => gyms.where((g) => !g.isSubscriptionActive).length,
    loading: () => 0,
    error: (_, __) => 0,
  );
});

final expiringSoonGymsProvider = Provider<List<GymModel>>((ref) {
  final gymsAsyncValue = ref.watch(allGymsProvider);
  return gymsAsyncValue.when(
    data: (gyms) {
      final now = DateTime.now();
      final threeDaysFromNow = now.add(const Duration(days: 3));
      return gyms.where((g) => 
        g.subscriptionEnd.isAfter(now) && 
        g.subscriptionEnd.isBefore(threeDaysFromNow)
      ).toList();
    },
    loading: () => [],
    error: (_, __) => [],
  );
});
