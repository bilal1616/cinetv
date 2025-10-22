import 'package:cinetv/widgets/app_empty.dart';
import 'package:cinetv/widgets/app_error.dart';
import 'package:cinetv/widgets/poster_shimmer.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../data/models/title_summary.dart';
import '../../data/repositories/search_repository.dart';
import '../../widgets/poster_card.dart';

// ✅ Favori & Snackbar
import '../../data/repositories/favorite_repository.dart';
import '../../widgets/app_snackbar.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key, required this.isTv});
  final bool isTv;

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final _repo = SearchRepository();
  final _favRepo = FavoritesRepository();

  // yıl aralığı
  static const int kMinYear = 1950;
  static const int kMaxYear = 2025;
  RangeValues _years = const RangeValues(2000, 2025);

  // türler
  List<Map<String, dynamic>> _genres = [];
  final Set<int> _selectedGenreIds = {};

  // sonuçlar
  final _items = <TitleSummary>[];
  bool _loading = true; // <-- önce false'tu, true yapıyoruz
  bool _error = false;
  int _page = 1;
  final _controller = ScrollController();

  // Favoriler (bu sayfanın UI state'i)
  final Set<String> _favs = {}; // key: "tv:123" / "movie:456"
  String _key(TitleSummary t) => '${t.isTv ? 'tv' : 'movie'}:${t.id}';
  bool _isFav(TitleSummary t) => _favs.contains(_key(t));

  // ✅ Bu sayfada yapılan değişiklikleri üst sayfaya taşıyacağız
  final Map<String, bool> _favDeltas = {};

  // Metinle arama
  String? _textQuery;
  bool get _isTextMode => (_textQuery ?? '').trim().isNotEmpty;

  @override
  void initState() {
    super.initState();
    _loading = true; // ilk build'te shimmer gözüksün
    _controller.addListener(_onScroll);
    _loadInit();
  }

  @override
  void didUpdateWidget(covariant SearchPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isTv != widget.isTv) {
      _clearTextMode();
      _resetAndFetch();
      _loadFavs(); // tip değiştiyse favorileri yeniden çek
    }
  }

  Future<void> _loadInit() async {
    await _loadFavs();
    try {
      final g = await _repo.getGenres(tv: widget.isTv);
      if (!mounted) return;
      setState(() => _genres = g);
      _resetAndFetch();
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = true);
    }
  }

  Future<void> _loadFavs() async {
    try {
      final list = await _favRepo.getMyFavorites(
        isTv: widget.isTv,
        limit: 1000,
      );
      if (!mounted) return;
      setState(() {
        _favs
          ..clear()
          ..addAll(list.map((e) => '${widget.isTv ? 'tv' : 'movie'}:${e.id}'));
      });
    } catch (_) {
      // sessiz
    }
  }

  void _resetAndFetch() {
    setState(() {
      _items.clear();
      _page = 1;
      _error = false;
    });
    _fetch();
  }

  void _onScroll() {
    if (_controller.position.pixels >
            _controller.position.maxScrollExtent - 600 &&
        !_loading) {
      _fetch();
    }
  }

  Future<void> _fetch() async {
    setState(() => _loading = true);
    try {
      List<TitleSummary> res;
      if (_isTextMode) {
        res = await _repo.searchByText(
          query: _textQuery!.trim(),
          isTv: widget.isTv,
          page: _page,
        );
      } else {
        res = await _repo.discover(
          tv: widget.isTv,
          page: _page,
          yearFrom: _years.start.toInt(),
          yearTo: _years.end.toInt(),
          genreIds:
              _selectedGenreIds.isEmpty ? null : _selectedGenreIds.toList(),
        );
      }
      if (!mounted) return;
      setState(() {
        _items.addAll(res);
        _page += 1;
        _error = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = true);
      AppSnack.show(
        context,
        title: 'Arama yüklenemedi',
        type: AppSnackType.danger,
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _clearTextMode() {
    if (!_isTextMode) return;
    setState(() {
      _textQuery = null;
      _items.clear();
      _page = 1;
    });
    _fetch();
  }

  Future<void> _askAndSearch() async {
    final controller = TextEditingController(text: _textQuery ?? '');
    final q = await showDialog<String>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setLocal) {
            return AlertDialog(
              title: Text(widget.isTv ? 'Dizi Ara' : 'Film Ara'),
              content: TextField(
                controller: controller,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Başlık yazın...',
                  suffixIcon:
                      controller.text.isEmpty
                          ? null
                          : IconButton(
                            tooltip: 'Temizle',
                            icon: const Icon(Icons.close),
                            onPressed: () {
                              controller.clear();
                              setLocal(() {});
                            },
                          ),
                ),
                onChanged: (_) => setLocal(() {}),
                onSubmitted: (v) => Navigator.of(ctx).pop(v.trim()),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('İptal'),
                ),
                ElevatedButton(
                  onPressed:
                      () => Navigator.of(ctx).pop(controller.text.trim()),
                  child: const Text('Ara'),
                ),
              ],
            );
          },
        );
      },
    );
    if (q == null) return;
    if (q.isEmpty) {
      _clearTextMode();
      return;
    }
    setState(() {
      _textQuery = q;
      _items.clear();
      _page = 1;
    });
    await _fetch();
  }

  // ---------- FAVORİ: toggle + sabit snackbar + delta taşı ----------
  Future<void> _toggleFavorite(TitleSummary t) async {
    final k = _key(t);
    final wasFav = _favs.contains(k);

    // optimistic
    setState(() {
      if (wasFav) {
        _favs.remove(k);
        _favDeltas[k] = false; // ✅ delta yaz
      } else {
        _favs.add(k);
        _favDeltas[k] = true; // ✅ delta yaz
      }
    });

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
      // revert
      setState(() {
        if (wasFav) {
          _favs.add(k);
          _favDeltas[k] = true;
        } else {
          _favs.remove(k);
          _favDeltas[k] = false;
        }
      });
      AppSnack.show(
        context,
        title: 'İşlem başarısız',
        message: 'Favori güncellenemedi',
        type: AppSnackType.danger,
      );
    }
  }

  // ---------- DETAIL'e gidip dönünce gelen deltalari uygula ----------
  Future<void> _openDetail(TitleSummary t) async {
    final res = await context.push(
      '/app/title/${t.isTv ? 'tv' : 'movie'}/${t.id}',
    );
    if (res is Map && res['favDeltas'] is Map) {
      final deltas = Map<String, bool>.from(res['favDeltas'] as Map);
      setState(() {
        deltas.forEach((k, v) {
          if (v) {
            _favs.add(k);
          } else {
            _favs.remove(k);
          }
          _favDeltas[k] =
              v; // ✅ kendi deltamıza da ekleyelim; geri dönüşte üst sayfa görsün
        });
      });
    } else if (res == true) {
      // geriye uyumluluk
      // ignore: unawaited_futures
      _loadFavs();
    }
  }

  // ---------- GERİ DÖNERKEN delta’yı parent’a ilet ----------
  void _finishWithResult() {
    final result =
        _favDeltas.isEmpty
            ? true
            : {'favDeltas': Map<String, bool>.from(_favDeltas)};
    if (context.canPop()) {
      context.pop(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.isTv ? 'Dizi Ara' : 'Film Ara';

    return PopScope(
      canPop: false, // sistem pop'unu engelle, biz yöneteceğiz
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return; // zaten pop edildiyse dokunma
        _finishWithResult(); // tek noktadan pop + result
      },
      child: Scaffold(
        body: SafeArea(
          child: CustomScrollView(
            controller: _controller,
            slivers: [
              SliverAppBar(
                pinned: true,
                floating: false,
                snap: false,
                backgroundColor: Theme.of(context).colorScheme.surface,
                expandedHeight: 64,
                automaticallyImplyLeading: false,
                title: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: _finishWithResult,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      title,
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const Spacer(),
                    if (_isTextMode)
                      IconButton(
                        tooltip: 'Aramayı temizle',
                        icon: const Icon(Icons.close),
                        onPressed: _clearTextMode,
                      ),
                    TextButton.icon(
                      onPressed: _askAndSearch,
                      icon: const Icon(Icons.search),
                      label: const Text('Ara'),
                      style: TextButton.styleFrom(
                        foregroundColor:
                            Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),

              if (!_isTextMode)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Yıl aralığı: ${_years.start.toInt()} – ${_years.end.toInt()}',
                        ),
                        RangeSlider(
                          values: _years,
                          min: kMinYear.toDouble(),
                          max: kMaxYear.toDouble(),
                          divisions: (kMaxYear - kMinYear),
                          labels: RangeLabels(
                            _years.start.toInt().toString(),
                            _years.end.toInt().toString(),
                          ),
                          onChanged: (v) => setState(() => _years = v),
                          onChangeEnd: (_) => _resetAndFetch(),
                        ),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children:
                              _genres.map((g) {
                                final id = g['id'] as int;
                                final selected = _selectedGenreIds.contains(id);
                                return FilterChip(
                                  label: Text(g['name'].toString()),
                                  selected: selected,
                                  onSelected: (s) {
                                    setState(() {
                                      if (s) {
                                        _selectedGenreIds.add(id);
                                      } else {
                                        _selectedGenreIds.remove(id);
                                      }
                                    });
                                    _resetAndFetch();
                                  },
                                );
                              }).toList(),
                        ),
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                ),

              if (_items.isEmpty && _loading)
                SliverLayoutBuilder(
                  builder: (context, constraints) {
                    final w = constraints.crossAxisExtent;
                    final cross = w >= 1000 ? 5 : (w >= 820 ? 4 : 3);
                    return PosterGridShimmerSliver(crossAxisCount: cross);
                  },
                )
              else if (_items.isEmpty && _error)
                AppErrorSliver(onRetry: _resetAndFetch)
              else if (_items.isEmpty && !_loading)
                const AppEmptySliver(
                  title: 'Sonuç bulunamadı',
                  message: 'Arama metnini değiştir veya filtreleri daralt.',
                  icon: Icons.search_off_rounded,
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  sliver: SliverGrid(
                    delegate: SliverChildBuilderDelegate((context, i) {
                      final item = _items[i];
                      final fav = _isFav(item);
                      return Stack(
                        children: [
                          PosterCard(
                            item: item,
                            onTap: () => _openDetail(item),
                          ),
                          Positioned(
                            top: 8,
                            right: 8,
                            child: Material(
                              color: Colors.black.withValues(
                                alpha: fav ? 0.45 : 0.35,
                              ),
                              shape: const CircleBorder(
                                side: BorderSide(color: Colors.grey),
                              ),
                              clipBehavior: Clip.antiAlias,
                              child: IconButton(
                                tooltip:
                                    fav ? 'Favoriden çıkar' : 'Favoriye ekle',
                                constraints: const BoxConstraints.tightFor(
                                  width: 36,
                                  height: 36,
                                ),
                                padding: EdgeInsets.zero,
                                icon: Icon(
                                  fav ? Icons.favorite : Icons.favorite_border,
                                  color: fav ? Colors.red : Colors.white,
                                  size: 18,
                                ),
                                onPressed: () => _toggleFavorite(item),
                              ),
                            ),
                          ),
                        ],
                      );
                    }, childCount: _items.length),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          childAspectRatio: .60,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                        ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }
}
