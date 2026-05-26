import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Member Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              context.push('/add-member', extra: member);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          MemberCardWidget(
            member: member,
            attendances: todayAttendances,
          ),
          const SizedBox(height: 8),
          Expanded(
            child: DefaultTabController(
              length: 3,
              child: Column(
                children: [
                  const TabBar(
                    tabs: [
                      Tab(text: 'Plan History'),
                      Tab(text: 'Attendance'),
                      Tab(text: 'Transactions'),
                    ],
                    labelColor: Colors.blue,
                    unselectedLabelColor: Colors.grey,
                    indicatorColor: Colors.blue,
                  ),
                  Expanded(
                    child: TabBarView(
                      children: [
                        _PlanHistoryTab(memberId: member.id),
                        _AttendanceHistoryTab(memberId: member.id),
                        _TransactionsTab(member: member),
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
                      leading: const CircleAvatar(
                        backgroundColor: Colors.blue,
                        child:
                            Icon(Icons.directions_run, color: Colors.white),
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
                    backgroundColor: Colors.blue.shade700,
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
          colors: [Colors.blue.shade800, Colors.blue.shade500],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.3),
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
