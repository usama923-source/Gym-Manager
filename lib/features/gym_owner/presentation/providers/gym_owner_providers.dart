import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gym/features/auth/presentation/providers/auth_provider.dart';
import 'package:gym/features/gym_owner/domain/models/member_model.dart';
import 'package:gym/features/gym_owner/domain/models/attendance_model.dart';
import 'package:gym/features/gym_owner/domain/models/payment_model.dart';
import 'package:gym/features/gym_owner/domain/models/expense_model.dart';
import 'package:gym/features/gym_owner/data/repositories/gym_owner_repository.dart';

// Provides the current Gym ID based on authenticated user
final currentGymIdProvider = Provider<String?>((ref) {
  final authState = ref.watch(authControllerProvider);
  return authState.value?.gymId;
});

// Stream of Members
final membersProvider = StreamProvider<List<MemberModel>>((ref) {
  final gymId = ref.watch(currentGymIdProvider);
  if (gymId == null) return const Stream.empty();
  return ref.watch(gymOwnerRepositoryProvider).getMembers(gymId);
});

// Stream of Expenses
final expensesListProvider = StreamProvider<List<ExpenseModel>>((ref) {
  final gymId = ref.watch(currentGymIdProvider);
  if (gymId == null) return const Stream.empty();
  return ref.watch(gymOwnerRepositoryProvider).getExpenses(gymId);
});

// Derived States for the Dashboard Stats
final totalMembersProvider = Provider<int>((ref) {
  final membersResult = ref.watch(membersProvider);
  return membersResult.when(
    data: (members) => members.length,
    loading: () => 0,
    error: (error, stackTrace) => 0,
  );
});

final activeMembersProvider = Provider<int>((ref) {
  final membersResult = ref.watch(membersProvider);
  return membersResult.when(
    data: (members) => members.where((m) => m.isMembershipActive).length,
    loading: () => 0,
    error: (error, stackTrace) => 0,
  );
});

final expiringMembersProvider = Provider<List<MemberModel>>((ref) {
  final membersResult = ref.watch(membersProvider);
  return membersResult.when(
    data: (members) {
      final now = DateTime.now();
      final threeDaysFromNow = now.add(const Duration(days: 3));
      return members.where((m) {
        final expiry = m.expiryDate;
        if (expiry == null) return false;
        return expiry.isAfter(now) && expiry.isBefore(threeDaysFromNow);
      }).toList();
    },
    loading: () => [],
    error: (error, stackTrace) => [],
  );
});

final expiringTodayProvider = Provider<List<MemberModel>>((ref) {
  final membersResult = ref.watch(membersProvider);
  return membersResult.when(
    data: (members) {
      final now = DateTime.now();
      return members.where((m) {
        final expiry = m.expiryDate;
        if (expiry == null) return false;
        return expiry.year == now.year && expiry.month == now.month && expiry.day == now.day;
      }).toList();
    },
    loading: () => [],
    error: (error, stackTrace) => [],
  );
});

final birthdaysThisMonthProvider = Provider<List<MemberModel>>((ref) {
  final membersResult = ref.watch(membersProvider);
  return membersResult.when(
    data: (members) {
      final now = DateTime.now();
      return members.where((m) {
        final dob = m.dateOfBirth;
        if (dob == null) return false;
        return dob.month == now.month;
      }).toList();
    },
    loading: () => [],
    error: (error, stackTrace) => [],
  );
});

final todayAttendanceProvider = StreamProvider<List<AttendanceModel>>((ref) {
  final gymId = ref.watch(currentGymIdProvider);
  if (gymId == null) return const Stream.empty();
  return ref.watch(gymOwnerRepositoryProvider).getTodayAttendance(gymId);
});

// Analytics
final monthlyIncomeProvider = StreamProvider<double>((ref) {
  final gymId = ref.watch(currentGymIdProvider);
  if (gymId == null) return Stream.value(0.0);
  final now = DateTime.now();
  return ref.watch(gymOwnerRepositoryProvider).getMonthlyIncome(gymId, now.month, now.year);
});

final monthlyExpensesProvider = StreamProvider<double>((ref) {
  final gymId = ref.watch(currentGymIdProvider);
  if (gymId == null) return Stream.value(0.0);
  final now = DateTime.now();
  return ref.watch(gymOwnerRepositoryProvider).getMonthlyExpenses(gymId, now.month, now.year);
});

final netProfitProvider = Provider<double>((ref) {
  final income = ref.watch(monthlyIncomeProvider).value ?? 0.0;
  final expense = ref.watch(monthlyExpensesProvider).value ?? 0.0;
  return income - expense;
});

// Member Specific Providers
final memberPaymentsProvider = StreamProvider.family<List<PaymentModel>, String>((ref, memberId) {
  return ref.watch(gymOwnerRepositoryProvider).getMemberPayments(memberId);
});

final memberAttendancesProvider = StreamProvider.family<List<AttendanceModel>, String>((ref, memberId) {
  return ref.watch(gymOwnerRepositoryProvider).getMemberAttendances(memberId);
});
