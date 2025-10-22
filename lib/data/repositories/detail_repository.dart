import 'package:dio/dio.dart';
import '../datasources/remote/tmdb_api.dart';

class DetailRepository {
  final _api = TmdbApi.I;

  Future<List<Map<String, dynamic>>> fetchSeasons({
    required int tvId,
    String language = 'tr-TR',
  }) async {
    final Response<Map<String, dynamic>> res = await _api.tvDetail(tvId);
    final data = res.data ?? const {};
    final seasons =
        (data['seasons'] as List? ?? const [])
            .whereType<Map>()
            .map<Map<String, dynamic>>(
              (e) => {
                'season_number': (e['season_number'] as num?)?.toInt(),
                'name': (e['name'] ?? '').toString(),
                'overview': (e['overview'] ?? '').toString(),
                'episode_count': (e['episode_count'] as num?)?.toInt(),
                'air_date': (e['air_date'] ?? '').toString(),
                'poster_path': e['poster_path'],
              },
            )
            .toList()
          ..sort(
            (a, b) =>
                (b['season_number'] ?? 0).compareTo(a['season_number'] ?? 0),
          );
    return seasons;
  }

  Future<List<Map<String, dynamic>>> fetchSeasonEpisodes({
    required int tvId,
    required int seasonNumber,
    String language = 'tr-TR',
  }) async {
    final Response<Map<String, dynamic>> res = await _api.tvSeason(
      tvId,
      seasonNumber,
      language: language,
    );
    final data = res.data ?? const {};
    final episodes =
        (data['episodes'] as List? ?? const [])
            .whereType<Map>()
            .map<Map<String, dynamic>>(
              (e) => {
                'episode_number': (e['episode_number'] as num?)?.toInt(),
                'name': (e['name'] ?? '').toString(),
                'overview': (e['overview'] ?? '').toString(),
                'runtime': (e['runtime'] as num?)?.toInt(),
                'air_date': (e['air_date'] ?? '').toString(),
                'still_path': e['still_path'],
              },
            )
            .toList();
    return episodes;
  }

