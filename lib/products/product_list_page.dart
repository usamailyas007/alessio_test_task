import 'dart:async';
import 'dart:math';

import 'package:alessio_test_task/auth/auth_controller.dart';
import 'package:alessio_test_task/core/api_exception.dart';
import 'package:alessio_test_task/core/theme.dart';
import 'package:alessio_test_task/products/product_detail_page.dart';
import 'package:alessio_test_task/products/products_controller.dart';
import 'package:alessio_test_task/products/widgets/list_skeleton.dart';
import 'package:alessio_test_task/products/widgets/load_more_footer.dart';
import 'package:alessio_test_task/products/widgets/message_view.dart';
import 'package:alessio_test_task/products/widgets/product_tile.dart';
import 'package:alessio_test_task/products/widgets/user_badge.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

const _loadMoreThreshold = 300.0;

class ProductListPage extends ConsumerStatefulWidget {
  const ProductListPage({super.key});

  @override
  ConsumerState<ProductListPage> createState() => _ProductListPageState();
}

class _ProductListPageState extends ConsumerState<ProductListPage> {
  late final _scroll = ScrollController()..addListener(_onScroll);

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scroll.position.extentAfter > _loadMoreThreshold) return;
    if (ref.read(productsControllerProvider).error != null) return;
    unawaited(ref.read(productsControllerProvider.notifier).loadMore());
  }

  Future<void> _refresh() async {
    try {
      await ref.read(productsControllerProvider.notifier).refresh();
    } on ApiException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);
    final state = ref.watch(productsControllerProvider);
    final controller = ref.read(productsControllerProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: auth is SignedIn ? UserBadge(user: auth.user) : null,
        actions: [
          IconButton(
            tooltip: 'Sign out',
            icon: const Icon(Icons.logout),
            onPressed: () =>
                unawaited(ref.read(authControllerProvider.notifier).signOut()),
          ),
        ],
      ),
      body: SafeArea(
        child: switch (state) {
          ProductsState(isLoading: true) => const ListSkeleton(),
          ProductsState(items: [], :final error?) => MessageView(
            icon: Icons.error_outline,
            message: error.message,
            actionLabel: 'Retry',
            onAction: () => unawaited(controller.loadFirstPage()),
          ),
          ProductsState(items: []) => MessageView(
            icon: Icons.inventory_2_outlined,
            message: 'No products to show.',
            actionLabel: 'Refresh',
            onAction: () => unawaited(controller.loadFirstPage()),
          ),
          _ => _ProductList(
            state: state,
            scroll: _scroll,
            onRefresh: _refresh,
            onRetryMore: () => unawaited(controller.loadMore()),
          ),
        },
      ),
    );
  }
}

class _ProductList extends StatelessWidget {
  const _ProductList({
    required this.state,
    required this.scroll,
    required this.onRefresh,
    required this.onRetryMore,
  });

  final ProductsState state;
  final ScrollController scroll;
  final Future<void> Function() onRefresh;
  final VoidCallback onRetryMore;

  @override
  Widget build(BuildContext context) {
    final showFooter = state.isLoadingMore || state.error != null;

    return LayoutBuilder(
      builder: (context, constraints) {
        final gutter = max(
          Spacing.md,
          (constraints.maxWidth - Sizes.contentMaxWidth) / 2,
        );
        return RefreshIndicator(
          onRefresh: onRefresh,
          child: CustomScrollView(
            controller: scroll,
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverPadding(
                padding: EdgeInsets.symmetric(horizontal: gutter),
                sliver: SliverList.separated(
                  itemCount: state.items.length,
                  separatorBuilder: (_, _) => const Divider(),
                  itemBuilder: (_, index) {
                    final product = state.items[index];
                    return ProductTile(
                      product: product,
                      onTap: () => unawaited(
                        context.push<void>(
                          productPath(product.id),
                          extra: product,
                        ),
                      ),
                    );
                  },
                ),
              ),
              if (showFooter)
                SliverPadding(
                  padding: EdgeInsets.symmetric(horizontal: gutter),
                  sliver: SliverToBoxAdapter(
                    child: LoadMoreFooter(
                      error: state.error,
                      onRetry: onRetryMore,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
