import 'package:dio/dio.dart';
import '../datasources/remote/tmdb_api.dart';
import '../models/title_summary.dart';

class SearchRepository {
  final _api = TmdbApi.I;

  Future<List<Map<String, dynamic>>> getGenres({required bool tv}) async {
    final Response<Map<String, dynamic>> r =
        tv ? await _api.tvGenres() : await _api.movieGenres();
    return (r.data?['genres'] as List? ?? []).cast<Map<String, dynamic>>();
  }

  Future<List<TitleSummary>> discover({
    required bool tv,
    required int page,
    int? yearFrom,
    int? yearTo,
    List<int>? genreIds,
  }) async {
    final resp =
        tv
            ? await _api.discoverTv(
              page: page,
              yearFrom: yearFrom,
              yearTo: yearTo,
              genreIds: genreIds,
            )
            : await _api.discoverMovies(
              page: page,
              yearFrom: yearFrom,
              yearTo: yearTo,
              genreIds: genreIds,
            );

    final list = (resp.data?['results'] as List? ?? []);
    return list.map((m) {
      final isTv = tv;
      final title =
          isTv
              ? (m['name'] ?? m['original_name'])
              : (m['title'] ?? m['original_title']);
      final date = isTv ? m['first_air_date'] : m['release_date'];
      final year =
          (date is String && date.length >= 4)
              ? int.tryParse(date.substring(0, 4))
              : null;

      return TitleSummary(
        id: m['id'] as int,
        isTv: isTv,
        title: (title ?? '').toString(),
        posterPath: m['poster_path'] as String?,
        vote: (m['vote_average'] as num?)?.toDouble() ?? 0,
        year: year,
      );
    }).toList();
  }

  /// METİNLE ARAMA (başlığa göre)
  Future<List<TitleSummary>> searchByText({
    required String query,
    required bool isTv,
    int page = 1,
  }) async {
    if (query.trim().isEmpty) return [];
    final Response<Map<String, dynamic>> r =
        isTv
            ? await _api.searchTv(query, page: page)
            : await _api.searchMovies(query, page: page);

    final list = (r.data?['results'] as List? ?? []);
    return list.map<TitleSummary>((m) {
      final title =
          isTv
              ? (m['name'] ?? m['original_name'])
              : (m['title'] ?? m['original_title']);
      final date = isTv ? m['first_air_date'] : m['release_date'];
      final year =
          (date is String && date.length >= 4)
              ? int.tryParse(date.substring(0, 4))
              : null;
      return TitleSummary(
        id: m['id'] as int,
        isTv: isTv,
        title: (title ?? '').toString(),
        posterPath: m['poster_path'] as String?,
        vote: (m['vote_average'] as num?)?.toDouble() ?? 0,
        year: year,
      );
    }).toList();
  }
}
