// lib/test_main_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class TestMainScreen extends StatelessWidget {
  const TestMainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Jma3a - Test Mode'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.groups_rounded, size: 80, color: Colors.blue),
              const SizedBox(height: 20),
              const Text(
                'Welcome to Jma3a',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              const Text(
                'Test Mode - Database Disabled',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: () {
                  // Navigate to auth screen
                  // context.go(RouteNames.authEmail);
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 40,
                    vertical: 15,
                  ),
                ),
                child: const Text('Continue to Auth'),
              ),
              const SizedBox(height: 20),
              OutlinedButton(
                onPressed: () {
                  // Exit app
                },
                child: const Text('Exit'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
