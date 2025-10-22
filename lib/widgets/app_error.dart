import 'package:flutter/material.dart';

class AppError extends StatelessWidget {
  const AppError({
    super.key,
    this.title = 'Bir şeyler yanlış gitti',
    this.message = 'Bağlantı ya da limit sorunu olabilir. Tekrar dener misin?',
    this.icon = Icons.error_outline,
    required this.onRetry,
    this.retryLabel = 'Tekrar Dene',
    this.padding = const EdgeInsets.fromLTRB(24, 24, 24, 24),
    this.center = true,
  });

  /// “Sliver doldur” versiyonu
  const AppError.sliver({
    super.key,
    this.title = 'Bir şeyler yanlış gitti',
    this.message = 'Bağlantı ya da limit sorunu olabilir. Tekrar dener misin?',
    this.icon = Icons.error_outline,
    required this.onRetry,
    this.retryLabel = 'Tekrar Dene',
    this.padding = const EdgeInsets.fromLTRB(24, 24, 24, 24),
  }) : center = true;

  final String title;
  final String message;
  final IconData icon;
  final VoidCallback onRetry;
  final String retryLabel;
  final EdgeInsets padding;
  final bool center;

  @override
  Widget build(BuildContext context) {
    final body = _Body(
      title: title,
      message: message,
      icon: icon,
      retryLabel: retryLabel,
      onRetry: onRetry,
      padding: padding,
    );

    if (center) {
      return Center(child: body);
    }
    return body;
  }
}

class AppErrorSliver extends StatelessWidget {
  const AppErrorSliver({
    super.key,
    this.title = 'Bir şeyler yanlış gitti',
    this.message = 'Bağlantı ya da limit sorunu olabilir. Tekrar dener misin?',
    this.icon = Icons.error_outline,
    required this.onRetry,
    this.retryLabel = 'Tekrar Dene',
    this.padding = const EdgeInsets.fromLTRB(24, 24, 24, 24),
  });

  final String title;
  final String message;
  final IconData icon;
  final VoidCallback onRetry;
  final String retryLabel;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return SliverFillRemaining(
      hasScrollBody: false,
      child: Center(
        child: _Body(
          title: title,
          message: message,
          icon: icon,
          retryLabel: retryLabel,
          onRetry: onRetry,
          padding: padding,
        ),
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({
    required this.title,
    required this.message,
    required this.icon,
    required this.retryLabel,
    required this.onRetry,
    required this.padding,
  });

  final String title;
  final String message;
  final IconData icon;
  final String retryLabel;
  final VoidCallback onRetry;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: padding,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 48, color: theme.colorScheme.error),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 14),
          ElevatedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: Text(retryLabel),
          ),
        ],
      ),
    );
  }
}
