import 'package:flutter/material.dart';

class AppEmpty extends StatelessWidget {
  const AppEmpty({
    super.key,
    this.title = 'İçerik bulunamadı',
    this.message = 'Filtreleri değiştirip tekrar deneyebilirsin.',
    this.icon = Icons.inbox_outlined,
    this.actionLabel,
    this.onAction,
    this.padding = const EdgeInsets.fromLTRB(24, 24, 24, 24),
    this.center = true,
  });

  /// “Sliver doldur” versiyonu
  const AppEmpty.sliver({
    super.key,
    this.title = 'İçerik bulunamadı',
    this.message = 'Filtreleri değiştirip tekrar deneyebilirsin.',
    this.icon = Icons.inbox_outlined,
    this.actionLabel,
    this.onAction,
    this.padding = const EdgeInsets.fromLTRB(24, 24, 24, 24),
  }) : center = true;

  final String title;
  final String message;
  final IconData icon;
  final String? actionLabel;
  final VoidCallback? onAction;
  final EdgeInsets padding;
  final bool center;

  @override
  Widget build(BuildContext context) {
    final body = _Body(
      title: title,
      message: message,
      icon: icon,
      actionLabel: actionLabel,
      onAction: onAction,
      padding: padding,
    );

    if (center) {
      return Center(child: body);
    }
    return body;
  }
}

class AppEmptySliver extends StatelessWidget {
  const AppEmptySliver({
    super.key,
    this.title = 'İçerik bulunamadı',
    this.message = 'Filtreleri değiştirip tekrar deneyebilirsin.',
    this.icon = Icons.inbox_outlined,
    this.actionLabel,
    this.onAction,
    this.padding = const EdgeInsets.fromLTRB(24, 24, 24, 24),
  });

  final String title;
  final String message;
  final IconData icon;
  final String? actionLabel;
  final VoidCallback? onAction;
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
          actionLabel: actionLabel,
          onAction: onAction,
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
    required this.padding,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String message;
  final IconData icon;
  final EdgeInsets padding;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: padding,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 48, color: theme.colorScheme.onSurfaceVariant),
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
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 14),
            OutlinedButton(onPressed: onAction, child: Text(actionLabel!)),
          ],
        ],
      ),
    );
  }
}
