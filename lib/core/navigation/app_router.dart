import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:gym/features/auth/domain/models/user_model.dart';
import 'package:gym/features/auth/presentation/providers/auth_provider.dart';

import 'package:gym/features/auth/presentation/login_screen.dart';
import 'package:gym/features/auth/presentation/register_owner_screen.dart';
import 'package:gym/features/super_admin/super_admin_dashboard.dart';
import 'package:gym/features/gym_owner/presentation/gym_owner_main_screen.dart';
import 'package:gym/features/trainer/trainer_dashboard.dart';
import 'package:gym/features/member/member_dashboard.dart';
import 'package:gym/features/gym_owner/presentation/add_member_screen.dart';
import 'package:gym/features/gym_owner/presentation/edit_profile_screen.dart';
import 'package:gym/features/gym_owner/presentation/expenses_screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authControllerProvider);

  return GoRouter(
    initialLocation: '/login',
    redirect: (context, state) {
      final isLoginRoute = state.matchedLocation == '/login' || state.matchedLocation == '/register';

      // Still loading
      if (authState.isLoading) return null;

      // Unauthenticated
      if (!authState.hasValue || authState.value == null) {
        return isLoginRoute ? null : '/login';
      }

      // Authenticated but trying to access login/register
      if (isLoginRoute) {
        final user = authState.value!;
        return _getInitialRouteForRole(user.role);
      }

      return null; // Let the navigation happen
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterOwnerScreen(),
      ),
      GoRoute(
        path: '/super-admin',
        builder: (context, state) => const SuperAdminDashboard(),
      ),
      GoRoute(
        path: '/gym-owner',
        builder: (context, state) => const GymOwnerMainScreen(),
      ),
      GoRoute(
        path: '/trainer',
        builder: (context, state) => const TrainerDashboard(),
      ),
      GoRoute(
        path: '/member',
        builder: (context, state) => const MemberDashboard(),
      ),
      GoRoute(
        path: '/add-member',
        builder: (context, state) => const AddMemberScreen(),
      ),
      GoRoute(
        path: '/edit-profile',
        builder: (context, state) => const EditProfileScreen(),
      ),
      GoRoute(
        path: '/expenses',
        builder: (context, state) => const ExpensesScreen(),
      ),
    ],
  );
});

String _getInitialRouteForRole(UserRole role) {
  switch (role) {
    case UserRole.superAdmin:
      return '/super-admin';
    case UserRole.gymOwner:
      return '/gym-owner';
    case UserRole.trainer:
      return '/trainer';
    case UserRole.member:
      return '/member';
  }
}
