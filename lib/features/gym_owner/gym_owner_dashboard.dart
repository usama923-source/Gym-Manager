import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gym/features/auth/presentation/providers/auth_provider.dart';
import 'package:gym/features/gym_owner/presentation/providers/gym_owner_providers.dart';
import 'package:gym/features/gym_owner/presentation/widgets/gym_owner_drawer.dart';

class GymOwnerDashboard extends ConsumerWidget {
  final VoidCallback? onNavigateToMembers;

  const GymOwnerDashboard({super.key, this.onNavigateToMembers});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);

    final totalMembers = ref.watch(totalMembersProvider);
    final activeMembers = ref.watch(activeMembersProvider);
    final income = ref.watch(monthlyIncomeProvider).value ?? 0.0;
    final expenses = ref.watch(monthlyExpensesProvider).value ?? 0.0;
    final netProfit = ref.watch(netProfitProvider);

    final attendancesAsync = ref.watch(todayAttendanceProvider);
    final birthdays = ref.watch(birthdaysThisMonthProvider);
    final expiringToday = ref.watch(expiringTodayProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Gym Dashboard')),
      drawer: const GymOwnerDrawer(),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Welcome back, ${authState.value?.name ?? 'Owner'}',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Members Stats
                  Text(
                    'Members Overview',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () {
                            ref.read(membersStatusFilterProvider.notifier).setFilter('All');
                            onNavigateToMembers?.call();
                          },
                          child: _buildStatCard(
                            context,
                            'Total',
                            totalMembers.toString(),
                            Icons.people,
                            Colors.blue,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: InkWell(
                          onTap: () {
                            ref.read(membersStatusFilterProvider.notifier).setFilter('Active');
                            onNavigateToMembers?.call();
                          },
                          child: _buildStatCard(
                            context,
                            'Active',
                            activeMembers.toString(),
                            Icons.verified_user,
                            Colors.green,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Financial Stats
                  Text(
                    'Financial Overview (This Month)',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () => context.push('/income-report'),
                          child: _buildStatCard(
                            context,
                            'Income',
                            '\$${income.toStringAsFixed(0)}',
                            Icons.arrow_upward,
                            Colors.green,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildStatCard(
                          context,
                          'Expenses',
                          '\$${expenses.toStringAsFixed(0)}',
                          Icons.arrow_downward,
                          Colors.red,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _buildStatCard(
                    context,
                    'Net Profit',
                    '\$${netProfit.toStringAsFixed(0)}',
                    Icons.account_balance_wallet,
                    netProfit >= 0 ? Colors.green : Colors.red,
                    isFullWidth: true,
                  ),
                  const SizedBox(height: 24),

                  Text(
                    'This Month Report',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Divider(),
                  const SizedBox(height: 8),

                  // Today's Attendance
                  _buildReportSectionHeader(
                    context,
                    'Attendance Today',
                    Icons.how_to_reg,
                    Colors.blue,
                  ),
                  attendancesAsync.when(
                    data: (attendances) {
                      if (attendances.isEmpty) {
                        return const Padding(
                          padding: EdgeInsets.only(bottom: 16),
                          child: Text('No check-ins today.'),
                        );
                      }
                      return ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: attendances.length,
                        itemBuilder: (context, index) {
                          final a = attendances[index];
                          final membersList =
                              ref.watch(membersProvider).value ?? [];
                          final m = membersList
                              .where((m) => m.id == a.memberId)
                              .firstOrNull;
                          final name = m?.name ?? 'Unknown Member';
                          final inTime =
                              '${a.checkInTime.hour}:${a.checkInTime.minute.toString().padLeft(2, '0')}';
                          final outTime = a.checkOutTime != null
                              ? '${a.checkOutTime!.hour}:${a.checkOutTime!.minute.toString().padLeft(2, '0')}'
                              : 'Active';
                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: const CircleAvatar(
                              child: Icon(Icons.person),
                            ),
                            title: Text(name),
                            subtitle: Text('In: $inTime - Out: $outTime'),
                          );
                        },
                      );
                    },
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (e, _) => Text('Error loading attendance: $e'),
                  ),
                  const SizedBox(height: 8),

                  // Birthdays This Month
                  _buildReportSectionHeader(
                    context,
                    'Birthdays This Month',
                    Icons.cake,
                    Colors.purple,
                  ),
                  if (birthdays.isEmpty)
                    const Padding(
                      padding: EdgeInsets.only(bottom: 16),
                      child: Text('No birthdays this month.'),
                    ),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: birthdays.length,
                    itemBuilder: (context, index) {
                      final m = birthdays[index];
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const CircleAvatar(
                          backgroundColor: Colors.purple,
                          child: Icon(Icons.cake, color: Colors.white),
                        ),
                        title: Text(m.name),
                        subtitle: Text(
                          m.dateOfBirth?.toString().split(' ')[0] ?? '',
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 8),

                  // Expiring Today
                  _buildReportSectionHeader(
                    context,
                    'Expiring Today',
                    Icons.warning,
                    Colors.orange,
                  ),
                  if (expiringToday.isEmpty)
                    const Padding(
                      padding: EdgeInsets.only(bottom: 16),
                      child: Text('No plans expiring today.'),
                    ),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: expiringToday.length,
                    itemBuilder: (context, index) {
                      final m = expiringToday[index];
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const CircleAvatar(
                          backgroundColor: Colors.orange,
                          child: Icon(Icons.warning, color: Colors.white),
                        ),
                        title: Text(m.name),
                        subtitle: Text('ID: ${m.memberId ?? m.id}'),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/add-member'),
        icon: const Icon(Icons.person_add),
        label: const Text('Add Member'),
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color color, {
    bool isFullWidth = false,
  }) {
    return Card(
      elevation: 2,
      child: Container(
        width: isFullWidth ? double.infinity : null,
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(title, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }

  Widget _buildReportSectionHeader(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
