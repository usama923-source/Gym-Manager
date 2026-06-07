import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gym/core/theme/app_theme.dart';
import 'package:intl/intl.dart';
import 'package:gym/features/gym_owner/domain/models/member_model.dart';
import 'package:gym/features/gym_owner/domain/models/member_transaction_model.dart';
import 'package:gym/features/gym_owner/presentation/providers/gym_owner_providers.dart';
import 'package:gym/features/gym_owner/presentation/widgets/member_card_widget.dart';
import 'package:gym/features/gym_owner/data/repositories/gym_owner_repository.dart';
import 'package:go_router/go_router.dart';

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

    final membersAsync = ref.watch(membersProvider);
    final currentMember = membersAsync.value?.firstWhere(
          (m) => m.id == member.id,
          orElse: () => member,
        ) ??
        member;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Member Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              context.push('/add-member', extra: currentMember);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          MemberCardWidget(
            member: currentMember,
            attendances: todayAttendances,
          ),
          const SizedBox(height: 8),
          Expanded(
            child: DefaultTabController(
              length: 4,
              child: Column(
                children: [
                  Material(
                    elevation: 2,
                    color: Theme.of(context).colorScheme.primary,
                    child: TabBar(
                      tabs: const [
                        Tab(text: 'Plan History'),
                        Tab(text: 'Attendance'),
                        Tab(text: 'Transactions'),
                        Tab(text: 'Progress'),
                      ],
                      labelColor: Colors.white,
                      unselectedLabelColor: Colors.white.withOpacity(0.7),
                      indicatorColor: Colors.white,
                    ),
                  ),
                  Expanded(
                    child: TabBarView(
                      children: [
                        _PlanHistoryTab(memberId: currentMember.id),
                        _AttendanceHistoryTab(memberId: currentMember.id),
                        _TransactionsTab(member: currentMember),
                        _ProgressTab(member: currentMember),
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

// ─── Plan History Tab ────────────────────────────────────────────────────────

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

// ─── Attendance History Tab ──────────────────────────────────────────────────

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
        final Map<String, List> grouped = {};
        for (var a in attendances) {
          final key = DateFormat('MMMM yyyy').format(a.date);
          grouped.putIfAbsent(key, () => []).add(a);
        }
        return ListView.builder(
          padding: const EdgeInsets.all(8.0),
          itemCount: grouped.keys.length,
          itemBuilder: (context, index) {
            final monthKey = grouped.keys.elementAt(index);
            final monthAttendances = grouped[monthKey]!;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                      vertical: 8.0, horizontal: 16.0),
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
                    margin: const EdgeInsets.symmetric(
                        vertical: 4.0, horizontal: 8.0),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        child:
                            const Icon(Icons.directions_run, color: Colors.white),
                      ),
                      title: Text(
                          DateFormat('EEEE, MMM dd').format(attendance.date)),
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

// ─── Transactions Tab ────────────────────────────────────────────────────────

class _TransactionsTab extends ConsumerWidget {
  final MemberModel member;
  const _TransactionsTab({required this.member});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final txAsync = ref.watch(memberTransactionsProvider(member.id));
    final gymId = ref.watch(currentGymIdProvider) ?? '';

    return txAsync.when(
      data: (transactions) {
        final totalPaid = transactions
            .where((t) => t.isDuePaid)
            .fold(0.0, (sum, t) => sum + t.amount);
        final totalRefunded = transactions
            .where((t) => t.isRefund)
            .fold(0.0, (sum, t) => sum + t.amount);
        final net = totalPaid - totalRefunded;

        return Column(
          children: [
            // Summary header
            _LedgerSummaryHeader(
              totalPaid: totalPaid,
              totalRefunded: totalRefunded,
              net: net,
            ),

            // Add button
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: const Icon(Icons.add),
                  label: const Text('Record Transaction',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  onPressed: () => _showAddTransactionSheet(
                      context, ref, member.id, gymId),
                ),
              ),
            ),

            // List
            Expanded(
              child: transactions.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.receipt_long,
                              size: 60, color: Colors.grey.shade300),
                          const SizedBox(height: 12),
                          Text('No transactions yet.',
                              style: TextStyle(color: Colors.grey.shade500)),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      itemCount: transactions.length,
                      itemBuilder: (context, index) {
                        final tx = transactions[index];
                        return _TransactionTile(tx: tx);
                      },
                    ),
            ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(child: Text('Error: $error')),
    );
  }

  void _showAddTransactionSheet(
      BuildContext context, WidgetRef ref, String memberId, String gymId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddTransactionSheet(
        memberId: memberId,
        gymId: gymId,
        ref: ref,
      ),
    );
  }
}

// ─── Summary Header ──────────────────────────────────────────────────────────

class _LedgerSummaryHeader extends StatelessWidget {
  final double totalPaid;
  final double totalRefunded;
  final double net;

  const _LedgerSummaryHeader({
    required this.totalPaid,
    required this.totalRefunded,
    required this.net,
  });

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,##0.00');
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 12, 12, 4),
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primary,
            Theme.of(context).colorScheme.primary.withOpacity(0.7),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _SummaryItem(
            label: 'Total Paid',
            value: 'Rs ${fmt.format(totalPaid)}',
            icon: Icons.arrow_downward,
            color: Colors.greenAccent,
          ),
          Container(width: 1, height: 40, color: Colors.white24),
          _SummaryItem(
            label: 'Refunded',
            value: 'Rs ${fmt.format(totalRefunded)}',
            icon: Icons.arrow_upward,
            color: Colors.orangeAccent,
          ),
          Container(width: 1, height: 40, color: Colors.white24),
          _SummaryItem(
            label: 'Net',
            value: 'Rs ${fmt.format(net)}',
            icon: Icons.account_balance_wallet,
            color: net >= 0 ? Colors.greenAccent : Colors.redAccent,
          ),
        ],
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _SummaryItem({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(height: 4),
        Text(label,
            style: const TextStyle(
                color: Colors.white70, fontSize: 11)),
        const SizedBox(height: 2),
        Text(value,
            style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 13)),
      ],
    );
  }
}

// ─── Transaction Tile ────────────────────────────────────────────────────────

class _TransactionTile extends StatelessWidget {
  final MemberTransactionModel tx;
  const _TransactionTile({required this.tx});

  @override
  Widget build(BuildContext context) {
    final isDue = tx.isDuePaid;
    final color = isDue ? Colors.green : Colors.orange;
    final bgColor = isDue ? Colors.green.shade50 : Colors.orange.shade50;
    final icon = isDue ? Icons.payments_outlined : Icons.undo;
    final label = isDue ? 'Due Paid' : 'Refund';

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
      color: bgColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: color.withOpacity(0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: color.withOpacity(0.15),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(label,
                            style: TextStyle(
                                color: color,
                                fontSize: 11,
                                fontWeight: FontWeight.bold)),
                      ),
                      if (tx.paymentMethod != null) ...[
                        const SizedBox(width: 6),
                        Text(tx.paymentMethod!,
                            style: TextStyle(
                                color: Colors.grey.shade600, fontSize: 11)),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('EEE, MMM dd yyyy').format(tx.date),
                    style: const TextStyle(fontSize: 12, color: Colors.black54),
                  ),
                  if (tx.notes != null && tx.notes!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        tx.notes!,
                        style: const TextStyle(
                            fontSize: 12, color: Colors.black45),
                      ),
                    ),
                ],
              ),
            ),
            Text(
              'Rs ${NumberFormat('#,##0.00').format(tx.amount)}',
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: isDue ? Colors.green.shade700 : Colors.orange.shade700),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Add Transaction Bottom Sheet ────────────────────────────────────────────

