import 'package:cached_network_image/cached_network_image.dart';
import 'package:cinetv/core/app_image_cache.dart';
import 'package:cinetv/widgets/poster_shimmer.dart';
import 'package:flutter/material.dart';
import '../data/models/title_summary.dart';

class PosterCard extends StatelessWidget {
  const PosterCard({
    super.key,
    required this.item,
    this.onTap,
    this.borderRadius = 12,
    this.showTitle = true,
    this.heroTag,
  });

  final TitleSummary item;
  final VoidCallback? onTap;
  final double borderRadius;
  final bool showTitle;
  final Object? heroTag;

  String? get _poster => item.posterUrl;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final card = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 🔧 Posteri kalan yüksekliğe sığdır → overflow bitecek
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(borderRadius),
            child:
                (_poster == null || _poster!.isEmpty)
                    ? Stack(
                      fit: StackFit.expand,
                      children: [
                        const PosterShimmer(
                          showTitleBar: false,
                          compactImageOnly: true,
                        ),
                        Center(
                          child: Icon(
                            Icons.broken_image_outlined,
                            color: theme.colorScheme.onSurfaceVariant
                                .withValues(alpha: .7),
                            size: 36,
                          ),
                        ),
                      ],
                    )
                    : CachedNetworkImage(
                      imageUrl: _poster!,
                      cacheManager: AppImageCache.instance,
                      fit: BoxFit.cover,
                      placeholder:
                          (_, __) => const PosterShimmer(
                            showTitleBar: false,
                            compactImageOnly: true,
                          ),
                      errorWidget:
                          (_, __, ___) => Container(
                            color: theme.colorScheme.surfaceContainerHighest
                                .withValues(alpha: .25),
                            child: Center(
                              child: Icon(
                                Icons.broken_image_outlined,
                                color: theme.colorScheme.onSurfaceVariant
                                    .withValues(alpha: .7),
                                size: 36,
                              ),
                            ),
                          ),
                    ),
          ),
        ),
        if (showTitle) const SizedBox(height: 4),
        if (showTitle)
          Text(
            item.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w700,
              height: 1.2,
            ),
          ),
      ],
    );

    final tappable = InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(borderRadius),
      child: card,
    );

    return heroTag != null ? Hero(tag: heroTag!, child: tappable) : tappable;
  }
}
