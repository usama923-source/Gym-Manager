import 'package:flutter/material.dart';
import 'package:gym/features/gym_owner/gym_owner_dashboard.dart';
import 'package:gym/features/gym_owner/presentation/members_screen.dart';
import 'package:gym/features/gym_owner/presentation/reports_screen.dart';

class GymOwnerMainScreen extends StatefulWidget {
  const GymOwnerMainScreen({super.key});

  @override
  State<GymOwnerMainScreen> createState() => _GymOwnerMainScreenState();
}

class _GymOwnerMainScreenState extends State<GymOwnerMainScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          GymOwnerDashboard(
            onNavigateToMembers: () {
              setState(() {
                _currentIndex = 1;
              });
            },
          ),
          const MembersScreen(),
          const ReportsScreen(),
        ],
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
