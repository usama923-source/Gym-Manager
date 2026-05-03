import 'package:flutter/material.dart';
import 'package:gym/features/gym_owner/gym_owner_dashboard.dart';
import 'package:gym/features/gym_owner/presentation/gym_profile_screen.dart';
import 'package:gym/features/gym_owner/presentation/members_screen.dart';
import 'package:gym/features/gym_owner/presentation/reports_screen.dart';

class GymOwnerMainScreen extends StatefulWidget {
  const GymOwnerMainScreen({super.key});

  @override
  State<GymOwnerMainScreen> createState() => _GymOwnerMainScreenState();
}

class _GymOwnerMainScreenState extends State<GymOwnerMainScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const GymOwnerDashboard(),
    const MembersScreen(),
    const ReportsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.people_outline),
            selectedIcon: Icon(Icons.people),
            label: 'Members',
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart_outlined),
            selectedIcon: Icon(Icons.bar_chart),
            label: 'Reports',
          ),
        ],
      ),
    );
  }
}
