import 'package:flutter/material.dart';

class EmptyStateView extends StatelessWidget {
  const EmptyStateView({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.article_outlined,
            size: 64,
            color: Theme.of(context).colorScheme.outline.withOpacity(0.5),
          ),
          const SizedBox(height: 24),
          Text(
            'No meeting selected',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Start a new recording or select a meeting from the left panel',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
