// lib/features/discover/widgets/recommendations_section.dart
import 'package:flutter/material.dart';
import 'package:cinetv/data/models/title_summary.dart';
import 'package:cinetv/data/repositories/favorite_repository.dart';
import 'package:cinetv/data/repositories/detail_repository.dart';
import 'package:cinetv/data/repositories/search_repository.dart';
import 'package:cinetv/widgets/poster_card.dart';
import 'package:cinetv/widgets/poster_shimmer.dart';

class RecommendationsSection extends StatefulWidget {
  const RecommendationsSection({
    super.key,
    required this.isShowMode,
    required this.isFav,
    required this.onToggleFavorite,
    required this.onOpenDetail,
  });

  final bool isShowMode;
  final bool Function(TitleSummary) isFav;
  final Future<void> Function(TitleSummary) onOpenDetail;
  final Future<void> Function(TitleSummary) onToggleFavorite;

  @override
  State<RecommendationsSection> createState() => _RecommendationsSectionState();
}

class _RecommendationsSectionState extends State<RecommendationsSection> {
  final _favRepo = FavoritesRepository();
  final _detailRepo = DetailRepository();
  final _searchRepo = SearchRepository();

  bool _busy = false;
  bool _error = false;

  final bool _moreLoading = false;

  int? _topGenreId;
  String? _topGenreName;
  int? _altGenreId;
  String? _altGenreName;

