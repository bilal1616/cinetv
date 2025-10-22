import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

/// Tek bir poster kartı için iskelet/shimmer.
/// Grid hücresinde overflow yapmaması için Expanded kullanımıyla güvenli.
class PosterShimmer extends StatelessWidget {
  const PosterShimmer({
    super.key,
    this.borderRadius = 12,
    this.showTitleBar = true,
    this.margin,
    this.compactImageOnly = false, // image placeholder için
  });

  final double borderRadius;
  final bool showTitleBar;
  final EdgeInsetsGeometry? margin;
  final bool compactImageOnly;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final base = theme.colorScheme.surfaceContainerHighest.withValues(alpha: .28);
    final highlight = theme.colorScheme.surfaceContainerHighest.withValues(alpha: .12);

    // CachedNetworkImage.placeholder içinde kullanılacak kompakt sürüm
    if (compactImageOnly) {
      return Shimmer.fromColors(
        baseColor: base,
        highlightColor: highlight,
        child: SizedBox.expand(
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: base,
              borderRadius: BorderRadius.circular(borderRadius),
            ),
          ),
        ),
      );
    }

    return Container(
      margin: margin,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Shimmer.fromColors(
              baseColor: base,
              highlightColor: highlight,
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: base,
                  borderRadius: BorderRadius.circular(borderRadius),
                ),
              ),
            ),
          ),
          if (showTitleBar) const SizedBox(height: 6),
          if (showTitleBar)
            Shimmer.fromColors(
              baseColor: base,
              highlightColor: highlight,
              child: Container(
                height: 12,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: base,
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ),
          if (showTitleBar) const SizedBox(height: 6),
          if (showTitleBar)
            Shimmer.fromColors(
              baseColor: base,
              highlightColor: highlight,
              child: Container(
                height: 12,
                width: MediaQuery.of(context).size.width * .4,
                decoration: BoxDecoration(
                  color: base,
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Discover/Search/Favorites grid’leri için hazır Sliver skeleton.
class PosterGridShimmerSliver extends StatelessWidget {
  const PosterGridShimmerSliver({
    super.key,
    required this.crossAxisCount,
    this.childAspectRatio = .60,
    this.crossAxisSpacing = 12,
    this.mainAxisSpacing = 12,
    this.padding = const EdgeInsets.fromLTRB(16, 0, 16, 16),
    this.itemCount = 12, // 3x4
  });

  final int crossAxisCount;
  final double childAspectRatio;
  final double crossAxisSpacing;
  final double mainAxisSpacing;
  final EdgeInsetsGeometry padding;
  final int itemCount;

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: padding,
      sliver: SliverGrid(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          childAspectRatio: childAspectRatio,
          crossAxisSpacing: crossAxisSpacing,
          mainAxisSpacing: mainAxisSpacing,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, _) => const PosterShimmer(),
          childCount: itemCount,
        ),
      ),
    );
  }
}
