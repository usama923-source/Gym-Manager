import 'package:flutter/material.dart';

class GymProfileScreen extends StatelessWidget {
  const GymProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gym'),
      ),
      body: const Center(
        child: Text(
          'Gym Settings & Info',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
