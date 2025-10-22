// lib/widgets/app_image.dart
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cinetv/core/app_image_cache.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

/// Tek tip resim bileşeni:
/// - cached_network_image kullanır
/// - AppImageCache (Custom CacheManager) ile tekil cache havuzu
/// - Shimmer placeholder
/// - Basit error fallback (ikon + arka plan)
///
/// Örnek:
/// ```dart
/// AppImage(
///   url: imageUrl,
///   width: 120,
///   height: 180,
///   fit: BoxFit.cover,
///   borderRadius: BorderRadius.circular(12),
/// )
/// ```
class AppImage extends StatelessWidget {
  const AppImage({
    super.key,
    required this.url,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.alignment = Alignment.center,
    this.borderRadius,
    this.aspectRatio,
    this.semanticLabel,
    this.memCacheWidth,
    this.memCacheHeight,
  });

  final String? url;
  final double? width;
  final double? height;
  final BoxFit fit;
  final AlignmentGeometry alignment;
  final BorderRadius? borderRadius;
  final double? aspectRatio;
  final String? semanticLabel;

  /// (Opsiyonel) Bellek içi yeniden boyut — özellikle grid posterleri için.
  final int? memCacheWidth;
  final int? memCacheHeight;

  /// Küçük yardımcı: URL yoksa “boş resim” döner.
  bool get _isEmpty => url == null || url!.trim().isEmpty;

  static Future<void> preload(String? url) async {
    await AppImageCache().precache(url);
  }

  @override
  Widget build(BuildContext context) {
    Widget child;

    if (_isEmpty) {
      child = const _ErrorBox();
    } else {
      child = CachedNetworkImage(
        imageUrl: url!,
        cacheManager: AppImageCache(),
        width: width,
        height: height,
        alignment:
            alignment is Alignment ? alignment as Alignment : Alignment.center,
        fit: fit,
        memCacheWidth: memCacheWidth,
        memCacheHeight: memCacheHeight,
        fadeInDuration: const Duration(milliseconds: 220),
        fadeOutDuration: const Duration(milliseconds: 120),
        filterQuality: FilterQuality.low,
        placeholder:
            (ctx, _) => _ShimmerBox(
              width: width,
              height: height,
              aspectRatio: aspectRatio,
              borderRadius: borderRadius,
            ),
        errorWidget: (ctx, _, __) => const _ErrorBox(),
      );
    }

    // AspectRatio isteniyorsa sarmala
    if (aspectRatio != null) {
      child = AspectRatio(aspectRatio: aspectRatio!, child: child);
    }

    // Köşe yuvarlama isteniyorsa kırp
    if (borderRadius != null) {
      child = ClipRRect(borderRadius: borderRadius!, child: child);
    }

    // Semantics (erişilebilirlik)
    if (semanticLabel != null && semanticLabel!.isNotEmpty) {
      child = Semantics(label: semanticLabel, child: child);
    }

    return child;
  }
}

/// Poster’ler için kısayol: varsayılan aspect ve köşe yarıçapı.
/// (PosterCard içinde direkt buna geçebilirsin)
class AppPosterImage extends AppImage {
  AppPosterImage({
    super.key,
    required super.url,
    super.width,
    super.height,
    super.fit = BoxFit.cover,
    BorderRadius? borderRadius,
    super.memCacheWidth,
    super.memCacheHeight,
    double posterAspect = 2 / 3, // 0.666…
  }) : super(
         aspectRatio: posterAspect,
         borderRadius: borderRadius ?? BorderRadius.circular(12),
         semanticLabel: 'Poster',
       );
}

/// Backdrop (16:9) için kısayol.
class AppBackdropImage extends AppImage {
  AppBackdropImage({
    super.key,
    required super.url,
    super.width,
    super.height,
    super.fit = BoxFit.cover,
    BorderRadius? borderRadius,
    super.memCacheWidth,
    super.memCacheHeight,
  }) : super(
         aspectRatio: 16 / 9,
         borderRadius: borderRadius ?? BorderRadius.circular(8),
         semanticLabel: 'Backdrop',
       );
}

/// Shimmer placeholder
class _ShimmerBox extends StatelessWidget {
  const _ShimmerBox({
    this.width,
    this.height,
    this.aspectRatio,
    this.borderRadius,
  });

  final double? width;
  final double? height;
  final double? aspectRatio;
  final BorderRadius? borderRadius;

  @override
  Widget build(BuildContext context) {
    Widget box = Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: borderRadius ?? BorderRadius.circular(8),
      ),
    );

    if (aspectRatio != null && (width == null || height == null)) {
      box = AspectRatio(aspectRatio: aspectRatio!, child: box);
    }

    return Shimmer.fromColors(
      baseColor: Theme.of(context).colorScheme.surfaceContainerHigh,
      highlightColor: Theme.of(context).colorScheme.surfaceContainerLowest,
      child: box,
    );
  }
}

/// Hata durumunda gösterilen basit kutu.
/// (İleride “yeniden dene” eklemek istersen burayı genişletebilirsin)
class _ErrorBox extends StatelessWidget {
  const _ErrorBox();

  @override
  Widget build(BuildContext context) {
    final bg = Theme.of(context).colorScheme.surfaceContainerHigh;
    final fg = Theme.of(context).colorScheme.onSurface.withValues(alpha: .55);

    return Container(
      color: bg,
      alignment: Alignment.center,
      child: Icon(Icons.broken_image_outlined, color: fg, size: 28),
    );
  }
}