  Future<TitleDetailBundle> fetchDetail({
    required bool isTv,
    required int id,
    String region = 'TR',
  }) async {
    final Response<Map<String, dynamic>> d =
        isTv ? await _api.tvDetail(id) : await _api.movieDetail(id);
    final Response<Map<String, dynamic>> v =
        isTv ? await _api.tvVideos(id) : await _api.movieVideos(id);
    final Response<Map<String, dynamic>> c =
        isTv ? await _api.tvCredits(id) : await _api.movieCredits(id);
    final Response<Map<String, dynamic>> p =
        isTv
            ? await _api.tvWatchProviders(id)
            : await _api.movieWatchProviders(id);

    Response<Map<String, dynamic>>? rd;
    if (!isTv) rd = await _api.movieReleaseDates(id);

    final detail = d.data ?? {};
    final videosRaw = (v.data?['results'] as List?) ?? const [];

    final videos =
        videosRaw
            .where(
              (e) => [
                'YouTube',
                'Vimeo',
                'Dailymotion',
              ].contains((e['site'] ?? '').toString()),
            )
            .map<Map<String, String>>(
              (e) => {
                'site': (e['site'] ?? '').toString(),
                'key': (e['key'] ?? '').toString(),
                'name': (e['name'] ?? '').toString(),
                'type': (e['type'] ?? '').toString(),
              },
            )
            .toList();

    final cast =
        ((c.data?['cast'] as List?) ?? const [])
            .take(20)
            .map<Map<String, dynamic>>(
              (e) => {
                'name': (e['name'] ?? '').toString(),
                'character': (e['character'] ?? '').toString(),
                'profile': TmdbApi.profileUrl(e['profile_path'] as String?),
              },
            )
            .toList();

    Map<String, dynamic>? regionBlock =
        (p.data?['results'] as Map?)?[region] as Map<String, dynamic>?;
    regionBlock ??=
        (p.data?['results'] as Map?)?['US'] as Map<String, dynamic>?;

    List<Map<String, String>> parseProviders(List list) =>
        list
            .map<Map<String, String>>(
              (e) => {
                'name': (e['provider_name'] ?? '').toString(),
                'logo': TmdbApi.logoUrl(e['logo_path'] as String?) ?? '',
              },
            )
            .toList();

    final providers = WatchProviders(
      flatrate: parseProviders((regionBlock?['flatrate'] as List?) ?? const []),
      buy: parseProviders((regionBlock?['buy'] as List?) ?? const []),
      rent: parseProviders((regionBlock?['rent'] as List?) ?? const []),
    );

    final networks = <Map<String, String>>[];
    if (isTv) {
      final list = (detail['networks'] as List?) ?? const [];
      for (final n in list) {
        final m = (n as Map).cast<String, dynamic>();
        networks.add({
          'name': (m['name'] ?? '').toString(),
          'logo': TmdbApi.logoUrl(m['logo_path'] as String?) ?? '',
          'country': (m['origin_country'] ?? '').toString(),
        });
      }
    }

    bool isTheatricalOnly = false;
    DateTime? theatricalDate;
    String? theatricalRegion;

    if (!isTv && rd != null) {
      final results = (rd.data?['results'] as List?) ?? const [];
      Map<String, dynamic>? tr = results
          .cast<Map<String, dynamic>>()
          .firstWhere(
            (e) => (e['iso_3166_1'] ?? '') == region,
            orElse: () => {},
          );
      Map<String, dynamic>? us = results
          .cast<Map<String, dynamic>>()
          .firstWhere((e) => (e['iso_3166_1'] ?? '') == 'US', orElse: () => {});
      Map<String, dynamic>? chosen =
          (tr.isNotEmpty)
              ? tr
              : (us.isNotEmpty)
              ? us
              : (results.isNotEmpty
                  ? results.first as Map<String, dynamic>
                  : null);

      if (chosen != null && chosen.isNotEmpty) {
        final rels = (chosen['release_dates'] as List?) ?? const [];
        final theatricals =
            rels.where((e) {
              final t = (e['type'] as num?)?.toInt();
              return t == 2 || t == 3;
            }).toList();

        if (theatricals.isNotEmpty) {
          theatricals.sort((a, b) {
            final da =
                DateTime.tryParse((a['release_date'] ?? '').toString()) ??
                DateTime(1900);
            final db =
                DateTime.tryParse((b['release_date'] ?? '').toString()) ??
                DateTime(1900);
            return da.compareTo(db);
          });
          theatricalDate = DateTime.tryParse(
            (theatricals.first['release_date'] ?? '').toString(),
          );
          theatricalRegion = (chosen['iso_3166_1'] ?? '').toString();
        }
      }

      final hasDigital =
          ((regionBlock?['flatrate'] as List?)?.isNotEmpty ?? false) ||
          ((regionBlock?['ads'] as List?)?.isNotEmpty ?? false) ||
          ((regionBlock?['free'] as List?)?.isNotEmpty ?? false) ||
          ((regionBlock?['rent'] as List?)?.isNotEmpty ?? false) ||
          ((regionBlock?['buy'] as List?)?.isNotEmpty ?? false);

      isTheatricalOnly = (theatricalDate != null) && !hasDigital;
    }

    return TitleDetailBundle(
      isTv: isTv,
      id: id,
      detail: detail,
      videos: videos,
      cast: cast,
      providers: providers,
      networks: networks,
      isTheatricalOnly: isTheatricalOnly,
      theatricalDate: theatricalDate,
      theatricalRegion: theatricalRegion,
    );
  }
}

/// Dönüş paketi
class TitleDetailBundle {
  final bool isTv;
  final int id;
  final Map<String, dynamic> detail;
  final List<Map<String, String>> videos; // site/key/name/type
  final List<Map<String, dynamic>> cast; // name/character/profile
  final WatchProviders providers;

  // TV / Movie ek alanlar
  final List<Map<String, String>> networks; // TV: name/logo/country
  final bool isTheatricalOnly; // Movie: yalnız sinemada mı?
  final DateTime? theatricalDate; // Movie: vizyon tarihi
  final String? theatricalRegion; // Movie: TR/US...

  TitleDetailBundle({
    required this.isTv,
    required this.id,
    required this.detail,
    required this.videos,
    required this.cast,
    required this.providers,
    required this.networks,
    required this.isTheatricalOnly,
    required this.theatricalDate,
    required this.theatricalRegion,
  });
}

class WatchProviders {
  final List<Map<String, String>> flatrate;
  final List<Map<String, String>> buy;
  final List<Map<String, String>> rent;

  WatchProviders({
    required this.flatrate,
    required this.buy,
    required this.rent,
  });

  bool get hasAny => flatrate.isNotEmpty || buy.isNotEmpty || rent.isNotEmpty;
}
