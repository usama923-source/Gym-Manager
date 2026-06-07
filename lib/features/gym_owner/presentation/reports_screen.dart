import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:gym/features/gym_owner/domain/models/payment_model.dart';
import 'package:gym/features/gym_owner/domain/models/expense_model.dart';
import 'package:gym/features/gym_owner/domain/models/member_model.dart';
import 'package:gym/features/gym_owner/presentation/providers/gym_owner_providers.dart';
import 'package:gym/features/gym_owner/presentation/widgets/gym_owner_drawer.dart';

// ─── Color palette ───────────────────────────────────────────────────────────
const _kIncome = Color(0xFF00C897);
const _kExpense = Color(0xFFFF5A5F);
const _kProfit = Color(0xFF3B82F6);
const _kPending = Color(0xFFFFA500);

final _fmt = DateFormat('MMM d, yyyy');
final _cur = NumberFormat.currency(symbol: 'Rs ', decimalDigits: 0);

// ─── Root screen ─────────────────────────────────────────────────────────────
class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});
  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const GymOwnerDrawer(),
      appBar: AppBar(
        elevation: 4,
        shadowColor: Colors.black.withOpacity(0.5),
        title: Text('Financial Reports',
            style: GoogleFonts.montserrat(fontWeight: FontWeight.bold)),
        bottom: TabBar(
          controller: _tab,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          labelStyle: GoogleFonts.lato(fontWeight: FontWeight.bold),
          tabs: const [
            Tab(icon: Icon(Icons.bar_chart_rounded), text: 'Overview'),
            Tab(icon: Icon(Icons.receipt_long_rounded), text: 'Transactions'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tab,
        children: const [_OverviewTab(), _TransactionsTab()],
      ),
    );
  }
}

// ─── Overview Tab ────────────────────────────────────────────────────────────
class _OverviewTab extends ConsumerWidget {
  const _OverviewTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final payments = ref.watch(reportPaymentsProvider);
    final expenses = ref.watch(reportExpensesProvider);
    final members = ref.watch(membersProvider);

    final totalIncome = payments.value?.fold<double>(0.0, (s, p) => s + p.amount) ?? 0.0;
    final totalExpense = expenses.value?.fold<double>(0.0, (s, e) => s + e.amount) ?? 0.0;
    final netProfit = totalIncome - totalExpense;

    // Pending = members whose paidAmount < monthlyPlanAmount
    final pendingDues = members.value?.fold<double>(0.0, (sum, m) {
          final plan = m.monthlyPlanAmount ?? 0.0;
          final paid = m.paidAmount ?? 0.0;
          final diff = plan - paid;
          return sum + (diff > 0 ? diff : 0.0);
        }) ??
        0.0;

    // Advance = members who paid more than plan
    final advanceTotal = members.value?.fold<double>(0.0, (sum, m) {
          final plan = m.monthlyPlanAmount ?? 0.0;
          final paid = m.paidAmount ?? 0.0;
          final diff = paid - plan;
          return sum + (diff > 0 ? diff : 0.0);
        }) ??
        0.0;

    // Cash vs online
    final cashTotal = payments.value
            ?.where((p) => p.paymentMethod.toLowerCase().contains('cash'))
            .fold<double>(0.0, (s, p) => s + p.amount) ??
        0.0;
    final onlineTotal = totalIncome - cashTotal;

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _FilterBar(),
              const SizedBox(height: 12),
              // KPI grid
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    Row(children: [
                      Expanded(
                          child: _KpiCard('Total Income', totalIncome, Icons.arrow_upward_rounded, _kIncome)),
                      const SizedBox(width: 12),
                      Expanded(
                          child: _KpiCard('Total Expenses', totalExpense, Icons.arrow_downward_rounded, _kExpense)),
                    ]),
                    const SizedBox(height: 12),
                    Row(children: [
                      Expanded(
                          child: _KpiCard('Net Profit/Loss', netProfit,
                              netProfit >= 0 ? Icons.trending_up_rounded : Icons.trending_down_rounded,
                              netProfit >= 0 ? _kProfit : _kExpense)),
                      const SizedBox(width: 12),
                      Expanded(
                          child: _KpiCard('Pending Dues', pendingDues, Icons.hourglass_bottom_rounded, _kPending)),
                    ]),
                    const SizedBox(height: 12),
                    Row(children: [
                      Expanded(
                          child: _KpiCard('Advance Paid', advanceTotal, Icons.savings_rounded, const Color(0xFF9B5DE5))),
                      const SizedBox(width: 12),
                      Expanded(
                          child: _KpiCard('Total Members',
                              (members.value?.length ?? 0).toDouble(),
                              Icons.people_alt_rounded,
                              const Color(0xFF00B4D8),
                              isCurrency: false)),
                    ]),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              // Monthly bar chart
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text('Monthly Overview (12 months)',
                    style: GoogleFonts.montserrat(
                        fontWeight: FontWeight.bold, fontSize: 14)),
              ),
              const SizedBox(height: 8),
              const _MonthlyChart(),
              const SizedBox(height: 24),
              // Payment method breakdown
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Payment Methods',
                        style: GoogleFonts.montserrat(
                            fontWeight: FontWeight.bold,
                            fontSize: 14)),
                    const SizedBox(height: 12),
                    _MethodBar('Cash', cashTotal, totalIncome, _kIncome),
                    const SizedBox(height: 8),
                    _MethodBar('Online / Card', onlineTotal, totalIncome, _kProfit),
                  ],
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Filter Bar ──────────────────────────────────────────────────────────────
class _FilterBar extends ConsumerStatefulWidget {
  const _FilterBar();
  @override
  ConsumerState<_FilterBar> createState() => _FilterBarState();
}

