import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gym/features/gym_owner/presentation/providers/gym_owner_providers.dart';
import 'package:gym/features/gym_owner/domain/models/member_model.dart';
import 'package:gym/features/gym_owner/presentation/widgets/member_card_widget.dart';
import 'package:gym/features/gym_owner/presentation/member_detail_screen.dart';
import 'package:gym/features/gym_owner/presentation/widgets/gym_owner_drawer.dart';
import 'package:gym/features/gym_owner/presentation/add_member_screen.dart';
import 'package:gym/features/gym_owner/data/repositories/gym_owner_repository.dart';

class MembersScreen extends ConsumerStatefulWidget {
  const MembersScreen({super.key});

  @override
  ConsumerState<MembersScreen> createState() => _MembersScreenState();
}

class _MembersScreenState extends ConsumerState<MembersScreen> {
  String _searchQuery = '';
  DateTime? _fromDate;
  DateTime? _toDate;

  @override
  Widget build(BuildContext context) {
    final membersAsync = ref.watch(membersProvider);
    final attendancesAsync = ref.watch(todayAttendanceProvider);
    final attendances = attendancesAsync.value ?? [];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Members'),
      ),
      drawer: const GymOwnerDrawer(),
      body: Column(
        children: [
          _buildSearchBar(),
          _buildFilterBar(),
          _buildStatusFilter(),
          Expanded(
            child: membersAsync.when(
              data: (members) {
                if (members.isEmpty) {
                  return const Center(child: Text('No members found.'));
                }
                
                Iterable<MemberModel> filteredMembers = members;
                if (_searchQuery.isNotEmpty) {
                  filteredMembers = filteredMembers.where((m) => m.name.toLowerCase().contains(_searchQuery.toLowerCase()));
                }
                final statusFilter = ref.watch(membersStatusFilterProvider);
                if (statusFilter == 'Active') {
                  filteredMembers = filteredMembers.where((m) => m.isMembershipActive);
                }
                if (_fromDate != null) {
                  final from = DateTime(_fromDate!.year, _fromDate!.month, _fromDate!.day);
                  filteredMembers = filteredMembers.where((m) => m.createdAt.isAfter(from.subtract(const Duration(seconds: 1))));
                }
                if (_toDate != null) {
                  final to = DateTime(_toDate!.year, _toDate!.month, _toDate!.day, 23, 59, 59);
                  filteredMembers = filteredMembers.where((m) => m.createdAt.isBefore(to));
                }

                final sortedMembers = filteredMembers.toList();
                
                if (sortedMembers.isEmpty) {
                  return const Center(child: Text('No members found for selected criteria.'));
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(8.0),
                  itemCount: sortedMembers.length,
                  itemBuilder: (context, index) {
                    final member = sortedMembers[index];
                    return Dismissible(
                      key: Key(member.id),
                      background: Container(
                        color: Colors.green,
                        alignment: Alignment.centerLeft,
                        padding: const EdgeInsets.only(left: 20.0),
                        child: const Icon(Icons.edit, color: Colors.white),
                      ),
                      secondaryBackground: Container(
                        color: Colors.red,
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20.0),
                        child: const Icon(Icons.delete, color: Colors.white),
                      ),
                      confirmDismiss: (direction) async {
                        if (direction == DismissDirection.startToEnd) {
                          // Swipe to edit
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => AddMemberScreen(member: member),
                            ),
                          );
                          return false; // Don't actually dismiss the item
                        } else if (direction == DismissDirection.endToStart) {
                          // Swipe to delete
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Delete Member'),
                              content: const Text('Are you sure you want to delete this member?'),
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
                            await ref.read(gymOwnerRepositoryProvider).deleteMember(member.id);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Member deleted successfully')),
                              );
                            }
                            return true;
                          }
                          return false;
                        }
                        return false;
                      },
                      child: MemberCardWidget(
                        member: member,
                        attendances: attendances,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => MemberDetailScreen(member: member),
                            ),
                          );
                        },
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(child: Text('Error: $error')),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AddMemberScreen(),
            ),
          );
        },
        icon: const Icon(Icons.person_add),
        label: const Text('Add Member'),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 0),
      child: TextField(
        decoration: InputDecoration(
          hintText: 'Search member by name...',
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
                _fromDate == null ? 'From Date' : _fromDate.toString().split(' ')[0],
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
                _toDate == null ? 'To Date' : _toDate.toString().split(' ')[0],
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

  Widget _buildStatusFilter() {
    final statusFilter = ref.watch(membersStatusFilterProvider);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        children: [
          const Text('Show:', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(width: 16),
          ChoiceChip(
            label: const Text('All'),
            selected: statusFilter == 'All',
            onSelected: (selected) {
              if (selected) {
                ref.read(membersStatusFilterProvider.notifier).setFilter('All');
              }
            },
          ),
          const SizedBox(width: 8),
          ChoiceChip(
            label: const Text('Active Members'),
            selected: statusFilter == 'Active',
            onSelected: (selected) {
              if (selected) {
                ref.read(membersStatusFilterProvider.notifier).setFilter('Active');
              }
            },
          ),
        ],
      ),
    );
  }
}
