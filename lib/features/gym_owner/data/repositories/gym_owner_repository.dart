import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gym/features/gym_owner/domain/models/expense_model.dart';
import 'package:gym/features/gym_owner/domain/models/payment_model.dart';
import 'package:gym/features/gym_owner/domain/models/member_model.dart';
import 'package:gym/features/gym_owner/domain/models/attendance_model.dart';
import 'package:gym/features/auth/domain/models/gym_model.dart';

final gymOwnerRepositoryProvider = Provider<GymOwnerRepository>((ref) {
  return GymOwnerRepository(FirebaseFirestore.instance);
});

class GymOwnerRepository {
  final FirebaseFirestore _firestore;

  GymOwnerRepository(this._firestore);

  // --- Gym Info ---
  Future<GymModel> getGym(String gymId) async {
    final doc = await _firestore.collection('gyms').doc(gymId).get();
    if (!doc.exists || doc.data() == null) throw Exception('Gym not found');
    return GymModel.fromMap(doc.data()!, doc.id);
  }

  Future<void> updateGymName(String gymId, String newName) async {
    await _firestore.collection('gyms').doc(gymId).update({'gymName': newName});
  }

  // --- Members ---
  Stream<List<MemberModel>> getMembers(String gymId) {
    return _firestore
        .collection('members')
        .where('gymId', isEqualTo: gymId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => MemberModel.fromMap(doc.data(), doc.id))
            .where((member) => member.isDeleted != true)
            .toList());
  }

  Stream<List<MemberModel>> getDeletedMembers(String gymId) {
    return _firestore
        .collection('members')
        .where('gymId', isEqualTo: gymId)
        .where('isDeleted', isEqualTo: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => MemberModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  Future<String> addMember(MemberModel member) async {
    final docRef = _firestore.collection('members').doc();
    await docRef.set(member.toMap());
    return docRef.id;
  }

  Future<void> updateMemberStatus(String memberId, bool isActive) async {
    await _firestore.collection('members').doc(memberId).update({'isActive': isActive});
  }

  Future<void> updateMember(MemberModel member) async {
    await _firestore.collection('members').doc(member.id).update(member.toMap());
  }

  Future<void> deleteMember(String memberId) async {
    await _firestore.collection('members').doc(memberId).update({
      'isDeleted': true,
      'deletedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> permanentDeleteMember(String memberId) async {
    await _firestore.collection('members').doc(memberId).delete();
  }

  Future<void> rejoinMember(String memberId) async {
    await _firestore.collection('members').doc(memberId).update({
      'isDeleted': false,
      'deletedAt': FieldValue.delete(),
    });
  }

  // --- Payments ---
  Stream<List<PaymentModel>> getPayments(String gymId) {
    return _firestore
        .collection('payments')
        .where('gymId', isEqualTo: gymId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => PaymentModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  Future<void> addPayment(PaymentModel payment) async {
    await _firestore.collection('payments').doc().set(payment.toMap());
  }

  Stream<List<PaymentModel>> getMemberPayments(String memberId) {
    return _firestore
        .collection('payments')
        .where('memberId', isEqualTo: memberId)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs
          .map((doc) => PaymentModel.fromMap(doc.data(), doc.id))
          .toList();
      list.sort((a, b) => b.paymentDate.compareTo(a.paymentDate));
      return list;
    });
  }

  // --- Expenses ---
  Stream<List<ExpenseModel>> getExpenses(String gymId) {
    return _firestore
        .collection('expenses')
        .where('gymId', isEqualTo: gymId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ExpenseModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  Future<void> addExpense(ExpenseModel expense) async {
    await _firestore.collection('expenses').doc().set(expense.toMap());
  }

  Future<void> updateExpense(ExpenseModel expense) async {
    await _firestore.collection('expenses').doc(expense.id).update(expense.toMap());
  }

  Future<void> deleteExpense(String expenseId) async {
    await _firestore.collection('expenses').doc(expenseId).delete();
  }

  // Analytics Helpers
  Stream<double> getMonthlyIncome(String gymId, int month, int year) {
    final start = DateTime(year, month, 1);
    final end = DateTime(year, month + 1, 0, 23, 59, 59);

    return _firestore
        .collection('payments')
        .where('gymId', isEqualTo: gymId)
        .where('paymentDate', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('paymentDate', isLessThanOrEqualTo: Timestamp.fromDate(end))
        .snapshots()
        .map((snapshot) {
      double total = 0;
      for (var doc in snapshot.docs) {
        total += (doc.data()['amount'] ?? 0.0).toDouble();
      }
      return total;
    });
  }

  Stream<List<PaymentModel>> getMonthlyPaymentsList(String gymId, int month, int year) {
    final start = DateTime(year, month, 1);
    final end = DateTime(year, month + 1, 0, 23, 59, 59);

    return _firestore
        .collection('payments')
        .where('gymId', isEqualTo: gymId)
        .where('paymentDate', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('paymentDate', isLessThanOrEqualTo: Timestamp.fromDate(end))
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs
          .map((doc) => PaymentModel.fromMap(doc.data(), doc.id))
          .toList();
      list.sort((a, b) => b.paymentDate.compareTo(a.paymentDate));
      return list;
    });
  }

  Stream<double> getMonthlyExpenses(String gymId, int month, int year) {
    final start = DateTime(year, month, 1);
    final end = DateTime(year, month + 1, 0, 23, 59, 59);

    return _firestore
        .collection('expenses')
        .where('gymId', isEqualTo: gymId)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('date', isLessThanOrEqualTo: Timestamp.fromDate(end))
        .snapshots()
        .map((snapshot) {
      double total = 0;
      for (var doc in snapshot.docs) {
        total += (doc.data()['amount'] ?? 0.0).toDouble();
      }
      return total;
    });
  }

  // --- Report Date-Range Queries ---

  Stream<List<PaymentModel>> getPaymentsByDateRange(
      String gymId, DateTime from, DateTime to) {
    final start = DateTime(from.year, from.month, from.day);
    final end = DateTime(to.year, to.month, to.day, 23, 59, 59);
    return _firestore
        .collection('payments')
        .where('gymId', isEqualTo: gymId)
        .where('paymentDate', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('paymentDate', isLessThanOrEqualTo: Timestamp.fromDate(end))
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs
          .map((doc) => PaymentModel.fromMap(doc.data(), doc.id))
          .toList();
      list.sort((a, b) => b.paymentDate.compareTo(a.paymentDate));
      return list;
    });
  }

  Stream<List<ExpenseModel>> getExpensesByDateRange(
      String gymId, DateTime from, DateTime to) {
    final start = DateTime(from.year, from.month, from.day);
    final end = DateTime(to.year, to.month, to.day, 23, 59, 59);
    return _firestore
        .collection('expenses')
        .where('gymId', isEqualTo: gymId)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('date', isLessThanOrEqualTo: Timestamp.fromDate(end))
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs
          .map((doc) => ExpenseModel.fromMap(doc.data(), doc.id))
          .toList();
      list.sort((a, b) => b.date.compareTo(a.date));
      return list;
    });
  }

  /// Returns a list of 12 monthly income totals for the last 12 months (oldest→newest).
  Future<List<double>> getLast12MonthsIncome(String gymId) async {
    final now = DateTime.now();
    final List<double> result = [];
    for (int i = 11; i >= 0; i--) {
      final month = now.month - i;
      final year = now.year + (month <= 0 ? -1 : 0);
      final adjustedMonth = month <= 0 ? month + 12 : month;
      final start = DateTime(year, adjustedMonth, 1);
      final end = DateTime(year, adjustedMonth + 1, 0, 23, 59, 59);
      final snapshot = await _firestore
          .collection('payments')
          .where('gymId', isEqualTo: gymId)
          .where('paymentDate',
              isGreaterThanOrEqualTo: Timestamp.fromDate(start))
          .where('paymentDate', isLessThanOrEqualTo: Timestamp.fromDate(end))
          .get();
      double total = 0;
      for (var doc in snapshot.docs) {
        total += (doc.data()['amount'] ?? 0.0).toDouble();
      }
      result.add(total);
    }
    return result;
  }

  /// Returns a list of 12 monthly expense totals for the last 12 months (oldest→newest).
  Future<List<double>> getLast12MonthsExpenses(String gymId) async {
    final now = DateTime.now();
    final List<double> result = [];
    for (int i = 11; i >= 0; i--) {
      final month = now.month - i;
      final year = now.year + (month <= 0 ? -1 : 0);
      final adjustedMonth = month <= 0 ? month + 12 : month;
      final start = DateTime(year, adjustedMonth, 1);
      final end = DateTime(year, adjustedMonth + 1, 0, 23, 59, 59);
      final snapshot = await _firestore
          .collection('expenses')
          .where('gymId', isEqualTo: gymId)
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
          .where('date', isLessThanOrEqualTo: Timestamp.fromDate(end))
          .get();
      double total = 0;
      for (var doc in snapshot.docs) {
        total += (doc.data()['amount'] ?? 0.0).toDouble();
      }
      result.add(total);
    }
    return result;
  }

  // --- Attendance ---
  Stream<List<AttendanceModel>> getTodayAttendance(String gymId) {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    
    return _firestore
        .collection('attendances')
        .where('gymId', isEqualTo: gymId)
        .where('date', isEqualTo: Timestamp.fromDate(startOfDay))
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => AttendanceModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  Future<void> checkIn(AttendanceModel attendance) async {
    await _firestore.collection('attendances').doc().set(attendance.toMap());
  }

  Future<void> checkOut(String attendanceId, DateTime checkOutTime) async {
    await _firestore.collection('attendances').doc(attendanceId).update({
      'checkOutTime': Timestamp.fromDate(checkOutTime),
    });
  }

  Stream<List<AttendanceModel>> getMemberAttendances(String memberId) {
    return _firestore
        .collection('attendances')
        .where('memberId', isEqualTo: memberId)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs
          .map((doc) => AttendanceModel.fromMap(doc.data(), doc.id))
          .toList();
      list.sort((a, b) => b.date.compareTo(a.date));
      return list;
    });
  }
}
