import 'package:flutter/material.dart';
import 'package:gym/features/gym_owner/presentation/widgets/gym_owner_drawer.dart';

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports'),
      ),
      drawer: const GymOwnerDrawer(),
      body: const Center(
        child: Text(
          'Financial & Attendance Reports',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
