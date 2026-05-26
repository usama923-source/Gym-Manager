import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gym/features/gym_owner/presentation/providers/gym_owner_providers.dart';
import 'package:gym/features/gym_owner/data/repositories/gym_owner_repository.dart';
import 'package:gym/features/gym_owner/presentation/widgets/renew_plan_dialog.dart';
import 'package:intl/intl.dart';

class ExpiredMembersScreen extends ConsumerStatefulWidget {
  const ExpiredMembersScreen({super.key});

  @override
  ConsumerState<ExpiredMembersScreen> createState() => _ExpiredMembersScreenState();
}

class _ExpiredMembersScreenState extends ConsumerState<ExpiredMembersScreen> {
  String _searchQuery = '';
  DateTime? _fromDate;
  DateTime? _toDate;

  @override
  Widget build(BuildContext context) {
    final expiredMembers = ref.watch(expiredMembersProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Expired Members'),
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          _buildFilterBar(),
          Expanded(
            child: expiredMembers.isEmpty
                ? const Center(child: Text('No expired members found.'))
                : Builder(
                    builder: (context) {
                      var filteredMembers = expiredMembers;
                      
                      if (_searchQuery.isNotEmpty) {
                        filteredMembers = filteredMembers
                            .where((m) => m.name.toLowerCase().contains(_searchQuery.toLowerCase()))
                            .toList();
                      }
                      
                      if (_fromDate != null) {
                        final from = DateTime(_fromDate!.year, _fromDate!.month, _fromDate!.day);
                        filteredMembers = filteredMembers.where((m) {
                          if (m.expiryDate == null) return false;
                          return m.expiryDate!.isAfter(from.subtract(const Duration(seconds: 1)));
                        }).toList();
                      }
                      
                      if (_toDate != null) {
                        final to = DateTime(_toDate!.year, _toDate!.month, _toDate!.day, 23, 59, 59);
                        filteredMembers = filteredMembers.where((m) {
                          if (m.expiryDate == null) return false;
                          return m.expiryDate!.isBefore(to);
                        }).toList();
                      }

                      if (filteredMembers.isEmpty) {
                        return const Center(child: Text('No members found for selected criteria.'));
                      }

                      return ListView.builder(
                        itemCount: filteredMembers.length,
                        itemBuilder: (context, index) {
                          final member = filteredMembers[index];
                          final dueAmount = (member.monthlyPlanAmount ?? 0) - (member.paidAmount ?? 0);
                          
                          return Card(
                            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          member.name,
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      if (member.expiryDate != null)
                                        Text(
                                          'Expired: ${DateFormat('MMM dd, yyyy').format(member.expiryDate!)}',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: Colors.red,
                                          ),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text('Phone: ${member.phone ?? 'N/A'}'),
                                  Text('ID: ${member.memberId ?? member.id}'),
                                  Text(
                                    'Previous Due: \$${dueAmount.toStringAsFixed(2)}',
                                    style: TextStyle(
                                      color: dueAmount > 0 ? Colors.red : Colors.green,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      TextButton.icon(
                                        onPressed: () => _confirmPermanentDelete(context, ref, member.id),
                                        icon: const Icon(Icons.delete_forever, color: Colors.red),
                                        label: const Text('Permanent Delete', style: TextStyle(color: Colors.red)),
                                      ),
                                      const SizedBox(width: 8),
                                      ElevatedButton.icon(
                                        onPressed: () {
                                          showDialog(
                                            context: context,
                                            builder: (context) => RenewPlanDialog(member: member),
                                          );
                                        },
                                        icon: const Icon(Icons.autorenew),
                                        label: const Text('Subscribe Again'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.green,
                                          foregroundColor: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 0),
      child: TextField(
        decoration: InputDecoration(
          hintText: 'Search expired member by name...',
          prefixIcon: const Icon(Icons.search),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
        ),
        onChanged: (value) {
          setState(() {
            _searchQuery = value;
          });
        },
      ),
    );
  }

  Widget _buildFilterBar() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              icon: const Icon(Icons.date_range, size: 18),
              label: Text(
                _fromDate == null ? 'From Date' : DateFormat('MMM dd, yyyy').format(_fromDate!),
                overflow: TextOverflow.ellipsis,
              ),
              onPressed: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _fromDate ?? DateTime.now(),
                  firstDate: DateTime(2000),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (date != null) {
                  setState(() => _fromDate = date);
                }
              },
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: OutlinedButton.icon(
              icon: const Icon(Icons.date_range, size: 18),
              label: Text(
                _toDate == null ? 'To Date' : DateFormat('MMM dd, yyyy').format(_toDate!),
                overflow: TextOverflow.ellipsis,
              ),
              onPressed: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _toDate ?? DateTime.now(),
                  firstDate: DateTime(2000),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (date != null) {
                  setState(() => _toDate = date);
                }
              },
            ),
          ),
          if (_fromDate != null || _toDate != null)
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () {
                setState(() {
                  _fromDate = null;
                  _toDate = null;
                });
              },
            ),
        ],
      ),
    );
  }

  Future<void> _confirmPermanentDelete(BuildContext context, WidgetRef ref, String memberId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Permanent Delete'),
        content: const Text('Are you sure you want to permanently delete this member? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await ref.read(gymOwnerRepositoryProvider).permanentDeleteMember(memberId);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Member permanently deleted')),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to delete: $e')),
          );
        }
      }
    }
  }
}
