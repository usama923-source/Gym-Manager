import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:gym/features/auth/presentation/providers/auth_provider.dart';
import 'package:gym/features/member/presentation/providers/member_providers.dart';


class MemberDashboard extends ConsumerWidget {
  const MemberDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);
    final myDetails = ref.watch(myDetailsProvider);
    final myWorkouts = ref.watch(myWorkoutsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Dashboard'),
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
                    'Hello, ${authState.value?.name ?? 'Member'}!',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Membership Status Card
                  myDetails.when(
                    data: (member) {
                      if (member == null) return const SizedBox.shrink();
                      
                      final isExpired = !member.isMembershipActive;
                      return Card(
                        color: isExpired ? Colors.red.shade50 : Colors.green.shade50,
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            children: [
                              Icon(
                                isExpired ? Icons.warning : Icons.check_circle,
                                color: isExpired ? Colors.red : Colors.green,
                                size: 32,
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Membership Status: ${isExpired ? 'Expired' : 'Active'}',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: isExpired ? Colors.red : Colors.green,
                                      ),
                                    ),
                                    Text('Goal: ${member.membershipType}'),
                                    Text(
                                      'Valid till: ${member.expiryDate != null ? DateFormat('MMM dd, yyyy').format(member.expiryDate!) : 'N/A'}',
                                      style: Theme.of(context).textTheme.bodySmall,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (e, stack) => Text('Error loading details: \$e'),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('My Workout Plans', style: Theme.of(context).textTheme.titleLarge),
                      TextButton.icon(
                        icon: const Icon(Icons.camera_alt),
                        label: const Text('Add Progress'),
                        onPressed: () {
                          // Handle progress photo upload
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
          myWorkouts.when(
            data: (workouts) {
              if (workouts.isEmpty) {
                return const SliverToBoxAdapter(
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.all(32.0),
                      child: Text('No workouts assigned yet. Check back later!'),
                    ),
                  ),
                );
              }
              return SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final workout = workouts[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: ExpansionTile(
                        title: Text('Workout Plan - ${DateFormat('MMM dd').format(workout.createdAt)}'),
                        subtitle: Text('${workout.exercises.length} Exercises'),
                        children: [
                          if (workout.notes.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Text('Notes: ${workout.notes}', style: const TextStyle(fontStyle: FontStyle.italic)),
                            ),
                          ...workout.exercises.map((e) => ListTile(
                            leading: const Icon(Icons.fitness_center),
                            title: Text(e.name),
                            trailing: Text('${e.sets} sets x ${e.reps} reps'),
                          )),
                        ],
                      ),
                    );
                  },
                  childCount: workouts.length,
                ),
              );
            },
            loading: () => const SliverToBoxAdapter(
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, stack) => SliverToBoxAdapter(
              child: Center(child: Text('Error: \$e')),
            ),
          ),
        ],
      ),
    );
  }
}
