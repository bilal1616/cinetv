import 'package:supabase_flutter/supabase_flutter.dart';
import '../datasources/remote/tmdb_api.dart';
import '../models/title_summary.dart';
import 'package:dio/dio.dart';

class FavoritesRepository {
  final _client = Supabase.instance.client;
  final _api = TmdbApi.I;

  String _type(bool isTv) => isTv ? 'show' : 'movie';

  Future<bool> isFavorite({required bool isTv, required int titleId}) async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return false;
    final rows = await _client
        .from('favorites')
        .select('tmdb_id')
        .eq('user_id', uid)
        .eq('type', _type(isTv))
        .eq('tmdb_id', titleId)
        .limit(1);
    return (rows as List).isNotEmpty;
  }

  Future<void> addFavorite({required bool isTv, required int titleId}) async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) throw Exception('not-authenticated');
    await _client.from('favorites').upsert({
      'user_id': uid,
      'type': _type(isTv),
      'tmdb_id': titleId,
    });
  }

  Future<void> removeFavorite({
    required bool isTv,
    required int titleId,
  }) async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) throw Exception('not-authenticated');
    await _client.from('favorites').delete().match({
      'user_id': uid,
      'type': _type(isTv),
      'tmdb_id': titleId,
    });
  }

  /// Varsa siler, yoksa ekler
  Future<bool> toggleFavorite({
    required bool isTv,
    required int titleId,
  }) async {
    final exists = await isFavorite(isTv: isTv, titleId: titleId);
    if (exists) {
      await removeFavorite(isTv: isTv, titleId: titleId);
      return false;
    } else {
      await addFavorite(isTv: isTv, titleId: titleId);
      return true;
    }
  }

  /// Profilde listelemek için
  Future<List<TitleSummary>> getMyFavorites({
    required bool isTv,
    int limit = 30,
    int offset = 0,
  }) async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return [];

    final rows = await _client
        .from('favorites')
        .select('tmdb_id')
        .eq('user_id', uid)
        .eq('type', _type(isTv))
        .order('created_at', ascending: false)
        .range(offset, offset + limit - 1);

    final ids = (rows as List).map((e) => e['tmdb_id'] as int).toList();
    final List<TitleSummary> out = [];
    for (final id in ids) {
      final Response<Map<String, dynamic>> r =
          isTv ? await _api.tvDetail(id) : await _api.movieDetail(id);
      final m = r.data ?? {};
      final title =
          isTv
              ? (m['name'] ?? m['original_name'])
              : (m['title'] ?? m['original_title']);
      final date = isTv ? m['first_air_date'] : m['release_date'];
      final year =
          (date is String && date.length >= 4)
              ? int.tryParse(date.substring(0, 4))
              : null;
      out.add(
        TitleSummary(
          id: id,
          isTv: isTv,
          title: (title ?? '').toString(),
          posterPath: m['poster_path'] as String?,
          vote: (m['vote_average'] as num?)?.toDouble() ?? 0,
          year: year,
        ),
      );
    }
    return out;
  }
}
