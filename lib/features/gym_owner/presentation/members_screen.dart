import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gym/features/gym_owner/presentation/providers/gym_owner_providers.dart';
import 'package:gym/features/gym_owner/data/repositories/gym_owner_repository.dart';
import 'package:gym/features/gym_owner/domain/models/attendance_model.dart';
import 'package:gym/features/gym_owner/domain/models/member_model.dart';
import 'package:gym/features/gym_owner/presentation/widgets/member_card_widget.dart';
import 'package:gym/features/gym_owner/presentation/member_detail_screen.dart';
import 'package:gym/features/gym_owner/presentation/widgets/gym_owner_drawer.dart';

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
                    return MemberCardWidget(
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
}
