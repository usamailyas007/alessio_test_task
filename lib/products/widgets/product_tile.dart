import 'package:alessio_test_task/core/theme.dart';
import 'package:alessio_test_task/products/product.dart';
import 'package:alessio_test_task/products/widgets/price.dart';
import 'package:alessio_test_task/products/widgets/rating.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

String productHeroTag(int id) => 'product-thumbnail-$id';

class ProductTile extends StatelessWidget {
  const ProductTile({required this.product, this.onTap, super.key});

  final Product product;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brand = product.brand;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: Spacing.sm),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Hero(
              tag: productHeroTag(product.id),
              child: Semantics(
                image: true,
                label: product.title,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(Sizes.radius),
                  child: ColoredBox(
                    color: theme.colorScheme.surfaceContainerHighest,
                    child: CachedNetworkImage(
                      imageUrl: product.thumbnail,
                      width: Sizes.thumbnail,
                      height: Sizes.thumbnail,
                      fit: BoxFit.cover,
                      errorWidget: (_, _, _) => const SizedBox.square(
                        dimension: Sizes.thumbnail,
                        child: Icon(Icons.image_not_supported_outlined),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: Spacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall,
                  ),
                  if (brand != null)
                    Text(
                      brand,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  const SizedBox(height: Spacing.xs),
                  Price(product: product),
                  const SizedBox(height: Spacing.xs),
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: Spacing.md,
                    children: [
                      Rating(value: product.rating),
                      if (product.isLowStock)
                        Text(
                          'Only ${product.stock} left',
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: theme.colorScheme.tertiary,
                          ),
                        ),
                    ],
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
