class TitleDetail {
  TitleDetail({
    required this.id,
    required this.isTv,
    required this.title,
    required this.overview,
    required this.posterPath,
    required this.backdropPath,
    required this.genres,
    required this.year,
    required this.vote,
    required this.youtubeKey, // null olabilir
  });

  final int id;
  final bool isTv;
  final String title;
  final String overview;
  final String? posterPath;
  final String? backdropPath;
  final List<String> genres;
  final int? year;
  final double vote;
  final String? youtubeKey;

  static TitleDetail fromMovieJson(Map<String, dynamic> m) {
    final vids = (m['videos']?['results'] as List? ?? []);
    final yt = vids.firstWhere(
      (v) => (v['site'] == 'YouTube') && (v['type'] == 'Trailer'),
      orElse: () => null,
    );
    final title = (m['title'] ?? m['original_title'] ?? '').toString();
    final rel = (m['release_date'] ?? '') as String;
    final year = rel.length >= 4 ? int.tryParse(rel.substring(0, 4)) : null;
    return TitleDetail(
      id: m['id'] as int,
      isTv: false,
      title: title,
      overview: (m['overview'] ?? '').toString(),
      posterPath: m['poster_path'] as String?,
      backdropPath: m['backdrop_path'] as String?,
      genres:
          ((m['genres'] as List?) ?? [])
              .map((g) => g['name'].toString())
              .toList(),
      year: year,
      vote: (m['vote_average'] as num?)?.toDouble() ?? 0,
      youtubeKey: yt == null ? null : (yt['key'] as String?),
    );
  }

  static TitleDetail fromTvJson(Map<String, dynamic> m) {
    final vids = (m['videos']?['results'] as List? ?? []);
    final yt = vids.firstWhere(
      (v) => (v['site'] == 'YouTube') && (v['type'] == 'Trailer'),
      orElse: () => null,
    );
    final title = (m['name'] ?? m['original_name'] ?? '').toString();
    final rel = (m['first_air_date'] ?? '') as String;
    final year = rel.length >= 4 ? int.tryParse(rel.substring(0, 4)) : null;
    return TitleDetail(
      id: m['id'] as int,
      isTv: true,
      title: title,
      overview: (m['overview'] ?? '').toString(),
      posterPath: m['poster_path'] as String?,
      backdropPath: m['backdrop_path'] as String?,
      genres:
          ((m['genres'] as List?) ?? [])
              .map((g) => g['name'].toString())
              .toList(),
      year: year,
      vote: (m['vote_average'] as num?)?.toDouble() ?? 0,
      youtubeKey: yt == null ? null : (yt['key'] as String?),
    );
  }
}