  final List<TitleSummary> _top = [];
  final List<TitleSummary> _alt = [];
  int _topPage = 1;
  int _altPage = 1;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant RecommendationsSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isShowMode != widget.isShowMode) {
      _reset();
      _load();
    }
  }

  void _reset() {
    _busy = false;
    _error = false;
    _topGenreId = null;
    _altGenreId = null;
    _topGenreName = null;
    _altGenreName = null;
    _top.clear();
    _alt.clear();
    _topPage = 1;
    _altPage = 1;
  }

  Future<void> _load() async {
    setState(() {
      _busy = true;
      _error = false;
    });

    try {
      // 1) Kullanıcının ilgili moddaki favorileri
      final favs = await _favRepo.getMyFavorites(
        isTv: widget.isShowMode,
        limit: 1000,
      );
      if (!mounted) return;

      // Favori yoksa öneri göstermeyelim.
      if (favs.isEmpty) {
        setState(() {
          _busy = false;
          _error = false;
        });
        return;
      }

      // En az 5 favori yoksa öneri göstermeyelim (daha anlamlı sonuçlar için)
      if (favs.length < 5) {
        setState(() {
          _busy = false;
          _error = false;
        });
        return;
      }

      // Tür isimleri sözlüğü
      final genreList = await _searchRepo.getGenres(tv: widget.isShowMode);
      final Map<int, String> idToName = {
        for (final g in genreList) (g['id'] as int): g['name'].toString(),
      };

      // 2) En sık 2 tür (örnekleme: ilk 20 favori)
      final sample = favs.take(20).toList();
      final Map<int, int> counts = {};
      await Future.wait(
        sample.map((t) async {
          try {
            final b = await _detailRepo.fetchDetail(isTv: t.isTv, id: t.id);
            final raw = b.detail['genres'];
            if (raw is List) {
              for (final g in raw) {
                final gid = (g is Map) ? g['id'] : null;
                if (gid is int) {
                  counts[gid] = (counts[gid] ?? 0) + 1;
                }
              }
            }
          } catch (_) {}
        }),
      );

      if (counts.isEmpty) {
        setState(() {
          _busy = false;
          _error = false;
        });
        return;
      }

      final sorted =
          counts.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
      final top = sorted.first.key;
      final alt = (sorted.length > 1) ? sorted[1].key : sorted.first.key;

      // 3) 9’ar öneri
      final topPage1 = await _searchRepo.discover(
        tv: widget.isShowMode,
        page: _topPage,
        genreIds: [top],
      );
      final altPage1 = await _searchRepo.discover(
        tv: widget.isShowMode,
        page: _altPage,
        genreIds: [alt],
      );

      if (!mounted) return;
      setState(() {
        _topGenreId = top;
        _altGenreId = alt;
        _topGenreName = idToName[top] ?? 'Önerilen';
        _altGenreName = idToName[alt] ?? 'Önerilen';
        _top.addAll(topPage1.take(9));
        _alt.addAll(altPage1.take(9));
        _topPage += 1;
        _altPage += 1;
        _busy = false;
        _error = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = true;
      });
    }
  }

  Future<void> _moreTop() async {
    if (_topGenreId == null) return;
    try {
      final res = await _searchRepo.discover(
        tv: widget.isShowMode,
        page: _topPage,
        genreIds: [_topGenreId!],
      );
      if (!mounted) return;
      setState(() {
        _top.addAll(res.take(9));
        _topPage += 1;
      });
    } catch (_) {}
  }

  Future<void> _moreAlt() async {
    if (_altGenreId == null) return;
    try {
      final res = await _searchRepo.discover(
        tv: widget.isShowMode,
        page: _altPage,
        genreIds: [_altGenreId!],
      );
      if (!mounted) return;
      setState(() {
        _alt.addAll(res.take(9));
        _altPage += 1;
      });
    } catch (_) {}
  }

  Widget _grid(List<TitleSummary> items) {
    return GridView.count(
      crossAxisCount: 3,
      childAspectRatio: .60,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children:
          items.map((t) {
            final fav = widget.isFav(t);
            return Stack(
              children: [
                PosterCard(item: t, onTap: () => widget.onOpenDetail(t)),
                Positioned(
                  top: 8,
                  right: 8,
                  child: Material(
                    color: Colors.black.withValues(alpha: fav ? .45 : .35),
                    shape: const CircleBorder(),
                    clipBehavior: Clip.antiAlias,
                    child: IconButton(
                      tooltip: fav ? 'Favoriden çıkar' : 'Favoriye ekle',
                      constraints: const BoxConstraints.tightFor(
                        width: 36,
                        height: 36,
                      ),
                      padding: EdgeInsets.zero,
                      icon: Icon(
                        fav ? Icons.favorite : Icons.favorite_border,
                        color: fav ? Colors.red : Colors.white,
                        size: 20,
                      ),
                      onPressed: () => widget.onToggleFavorite(t),
                    ),
                  ),
                ),
              ],
            );
          }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    const purple = Color(0xFF7C3AED);
    const cyan = Color(0xFF06B6D4);

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Başlık / yükleniyor
            if (_busy && _top.isEmpty && _alt.isEmpty) ...[
              Text(
                'Senin için öneriler',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              // Shimmer sliver’ı kutuya dönüştürelim
              _ShimmerBox.toBox(crossAxisCount: 3),
            ] else if (_error)
              Text('Öneriler yüklenemedi', style: theme.textTheme.titleMedium)
            else if (_top.isEmpty && _alt.isEmpty)
              const SizedBox.shrink()
            else ...[
              if (_top.isNotEmpty) ...[
                Text(
                  'Senin için: ${_topGenreName ?? 'Önerilen'}',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 14),
                _grid(_top),
                const SizedBox(height: 14),
                SizedBox(
                  height: 44,
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _moreTop,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _moreLoading ? cyan : purple,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Daha fazla öneri',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              if (_alt.isNotEmpty) ...[
                Text(
                  'Bunlara da bak: ${_altGenreName ?? 'Önerilen'}',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 14),
                _grid(_alt),
                const SizedBox(height: 14),
                SizedBox(
                  height: 44,
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _moreAlt,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _moreLoading ? cyan : purple,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Daha fazla öneri',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

// --- Küçük yardımcı: Shimmer sliver'ını box'a çevirmek için ---
extension _ShimmerBox on PosterGridShimmerSliver {
  static Widget toBox({required int crossAxisCount}) {
    return GridView.builder(
      itemCount: crossAxisCount * 3, // 1 satır shimmer görünümü
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        childAspectRatio: .60,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemBuilder:
          (_, __) => Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: .08),
              borderRadius: BorderRadius.circular(12),
            ),
          ),
    );
  }
}