class _FilterBarState extends ConsumerState<_FilterBar> {
  String _active = 'This Month';

  Future<void> _pickCustom() async {
    final now = DateTime.now();
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: now,
      builder: (ctx, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: Theme.of(context).colorScheme.copyWith(primary: _kIncome),
        ),
        child: child!,
      ),
    );
    if (range != null) {
      ref.read(reportFilterProvider.notifier).setCustom(range.start, range.end);
      setState(() => _active = 'Custom');
    }
  }

  @override
  Widget build(BuildContext context) {
    final filter = ref.watch(reportFilterProvider);
    final chips = ['This Week', 'This Month', 'Last Month', 'This Year', 'Custom'];
    return Column(
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: chips.map((label) {
              final selected = _active == label;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: Text(label,
                      style: GoogleFonts.lato(
                          color: selected ? Colors.white : null,
                          fontWeight: selected ? FontWeight.bold : FontWeight.normal)),
                  selected: selected,
                  selectedColor: _kIncome,
                  backgroundColor: Theme.of(context).cardColor,
                  checkmarkColor: Colors.white,
                  side: BorderSide(color: Colors.grey.withOpacity(0.2)),
                  onSelected: (_) {
                    if (label == 'Custom') {
                      _pickCustom();
                    } else {
                      setState(() => _active = label);
                      final n = ref.read(reportFilterProvider.notifier);
                      if (label == 'This Week') n.setThisWeek();
                      if (label == 'This Month') n.setThisMonth();
                      if (label == 'Last Month') n.setLastMonth();
                      if (label == 'This Year') n.setThisYear();
                    }
                  },
                ),
              );
            }).toList(),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Card(
            elevation: 2,
            margin: EdgeInsets.zero,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: _kIncome.withOpacity(0.3)),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Icon(Icons.date_range_rounded, color: _kIncome, size: 18),
                const SizedBox(width: 8),
                Text(_fmt.format(filter.from),
                    style: GoogleFonts.lato()),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Icon(Icons.arrow_forward_rounded,
                      color: Theme.of(context).iconTheme.color?.withOpacity(0.5), size: 16),
                ),
                Text(_fmt.format(filter.to),
                    style: GoogleFonts.lato()),
                const Spacer(),
              ],
            ),
            ),
          ),
        ),
      ],
    );
  }
}

// ─── KPI Card ────────────────────────────────────────────────────────────────
class _KpiCard extends StatelessWidget {
  final String label;
  final double value;
  final IconData icon;
  final Color color;
  final bool isCurrency;

  const _KpiCard(this.label, this.value, this.icon, this.color,
      {this.isCurrency = true});

  @override
  Widget build(BuildContext context) {
    final display = isCurrency ? _cur.format(value) : value.toInt().toString();
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: color.withOpacity(0.25)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 12),
          Text(display,
              style: GoogleFonts.montserrat(
                  fontWeight: FontWeight.bold,
                  fontSize: 18)),
          const SizedBox(height: 4),
          Text(label,
              style: GoogleFonts.lato(fontSize: 12, color: Theme.of(context).textTheme.bodySmall?.color)),
        ],
      ),
      ),
    );
  }
}

// ─── Monthly Bar Chart ───────────────────────────────────────────────────────
class _MonthlyChart extends ConsumerWidget {
  const _MonthlyChart();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final incomeAsync = ref.watch(last12MonthsIncomeProvider);
    final expenseAsync = ref.watch(last12MonthsExpensesProvider);

