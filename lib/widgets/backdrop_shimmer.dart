// lib/widgets/shimmers/backdrop_shimmer.dart
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

/// 16:9 geniş başlık/backdrop için shimmer.
class BackdropShimmer extends StatelessWidget {
  const BackdropShimmer({
    super.key,
    this.aspectRatio = 16 / 9,
    this.borderRadius = 0,
  });

  final double aspectRatio;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final base = theme.colorScheme.surfaceContainerHighest.withValues(alpha: .28);
    final highlight = theme.colorScheme.surfaceContainerHighest.withValues(alpha: .12);

    return Shimmer.fromColors(
      baseColor: base,
      highlightColor: highlight,
      child: AspectRatio(
        aspectRatio: aspectRatio,
        child: Container(
          decoration: BoxDecoration(
            color: base,
            borderRadius: BorderRadius.circular(borderRadius),
          ),
        ),
      ),
    );
  }
}

/// TitleDetail üst kısmı için: Backdrop + sol altta küçük poster iskeleti.
class BackdropWithPosterShimmer extends StatelessWidget {
  const BackdropWithPosterShimmer({
    super.key,
    this.backdropAspect = 16 / 9,
    this.posterWidth = 120,
    this.posterBorderRadius = 12,
    this.padding = const EdgeInsets.all(16),
  });

  final double backdropAspect;
  final double posterWidth;
  final double posterBorderRadius;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final base = theme.colorScheme.surfaceContainerHighest.withValues(alpha: .28);
    final highlight = theme.colorScheme.surfaceContainerHighest.withValues(alpha: .12);

    return AspectRatio(
      aspectRatio: backdropAspect,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Shimmer.fromColors(
            baseColor: base,
            highlightColor: highlight,
            child: Container(color: base),
          ),
          // Alt kısımda siyah gradient (başlık metni okunaklı olsun)
          IgnorePointer(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.center,
                  colors: [Colors.black54, Colors.transparent],
                ),
              ),
            ),
          ),
          // Sol altta poster iskeleti
          Positioned(
            left: padding.left,
            bottom: padding.bottom,
            child: Shimmer.fromColors(
              baseColor: base,
              highlightColor: highlight,
              child: Container(
                width: posterWidth,
                height: posterWidth * (3 / 2), // 2:3 oranına uygun yükseklik
                decoration: BoxDecoration(
                  color: base,
                  borderRadius: BorderRadius.circular(posterBorderRadius),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
