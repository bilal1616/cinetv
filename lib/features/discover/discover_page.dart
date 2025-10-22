// lib/features/discover/discover_page.dart
import 'package:cinetv/widgets/app_error.dart';
import 'package:cinetv/widgets/poster_shimmer.dart';
import 'package:cinetv/widgets/recommendations_section.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../data/models/title_summary.dart';
import '../../data/repositories/discover_repository.dart'
    show DiscoverRepository, PagedResult, DiscoverCategory; // repo enum
import '../../data/repositories/favorite_repository.dart';
import '../../widgets/poster_card.dart';
import '../../widgets/app_snackbar.dart';

// UI menüsü için enum
enum DiscoverMenu { trending, popular, nowPlaying, recommended }

class DiscoverPage extends StatefulWidget {
  const DiscoverPage({super.key, this.isShowMode = false});
  final bool isShowMode;

  @override
  State<DiscoverPage> createState() => _DiscoverPageState();
}

class _DiscoverPageState extends State<DiscoverPage> {
  final _discover = DiscoverRepository();
  final _favRepo = FavoritesRepository();

  final _items = <TitleSummary>[];
  int _chunk = 1;
  bool _loading = true;
  bool _error = false;
  bool _moreLoading = false;

  // Başlangıç: önce Trend atanır, init içinde "5+ favori varsa Öneriler"e çevrilecektir.
  late DiscoverMenu _category = DiscoverMenu.trending;

  final ScrollController _scroll = ScrollController();
  bool _showFab = false;

  // Favori state
  final Set<String> _favs = {};
  String _key(TitleSummary t) => '${t.isTv ? 'tv' : 'movie'}:${t.id}';
  bool _isFav(TitleSummary t) => _favs.contains(_key(t));

  void _applyDeltas(Map<String, bool> deltas) {
    setState(() {
      deltas.forEach((k, v) => v ? _favs.add(k) : _favs.remove(k));
    });
  }

