import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gym/features/auth/presentation/providers/auth_provider.dart';
import 'package:gym/features/super_admin/presentation/providers/super_admin_providers.dart';
import 'package:intl/intl.dart';

class SuperAdminDashboard extends ConsumerWidget {
  const SuperAdminDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);
    final allGyms = ref.watch(allGymsProvider);
    
    final totalGyms = ref.watch(totalGymsProvider);
    final activeGyms = ref.watch(activeGymsProvider);
    final expiredGyms = ref.watch(expiredGymsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Super Admin Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => ref.read(authControllerProvider.notifier).logout(),
          ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Welcome, ${authState.value?.name ?? 'Admin'}",
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildStatCards(context, totalGyms, activeGyms, expiredGyms),
                  const SizedBox(height: 24),
                  Text(
                    'All Registered Gyms',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
          allGyms.when(
            data: (gyms) {
              if (gyms.isEmpty) {
                return const SliverToBoxAdapter(
                  child: Center(child: Text('No gyms registered yet.')),
                );
              }
              return SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final gym = gyms[index];
                    final isExpired = !gym.isSubscriptionActive;
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: ListTile(
                        onTap: () => _showGymDetailsDialog(context, ref, gym),
                        title: Text(gym.gymName),
                        subtitle: Text(
                          'Expires: ${DateFormat('MMM dd, yyyy').format(gym.subscriptionEnd)}\nStatus: ${isExpired ? 'Expired' : 'Active'}',  
                          style: TextStyle(
                            color: isExpired ? Colors.red : Colors.green,
                          ),
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.settings),
                          onPressed: () => _showGymActionsDialog(context, ref, gym),
                        ),
                      ),
                    );
                  },
                  childCount: gyms.length,
                ),
              );
            },
            loading: () => const SliverToBoxAdapter(
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, stack) => SliverToBoxAdapter(
              child: Center(child: Text('Error loading gyms: \$e')),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCards(BuildContext context, int total, int active, int expired) {
    return Row(
      children: [
        Expanded(child: _StatCard(title: 'Total Gyms', value: total.toString(), color: Colors.blue)),
        const SizedBox(width: 8),
        Expanded(child: _StatCard(title: 'Active', value: active.toString(), color: Colors.green)),
        const SizedBox(width: 8),
        Expanded(child: _StatCard(title: 'Expired', value: expired.toString(), color: Colors.red)),
      ],
    );
  }

  void _showGymActionsDialog(BuildContext context, WidgetRef ref, dynamic gym) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Manage ${gym.gymName}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
             ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                ref.read(superAdminControllerProvider).toggleGymStatus(gym.id, gym.isActive);
              },
              child: Text(gym.isActive ? 'Deactivate Gym' : 'Activate Gym'),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _showExtendSubscriptionDialog(context, ref, gym.id);
              },
              child: const Text('Extend Subscription'),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () {
                Navigator.pop(context);
                _showDeleteConfirmationDialog(context, ref, gym.id, gym.ownerId);
              },
              child: const Text('Delete Gym', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  void _showExtendSubscriptionDialog(BuildContext context, WidgetRef ref, String gymId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Extend Subscription'),
        content: const Text("Add 30 days to the gym's subscription?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              ref.read(superAdminControllerProvider).extendSubscription(gymId, 30);
              Navigator.pop(ctx);
            },
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }
  
  void _showDeleteConfirmationDialog(BuildContext context, WidgetRef ref, String gymId, String ownerId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Gym'),
        content: const Text('Are you sure? This will delete the gym and the owner account permanently.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              ref.read(superAdminControllerProvider).deleteGym(gymId, ownerId);
              Navigator.pop(ctx);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showGymDetailsDialog(BuildContext context, WidgetRef ref, dynamic gym) {
    showDialog(
      context: context,
      builder: (context) {
        return _GymDetailsDialog(gym: gym);
      },
    );
  }
}

class _GymDetailsDialog extends ConsumerWidget {
  final dynamic gym; // GymModel

  const _GymDetailsDialog({required this.gym});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ownerAsync = ref.watch(gymOwnerProvider(gym.ownerId));

    return AlertDialog(
      title: const Text('Gym Details'),
      content: ownerAsync.when(
        data: (owner) {
          if (owner == null) return const Text('Owner details not found.');
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Gym Name: ${gym.gymName}', style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text('Full Name: ${owner.name}'),
              const SizedBox(height: 4),
              Text('Email: ${owner.email}'),
              const SizedBox(height: 4),
              Text('Status: ${gym.isActive ? 'Active' : 'Deactivated'}'),
              const SizedBox(height: 4),
              Text('Subscription: ${gym.isSubscriptionActive ? 'Active' : 'Expired'}'),
            ],
          );
        },
        loading: () => const SizedBox(
          height: 100,
          child: Center(child: CircularProgressIndicator()),
        ),
        error: (e, st) => Text('Error loading details: $e'),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final Color color;

  const _StatCard({required this.title, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16.0),
        child: Column(
          children: [
            Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
            const SizedBox(height: 4),
            Text(title, style: Theme.of(context).textTheme.bodySmall, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
