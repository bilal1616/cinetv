import 'package:cinetv/data/models/video_source.dart';
import 'package:cinetv/widgets/backdrop_shimmer.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../data/repositories/detail_repository.dart';
import '../../data/datasources/remote/tmdb_api.dart';

// ✅ Favori & Snackbar
import '../../data/repositories/favorite_repository.dart';
import '../../widgets/app_snackbar.dart';

class TitleDetailPage extends StatefulWidget {
  const TitleDetailPage({super.key, required this.isTv, required this.tmdbId});

  final bool isTv;
  final int tmdbId;

  @override
  State<TitleDetailPage> createState() => _TitleDetailPageState();
}

class _TitleDetailPageState extends State<TitleDetailPage> {
  final _repo = DetailRepository();
  final _favRepo = FavoritesRepository();

  TitleDetailBundle? _bundle;
  bool _loading = true;
  bool _error = false;

  // ✅ Favori durumu ve geri bildirim için flag
  bool _isFav = false;

  // ✅ Bu sayfadan çıkarken ebeveyne dönecek delta
  final Map<String, bool> _favDeltas = {};

  String get _favKey => '${widget.isTv ? 'tv' : 'movie'}:${widget.tmdbId}';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = false;
    });
    try {
      final b = await _repo.fetchDetail(isTv: widget.isTv, id: widget.tmdbId);
      // favori bilgisini çek (temel kontrol)
      final favs = await _favRepo.getMyFavorites(
        isTv: widget.isTv,
        limit: 1000,
      );
      if (!mounted) return;
      setState(() {
        _bundle = b;
        _isFav = favs.any((e) => e.id == widget.tmdbId);
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = true;
      });
    }
  }

  // ---------- FAVORİ: toggle + sabit snackbar + delta-sync ----------
  Future<void> _toggleFavorite() async {
    final wasFav = _isFav;

    // optimistic
    setState(() {
      _isFav = !wasFav;
      _favDeltas[_favKey] = _isFav; // ✅ delta güncelle
    });

    try {
      await _favRepo.toggleFavorite(isTv: widget.isTv, titleId: widget.tmdbId);
      if (!mounted) return;

      final title = _titleText();
      if (wasFav) {
        AppSnack.favoriteRemoved(
          context,
          title,
          actionLabel: 'Geri Al',
          onAction: _toggleFavorite,
        );
      } else {
        AppSnack.favoriteAdded(
          context,
          title,
          actionLabel: 'Geri Al',
          onAction: _toggleFavorite,
        );
      }
    } catch (_) {
      if (!mounted) return;
      // revert
      setState(() {
        _isFav = wasFav;
        _favDeltas[_favKey] = _isFav; // revert delta
      });
      AppSnack.show(
        context,
        title: 'İşlem başarısız',
        message: 'Favori güncellenemedi',
        type: AppSnackType.danger,
      );
    }
  }

  String _countryName(String? code) {
    if (code == null || code.trim().isEmpty) return '';
    final c = code.toUpperCase();
    const map = {
      'TR': 'Türkiye',
      'US': 'Amerika Birleşik Devletleri',
      'GB': 'Birleşik Krallık',
      'AR': 'Arjantin',
      'TW': 'Tayvan',
      'DE': 'Almanya',
      'FR': 'Fransa',
      'ES': 'İspanya',
      'IT': 'İtalya',
      'PT': 'Portekiz',
      'NL': 'Hollanda',
      'BE': 'Belçika',
      'SE': 'İsveç',
      'NO': 'Norveç',
      'DK': 'Danimarka',
      'FI': 'Finlandiya',
      'RU': 'Rusya',
      'UA': 'Ukrayna',
      'PL': 'Polonya',
      'CZ': 'Çekya',
      'HU': 'Macaristan',
      'RO': 'Romanya',
      'GR': 'Yunanistan',
      'BG': 'Bulgaristan',
      'RS': 'Sırbistan',
      'BA': 'Bosna-Hersek',
      'HR': 'Hırvatistan',
      'MK': 'Kuzey Makedonya',
      'AL': 'Arnavutluk',
      'IE': 'İrlanda',
      'IS': 'İzlanda',
      'CH': 'İsviçre',
      'AT': 'Avusturya',
      'AU': 'Avustralya',
      'NZ': 'Yeni Zelanda',
      'CA': 'Kanada',
      'BR': 'Brezilya',
      'MX': 'Meksika',
      'CL': 'Şili',
      'CO': 'Kolombiya',
      'PE': 'Peru',
      'JP': 'Japonya',
      'KR': 'Güney Kore',
      'CN': 'Çin',
      'HK': 'Hong Kong',
      'SG': 'Singapur',
      'IN': 'Hindistan',
      'ID': 'Endonezya',
      'MY': 'Malezya',
      'TH': 'Tayland',
      'SA': 'Suudi Arabistan',
      'AE': 'Birleşik Arap Emirlikleri',
      'EG': 'Mısır',
      'MA': 'Fas',
      'ZA': 'Güney Afrika',
    };
    return map[c] ?? c;
  }

  String _titleText() {
    final d = _bundle?.detail ?? {};
    final name =
        widget.isTv
            ? (d['name'] ?? d['original_name'])
            : (d['title'] ?? d['original_title']);
    final date = widget.isTv ? d['first_air_date'] : d['release_date'];
    String year = '';
    if (date is String && date.length >= 4) year = ' (${date.substring(0, 4)})';
    return '${(name ?? '').toString()}$year';
  }

  int? _extractYear(Map<String, dynamic> d) {
    final date = widget.isTv ? d['first_air_date'] : d['release_date'];
    if (date is String && date.length >= 4) {
      return int.tryParse(date.substring(0, 4));
    }
    return null;
  }

  List<String> _extractGenres(Map<String, dynamic> d) {
    final raw = d['genres'];
    if (raw is List) {
      return raw
          .map((e) {
            if (e is Map) return (e['name'] ?? '').toString();
            return e?.toString() ?? '';
          })
          .where((e) => e.trim().isNotEmpty)
          .cast<String>()
          .toList();
    }
    return const [];
  }

  Map<String, String> _collectRatings(Map<String, dynamic> d) {
    final out = <String, String>{};
    final tmdbVote =
        (d['vote_average'] is num)
            ? (d['vote_average'] as num).toDouble()
            : null;
    if (tmdbVote != null && tmdbVote > 0) {
      out['TMDb'] = tmdbVote.toStringAsFixed(1);
    }

    dynamic imdbRaw =
        d['imdb_rating'] ??
        d['imdbRating'] ??
        d['imdb_score'] ??
        (d['omdb'] is Map ? (d['omdb'] as Map)['imdbRating'] : null);
    double? imdb;
    if (imdbRaw is num) {
      imdb = imdbRaw.toDouble();
    } else if (imdbRaw is String) {
      imdb = double.tryParse(imdbRaw.replaceAll(',', '.'));
    }
    if (imdb != null && imdb > 0) {
      out['IMDb'] = imdb.toStringAsFixed(imdb % 1 == 0 ? 0 : 1);
    }
    return out;
  }

  void _openTrailer({
    required String title,
    required String provider,
    required String videoId,
  }) {
    final prov = provider.toLowerCase();
    TrailerSource? src;
    if (prov.contains('you')) {
      src = TrailerSource(provider: TrailerProvider.youtube, videoId: videoId);
    } else if (prov.contains('vimeo')) {
      src = TrailerSource(provider: TrailerProvider.vimeo, videoId: videoId);
    } else if (prov.contains('daily')) {
      src = TrailerSource(
        provider: TrailerProvider.dailymotion,
        videoId: videoId,
      );
    }
    if (src == null) return;
    context.pushNamed('trailer', extra: TrailerArgs(title: title, source: src));
  }

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
    final theme = Theme.of(context);

    return PopScope(
      canPop: false, // sistem pop'unu engelle, biz yöneteceğiz
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return; // zaten pop edildiyse dokunma
        _finishWithResult(); // tek noktadan pop + result
      },
      child: Scaffold(
        body: SafeArea(
          child:
              _loading
                  ? CustomScrollView(
                    slivers: [
                      SliverAppBar(
                        pinned: true,
                        automaticallyImplyLeading: false,
                        title: Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.arrow_back),
                              onPressed: _finishWithResult,
                            ),
                            const SizedBox(width: 6),
                            const Text('Detay'),
                          ],
                        ),
                      ),
                      const SliverToBoxAdapter(
                        child: BackdropWithPosterShimmer(),
                      ),
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                          child: Column(
                            children: [
                              Container(
                                height: 16,
                                width: double.infinity,
                                color: Colors.black12,
                              ),
                              const SizedBox(height: 8),
                              Container(
                                height: 14,
                                width: double.infinity,
                                color: Colors.black12,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  )
                  : _error
                  ? Center(
                    child: TextButton.icon(
                      onPressed: _load,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Yüklenemedi, tekrar dene'),
                    ),
                  )
                  : CustomScrollView(
                    slivers: [
                      SliverAppBar(
                        pinned: true,
                        automaticallyImplyLeading: false,
                        title: Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.arrow_back),
                              onPressed: _finishWithResult,
                            ),
                            const SizedBox(width: 6),
                            const Text('Detay'),
                            const Spacer(),
                            IconButton(
                              tooltip:
                                  _isFav ? 'Favoriden çıkar' : 'Favoriye ekle',
                              icon: Icon(
                                _isFav ? Icons.favorite : Icons.favorite_border,
                                color: _isFav ? Colors.red : Colors.white,
                                size: 23,
                              ),
                              onPressed: _toggleFavorite,
                            ),
                            if (widget.isTv)
                              OutlinedButton.icon(
                                onPressed: () {
                                  context.pushNamed(
                                    'seasons',
                                    pathParameters: {
                                      'id': widget.tmdbId.toString(),
                                    },
                                  );
                                },
                                icon: const Icon(
                                  Icons.live_tv,
                                  color: Colors.white,
                                ),
                                label: const Text(
                                  'Tüm sezon & bölümler',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                  ),
                                ),
                                style: OutlinedButton.styleFrom(
                                  side: BorderSide(
                                    color: theme.colorScheme.primary.withValues(
                                      alpha: .6,
                                    ),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 8,
                                  ),
                                  shape: const StadiumBorder(),
                                ),
                              ),
                          ],
                        ),
                      ),
                      SliverToBoxAdapter(
                        child: _HeaderSection(bundle: _bundle!),
                      ),
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _titleText(),
                                style: theme.textTheme.headlineMedium?.copyWith(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 8),
                              _MetaGenresRow(
                                year: _extractYear(_bundle!.detail),
                                genres: _extractGenres(_bundle!.detail),
                              ),
                              const SizedBox(height: 8),
                              _RatingsRow(
                                ratings: _collectRatings(_bundle!.detail),
                              ),
                              const SizedBox(height: 12),
                              if ((_bundle!.detail['overview'] ?? '')
                                  .toString()
                                  .isNotEmpty)
                                Text(
                                  (_bundle!.detail['overview'] ?? '')
                                      .toString(),
                                  style: theme.textTheme.bodyLarge,
                                ),
                              const SizedBox(height: 16),
                              if (_bundle!.videos.isNotEmpty)
                                ElevatedButton.icon(
                                  style: ButtonStyle(
                                    backgroundColor: WidgetStatePropertyAll(
                                      theme.colorScheme.secondaryFixed,
                                    ),
                                  ),
                                  onPressed: () {
                                    final vids = _bundle!.videos;
                                    final v = vids.firstWhere(
                                      (e) => (e['type'] ?? '')
                                          .toString()
                                          .toLowerCase()
                                          .contains('trailer'),
                                      orElse: () => vids.first,
                                    );
                                    final provider =
                                        (v['site'] ?? v['provider'] ?? '')
                                            .toString();
                                    final key =
                                        (v['key'] ?? v['id'] ?? '').toString();
                                    if (provider.isEmpty || key.isEmpty) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text('Fragman bulunamadı'),
                                        ),
                                      );
                                      return;
                                    }
                                    _openTrailer(
                                      title: _titleText(),
                                      provider: provider,
                                      videoId: key,
                                    );
                                  },
                                  icon: const Icon(
                                    Icons.play_circle_fill,
                                    color: Colors.black,
                                  ),
                                  label: const Text(
                                    'Fragmanı izle',
                                    style: TextStyle(color: Colors.black),
                                  ),
                                ),
                              const SizedBox(height: 8),
                            ],
                          ),
                        ),
                      ),
                      if (widget.isTv)
                        const SliverToBoxAdapter(child: SizedBox(height: 8)),
                      if (widget.isTv)
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: _SeasonsEpisodes(detail: _bundle!.detail),
                          ),
                        ),
                      if (_bundle!.cast.isNotEmpty)
                        SliverToBoxAdapter(
                          child: _CastSection(cast: _bundle!.cast),
                        ),
                      if (_bundle!.providers.hasAny)
                        SliverToBoxAdapter(
                          child: _ProvidersSection(prov: _bundle!.providers),
                        ),
                      if (widget.isTv && _bundle!.networks.isNotEmpty)
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Yayınlandığı Kanal(lar)',
                                  style: theme.textTheme.titleMedium,
                                ),
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: -6,
                                  children:
                                      _bundle!.networks.map((n) {
                                        final logo = n['logo'] ?? '';
                                        final name = n['name'] ?? '';
                                        final cc = _countryName(n['country']);
                                        return Chip(
                                          avatar:
                                              (logo.isNotEmpty)
                                                  ? CircleAvatar(
                                                    backgroundImage:
                                                        NetworkImage(logo),
                                                  )
                                                  : null,
                                          label: Text(
                                            cc.isNotEmpty
                                                ? '$name ($cc)'
                                                : name,
                                          ),
                                          visualDensity: VisualDensity.compact,
                                          materialTapTargetSize:
                                              MaterialTapTargetSize.shrinkWrap,
                                        );
                                      }).toList(),
                                ),
                              ],
                            ),
                          ),
                        ),
                      if (!widget.isTv && _bundle!.isTheatricalOnly)
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.purple.withValues(
                                          alpha: .18,
                                        ),
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(
                                          color: Colors.purple.withValues(
                                            alpha: .3,
                                          ),
                                        ),
                                      ),
                                      child: const Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.local_movies, size: 18),
                                          SizedBox(width: 6),
                                          Text('Sadece Sinemalarda'),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                if (_bundle!.theatricalDate != null)
                                  Text(
                                    'Vizyon: ${_bundle!.theatricalDate!.toLocal().toString().substring(0, 10)}'
                                    ' • Bölge: ${_countryName(_bundle!.theatricalRegion)}',
                                    style: theme.textTheme.bodyMedium,
                                  ),
                              ],
                            ),
                          ),
                        ),
                      const SliverToBoxAdapter(child: SizedBox(height: 24)),
                    ],
                  ),
        ),
      ),
    );
  }
}

