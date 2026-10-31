import 'package:alessio_test_task/core/api_exception.dart';
import 'package:alessio_test_task/core/theme.dart';
import 'package:alessio_test_task/products/product.dart';
import 'package:alessio_test_task/products/products_repository.dart';
import 'package:alessio_test_task/products/widgets/image_gallery.dart';
import 'package:alessio_test_task/products/widgets/info_row.dart';
import 'package:alessio_test_task/products/widgets/message_view.dart';
import 'package:alessio_test_task/products/widgets/price.dart';
import 'package:alessio_test_task/products/widgets/rating.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

String productPath(int id) => '/products/$id';

final productDetailProvider = FutureProvider.autoDispose.family<Product, int>(
  (ref, id) => ref.watch(productsRepositoryProvider).fetchOne(id),
  retry: (_, _) => null,
);

class ProductDetailPage extends ConsumerWidget {
  const ProductDetailPage({required this.id, this.initial, super.key});

  final int id;
  final Product? initial;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detail = ref.watch(productDetailProvider(id));
    final product = detail.value ?? initial;
    final failure = switch (detail) {
      AsyncError(:final error) => ApiException.from(error),
      _ => null,
    };

    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: switch (detail) {
          _ when product != null => _Detail(
            product: product,
            error: failure,
            onRetry: () => ref.invalidate(productDetailProvider(id)),
          ),
          AsyncError() => MessageView(
            icon: Icons.error_outline,
            message: failure!.message,
            actionLabel: 'Retry',
            onAction: () => ref.invalidate(productDetailProvider(id)),
          ),
          _ => const Center(child: CircularProgressIndicator()),
        },
      ),
    );
  }
}

class _Detail extends StatelessWidget {
  const _Detail({required this.product, required this.onRetry, this.error});

  final Product product;
  final ApiException? error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    final brand = product.brand;
    final category = _categoryLabel(product.category);
    final subtitle = [?brand, if (category.isNotEmpty) category].join('  ·  ');
    final availability = _availability(product);
    final hasInfo =
        product.shippingInformation.isNotEmpty ||
        product.returnPolicy.isNotEmpty;
    final urls = product.images.isEmpty ? [product.thumbnail] : product.images;

    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: Sizes.contentMaxWidth),
        child: ListView(
          padding: const EdgeInsets.only(bottom: Spacing.xl),
          children: [
            if (error case final error?)
              _RefreshError(error: error, onRetry: onRetry),
            ImageGallery(
              productId: product.id,
              title: product.title,
              urls: urls,
            ),
            Padding(
              padding: const EdgeInsets.all(Spacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(product.title, style: theme.textTheme.headlineSmall),
                  if (subtitle.isNotEmpty) ...[
                    const SizedBox(height: Spacing.xs),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodyMedium?.copyWith(color: muted),
                    ),
                  ],
                  const SizedBox(height: Spacing.md),
                  Price(product: product, large: true),
                  if (product.hasDiscount)
                    Text(
                      '${product.discountPercentage.round()}% off',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: theme.colorScheme.tertiary,
                      ),
                    ),
                  const SizedBox(height: Spacing.md),
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: Spacing.md,
                    children: [
                      Rating(value: product.rating),
                      if (availability.isNotEmpty)
                        Text(
                          availability,
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: product.isLowStock
                                ? theme.colorScheme.tertiary
                                : muted,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: Spacing.lg),
                  Text(product.description, style: theme.textTheme.bodyLarge),
                  const SizedBox(height: Spacing.lg),
                  if (hasInfo) const Divider(),
                  if (product.shippingInformation.isNotEmpty)
                    InfoRow(
                      icon: Icons.local_shipping_outlined,
                      label: 'Shipping',
                      value: product.shippingInformation,
                    ),
                  if (product.returnPolicy.isNotEmpty)
                    InfoRow(
                      icon: Icons.assignment_return_outlined,
                      label: 'Returns',
                      value: product.returnPolicy,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RefreshError extends StatelessWidget {
  const _RefreshError({required this.error, required this.onRetry});

  final ApiException error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(Spacing.md, Spacing.sm, Spacing.sm, 0),
      child: Row(
        children: [
          Expanded(
            child: Semantics(
              liveRegion: true,
              child: Text(
                'Could not refresh this product. ${error.message}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
            ),
          ),
          TextButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}

String _availability(Product product) {
  final status = product.availabilityStatus;
  if (product.stock == 0) return status;
  final stock = '${product.stock} available';
  return status.isEmpty ? stock : '$status  ·  $stock';
}

String _categoryLabel(String category) {
  if (category.isEmpty) return '';
  final words = category.replaceAll('-', ' ');
  return words[0].toUpperCase() + words.substring(1);
}
