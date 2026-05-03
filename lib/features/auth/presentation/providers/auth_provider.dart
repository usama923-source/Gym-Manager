import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gym/features/auth/data/repositories/auth_repository.dart';
import 'package:gym/features/auth/domain/models/user_model.dart';
import 'package:gym/features/gym_owner/data/repositories/gym_owner_repository.dart';

final authControllerProvider = NotifierProvider<AuthController, AsyncValue<UserModel?>>(
  AuthController.new,
);

class AuthController extends Notifier<AsyncValue<UserModel?>> {
  late final AuthRepository _authRepository;

  @override
  AsyncValue<UserModel?> build() {
    _authRepository = ref.watch(authRepositoryProvider);
    _init();
    return const AsyncValue.loading();
  }

  Future<void> _init() async {
    _authRepository.authStateChanges.listen((user) async {
      if (user == null) {
        state = const AsyncValue.data(null);
      } else {
        try {
          final userData = await _authRepository.getUserData(user.uid);
          state = AsyncValue.data(userData);
        } catch (e) {
          state = AsyncValue.error(e, StackTrace.current);
        }
      }
    });
  }

  Future<void> login(String email, String password) async {
    state = const AsyncValue.loading();
    try {
      final user = await _authRepository.login(email, password);
      state = AsyncValue.data(user);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      rethrow; // Used for UI to catch and show snackbar
    }
  }

  Future<void> registerGymOwner({
    required String ownerName,
    required String email,
    required String password,
    required String gymName,
  }) async {
    state = const AsyncValue.loading();
    try {
      final user = await _authRepository.registerGymOwner(
        ownerName: ownerName,
        email: email,
        password: password,
        gymName: gymName,
      );
      state = AsyncValue.data(user);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      rethrow;
    }
  }

  Future<void> updateProfileData(String newName, String newEmail, String newGymName) async {
    if (state.value == null) return;
    try {
      final user = state.value!;
      
      if (user.name != newName) {
        await _authRepository.updateProfile(uid: user.id, name: newName);
      }
      
      if (user.email != newEmail) {
        await _authRepository.updateEmail(uid: user.id, newEmail: newEmail);
      }
      
      if (user.gymId != null && newGymName.isNotEmpty) {
        final gymOwnerRepo = ref.read(gymOwnerRepositoryProvider);
        await gymOwnerRepo.updateGymName(user.gymId!, newGymName);
      }

      final updatedUser = UserModel(
        id: user.id,
        name: newName,
        email: newEmail,
        role: user.role,
        gymId: user.gymId,
        createdAt: user.createdAt,
      );
      state = AsyncValue.data(updatedUser);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> changePassword(String newPassword) async {
    try {
      await _authRepository.changePassword(newPassword);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> logout() async {
    state = const AsyncValue.loading();
    await _authRepository.logout();
    state = const AsyncValue.data(null);
  }

  Future<void> registerSuperAdmin() async {
    state = const AsyncValue.loading();
    try {
      final user = await _authRepository.registerSuperAdmin();
      state = AsyncValue.data(user);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      rethrow;
    }
  }
}
