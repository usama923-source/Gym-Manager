import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gym/features/gym_owner/presentation/providers/gym_owner_providers.dart';
import 'package:intl/intl.dart';

class IncomeReportScreen extends ConsumerWidget {
  const IncomeReportScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final monthlyPaymentsAsync = ref.watch(monthlyPaymentsListProvider);
    final membersAsync = ref.watch(membersProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Income Report (This Month)'),
      ),
      body: monthlyPaymentsAsync.when(
        data: (payments) {
          if (payments.isEmpty) {
            return const Center(child: Text('No payments recorded this month.'));
          }

          return membersAsync.when(
            data: (members) {
              return ListView.builder(
                itemCount: payments.length,
                itemBuilder: (context, index) {
                  final payment = payments[index];
                  // Find member details to get name
                  final member = members.where((m) => m.id == payment.memberId).firstOrNull;
                  final memberName = member?.name ?? 'Unknown Member';

                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.green.shade100,
                        child: const Icon(Icons.attach_money, color: Colors.green),
                      ),
                      title: Text(
                        memberName,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          Text('Method: ${payment.paymentMethod}'),
                          Text('Date: ${DateFormat('MMM dd, yyyy').format(payment.paymentDate)}'),
                        ],
                      ),
                      trailing: Text(
                        '\$${payment.amount.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ),
                  );
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, st) => Center(child: Text('Error loading members: $e')),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error loading payments: $e')),
      ),
    );
  }
}