class _AddTransactionSheet extends StatefulWidget {
  final String memberId;
  final String gymId;
  final WidgetRef ref;

  const _AddTransactionSheet({
    required this.memberId,
    required this.gymId,
    required this.ref,
  });

  @override
  State<_AddTransactionSheet> createState() => _AddTransactionSheetState();
}

class _AddTransactionSheetState extends State<_AddTransactionSheet> {
  final _formKey = GlobalKey<FormState>();
  final _amountCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  String _type = TransactionType.duePaid;
  String _method = 'Cash';
  DateTime _date = DateTime.now();
  bool _loading = false;

  static const _methods = ['Cash', 'Card', 'Online', 'Other'];

  @override
  void dispose() {
    _amountCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    final tx = MemberTransactionModel(
      id: '',
      gymId: widget.gymId,
      memberId: widget.memberId,
      type: _type,
      amount: double.parse(_amountCtrl.text.trim()),
      date: _date,
      paymentMethod: _method,
      notes: _notesCtrl.text.trim(),
      createdAt: DateTime.now(),
    );

    try {
      await widget.ref
          .read(gymOwnerRepositoryProvider)
          .addMemberTransaction(tx);
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDue = _type == TransactionType.duePaid;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + bottomInset),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Theme(
        data: AppTheme.getFormTheme(context),
        child: Form(
          key: _formKey,
          child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text('Record Transaction',
                style:
                    TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),

            // Type toggle
            Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _TypeButton(
                      label: 'Due Paid',
                      icon: Icons.payments_outlined,
                      selected: isDue,
                      selectedColor: Colors.green,
                      onTap: () => setState(
                          () => _type = TransactionType.duePaid),
                    ),
                  ),
                  Expanded(
                    child: _TypeButton(
                      label: 'Refund',
                      icon: Icons.undo,
                      selected: !isDue,
                      selectedColor: Colors.orange,
                      onTap: () =>
                          setState(() => _type = TransactionType.refund),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Amount
            TextFormField(
              controller: _amountCtrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(
                    RegExp(r'^\d+\.?\d{0,2}'))
              ],
              decoration: InputDecoration(
                labelText: 'Amount (Rs)',
                prefixIcon: const Icon(Icons.attach_money),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Enter amount';
                if (double.tryParse(v.trim()) == null)
                  return 'Invalid number';
                if (double.parse(v.trim()) <= 0)
                  return 'Must be > 0';
                return null;
              },
            ),
            const SizedBox(height: 12),

            // Date
            InkWell(
              onTap: _pickDate,
              borderRadius: BorderRadius.circular(10),
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: 'Date',
                  prefixIcon: const Icon(Icons.calendar_today),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                child: Text(DateFormat('EEE, MMM dd yyyy').format(_date)),
              ),
            ),
            const SizedBox(height: 12),

            // Payment method
            DropdownButtonFormField<String>(
              value: _method,
              decoration: InputDecoration(
                labelText: 'Payment Method',
                prefixIcon: const Icon(Icons.credit_card),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              items: _methods
                  .map((m) =>
                      DropdownMenuItem(value: m, child: Text(m)))
                  .toList(),
              onChanged: (v) => setState(() => _method = v!),
            ),
            const SizedBox(height: 12),

            // Notes
            TextFormField(
              controller: _notesCtrl,
              maxLines: 2,
              decoration: InputDecoration(
                labelText: 'Notes (optional)',
                prefixIcon: const Icon(Icons.notes),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const SizedBox(height: 20),

            // Save button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      isDue ? Colors.green.shade600 : Colors.orange.shade600,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _loading ? null : _save,
                child: _loading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : Text(
                        isDue ? 'Save — Due Paid' : 'Save — Refund',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16),
                      ),
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }
}

class _TypeButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final Color selectedColor;
  final VoidCallback onTap;

  const _TypeButton({
    required this.label,
    required this.icon,
    required this.selected,
    required this.selectedColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.all(4),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected ? selectedColor : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          boxShadow: selected
              ? [
                  BoxShadow(
                      color: selectedColor.withOpacity(0.3),
                      blurRadius: 6,
                      offset: const Offset(0, 3))
                ]
              : [],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon,
                color: selected ? Colors.white : Colors.grey, size: 18),
            const SizedBox(width: 6),
            Text(label,
                style: TextStyle(
                    color: selected ? Colors.white : Colors.grey,
                    fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}

// ─── Progress Tab ────────────────────────────────────────────────────────────

class _ProgressTab extends ConsumerWidget {
  final MemberModel member;

  const _ProgressTab({required this.member});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final attendancesAsync = ref.watch(memberAttendancesProvider(member.id));
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section 1: Average Session Duration & Attendance Stats
          attendancesAsync.when(
            data: (attendances) {
              final completedSessions = attendances.where((a) => a.checkOutTime != null).toList();
              String avgDurationStr = 'N/A';
              
              if (completedSessions.isNotEmpty) {
                double totalMinutes = 0;
                for (var session in completedSessions) {
                  totalMinutes += session.checkOutTime!.difference(session.checkInTime).inMinutes;
                }
                final avgMinutes = (totalMinutes / completedSessions.length).round();
                final hours = avgMinutes ~/ 60;
                final mins = avgMinutes % 60;
                if (hours > 0) {
                  avgDurationStr = '${hours}h ${mins}m';
                } else {
                  avgDurationStr = '${mins}m';
                }
              }

              return Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                        child: Icon(Icons.timer, color: theme.colorScheme.primary, size: 28),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Daily Avg Time in Gym',
                              style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey.shade600),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              avgDurationStr,
                              style: theme.textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'Total Visits',
                            style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
                          ),
                          Text(
                            '${attendances.length}',
                            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) => const Text('Error loading attendance stats'),
          ),
          const SizedBox(height: 20),

          // Section 2: Weight History
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Weight History',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  minimumSize: Size.zero,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
                onPressed: () => _showAddWeightDialog(context, ref),
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Add Weight', style: TextStyle(fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _buildWeightSection(context, theme),
          
          const SizedBox(height: 24),

          // Section 3: Injury History
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Injury History',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  minimumSize: Size.zero,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
                onPressed: () => _showAddInjuryDialog(context, ref),
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Add Injury', style: TextStyle(fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _buildInjurySection(context, theme),
        ],
      ),
    );
  }