    return incomeAsync.when(
      loading: () => const SizedBox(
          height: 200,
          child: Center(child: CircularProgressIndicator(color: _kIncome))),
      error: (e, _) => const SizedBox(),
      data: (incomes) {
        return expenseAsync.when(
          loading: () => const SizedBox(
              height: 200,
              child: Center(child: CircularProgressIndicator(color: _kIncome))),
          error: (e, _) => const SizedBox(),
          data: (expensesList) {
            final now = DateTime.now();
            final maxVal = [
              ...incomes,
              ...expensesList,
              1.0,
            ].reduce((a, b) => a > b ? a : b);

            return Card(
              elevation: 2,
              margin: const EdgeInsets.symmetric(horizontal: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: Colors.grey.withOpacity(0.2)),
              ),
              child: Container(
                height: 220,
                padding: const EdgeInsets.fromLTRB(8, 16, 16, 8),
                child: BarChart(
                BarChartData(
                  maxY: maxVal * 1.25,
                  barTouchData: BarTouchData(
                    enabled: true,
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipColor: (_) => Theme.of(context).colorScheme.surface,
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        final label = rodIndex == 0 ? 'Income' : 'Expense';
                        return BarTooltipItem(
                          '$label\n${_cur.format(rod.toY)}',
                          GoogleFonts.lato(
                              color: rodIndex == 0 ? _kIncome : _kExpense,
                              fontSize: 11,
                              fontWeight: FontWeight.bold),
                        );
                      },
                    ),
                  ),
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (val, meta) {
                          final idx = val.toInt();
                          if (idx < 0 || idx >= 12) return const SizedBox();
                          final m = DateTime(now.year, now.month - 11 + idx);
                          return Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              DateFormat('MMM').format(m),
                              style: GoogleFonts.lato(fontSize: 9),
                            ),
                          );
                        },
                        reservedSize: 28,
                      ),
                    ),
                    leftTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                  ),
                  gridData: FlGridData(
                    show: true,
                    getDrawingHorizontalLine: (_) =>
                        FlLine(color: Colors.grey.withOpacity(0.2), strokeWidth: 1),
                    drawVerticalLine: false,
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: List.generate(12, (i) {
                    final income = i < incomes.length ? incomes[i] : 0.0;
                    final exp = i < expensesList.length ? expensesList[i] : 0.0;
                    return BarChartGroupData(
                      x: i,
                      barRods: [
                        BarChartRodData(
                          toY: income,
                          color: _kIncome,
                          width: 7,
                          borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(4)),
                        ),
                        BarChartRodData(
                          toY: exp,
                          color: _kExpense,
                          width: 7,
                          borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(4)),
                        ),
                      ],
                      groupVertically: false,
                      barsSpace: 3,
                    );
                  }),
                ),
              ),
            ),
          );
        },
      );
      },
    );
  }
}

// ─── Method Bar ──────────────────────────────────────────────────────────────
class _MethodBar extends StatelessWidget {
  final String label;
  final double amount;
  final double total;
  final Color color;
  const _MethodBar(this.label, this.amount, this.total, this.color);

  @override
  Widget build(BuildContext context) {
    final pct = total > 0 ? (amount / total).clamp(0.0, 1.0) : 0.0;
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.withOpacity(0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label,
                  style: GoogleFonts.lato(fontSize: 13)),
              Text(_cur.format(amount),
                  style: GoogleFonts.montserrat(
                      color: color,
                      fontWeight: FontWeight.bold,
                      fontSize: 13)),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 8,
              backgroundColor: Colors.grey.withOpacity(0.2),
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
          const SizedBox(height: 4),
          Text('${(pct * 100).toStringAsFixed(1)}% of total income',
              style: GoogleFonts.lato(fontSize: 11, color: Theme.of(context).textTheme.bodySmall?.color)),
        ],
      ),
      ),
    );
  }
}

// ─── Transactions Tab ────────────────────────────────────────────────────────
class _TransactionsTab extends ConsumerStatefulWidget {
  const _TransactionsTab();
  @override
  ConsumerState<_TransactionsTab> createState() => _TransactionsTabState();
}

