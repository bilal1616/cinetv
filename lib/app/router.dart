import 'package:cinetv/data/models/video_source.dart';
import 'package:cinetv/features/detail/season_episodes_page.dart';
import 'package:cinetv/features/detail/title_detail_page.dart';
import 'package:cinetv/features/detail/trailer_player_page.dart';
import 'package:cinetv/features/profile/favorites_page.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../features/auth/splash_screen.dart';
import '../features/auth/login_page.dart';
import '../features/auth/register_page.dart';
import '../features/discover/discover_page.dart';
import '../features/profile/profile_page.dart';
import '../features/search/search_page.dart';
import '../app/app_scaffold.dart';

GoRouter createRouter() {
  final auth = Supabase.instance.client.auth;
  Page<dynamic> noTransition(Widget child) => NoTransitionPage(child: child);

  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      final session = auth.currentSession;
      final path = state.uri.path;

      if (path == '/') return null;

      final isProtected = path.startsWith('/app');
      if (session == null && isProtected) return '/login';

      final isAuthRoute = path == '/login' || path == '/register';
      if (session != null && isAuthRoute) return '/app/movies';

      if (path == '/discover') return '/app/movies';
      return null;
    },
    routes: [
      GoRoute(
        path: '/',
        pageBuilder: (context, state) => noTransition(const SplashScreen()),
      ),
      GoRoute(
        path: '/login',
        pageBuilder: (context, state) {
          final fromSplash = state.extra == 'from_splash';
          return fromSplash
              ? noTransition(const LoginPage())
              : const MaterialPage(child: LoginPage());
        },
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterPage(),
      ),

      // SHELL
      ShellRoute(
        builder: (context, state, child) => AppScaffold(child: child),
        routes: [
          GoRoute(
            path: '/app/movies',
            name: 'movies',
            pageBuilder:
                (context, state) => const NoTransitionPage(
                  key: ValueKey('discover_movies'),
                  child: DiscoverPage(isShowMode: false),
                ),
          ),
          GoRoute(
            path: '/app/shows',
            name: 'shows',
            pageBuilder:
                (context, state) => const NoTransitionPage(
                  key: ValueKey('discover_shows'),
                  child: DiscoverPage(isShowMode: true),
                ),
          ),
          GoRoute(
            path: '/app/profile',
            name: 'profile',
            pageBuilder:
                (context, state) =>
                    const NoTransitionPage(child: ProfilePage()),
          ),

          // Arama
          GoRoute(
            path: '/app/search/movies',
            builder: (ctx, st) => const SearchPage(isTv: false),
          ),
          GoRoute(
            path: '/app/search/shows',
            builder: (ctx, st) => const SearchPage(isTv: true),
          ),

          // 🔥 Tek ve kesin fragman rotası: TrailerArgs zorunlu
          GoRoute(
            path: '/app/trailer',
            name: 'trailer',
            pageBuilder: (context, state) {
              final args = state.extra as TrailerArgs;
              return NoTransitionPage(child: TrailerPlayerPage(args: args));
            },
          ),

          GoRoute(
            path: '/app/favorites',
            name: 'favorites',
            pageBuilder:
                (context, state) =>
                    const NoTransitionPage(child: FavoritesPage()),
          ),

          // ✅ SEASONS: /app/title/:id/seasons  (ÖNCE BUNU KOY)
          GoRoute(
            name: 'seasons',
            path: '/app/title/:id/seasons',
            builder: (context, state) {
              final id = int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
              return SeasonsEpisodesPage(tvId: id);
            },
          ),

          // Detay (bunu altta tutmak iyi; daha spesifik olan seasons önce eşleşir)
          GoRoute(
            path: '/app/title/:kind/:id', // kind=movie|tv
            name: 'title_detail',
            pageBuilder: (context, state) {
              final kind = state.pathParameters['kind']!;
              final id = int.parse(
                state.pathParameters['id']!,
              ); // burada int.parse kalabilir
              return NoTransitionPage(
                child: TitleDetailPage(isTv: kind == 'tv', tmdbId: id),
              );
            },
          ),
        ],
      ),
    ],
  );
}