  Widget _buildWeightSection(BuildContext context, ThemeData theme) {
    if (member.weightHistory.isEmpty) {
      return Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: const Padding(
          padding: EdgeInsets.all(24.0),
          child: Center(
            child: Text(
              'No weight records entered yet.',
              style: TextStyle(color: Colors.grey),
            ),
          ),
        ),
      );
    }

    // Sort weightHistory by date descending
    final sortedWeightList = List<WeightEntry>.from(member.weightHistory)
      ..sort((a, b) => b.date.compareTo(a.date));

    // Get current weight (latest date)
    final currentWeight = sortedWeightList.first.weight;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Current Weight Info Card
        Card(
          color: theme.colorScheme.primary.withOpacity(0.05),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: theme.colorScheme.primary.withOpacity(0.1)),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Current Recorded Weight', style: TextStyle(fontWeight: FontWeight.w600)),
                Text(
                  '${currentWeight.toStringAsFixed(1)} kg',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        // History List
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: sortedWeightList.length,
          itemBuilder: (context, index) {
            final entry = sortedWeightList[index];
            return Card(
              margin: const EdgeInsets.symmetric(vertical: 4.0),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              child: ListTile(
                leading: const Icon(Icons.monitor_weight_outlined),
                title: Text('${entry.weight} kg', style: const TextStyle(fontWeight: FontWeight.bold)),
                trailing: Text(
                  DateFormat('MMM dd, yyyy').format(entry.date),
                  style: const TextStyle(color: Colors.grey, fontSize: 13),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildInjurySection(BuildContext context, ThemeData theme) {
    if (member.injuryHistory.isEmpty) {
      return Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: const Padding(
          padding: EdgeInsets.all(24.0),
          child: Center(
            child: Text(
              'No injury history recorded.',
              style: TextStyle(color: Colors.grey),
            ),
          ),
        ),
      );
    }

    final sortedInjuryList = List<InjuryEntry>.from(member.injuryHistory)
      ..sort((a, b) => b.date.compareTo(a.date));

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: sortedInjuryList.length,
      itemBuilder: (context, index) {
        final entry = sortedInjuryList[index];
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 4.0),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          child: ListTile(
            leading: Icon(Icons.personal_injury_outlined, color: theme.colorScheme.error),
            title: Text(entry.description, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: entry.notes.isNotEmpty ? Text(entry.notes) : null,
            trailing: Text(
              DateFormat('MMM dd, yyyy').format(entry.date),
              style: const TextStyle(color: Colors.grey, fontSize: 13),
            ),
          ),
        );
      },
    );
  }

  void _showAddWeightDialog(BuildContext context, WidgetRef ref) {
    final formKey = GlobalKey<FormState>();
    final weightCtrl = TextEditingController();
    DateTime date = DateTime.now();

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Add Weight Record'),
              content: Theme(
                data: AppTheme.getFormTheme(context),
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: weightCtrl,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(
                          labelText: 'Weight (kg)',
                          prefixIcon: Icon(Icons.monitor_weight),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) return 'Please enter weight';
                          if (double.tryParse(value) == null) return 'Enter a valid number';
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      InkWell(
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: date,
                            firstDate: DateTime(2020),
                            lastDate: DateTime.now(),
                          );
                          if (picked != null) {
                            setDialogState(() => date = picked);
                          }
                        },
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Date',
                            prefixIcon: Icon(Icons.calendar_today),
                          ),
                          child: Text(DateFormat('yyyy-MM-dd').format(date)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogCtx),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (formKey.currentState!.validate()) {
                      final weight = double.parse(weightCtrl.text);
                      final entry = WeightEntry(date: date, weight: weight);
                      final updatedList = [...member.weightHistory, entry];
                      final updatedMember = member.copyWith(weightHistory: updatedList);

                      try {
                        await ref.read(gymOwnerRepositoryProvider).updateMember(updatedMember);
                        if (dialogCtx.mounted) {
                          Navigator.pop(dialogCtx);
                        }
                      } catch (e) {
                        if (dialogCtx.mounted) {
                          ScaffoldMessenger.of(dialogCtx).showSnackBar(
                            SnackBar(content: Text('Error saving: $e')),
                          );
                        }
                      }
                    }
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showAddInjuryDialog(BuildContext context, WidgetRef ref) {
    final formKey = GlobalKey<FormState>();
    final descCtrl = TextEditingController();
    final notesCtrl = TextEditingController();
    DateTime date = DateTime.now();

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Add Injury Record'),
              content: Theme(
                data: AppTheme.getFormTheme(context),
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: descCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Injury Description',
                          prefixIcon: Icon(Icons.personal_injury),
                          hintText: 'e.g. Knee Sprain',
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) return 'Please enter description';
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: notesCtrl,
                        maxLines: 2,
                        decoration: const InputDecoration(
                          labelText: 'Notes / Recovery Status',
                          prefixIcon: Icon(Icons.notes),
                        ),
                      ),
                      const SizedBox(height: 16),
                      InkWell(
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: date,
                            firstDate: DateTime(2020),
                            lastDate: DateTime.now(),
                          );
                          if (picked != null) {
                            setDialogState(() => date = picked);
                          }
                        },
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Date of Injury',
                            prefixIcon: Icon(Icons.calendar_today),
                          ),
                          child: Text(DateFormat('yyyy-MM-dd').format(date)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogCtx),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (formKey.currentState!.validate()) {
                      final entry = InjuryEntry(
                        date: date,
                        description: descCtrl.text.trim(),
                        notes: notesCtrl.text.trim(),
                      );
                      final updatedList = [...member.injuryHistory, entry];
                      final updatedMember = member.copyWith(injuryHistory: updatedList);

                      try {
                        await ref.read(gymOwnerRepositoryProvider).updateMember(updatedMember);
                        if (dialogCtx.mounted) {
                          Navigator.pop(dialogCtx);
                        }
                      } catch (e) {
                        if (dialogCtx.mounted) {
                          ScaffoldMessenger.of(dialogCtx).showSnackBar(
                            SnackBar(content: Text('Error saving: $e')),
                          );
                        }
                      }
                    }
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
