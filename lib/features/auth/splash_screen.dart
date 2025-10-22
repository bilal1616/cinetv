import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _logoCtrl;
  late final Animation<Offset> _logoOffset;
  late final Animation<double> _logoFade;

  late final AnimationController _textCtrl;
  late final Animation<Offset> _textOffset;
  late final Animation<double> _textFade;

  // Şeffaf logo
  static const String _logoPath = 'assets/splash/splashscreen.png';
  late final ImageProvider _logoProvider = const AssetImage(_logoPath);

  @override
  void initState() {
    super.initState();

    // Animasyonlar
    _logoCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _logoOffset = Tween<Offset>(
      begin: const Offset(0, -0.8),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _logoCtrl, curve: Curves.easeOutCubic));
    _logoFade = CurvedAnimation(parent: _logoCtrl, curve: Curves.easeOut);

    _textCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _textOffset = Tween<Offset>(
      begin: const Offset(0.6, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _textCtrl, curve: Curves.easeOutCubic));
    _textFade = CurvedAnimation(parent: _textCtrl, curve: Curves.easeOut);

    _logoCtrl.forward().whenComplete(() {
      Future.delayed(const Duration(milliseconds: 150), () {
        if (mounted) _textCtrl.forward();
      });
    });

    // 3000ms sonra kesin yönlendirme (post-frame + delayed; Timer yok)
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await Future.delayed(const Duration(milliseconds: 3000));
      if (!mounted) return;
      final session = Supabase.instance.client.auth.currentSession;
      final dest = (session == null) ? '/login' : '/discover';
      if (!mounted) return;
      context.go(dest, extra: 'from_splash');
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Görseli önceden cache’le (ilk frame jank olmasın)
    precacheImage(_logoProvider, context);
  }

  @override
  void dispose() {
    _logoCtrl.dispose();
    _textCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF7C3AED), Color(0xFF06B6D4)],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              FadeTransition(
                opacity: _logoFade,
                child: SlideTransition(
                  position: _logoOffset,
                  child: SizedBox(
                    width: 300,
                    height: 300,
                    child: Image(image: _logoProvider, fit: BoxFit.contain),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              FadeTransition(
                opacity: _textFade,
                child: SlideTransition(
                  position: _textOffset,
                  child: Text(
                    'CineTv',
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      color: Colors.white.withValues(alpha: 0.92),
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.1,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
