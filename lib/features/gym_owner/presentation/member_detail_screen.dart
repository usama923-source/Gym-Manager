import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:gym/features/gym_owner/domain/models/member_model.dart';
import 'package:gym/features/gym_owner/presentation/providers/gym_owner_providers.dart';
import 'package:gym/features/gym_owner/presentation/widgets/member_card_widget.dart';

class MemberDetailScreen extends ConsumerWidget {
  final MemberModel member;

  const MemberDetailScreen({
    super.key,
    required this.member,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final todayAttendancesAsync = ref.watch(todayAttendanceProvider);
    final todayAttendances = todayAttendancesAsync.value ?? [];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Member Details'),
      ),
      body: Column(
        children: [
          // Member Card
          MemberCardWidget(
            member: member,
            attendances: todayAttendances,
          ),
          
          const SizedBox(height: 16),
          
          // Tabs for History
          Expanded(
            child: DefaultTabController(
              length: 2,
              child: Column(
                children: [
                  const TabBar(
                    tabs: [
                      Tab(text: 'Plan History'),
                      Tab(text: 'Attendance History'),
                    ],
                    labelColor: Colors.blue,
                    unselectedLabelColor: Colors.grey,
                  ),
                  Expanded(
                    child: TabBarView(
                      children: [
                        _PlanHistoryTab(memberId: member.id),
                        _AttendanceHistoryTab(memberId: member.id),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PlanHistoryTab extends ConsumerWidget {
  final String memberId;

  const _PlanHistoryTab({required this.memberId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final paymentsAsync = ref.watch(memberPaymentsProvider(memberId));

    return paymentsAsync.when(
      data: (payments) {
        if (payments.isEmpty) {
          return const Center(child: Text('No plan history found.'));
        }
        return ListView.builder(
          padding: const EdgeInsets.all(8.0),
          itemCount: payments.length,
          itemBuilder: (context, index) {
            final payment = payments[index];
            return Card(
              margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
              child: ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Colors.green,
                  child: Icon(Icons.payment, color: Colors.white),
                ),
                title: Text(
                  '\$${payment.amount.toStringAsFixed(2)}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  'Paid on ${DateFormat('MMM dd, yyyy - hh:mm a').format(payment.paymentDate)}\nMethod: ${payment.paymentMethod}',
                ),
                isThreeLine: true,
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(child: Text('Error: $error')),
    );
  }
}

class _AttendanceHistoryTab extends ConsumerWidget {
  final String memberId;

  const _AttendanceHistoryTab({required this.memberId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final attendancesAsync = ref.watch(memberAttendancesProvider(memberId));

    return attendancesAsync.when(
      data: (attendances) {
        if (attendances.isEmpty) {
          return const Center(child: Text('No attendance history found.'));
        }

        // Group by month
        final Map<String, List> groupedAttendances = {};
        for (var attendance in attendances) {
          final monthKey = DateFormat('MMMM yyyy').format(attendance.date);
          if (!groupedAttendances.containsKey(monthKey)) {
            groupedAttendances[monthKey] = [];
          }
          groupedAttendances[monthKey]!.add(attendance);
        }

        return ListView.builder(
          padding: const EdgeInsets.all(8.0),
          itemCount: groupedAttendances.keys.length,
          itemBuilder: (context, index) {
            final monthKey = groupedAttendances.keys.elementAt(index);
            final monthAttendances = groupedAttendances[monthKey]!;
            
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                  child: Text(
                    monthKey,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.blueGrey,
                    ),
                  ),
                ),
                ...monthAttendances.map((attendance) {
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
                    child: ListTile(
                      leading: const CircleAvatar(
                        backgroundColor: Colors.blue,
                        child: Icon(Icons.directions_run, color: Colors.white),
                      ),
                      title: Text(DateFormat('EEEE, MMM dd').format(attendance.date)),
                      subtitle: Text(
                        'In: ${DateFormat('hh:mm a').format(attendance.checkInTime)}'
                        '${attendance.checkOutTime != null ? ' - Out: ${DateFormat('hh:mm a').format(attendance.checkOutTime!)}' : ' - Out: Pending'}',
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 8),
              ],
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(child: Text('Error: $error')),
    );
  }
}
