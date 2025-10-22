import 'package:flutter/material.dart';

enum AppSnackType { success, danger, info, warning }

class AppSnack {
  static void show(
    BuildContext context, {
    required String title,
    String? message,
    AppSnackType type = AppSnackType.info,
    String? actionLabel,
    VoidCallback? onAction,
    Duration duration = const Duration(milliseconds: 1900),
  }) {
    // Sabit renkler
    late IconData icon;
    late List<Color> gradient;
    late Color textColor;
    late Color iconColor;

    switch (type) {
      case AppSnackType.success: // YEŞİL sabit
        icon = Icons.check_circle_rounded;
        gradient = [
          const Color(0xFFA7F3D0),
          const Color(0xFF34D399),
        ]; // light→green
        textColor = Colors.black;
        iconColor = const Color(0xFF16A34A); // koyu yeşil
        break;

      case AppSnackType.danger: // KIRMIZI sabit
        icon = Icons.close_rounded; // X icon
        gradient = [
          const Color(0xFFFCA5A5),
          const Color(0xFFEF4444),
        ]; // light→red
        textColor = Colors.black;
        iconColor = const Color(0xFF7F1D1D); // koyu kırmızı
        break;

      case AppSnackType.warning:
        icon = Icons.warning_amber_rounded;
        gradient = [const Color(0xFFFFE08A), const Color(0xFFFFB74D)];
        textColor = Colors.black;
        iconColor = const Color(0xFFB45309);
        break;

      case AppSnackType.info:
        icon = Icons.info_rounded;
        gradient = [const Color(0xFFD1C4E9), const Color(0xFF7C3AED)];
        textColor = Colors.black;
        iconColor = const Color(0xFF5B21B6);
    }

    final snack = SnackBar(
      behavior: SnackBarBehavior.floating,
      elevation: 0,
      backgroundColor: Colors.transparent,
      duration: duration,
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      content: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: gradient),
          borderRadius: BorderRadius.circular(14),
          boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 12)],
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.transparent,
              child: Icon(icon, size: 22, color: iconColor),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: textColor,
                    ),
                  ),
                  if (message != null && message.trim().isNotEmpty)
                    Text(
                      message,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: textColor.withValues(alpha: .85)),
                    ),
                ],
              ),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(width: 8),
              TextButton(
                style: TextButton.styleFrom(
                  foregroundColor: textColor,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                ),
                onPressed: () {
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                  onAction();
                },
                child: Text(
                  actionLabel,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ],
        ),
      ),
    );

    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(snack);
  }

  // Kolay yardımcılar — favori akışı için sabit renkler
  static void favoriteAdded(
    BuildContext context,
    String title, {
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    show(
      context,
      title: 'Favorilere eklendi',
      message: title,
      type: AppSnackType.success,
      actionLabel: actionLabel,
      onAction: onAction,
    );
  }

  static void favoriteRemoved(
    BuildContext context,
    String title, {
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    show(
      context,
      title: 'Favoriden çıkarıldı',
      message: title,
      type: AppSnackType.danger,
      actionLabel: actionLabel,
      onAction: onAction,
    );
  }

  // Kolay yardımcılar — profil akışı için
  static void profileSaved(BuildContext context, {String? message}) {
    show(
      context,
      title: 'Profil kaydedildi',
      message: message,
      type: AppSnackType.success, // yeşil
      duration: const Duration(milliseconds: 1800),
    );
  }

  static void avatarUpdated(BuildContext context, {String? message}) {
    show(
      context,
      title: 'Avatar güncellendi',
      message: message,
      type: AppSnackType.success, // yeşil
      duration: const Duration(milliseconds: 1800),
    );
  }
}
