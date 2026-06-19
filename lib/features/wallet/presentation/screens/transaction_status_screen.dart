import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/extensions/context_ext.dart';
import '../../../../core/theme/app_colors.dart';
// ── Transaction status screen ─────────────────────────────────────────────────

class TransactionStatusScreen extends StatelessWidget {
  const TransactionStatusScreen({
    super.key,
    required this.isSuccess,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
  });

  final bool     isSuccess;
  final String   title;
  final String   subtitle;
  final IconData icon;
  final Color    iconColor;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icon
              Container(
                width: 88, height: 88,
                decoration: BoxDecoration(
                  color:  iconColor.withOpacity(0.12),
                  shape:  BoxShape.circle,
                ),
                child: Icon(icon, size: 44, color: iconColor),
              )
                  .animate()
                  .scale(
                    begin: const Offset(0.3, 0.3),
                    end:   const Offset(1, 1),
                    duration: 500.ms,
                    curve: Curves.elasticOut,
                  ),

              const SizedBox(height: 28),

              Text(title,
                  style: context.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800),
                  textAlign: TextAlign.center)
                  .animate(delay: 200.ms).fadeIn(),

              const SizedBox(height: 12),

              Text(subtitle,
                  style: context.textTheme.bodyMedium?.copyWith(
                      color: context.colorScheme.onSurfaceVariant,
                      height: 1.6),
                  textAlign: TextAlign.center)
                  .animate(delay: 280.ms).fadeIn(),

              const SizedBox(height: 40),

              FilledButton(
                onPressed: () =>
                    Navigator.of(context).popUntil((r) => r.isFirst),
                style: FilledButton.styleFrom(
                  minimumSize: const Size(double.infinity, 52),
                ),
                child: const Text('Back to Wallet'),
              ).animate(delay: 400.ms).fadeIn(),
            ],
          ),
        ),
      ),
    );
  }
}
