import 'package:dio/dio.dart';
import '../models/title_summary.dart';
import '../datasources/remote/tmdb_api.dart';

enum DiscoverCategory { trending, popular, nowPlaying }

class PagedResult<T> {
  PagedResult({required this.items, required this.pageChunk});
  final List<T> items;
  final int pageChunk; // 1,2,3... her biri 30’luk paket
}

class DiscoverRepository {
  static const chunkSize = 30; // 3x10
  final _api = TmdbApi.I;

  // ---- FILMLER ----
  Future<PagedResult<TitleSummary>> getMovies({
    required DiscoverCategory category,
    required int chunk,
  }) {
    Future<Response<Map<String, dynamic>>> Function(int) loader;
    switch (category) {
      case DiscoverCategory.trending:
        loader = (page) => _api.trendingMovies(page);
        break;
      case DiscoverCategory.popular:
        loader = (page) => _api.popularMovies(page);
        break;
      case DiscoverCategory.nowPlaying:
        loader = (page) => _api.nowPlayingMovies(page);
        break;
    }
    return _fetchChunk(chunk: chunk, loader: loader, isTv: false);
  }

  // ---- DIZILER ----
  Future<PagedResult<TitleSummary>> getShows({
    required DiscoverCategory category,
    required int chunk,
  }) {
    Future<Response<Map<String, dynamic>>> Function(int) loader;
    switch (category) {
      case DiscoverCategory.trending:
        loader = (page) => _api.trendingShows(page);
        break;
      case DiscoverCategory.popular:
        loader = (page) => _api.popularShows(page);
        break;
      case DiscoverCategory.nowPlaying:
        loader = (page) => _api.onTheAirShows(page);
        break;
    }
    return _fetchChunk(chunk: chunk, loader: loader, isTv: true);
  }

  /// TMDB 20’şer döndüğü için bir "chunk" = 30 yapmak adına
  /// gereken kadar sayfa çeker, 30’a kırpar.
  Future<PagedResult<TitleSummary>> _fetchChunk({
    required int chunk,
    required Future<Response<Map<String, dynamic>>> Function(int page) loader,
    required bool isTv,
  }) async {
    final want = chunkSize;
    final startIndex = (chunk - 1) * want; // 0, 30, 60...
    final startPage = (startIndex ~/ 20) + 1; // TMDB sayfası

    final collected = <TitleSummary>[];
    var page = startPage;

    while (collected.length < want) {
      final resp = await loader(page);
      final list = (resp.data?['results'] as List? ?? []);
      if (list.isEmpty) break;

      for (final m in list) {
        final title =
            isTv
                ? (m['name'] ?? m['original_name'])
                : (m['title'] ?? m['original_title']);
        collected.add(
          TitleSummary(
            id: m['id'] as int,
            isTv: isTv,
            title: (title ?? '').toString(),
            posterPath: m['poster_path'] as String?,
            vote: (m['vote_average'] as num?)?.toDouble() ?? 0,
            year: _extractYear(isTv ? m['first_air_date'] : m['release_date']),
          ),
        );
      }
      page++;
      if (page - startPage > 4) break; // güvenlik
    }

    final startOffset = startIndex % 20;
    final sliced = collected.skip(startOffset).take(want).toList();
    return PagedResult(items: sliced, pageChunk: chunk);
  }

  int? _extractYear(dynamic dateStr) {
    final s = (dateStr ?? '').toString();
    if (s.length >= 4) return int.tryParse(s.substring(0, 4));
    return null;
  }
}
