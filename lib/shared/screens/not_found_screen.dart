import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/extensions/context_ext.dart';
import '../../core/router/route_names.dart';

class NotFoundScreen extends StatelessWidget {
  const NotFoundScreen({super.key, this.error});
  final Exception? error;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.map_outlined,
                size: 64,
                color: context.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(height: 16),
              Text(
                'Page Not Found',
                style: context.textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                'The page you\'re looking for doesn\'t exist.',
                style: context.textTheme.bodyMedium?.copyWith(
                  color: context.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () => context.go(RouteNames.home),
                child: const Text('Go Home'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
