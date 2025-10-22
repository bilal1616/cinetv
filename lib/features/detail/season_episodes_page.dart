import 'package:flutter/material.dart';
import 'package:cinetv/data/repositories/detail_repository.dart';

class SeasonsEpisodesPage extends StatefulWidget {
  const SeasonsEpisodesPage({super.key, required this.tvId});
  final int tvId;

  @override
  State<SeasonsEpisodesPage> createState() => _SeasonsEpisodesPageState();
}

class _SeasonsEpisodesPageState extends State<SeasonsEpisodesPage> {
  final _repo = DetailRepository();

  // Scroll/FAB
  final _scroll = ScrollController();
  bool _showFab = false;

  bool _loading = true;
  bool _error = false;
  List<Map<String, dynamic>> _seasons = [];

  final Map<int, List<Map<String, dynamic>>> _episodesBySeason = {};
  final Map<int, bool> _loadingSeason = {};
  final Map<int, bool> _errorSeason = {};

  // --- Showcase/Coachmark için ---
  final LayerLink _coachLink = LayerLink();
  OverlayEntry? _coachEntry;
  bool _coachShown = false; // sayfa ömründe bir kere göster
  final Set<int> _openSeasons = {}; // hangi ExpansionTile açık

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
    _loadSeasons();
  }

  @override
  void dispose() {
    _scroll.removeListener(_onScroll);
    _scroll.dispose();
    _removeCoach();
    super.dispose();
  }

  void _onScroll() {
    final shouldShow = _scroll.hasClients && _scroll.offset > 300;
    if (shouldShow != _showFab) setState(() => _showFab = shouldShow);
  }

  Future<void> _loadSeasons() async {
    setState(() {
      _loading = true;
      _error = false;
    });
    try {
      final data = await _repo.fetchSeasons(tvId: widget.tvId);
      if (!mounted) return;
      setState(() {
        _seasons = List<Map<String, dynamic>>.from(data)..sort(
          (a, b) =>
              (b['season_number'] ?? 0).compareTo(a['season_number'] ?? 0),
        );
        _loading = false;
      });

      // İlk yüklemede (her şey kapalıyken) küçük bir coachmark göster
      _tryShowCoachAfterBuild();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = true;
      });
    }
  }

  // ---- Bölümleri çek ----
  Future<void> _loadEpisodes(int seasonNumber) async {
    if (_episodesBySeason.containsKey(seasonNumber)) return;
    setState(() {
      _loadingSeason[seasonNumber] = true;
      _errorSeason[seasonNumber] = false;
    });
    try {
      final eps = await _repo.fetchSeasonEpisodes(
        tvId: widget.tvId,
        seasonNumber: seasonNumber,
      );
      if (!mounted) return;
      setState(() {
        _episodesBySeason[seasonNumber] = eps;
        _loadingSeason[seasonNumber] = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loadingSeason[seasonNumber] = false;
        _errorSeason[seasonNumber] = true;
      });
    }
  }

  // ---- Bölüm detay modalı ----
  void _openEpisodeDetail(Map<String, dynamic> e) {
    String? stillUrl(String? path) {
      if (path == null || path.isEmpty) return null;
      return 'https://image.tmdb.org/t/p/w780$path';
    }

    final still = stillUrl(e['still_path'] as String?);
    final episodeNo = e['episode_number'];
    final name = (e['name'] ?? '').toString();
    final overview = (e['overview'] ?? '').toString();
    final runtime = (e['runtime'] as num?)?.toInt();
    final airDate = (e['air_date'] ?? '').toString();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.75,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          builder: (context, controller) {
            return SingleChildScrollView(
              controller: controller,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (still != null)
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(20),
                      ),
                      child: AspectRatio(
                        aspectRatio: 16 / 9,
                        child: Image.network(still, fit: BoxFit.cover),
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Bölüm $episodeNo${name.isNotEmpty ? ' – $name' : ''}',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: -6,
                          children: [
                            if (runtime != null && runtime > 0)
                              Chip(
                                label: Text('$runtime dk'),
                                visualDensity: VisualDensity.compact,
                                materialTapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
                              ),
                            if (airDate.isNotEmpty)
                              Chip(
                                label: Text(airDate),
                                visualDensity: VisualDensity.compact,
                                materialTapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
                              ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        if (overview.isNotEmpty)
                          Text(
                            overview,
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                        const SizedBox(height: 18),
                        Align(
                          alignment: Alignment.centerRight,
                          child: FilledButton.icon(
                            style: const ButtonStyle(
                              backgroundColor: WidgetStatePropertyAll(
                                Color.fromARGB(255, 190, 24, 12),
                              ),
                            ),
                            onPressed: () => Navigator.of(context).pop(),
                            icon: const Icon(Icons.close, color: Colors.white),
                            label: const Text(
                              'Kapat',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _scrollToTop() async {
    if (!_scroll.hasClients) return;
    await _scroll.animateTo(
      0,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
    );
  }

  // ---- Coachmark (overlay) ----
  void _tryShowCoachAfterBuild() {
    if (_coachShown || _seasons.isEmpty) return;
    if (_openSeasons.isNotEmpty) return;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await Future.delayed(const Duration(milliseconds: 450));
      if (!mounted || _coachShown) return;
      _showCoach();
    });
  }

  void _showCoach() {
    _coachEntry = OverlayEntry(
      builder: (context) {
        return Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                onTap: _removeCoach,
                child: Container(color: Colors.black54),
              ),
            ),
            CompositedTransformFollower(
              link: _coachLink,
              offset: const Offset(-220, 36),
              showWhenUnlinked: false,
              child: Material(
                color: Colors.transparent,
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 260),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: ShapeDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: Theme.of(context).colorScheme.outlineVariant,
                        width: 1,
                      ),
                    ),
                    shadows: const [
                      BoxShadow(
                        blurRadius: 16,
                        spreadRadius: 2,
                        color: Colors.black26,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // ⬇️ daire içine alınmış ok — SADECE BU KISIM DEĞİŞTİ
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Theme.of(
                            context,
                          ).colorScheme.secondaryContainer.withValues(alpha: .25),
                          border: Border.all(
                            color: Theme.of(context).colorScheme.outlineVariant,
                          ),
                        ),
                        alignment: Alignment.center,
                        child: const Icon(
                          Icons.keyboard_arrow_down_rounded,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Bölüm detaylarına buradan ulaşabilirsiniz.',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                      const SizedBox(width: 8),
                      TextButton(
                        onPressed: _removeCoach,
                        child: const Text(
                          'Kapat',
                          style: TextStyle(
                            color: Color.fromARGB(255, 190, 24, 12),
                            fontWeight: FontWeight.bold,
                            textBaseline: TextBaseline.alphabetic,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );

    Overlay.of(context, rootOverlay: true).insert(_coachEntry!);
    _coachShown = true;
  }

  void _removeCoach() {
    _coachEntry?.remove();
    _coachEntry = null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Tüm sezon & bölümler')),
      body:
          _loading
              ? const Center(child: CircularProgressIndicator())
              : _error
              ? Center(
                child: TextButton.icon(
                  onPressed: _loadSeasons,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Yüklenemedi, tekrar dene'),
                ),
              )
              : ListView.separated(
                controller: _scroll,
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: _seasons.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, i) {
                  final s = _seasons[i];
                  final sn = s['season_number'] as int?;
                  final posterPath = s['poster_path'] as String?;
                  final poster =
                      posterPath == null || posterPath.isEmpty
                          ? null
                          : 'https://image.tmdb.org/t/p/w185$posterPath';

                  final title =
                      (s['name'] as String?)?.isNotEmpty == true
                          ? s['name'] as String
                          : 'Sezon ${sn ?? ''}';
                  final subtitleParts = <String>[];
                  final epCount = s['episode_count'] as int?;
                  if (epCount != null) subtitleParts.add('$epCount bölüm');
                  final air = s['air_date'] as String?;
                  if (air != null && air.isNotEmpty) subtitleParts.add(air);
                  final subtitle = subtitleParts.join(' • ');

                  final isOpen = sn != null && _openSeasons.contains(sn);

                  final trailingIcon = AnimatedRotation(
                    turns: isOpen ? 0.5 : 0.0,
                    duration: const Duration(milliseconds: 200),
                    child: const Icon(Icons.keyboard_arrow_down_rounded),
                  );

                  final trailing =
                      i == 0
                          ? CompositedTransformTarget(
                            link: _coachLink,
                            child: trailingIcon,
                          )
                          : trailingIcon;

                  return ExpansionTile(
                    trailing: trailing,
                    title: Text(title, style: theme.textTheme.titleMedium),
                    subtitle: subtitle.isNotEmpty ? Text(subtitle) : null,
                    leading:
                        poster != null
                            ? ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                poster,
                                width: 48,
                                fit: BoxFit.cover,
                              ),
                            )
                            : const SizedBox(width: 48, height: 48),
                    onExpansionChanged: (open) {
                      if (sn != null) {
                        setState(() {
                          if (open) {
                            _openSeasons.add(sn);
                            _removeCoach();
                          } else {
                            _openSeasons.remove(sn);
                          }
                        });
                        if (open) _loadEpisodes(sn);
                      }
                    },
                    children: [
                      if (sn == null)
                        const Padding(
                          padding: EdgeInsets.all(16),
                          child: Text('Sezon numarası bulunamadı.'),
                        )
                      else if (_loadingSeason[sn] == true)
                        const Padding(
                          padding: EdgeInsets.all(16),
                          child: CircularProgressIndicator(),
                        )
                      else if (_errorSeason[sn] == true)
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: TextButton.icon(
                            onPressed: () => _loadEpisodes(sn),
                            icon: const Icon(Icons.refresh),
                            label: const Text(
                              'Bölümler yüklenemedi, tekrar dene',
                            ),
                          ),
                        )
                      else
                        _EpisodesList(
                          items: _episodesBySeason[sn] ?? [],
                          onEpisodeTap: _openEpisodeDetail,
                        ),
                    ],
                  );
                },
              ),

      floatingActionButton: AnimatedSlide(
        duration: const Duration(milliseconds: 200),
        offset: _showFab ? Offset.zero : const Offset(0, 2),
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 200),
          opacity: _showFab ? 1 : 0,
          child: FloatingActionButton(
            tooltip: 'Yukarı çık',
            onPressed: _scrollToTop,
            child: const Icon(Icons.arrow_upward_rounded),
          ),
        ),
      ),
    );
  }
}

class _EpisodesList extends StatelessWidget {
  const _EpisodesList({required this.items, required this.onEpisodeTap});

  final List<Map<String, dynamic>> items;
  final void Function(Map<String, dynamic>) onEpisodeTap;

  String? _thumbUrl(String? path) {
    if (path == null || path.isEmpty) return null;
    return 'https://image.tmdb.org/t/p/w300$path';
  }

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Text('Bu sezon için bölüm bulunamadı.'),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const ClampingScrollPhysics(),
      itemCount: items.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, i) {
        final e = items[i];
        final still = _thumbUrl(e['still_path'] as String?);
        final num = e['episode_number'] ?? '';
        final name = (e['name'] ?? '').toString();
        final overview = (e['overview'] ?? '').toString();
        final runtime = e['runtime'] as int?;
        final tr = <String>[];
        if (runtime != null && runtime > 0) tr.add('$runtime dk');
        final air = (e['air_date'] ?? '').toString();
        if (air.isNotEmpty) tr.add(air);

        return ListTile(
          onTap: () => onEpisodeTap(e),
          leading:
              still != null
                  ? ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      still,
                      width: 72,
                      height: 40,
                      fit: BoxFit.cover,
                    ),
                  )
                  : const SizedBox(width: 72, height: 40),
          title: Text('Bölüm $num${name.isNotEmpty ? ' – $name' : ''}'),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (tr.isNotEmpty) Text(tr.join(' • ')),
              if (overview.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    overview,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 8,
          ),
        );
      },
    );
  }
}
