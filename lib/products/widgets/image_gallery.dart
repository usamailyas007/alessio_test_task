import 'package:alessio_test_task/core/theme.dart';
import 'package:alessio_test_task/products/widgets/product_tile.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class ImageGallery extends StatefulWidget {
  const ImageGallery({
    required this.productId,
    required this.title,
    required this.urls,
    super.key,
  });

  final int productId;
  final String title;
  final List<String> urls;

  @override
  State<ImageGallery> createState() => _ImageGalleryState();
}

class _ImageGalleryState extends State<ImageGallery> {
  var _page = 0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final count = widget.urls.length;

    return Column(
      children: [
        AspectRatio(
          aspectRatio: 1,
          child: ColoredBox(
            color: theme.colorScheme.surfaceContainerHighest,
            child: PageView.builder(
              itemCount: count,
              onPageChanged: (page) => setState(() => _page = page),
              itemBuilder: (_, index) {
                final image = Semantics(
                  image: true,
                  label: '${widget.title}, image ${index + 1} of $count',
                  child: CachedNetworkImage(
                    imageUrl: widget.urls[index],
                    fit: BoxFit.contain,
                    errorWidget: (_, _, _) =>
                        const Icon(Icons.image_not_supported_outlined),
                  ),
                );
                return index == 0
                    ? Hero(tag: productHeroTag(widget.productId), child: image)
                    : image;
              },
            ),
          ),
        ),
        if (count > 1)
          Padding(
            padding: const EdgeInsets.only(top: Spacing.md),
            child: Semantics(
              label: 'Image ${_page + 1} of $count',
              excludeSemantics: true,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var i = 0; i < count; i++)
                    Container(
                      width: Spacing.sm,
                      height: Spacing.sm,
                      margin: const EdgeInsets.symmetric(
                        horizontal: Spacing.xs / 2,
                      ),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: i == _page
                            ? theme.colorScheme.primary
                            : theme.colorScheme.outlineVariant,
                      ),
                    ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
