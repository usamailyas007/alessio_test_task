import 'package:alessio_test_task/core/theme.dart';
import 'package:flutter/material.dart';

class Rating extends StatelessWidget {
  const Rating({required this.value, super.key});

  final double value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      label: 'Rated ${value.toStringAsFixed(1)} out of 5',
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.star_rounded, size: 16, color: theme.colorScheme.primary),
          const SizedBox(width: Spacing.xs),
          Text(
            value.toStringAsFixed(1),
            style: theme.textTheme.labelMedium?.copyWith(
              fontFeatures: tabularFigures,
            ),
          ),
        ],
      ),
    );
  }
}
