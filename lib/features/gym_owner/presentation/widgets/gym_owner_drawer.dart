import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gym/features/auth/presentation/providers/auth_provider.dart';

class GymOwnerDrawer extends ConsumerWidget {
  const GymOwnerDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);

    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  DrawerHeader(
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        GestureDetector(
                          onTap: () {
                            context.pop();
                            context.push('/edit-profile');
                          },
                          child: const CircleAvatar(
                            radius: 30,
                            child: Icon(Icons.person, size: 30),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          authState.value?.name ?? 'Owner',
                          style: const TextStyle(color: Colors.white, fontSize: 18),
                        ),
                      ],
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Text(
                      'Gym Management',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey),
                    ),
                  ),
                  ListTile(
                    leading: const Icon(Icons.store),
                    title: const Text('Manage Branch'),
                    onTap: () {
                      context.pop();
                      // TODO: Implement Manage Branch
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.attach_money),
                    title: const Text('Expenses'),
                    onTap: () {
                      context.pop();
                      context.push('/expenses');
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.download),
                    title: const Text('Member Reports Downloads'),
                    onTap: () {
                      context.pop();
                      // TODO: Implement Member Reports Downloads
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.delete_outline),
                    title: const Text('Deleted Members'),
                    onTap: () {
                      context.pop();
                      context.push('/deleted-members');
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.block),
                    title: const Text('Expired Members'),
                    onTap: () {
                      context.pop();
                      context.push('/expired-members');
                    },
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('Logout', style: TextStyle(color: Colors.red)),
              onTap: () {
                context.pop();
                ref.read(authControllerProvider.notifier).logout();
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
