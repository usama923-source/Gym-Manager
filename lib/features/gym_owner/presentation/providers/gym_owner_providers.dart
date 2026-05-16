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

// State for Members Status Filter (All, Active, etc.)
class MembersStatusFilterNotifier extends Notifier<String> {
  @override
  String build() => 'All';

  void setFilter(String filter) {
    state = filter;
  }
}

final membersStatusFilterProvider =
    NotifierProvider<MembersStatusFilterNotifier, String>(
      MembersStatusFilterNotifier.new,
    );

// Stream of Members
final membersProvider = StreamProvider<List<MemberModel>>((ref) {
  final gymId = ref.watch(currentGymIdProvider);
  if (gymId == null) return const Stream.empty();
  return ref.watch(gymOwnerRepositoryProvider).getMembers(gymId);
});

// Stream of Deleted Members
final deletedMembersProvider = StreamProvider<List<MemberModel>>((ref) {
  final gymId = ref.watch(currentGymIdProvider);
  if (gymId == null) return const Stream.empty();
  return ref.watch(gymOwnerRepositoryProvider).getDeletedMembers(gymId);
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
        return expiry.year == now.year &&
            expiry.month == now.month &&
            expiry.day == now.day;
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
  return ref
      .watch(gymOwnerRepositoryProvider)
      .getMonthlyIncome(gymId, now.month, now.year);
});

final monthlyPaymentsListProvider = StreamProvider<List<PaymentModel>>((ref) {
  final gymId = ref.watch(currentGymIdProvider);
  if (gymId == null) return const Stream.empty();
  final now = DateTime.now();
  return ref
      .watch(gymOwnerRepositoryProvider)
      .getMonthlyPaymentsList(gymId, now.month, now.year);
});

final monthlyExpensesProvider = StreamProvider<double>((ref) {
  final gymId = ref.watch(currentGymIdProvider);
  if (gymId == null) return Stream.value(0.0);
  final now = DateTime.now();
  return ref
      .watch(gymOwnerRepositoryProvider)
      .getMonthlyExpenses(gymId, now.month, now.year);
});

final netProfitProvider = Provider<double>((ref) {
  final income = ref.watch(monthlyIncomeProvider).value ?? 0.0;
  final expense = ref.watch(monthlyExpensesProvider).value ?? 0.0;
  return income - expense;
});

final memberPaymentsProvider =
    StreamProvider.family<List<PaymentModel>, String>((ref, memberId) {
      return ref.watch(gymOwnerRepositoryProvider).getMemberPayments(memberId);
    });

final memberAttendancesProvider =
    StreamProvider.family<List<AttendanceModel>, String>((ref, memberId) {
      return ref
          .watch(gymOwnerRepositoryProvider)
          .getMemberAttendances(memberId);
    });

// ─── Report Screen Filter ────────────────────────────────────────────────────

class ReportDateRange {
  final DateTime from;
  final DateTime to;
  const ReportDateRange({required this.from, required this.to});

  ReportDateRange copyWith({DateTime? from, DateTime? to}) =>
      ReportDateRange(from: from ?? this.from, to: to ?? this.to);
}

class ReportFilterNotifier extends Notifier<ReportDateRange> {
  @override
  ReportDateRange build() {
    final now = DateTime.now();
    return ReportDateRange(
      from: DateTime(now.year, now.month, 1),
      to: DateTime(now.year, now.month + 1, 0),
    );
  }

  void setThisMonth() {
    final now = DateTime.now();
    state = ReportDateRange(
      from: DateTime(now.year, now.month, 1),
      to: DateTime(now.year, now.month + 1, 0),
    );
  }

  void setLastMonth() {
    final now = DateTime.now();
    final lastMonth = now.month == 1 ? 12 : now.month - 1;
    final year = now.month == 1 ? now.year - 1 : now.year;
    state = ReportDateRange(
      from: DateTime(year, lastMonth, 1),
      to: DateTime(year, lastMonth + 1, 0),
    );
  }

  void setThisWeek() {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    state = ReportDateRange(
      from: DateTime(weekStart.year, weekStart.month, weekStart.day),
      to: now,
    );
  }

  void setThisYear() {
    final now = DateTime.now();
    state = ReportDateRange(
      from: DateTime(now.year, 1, 1),
      to: DateTime(now.year, 12, 31),
    );
  }

  void setCustom(DateTime from, DateTime to) {
    state = ReportDateRange(from: from, to: to);
  }
}

final reportFilterProvider =
    NotifierProvider<ReportFilterNotifier, ReportDateRange>(
  ReportFilterNotifier.new,
);

final reportPaymentsProvider = StreamProvider<List<PaymentModel>>((ref) {
  final gymId = ref.watch(currentGymIdProvider);
  if (gymId == null) return const Stream.empty();
  final filter = ref.watch(reportFilterProvider);
  return ref
      .watch(gymOwnerRepositoryProvider)
      .getPaymentsByDateRange(gymId, filter.from, filter.to);
});

final reportExpensesProvider = StreamProvider<List<ExpenseModel>>((ref) {
  final gymId = ref.watch(currentGymIdProvider);
  if (gymId == null) return const Stream.empty();
  final filter = ref.watch(reportFilterProvider);
  return ref
      .watch(gymOwnerRepositoryProvider)
      .getExpensesByDateRange(gymId, filter.from, filter.to);
});

final last12MonthsIncomeProvider = FutureProvider<List<double>>((ref) async {
  final gymId = ref.watch(currentGymIdProvider);
  if (gymId == null) return List.filled(12, 0.0);
  return ref.watch(gymOwnerRepositoryProvider).getLast12MonthsIncome(gymId);
});

final last12MonthsExpensesProvider = FutureProvider<List<double>>((ref) async {
  final gymId = ref.watch(currentGymIdProvider);
  if (gymId == null) return List.filled(12, 0.0);
  return ref.watch(gymOwnerRepositoryProvider).getLast12MonthsExpenses(gymId);
});

