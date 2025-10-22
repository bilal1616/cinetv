// lib/features/profile/favorites_page.dart
// ignore_for_file: unused_element

import 'package:cinetv/widgets/app_error.dart';
import 'package:cinetv/widgets/poster_shimmer.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../data/models/title_summary.dart';
import '../../data/repositories/favorite_repository.dart';
import '../../widgets/poster_card.dart';
import '../../widgets/app_snackbar.dart';

class FavoritesPage extends StatefulWidget {
  const FavoritesPage({super.key});

  @override
  State<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage>
    with SingleTickerProviderStateMixin {
  final _repo = FavoritesRepository();

  late final TabController _tab = TabController(length: 2, vsync: this);
  final _scrollMovies = ScrollController();
  final _scrollShows = ScrollController();

  List<TitleSummary> _movies = [];
  List<TitleSummary> _shows = [];
  bool _loading = true;
  bool _error = false;

  bool _changed =
      false; // ↺ diğer ekranlarla aynı: çıkarken üst sayfayı tetiklemek için

  @override
  void initState() {
    super.initState();
    _tab.addListener(() => setState(() {}));
    _load();
  }

  @override
  void dispose() {
    _tab.dispose();
    _scrollMovies.dispose();
    _scrollShows.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = false;
    });
    try {
      final m = await _repo.getMyFavorites(isTv: false, limit: 200);
      final s = await _repo.getMyFavorites(isTv: true, limit: 200);
      if (!mounted) return;
      setState(() {
        _movies = m;
        _shows = s;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = true;
        _loading = false;
      });
    }
  }

  Future<void> _openDetail(TitleSummary t) async {
    // ⬅️ Discover/Search’te yaptığımız gibi: sonucu bekle ve değiştiyse yenile
    final changed = await context.push<bool>(
      '/app/title/${t.isTv ? 'tv' : 'movie'}/${t.id}',
    );
    if (changed == true) {
      _changed = true;
      await _load();
    }
  }

  Future<void> _toggle(TitleSummary t) async {
    try {
      await _repo.toggleFavorite(isTv: t.isTv, titleId: t.id);
      if (!mounted) return;

      setState(() {
        if (t.isTv) {
          _shows.removeWhere((e) => e.id == t.id);
        } else {
          _movies.removeWhere((e) => e.id == t.id);
        }
      });
      _changed = true; // ↺ diğer sayfalar geri dönünce kendini güncellesin

      AppSnack.favoriteRemoved(
        context,
        t.title,
        actionLabel: 'Geri Al',
        onAction: () async {
          try {
            await _repo.toggleFavorite(isTv: t.isTv, titleId: t.id);
            if (!mounted) return;
            setState(() {
              if (t.isTv) {
                _shows.insert(0, t);
              } else {
                _movies.insert(0, t);
              }
            });
            _changed = true;
            AppSnack.favoriteAdded(context, t.title);
          } catch (_) {
            if (!mounted) return;
            AppSnack.show(
              context,
              title: 'İşlem başarısız',
              message: 'Geri alma yapılamadı',
              type: AppSnackType.danger,
            );
          }
        },
      );
    } catch (_) {
      if (!mounted) return;
      AppSnack.show(
        context,
        title: 'İşlem başarısız',
        message: 'Favori güncellenemedi',
        type: AppSnackType.danger,
      );
    }
  }

  // — Boş durum
  Widget _emptyState({required bool isTv, required String targetRoute}) {
    final iconMain = isTv ? Icons.live_tv_rounded : Icons.local_movies_rounded;
    final label = isTv ? 'Dizi favoriniz yok' : 'Film favoriniz yok';
    final desc =
        isTv
            ? 'Beğendiğiniz dizileri favorileyin; burada hızlıca bulalım.'
            : 'Beğendiğiniz filmleri favorileyin; burada hızlıca bulalım.';

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(32, 24, 32, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: .18),
                    border: Border.all(color: Colors.white24),
                  ),
                ),
                Icon(iconMain, size: 64, color: Colors.white),
                Positioned(
                  right: 22,
                  bottom: 22,
                  child: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: .24),
                      border: Border.all(color: Colors.white30),
                    ),
                    child: const Icon(
                      Icons.favorite_border_rounded,
                      size: 22,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              desc,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 18),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: BorderSide(color: Colors.white.withValues(alpha: .7)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
              ),
              onPressed: () {
                // Keşfe git (shell route kullanıyorsanız go ile sekmeye geçer)
                context.go(targetRoute);
              },
              icon: const Icon(Icons.explore_rounded),
              label: const Text('Keşfet'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _grid(List<TitleSummary> list, ScrollController controller) {
    return LayoutBuilder(
      builder: (context, c) {
        final w = c.maxWidth;
        final cross = w >= 1000 ? 5 : (w >= 820 ? 4 : 3);
        return GridView.builder(
          controller: controller,
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: cross,
            childAspectRatio: .60,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: list.length,
          itemBuilder: (_, i) {
            final t = list[i];
            return Stack(
              children: [
                PosterCard(item: t, onTap: () => _openDetail(t)),
                Positioned(
                  top: 8,
                  right: 8,
                  child: Material(
                    color: Colors.black.withValues(alpha: 0.35),
                    shape: const CircleBorder(),
                    clipBehavior: Clip.antiAlias,
                    child: IconButton(
                      tooltip: 'Favoriden çıkar',
                      constraints: const BoxConstraints.tightFor(
                        width: 36,
                        height: 36,
                      ),
                      padding: EdgeInsets.zero,
                      icon: const Icon(
                        Icons.favorite,
                        color: Colors.red,
                        size: 20,
                      ),
                      onPressed: () => _toggle(t),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<bool> _onWillPop() async {
    context.pop(_changed); // Discover/Search gibi: değiştiyse true dön
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final titleStyle = Theme.of(context).textTheme.headlineSmall?.copyWith(
      color: Colors.white,
      fontWeight: FontWeight.w800,
    );

    return PopScope(
      canPop: false, // sistem back'i engelle; kontrol bizde
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return; // zaten pop edildiyse dokunma
        if (context.canPop()) {
          context.pop(_changed); // tek noktadan güvenli pop + result
        }
      },
      child: Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF7C3AED), Color(0xFF06B6D4)],
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                // Üst başlık
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 6, 12, 4),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () {
                          if (context.canPop()) context.pop(_changed);
                        },
                      ),

                      const SizedBox(width: 6),
                      Expanded(child: Text('Favorilerim', style: titleStyle)),
                    ],
                  ),
                ),
                // Sekmeler
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
                  child: Container(
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: .14),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white24),
                    ),
                    child: TabBar(
                      controller: _tab,
                      indicatorSize: TabBarIndicatorSize.tab,
                      indicator: BoxDecoration(
                        color: Colors.white.withValues(alpha: .22),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      labelColor: Colors.white,
                      unselectedLabelColor: Colors.white70,
                      labelStyle: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                      unselectedLabelStyle: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                      tabs: const [Tab(text: 'Filmler'), Tab(text: 'Diziler')],
                    ),
                  ),
                ),
                // İçerik
                Expanded(
                  child:
                      _loading
                          ? LayoutBuilder(
                            builder: (context, c) {
                              final w = c.maxWidth;
                              final cross = w >= 1000 ? 5 : (w >= 820 ? 4 : 3);
                              return CustomScrollView(
                                slivers: [
                                  PosterGridShimmerSliver(
                                    crossAxisCount: cross,
                                  ),
                                ],
                              );
                            },
                          )
                          : _error
                          ? AppError(onRetry: _load)
                          : TabBarView(
                            controller: _tab,
                            children: [
                              _movies.isEmpty
                                  ? _emptyState(
                                    isTv: false,
                                    targetRoute: '/app/movies',
                                  )
                                  : _grid(_movies, _scrollMovies),
                              _shows.isEmpty
                                  ? _emptyState(
                                    isTv: true,
                                    targetRoute: '/app/shows',
                                  )
                                  : _grid(_shows, _scrollShows),
                            ],
                          ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
