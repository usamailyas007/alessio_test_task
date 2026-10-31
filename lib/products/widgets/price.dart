import 'package:alessio_test_task/core/theme.dart';
import 'package:alessio_test_task/products/product.dart';
import 'package:flutter/material.dart';

String formatPrice(double value) => '\$${value.toStringAsFixed(2)}';

class Price extends StatelessWidget {
  const Price({required this.product, this.large = false, super.key});

  final Product product;
  final bool large;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final base = large
        ? theme.textTheme.headlineSmall
        : theme.textTheme.titleMedium;
    final current = product.hasDiscount
        ? product.discountedPrice
        : product.price;

    return Semantics(
      label: product.hasDiscount
          ? '${formatPrice(current)}, was ${formatPrice(product.price)}'
          : formatPrice(current),
      excludeSemantics: true,
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.end,
        spacing: Spacing.sm,
        children: [
          Text(
            formatPrice(current),
            style: base?.copyWith(
              fontWeight: FontWeight.w600,
              fontFeatures: tabularFigures,
            ),
          ),
          if (product.hasDiscount)
            Text(
              formatPrice(product.price),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                decoration: TextDecoration.lineThrough,
                fontFeatures: tabularFigures,
              ),
            ),
        ],
      ),
    );
  }
}
