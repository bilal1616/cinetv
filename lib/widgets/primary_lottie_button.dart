import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class PrimaryLottieButton extends StatelessWidget {
  const PrimaryLottieButton({
    super.key,
    required this.onPressed,
    required this.text,
    required this.loading,
    this.minHeight = 56, // klasik buton yüksekliği
    this.lottieSize = 99, // görünür ama abartısız
  });

  final VoidCallback? onPressed;
  final String text;
  final bool loading;
  final double minHeight;
  final double lottieSize;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(14);

    return SizedBox(
      width: double.infinity,
      height: minHeight,
      child: FilledButton(
        style: FilledButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: const Color(0xFF111827),
          shape: RoundedRectangleBorder(borderRadius: radius),
          padding: const EdgeInsets.symmetric(horizontal: 16),
        ),
        onPressed: loading ? null : onPressed,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          switchInCurve: Curves.easeOut,
          switchOutCurve: Curves.easeIn,
          transitionBuilder: (c, a) => FadeTransition(opacity: a, child: c),
          child:
              loading
                  ? Center(
                    key: const ValueKey('loading'),
                    child: Lottie.asset(
                      'assets/Loading1.json',
                      height: lottieSize,
                      width: lottieSize,
                      fit: BoxFit.contain,
                      frameRate: FrameRate.max,
                      repeat: true,
                      delegates: LottieDelegates(
                        values: [
                          ValueDelegate.color([
                            '**',
                          ], value: const Color(0xFF0F172A)),
                        ],
                      ),
                    ),
                  )
                  : Text(
                    text,
                    key: const ValueKey('text'),
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
        ),
      ),
    );
  }
}
