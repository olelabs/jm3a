import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../../core/theme/app_colors.dart';

class TodLoadingScreen extends StatelessWidget {
  const TodLoadingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.navyBlue,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🎯', style: TextStyle(fontSize: 72))
                .animate().scale(
                  begin: const Offset(0.5, 0.5), end: const Offset(1, 1),
                  duration: 600.ms, curve: Curves.elasticOut),
            const SizedBox(height: 24),
            const Text('Truth or Dare',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800,
                    color: Colors.white))
                .animate(delay: 200.ms).fadeIn().slideY(begin: 0.2, end: 0),
            const SizedBox(height: 12),
            Text('Loading game…',
                style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.6)))
                .animate(delay: 350.ms).fadeIn(),
            const SizedBox(height: 40),
            SizedBox(
              width: 24, height: 24,
              child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Colors.white.withOpacity(0.6))),
          ],
        ),
      ),
    );
  }
}
