import 'package:alessio_test_task/core/theme.dart';
import 'package:flutter/material.dart';

const _rowCount = 8;
const _pulse = Duration(milliseconds: 900);

class ListSkeleton extends StatefulWidget {
  const ListSkeleton({super.key});

  @override
  State<ListSkeleton> createState() => _ListSkeletonState();
}

class _ListSkeletonState extends State<ListSkeleton>
    with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(vsync: this, duration: _pulse);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.stop();
    } else if (!_controller.isAnimating) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.surfaceContainerHighest;
    return Semantics(
      label: 'Loading products',
      child: ExcludeSemantics(
        child: FadeTransition(
          opacity: Tween<double>(begin: 0.5, end: 1).animate(_controller),
          child: ListView.builder(
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.all(Spacing.md),
            itemCount: _rowCount,
            itemBuilder: (_, _) => _SkeletonRow(color: color),
          ),
        ),
      ),
    );
  }
}

class _SkeletonRow extends StatelessWidget {
  const _SkeletonRow({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Spacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Block(color: color, width: Sizes.thumbnail, height: Sizes.thumbnail),
          const SizedBox(width: Spacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Block(color: color, height: Spacing.md),
                const SizedBox(height: Spacing.sm),
                _Block(color: color, width: 96, height: Spacing.md),
                const SizedBox(height: Spacing.md),
                _Block(color: color, width: 64, height: Spacing.md),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Block extends StatelessWidget {
  const _Block({required this.color, required this.height, this.width});

  final Color color;
  final double height;
  final double? width;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(Spacing.xs),
      ),
      child: SizedBox(width: width, height: height),
    );
  }
}