class _TransactionsTabState extends ConsumerState<_TransactionsTab>
    with SingleTickerProviderStateMixin {
  late TabController _sub;

  @override
  void initState() {
    super.initState();
    _sub = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _sub.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final payments = ref.watch(reportPaymentsProvider);
    final expenses = ref.watch(reportExpensesProvider);
    final members = ref.watch(membersProvider);

    // Pending members
    final pendingMembers = members.value
            ?.where((m) => (m.monthlyPlanAmount ?? 0) > (m.paidAmount ?? 0))
            .toList() ??
        [];

    return Column(
      children: [
        const _FilterBar(),
        const SizedBox(height: 12),
        Material(
          elevation: 2,
          color: Theme.of(context).colorScheme.primary,
          child: TabBar(
            controller: _sub,
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white.withOpacity(0.7),
            labelStyle:
                GoogleFonts.lato(fontWeight: FontWeight.bold, fontSize: 13),
            tabs: [
              Tab(text: 'Income (${payments.value?.length ?? 0})'),
              Tab(text: 'Expenses (${expenses.value?.length ?? 0})'),
              Tab(text: 'Pending (${pendingMembers.length})'),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _sub,
            children: [
              _PaymentsList(payments.value ?? [], payments.isLoading),
              _ExpensesList(expenses.value ?? [], expenses.isLoading),
              _PendingList(pendingMembers),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Income list ─────────────────────────────────────────────────────────────
class _PaymentsList extends StatelessWidget {
  final List<PaymentModel> payments;
  final bool loading;
  const _PaymentsList(this.payments, this.loading);

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Center(child: CircularProgressIndicator(color: _kIncome));
    }
    if (payments.isEmpty) {
      return _EmptyState('No income records', Icons.payments_rounded);
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: payments.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, i) {
        final p = payments[i];
        return _TxCard(
          icon: Icons.arrow_upward_rounded,
          color: _kIncome,
          title: 'Payment — ${p.paymentMethod}',
          subtitle: _fmt.format(p.paymentDate),
          amount: p.amount,
          isPositive: true,
        );
      },
    );
  }
}

// ─── Expenses list ───────────────────────────────────────────────────────────
class _ExpensesList extends StatelessWidget {
  final List<ExpenseModel> expenses;
  final bool loading;
  const _ExpensesList(this.expenses, this.loading);

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Center(child: CircularProgressIndicator(color: _kIncome));
    }
    if (expenses.isEmpty) {
      return _EmptyState('No expense records', Icons.money_off_rounded);
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: expenses.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, i) {
        final e = expenses[i];
        return _TxCard(
          icon: Icons.arrow_downward_rounded,
          color: _kExpense,
          title: e.title,
          subtitle: e.description.isNotEmpty
              ? '${e.description} • ${_fmt.format(e.date)}'
              : _fmt.format(e.date),
          amount: e.amount,
          isPositive: false,
        );
      },
    );
  }
}

// ─── Pending list ────────────────────────────────────────────────────────────
class _PendingList extends StatelessWidget {
  final List<MemberModel> members;
  const _PendingList(this.members);

  @override
  Widget build(BuildContext context) {
    if (members.isEmpty) {
      return const _EmptyState('No pending dues', Icons.check_circle_rounded);
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: members.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, i) {
        final m = members[i];
        final due = (m.monthlyPlanAmount ?? 0) - (m.paidAmount ?? 0);
        return _TxCard(
          icon: Icons.hourglass_bottom_rounded,
          color: _kPending,
          title: m.name,
          subtitle:
              'Plan: ${_cur.format(m.monthlyPlanAmount ?? 0)}  •  Paid: ${_cur.format(m.paidAmount ?? 0)}',
          amount: due,
          isPositive: false,
          amountLabel: 'Due',
        );
      },
    );
  }
}

// ─── Transaction Card ────────────────────────────────────────────────────────
class _TxCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final double amount;
  final bool isPositive;
  final String? amountLabel;

  const _TxCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.isPositive,
    this.amountLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: color.withOpacity(0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: GoogleFonts.lato(
                        fontWeight: FontWeight.bold,
                        fontSize: 14),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text(subtitle,
                    style:
                        GoogleFonts.lato(fontSize: 12, color: Theme.of(context).textTheme.bodySmall?.color),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${isPositive ? '+' : '-'}${_cur.format(amount)}',
                style: GoogleFonts.montserrat(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 14),
              ),
              if (amountLabel != null)
                Text(amountLabel!,
                    style:
                        GoogleFonts.lato(fontSize: 11, color: Theme.of(context).textTheme.bodySmall?.color)),
            ],
          ),
        ],
      ),
      ),
    );
  }
}

// ─── Empty State ─────────────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  final String message;
  final IconData icon;
  const _EmptyState(this.message, this.icon);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 56, color: Colors.grey),
          const SizedBox(height: 12),
          Text(message,
              style: GoogleFonts.lato(fontSize: 16, color: Theme.of(context).textTheme.bodySmall?.color)),
        ],
      ),
    );
  }
}