class _HeaderSection extends StatelessWidget {
  const _HeaderSection({required this.bundle});
  final TitleDetailBundle bundle;

  @override
  Widget build(BuildContext context) {
    final d = bundle.detail;
    final backdrop = TmdbApi.backdropUrl(d['backdrop_path'] as String?);
    final poster = TmdbApi.posterUrl(d['poster_path'] as String?);

    return AspectRatio(
      aspectRatio: 16 / 9,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (backdrop != null)
            Image.network(backdrop, fit: BoxFit.cover)
          else
            Container(color: Colors.black12),
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.center,
                colors: [Colors.black87, Colors.transparent],
              ),
            ),
          ),
          if (poster != null)
            Align(
              alignment: Alignment.bottomLeft,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(poster, width: 120, fit: BoxFit.cover),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _MetaGenresRow extends StatelessWidget {
  const _MetaGenresRow({required this.year, required this.genres});
  final int? year;
  final List<String> genres;

  @override
  Widget build(BuildContext context) {
    final chips = <Widget>[];
    if (year != null) {
      chips.add(
        Chip(
          label: Text('$year'),
          visualDensity: VisualDensity.compact,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      );
    }
    for (final g in genres) {
      chips.add(
        Chip(
          label: Text(g),
          visualDensity: VisualDensity.compact,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      );
    }
    if (chips.isEmpty) return const SizedBox.shrink();
    return Wrap(spacing: 6, runSpacing: -6, children: chips);
  }
}

class _RatingsRow extends StatelessWidget {
  const _RatingsRow({required this.ratings});
  final Map<String, String> ratings;

  @override
  Widget build(BuildContext context) {
    if (ratings.isEmpty) return const SizedBox.shrink();
    return Wrap(
      spacing: 8,
      runSpacing: -6,
      children:
          ratings.entries.map((e) {
            final isImdb = e.key.toLowerCase().contains('imdb');
            final isTmdb = e.key.toLowerCase().contains('tmdb');
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).colorScheme.surfaceContainerHighest.withValues(alpha: .6),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.star_rounded,
                    size: 18,
                    color:
                        isImdb
                            ? const Color(0xFFFFC107)
                            : isTmdb
                            ? const Color(0xFF01B4E4)
                            : Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${e.key}: ${e.value}',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            );
          }).toList(),
    );
  }
}

class _SeasonsEpisodes extends StatelessWidget {
  const _SeasonsEpisodes({required this.detail});
  final Map<String, dynamic> detail;

  @override
  Widget build(BuildContext context) {
    final seasons = (detail['number_of_seasons'] as num?)?.toInt();
    final episodes = (detail['number_of_episodes'] as num?)?.toInt();

    if ((seasons ?? 0) == 0 && (episodes ?? 0) == 0) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.tv,
                color: Theme.of(context).colorScheme.secondaryFixed,
              ),
              const SizedBox(width: 8),
              Text(
                'Sezon / Bölüm',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              if (seasons != null)
                Text(
                  '⭐️ Sezon: $seasons',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              if (seasons != null && episodes != null) const Text('  •  '),
              if (episodes != null)
                Text(
                  'Bölüm: $episodes',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CastSection extends StatelessWidget {
  const _CastSection({required this.cast});
  final List<Map<String, dynamic>> cast;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 0, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Oyuncular',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 110,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.only(right: 16),
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemCount: cast.length,
              itemBuilder: (_, i) {
                final c = cast[i];
                return Column(
                  children: [
                    CircleAvatar(
                      radius: 32,
                      backgroundImage:
                          (c['profile'] as String?)?.isNotEmpty == true
                              ? NetworkImage(c['profile'] as String)
                              : null,
                      child:
                          (c['profile'] as String?)?.isNotEmpty == true
                              ? null
                              : const Icon(Icons.person),
                    ),
                    const SizedBox(height: 6),
                    SizedBox(
                      width: 90,
                      child: Text(
                        c['name'] ?? '',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ProvidersSection extends StatelessWidget {
  const _ProvidersSection({required this.prov});
  final WatchProviders prov;

  Widget _row(String title, List<Map<String, String>> items) {
    if (items.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
          ...items.map(
            (e) => Chip(
              avatar:
                  (e['logo'] ?? '').isNotEmpty
                      ? CircleAvatar(backgroundImage: NetworkImage(e['logo']!))
                      : null,
              label: Text(e['name'] ?? ''),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Nerede İzlenir?',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          _row('Abonelik', prov.flatrate),
          _row('Satın Al', prov.buy),
          _row('Kirala', prov.rent),
        ],
      ),
    );
  }
}
