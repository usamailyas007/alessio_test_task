import 'package:alessio_test_task/core/api_exception.dart';
import 'package:alessio_test_task/core/theme.dart';
import 'package:flutter/material.dart';

class LoadMoreFooter extends StatelessWidget {
  const LoadMoreFooter({required this.error, required this.onRetry, super.key});

  final ApiException? error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final error = this.error;
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Spacing.md),
      child: error == null
          ? const Center(
              child: SizedBox.square(
                dimension: Sizes.progress,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          : Row(
              children: [
                Expanded(
                  child: Text(
                    error.message,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.error,
                    ),
                  ),
                ),
                TextButton(onPressed: onRetry, child: const Text('Retry')),
              ],
            ),
    );
  }
}