  // Favoriler, grid gelmeden yüklensin
  late final Future<void> _favInit;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);

    // Favorileri önceden çek
    _favInit = _loadFavs();

    // Açılışta kategori kararını verip öyle yükle
    _initCategoryAndLoad();
  }

  // Açılışta: 5+ favori varsa Öneriler, yoksa Trend ile başla
  Future<void> _initCategoryAndLoad() async {
    final startWithRec = await _shouldStartWithRecommended();
    if (!mounted) return;
    setState(() {
      _category =
          startWithRec ? DiscoverMenu.recommended : DiscoverMenu.trending;
    });
    await _reload();
  }

  // Mod (Film/Dizi) değişince aynı kararı tekrar ver
  Future<void> _redecideCategoryAndReload() async {
    final startWithRec = await _shouldStartWithRecommended();
    if (!mounted) return;
    setState(() {
      _category =
          startWithRec ? DiscoverMenu.recommended : DiscoverMenu.trending;
    });
    _reload();
  }

  // İlgili modda (film/dizi) en az 5 favori varsa true
  Future<bool> _shouldStartWithRecommended() async {
    try {
      final favs = await _favRepo.getMyFavorites(
        isTv: widget.isShowMode,
        limit: 6, // 5 kontrolü için yeterli
      );
      return favs.length >= 5;
    } catch (_) {
      return false;
    }
  }

  @override
  void dispose() {
    _scroll.removeListener(_onScroll);
    _scroll.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant DiscoverPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isShowMode != widget.isShowMode) {
      _scroll.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
      // Mod değişince: favori sayısına göre başlangıç menüsünü yeniden seç ve yükle
      _redecideCategoryAndReload();
    }
  }

  void _onScroll() {
    final shouldShow = _scroll.hasClients && _scroll.offset > 600;
    if (shouldShow != _showFab) setState(() => _showFab = shouldShow);
  }

  Future<void> _loadFavs() async {
    try {
      final movies = await _favRepo.getMyFavorites(isTv: false, limit: 1000);
      final shows = await _favRepo.getMyFavorites(isTv: true, limit: 1000);
      if (!mounted) return;
      setState(() {
        _favs
          ..clear()
          ..addAll(movies.map((e) => 'movie:${e.id}'))
          ..addAll(shows.map((e) => 'tv:${e.id}'));
      });
    } catch (_) {}
  }

  Future<void> _reload() async {
    setState(() {
      _loading = true;
      _error = false;
      _items.clear();
      _chunk = 1;
    });
    try {
      await _favInit; // kalpler ilk framede doğru
      final res = await _loadChunk(_chunk);
      if (!mounted) return;
      setState(() {
        _items.addAll(res.items);
        _chunk += 1;
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

  Future<void> _loadMore() async {
    if (_moreLoading) return;
    setState(() => _moreLoading = true);
    try {
      final res = await _loadChunk(_chunk);
      if (!mounted) return;
      setState(() {
        _items.addAll(res.items.take(12));
        _chunk += 1;
        _moreLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _moreLoading = false);
      AppSnack.show(
        context,
        title: 'İçerik alınamadı',
        message: 'Daha fazla içerik yüklenemedi',
        type: AppSnackType.danger,
      );
    }
  }

  // UI menüsünü repo enumuna map eden helper
  DiscoverCategory _mapToRepo(DiscoverMenu m) {
    switch (m) {
      case DiscoverMenu.trending:
        return DiscoverCategory.trending;
      case DiscoverMenu.popular:
        return DiscoverCategory.popular;
      case DiscoverMenu.nowPlaying:
        return DiscoverCategory.nowPlaying;
      case DiscoverMenu.recommended:
        // Öneriler açıkken ana akış için trendi kullanıyoruz
        return DiscoverCategory.trending;
    }
  }

  Future<PagedResult<TitleSummary>> _loadChunk(int chunk) {
    final repoCat = _mapToRepo(_category);
    return widget.isShowMode
        ? _discover.getShows(category: repoCat, chunk: chunk)
        : _discover.getMovies(category: repoCat, chunk: chunk);
  }

  // Navigation helpers
  Future<void> _openDetail(TitleSummary t) async {
    final res = await context.push(
      '/app/title/${t.isTv ? 'tv' : 'movie'}/${t.id}',
    );
    if (res is Map && res['favDeltas'] is Map) {
      _applyDeltas(Map<String, bool>.from(res['favDeltas'] as Map));
    } else if (res == true) {
      _loadFavs(); // sessiz sync
    }
  }

  Future<void> _openSearch() async {
    final route =
        widget.isShowMode ? '/app/search/shows' : '/app/search/movies';
    final res = await context.push(route);
    if (res is Map && res['favDeltas'] is Map) {
      _applyDeltas(Map<String, bool>.from(res['favDeltas'] as Map));
    } else if (res == true) {
      _loadFavs();
    }
  }

  // Favori toggle
  Future<void> _toggleFavorite(TitleSummary t) async {
    final k = _key(t);
    final wasFav = _favs.contains(k);

    setState(() => wasFav ? _favs.remove(k) : _favs.add(k));

    try {
      await _favRepo.toggleFavorite(isTv: t.isTv, titleId: t.id);
      if (!mounted) return;
      if (wasFav) {
        AppSnack.favoriteRemoved(
          context,
          t.title,
          actionLabel: 'Geri Al',
          onAction: () => _toggleFavorite(t),
        );
      } else {
        AppSnack.favoriteAdded(
          context,
          t.title,
          actionLabel: 'Geri Al',
          onAction: () => _toggleFavorite(t),
        );
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => wasFav ? _favs.add(k) : _favs.remove(k)); // revert
      AppSnack.show(
        context,
        title: 'İşlem başarısız',
        message: 'Favori güncellenemedi',
        type: AppSnackType.danger,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    const purple = Color(0xFF7C3AED);
    const cyan = Color(0xFF06B6D4);
    final title = widget.isShowMode ? 'Diziler' : 'Filmler';

    return Scaffold(
      floatingActionButton:
          _showFab
              ? FloatingActionButton(
                onPressed:
                    () => _scroll.animateTo(
                      0,
                      duration: const Duration(milliseconds: 400),
                      curve: Curves.easeOut,
                    ),
                child: const Icon(Icons.arrow_upward, color: Color(0xFF06B6D4)),
              )
              : null,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [purple, cyan],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // ÜST BAR
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 6, 16, 10),
                child: Row(
                  children: [
                    Text(
                      title,
                      style: Theme.of(
                        context,
                      ).textTheme.headlineSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(width: 10),
                    TextButton.icon(
                      onPressed: _openSearch,
                      icon: const Icon(Icons.search, color: Colors.white),
                      label: Text(widget.isShowMode ? 'Dizi Ara' : 'Film Ara'),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.white,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: .18),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: Colors.white24),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<DiscoverMenu>(
                          value: _category,
                          iconEnabledColor: Colors.white,
                          dropdownColor: Colors.black87,
                          style: const TextStyle(color: Colors.white),
                          items: const [
                            DropdownMenuItem(
                              value: DiscoverMenu.trending,
                              child: Text('Trend'),
                            ),
                            DropdownMenuItem(
                              value: DiscoverMenu.popular,
                              child: Text('Popüler'),
                            ),
                            DropdownMenuItem(
                              value: DiscoverMenu.nowPlaying,
                              child: Text('Vizyondaki'),
                            ),
                            DropdownMenuItem(
                              value: DiscoverMenu.recommended,
                              child: Text('Öneriler'),
                            ),
                          ],
                          onChanged: (v) {
                            if (v == null) return;
                            setState(() => _category = v);
                            _reload();
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),

              Expanded(
                child:
                    _loading
                        ? LayoutBuilder(
                          builder: (context, c) {
                            final w = c.maxWidth;
                            final cross = w >= 1000 ? 5 : (w >= 820 ? 4 : 3);
                            return CustomScrollView(
                              controller: _scroll,
                              slivers: [
                                if (_category == DiscoverMenu.recommended)
                                  RecommendationsSection(
                                    isShowMode: widget.isShowMode,
                                    isFav: _isFav,
                                    onToggleFavorite: _toggleFavorite,
                                    onOpenDetail: _openDetail,
                                  ),
                                PosterGridShimmerSliver(crossAxisCount: cross),
                              ],
                            );
                          },
                        )
                        : _error
                        ? Center(child: AppError(onRetry: _reload))
                        : LayoutBuilder(
                          builder: (context, c) {
                            final w = c.maxWidth;
                            final cross = w >= 1000 ? 5 : (w >= 820 ? 4 : 3);

                            return CustomScrollView(
                              controller: _scroll,
                              slivers: [
                                if (_category == DiscoverMenu.recommended)
                                  RecommendationsSection(
                                    isShowMode: widget.isShowMode,
                                    isFav: _isFav,
                                    onToggleFavorite: _toggleFavorite,
                                    onOpenDetail: _openDetail,
                                  ),
                                SliverPadding(
                                  padding: const EdgeInsets.fromLTRB(
                                    16,
                                    0,
                                    16,
                                    12,
                                  ),
                                  sliver: SliverGrid(
                                    delegate: SliverChildBuilderDelegate((
                                      context,
                                      i,
                                    ) {
                                      final t = _items[i];
                                      final isFav = _isFav(t);
                                      return Stack(
                                        children: [
                                          PosterCard(
                                            item: t,
                                            onTap: () => _openDetail(t),
                                          ),
                                          Positioned(
                                            top: 8,
                                            right: 8,
                                            child: Material(
                                              color: Colors.black.withValues(
                                                alpha: isFav ? 0.45 : 0.35,
                                              ),
                                              shape: const CircleBorder(
                                                side: BorderSide(
                                                  color: Colors.grey,
                                                ),
                                              ),
                                              clipBehavior: Clip.antiAlias,
                                              child: IconButton(
                                                tooltip:
                                                    isFav
                                                        ? 'Favoriden çıkar'
                                                        : 'Favoriye ekle',
                                                constraints:
                                                    const BoxConstraints.tightFor(
                                                      width: 36,
                                                      height: 36,
                                                    ),
                                                padding: EdgeInsets.zero,
                                                icon: Icon(
                                                  isFav
                                                      ? Icons.favorite
                                                      : Icons.favorite_border,
                                                  color:
                                                      isFav
                                                          ? Colors.red
                                                          : Colors.white,
                                                  size: 18,
                                                ),
                                                onPressed:
                                                    () => _toggleFavorite(t),
                                              ),
                                            ),
                                          ),
                                        ],
                                      );
                                    }, childCount: _items.length),
                                    gridDelegate:
                                        SliverGridDelegateWithFixedCrossAxisCount(
                                          crossAxisCount: cross,
                                          childAspectRatio: .60,
                                          crossAxisSpacing: 12,
                                          mainAxisSpacing: 12,
                                        ),
                                  ),
                                ),
                                SliverToBoxAdapter(
                                  child: Padding(
                                    padding: const EdgeInsets.fromLTRB(
                                      16,
                                      4,
                                      16,
                                      16,
                                    ),
                                    child: SizedBox(
                                      width: double.infinity,
                                      height: 44,
                                      child: ElevatedButton(
                                        onPressed:
                                            _moreLoading ? null : _loadMore,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor:
                                              _moreLoading ? cyan : purple,
                                          foregroundColor: Colors.white,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                        ),
                                        child:
                                            _moreLoading
                                                ? const SizedBox(
                                                  width: 22,
                                                  height: 22,
                                                  child:
                                                      CircularProgressIndicator(
                                                        strokeWidth: 2,
                                                        color: Colors.white,
                                                      ),
                                                )
                                                : const Text(
                                                  'Daha fazla göster',
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w700,
                                                  ),
                                                ),
                                      ),
                                    ),
                                  ),
                                ),
                                const SliverToBoxAdapter(
                                  child: SizedBox(height: 8),
                                ),
                              ],
                            );
                          },
                        ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
