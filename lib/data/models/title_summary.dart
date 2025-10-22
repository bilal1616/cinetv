import 'package:meta/meta.dart';

/// Keşif listelerinde kullandığımız hafif model.
/// Repo `TitleSummary(isTv: ..., vote: ..., year: ...)` şeklinde çağırdığı için
/// bu alanlar ana kurucuda zorunlu tutulur.
@immutable
class TitleSummary {
  final int id;
  final bool isTv; // true => tv, false => movie
  final String title;
  final String? posterPath; // TMDB relative path: /abc.jpg
  final double vote; // 0..10
  final int? year; // yyyy

  // Ek bilgiler (opsiyonel): overview & popularity
  final String? overview;
  final double popularity;

  const TitleSummary({
    required this.id,
    required this.isTv,
    required this.title,
    required this.posterPath,
    required this.vote,
    required this.year,
    this.overview,
    this.popularity = 0,
  });

  /// Tam poster URL’si
  String? get posterUrl =>
      (posterPath == null || posterPath!.isEmpty)
          ? null
          : 'https://image.tmdb.org/t/p/w500$posterPath';

  /// TMDB movie cevabından dönüştürür
  factory TitleSummary.fromMovieJson(Map<String, dynamic> j) {
    final title = (j['title'] ?? j['original_title'] ?? '').toString();
    return TitleSummary(
      id: j['id'] as int,
      isTv: false,
      title: title,
      posterPath: j['poster_path'] as String?,
      vote: ((j['vote_average'] ?? 0) as num).toDouble(),
      year: _year(j['release_date']),
      overview: j['overview'] as String?,
      popularity: ((j['popularity'] ?? 0) as num).toDouble(),
    );
  }

  /// TMDB tv cevabından dönüştürür
  factory TitleSummary.fromTvJson(Map<String, dynamic> j) {
    final title = (j['name'] ?? j['original_name'] ?? '').toString();
    return TitleSummary(
      id: j['id'] as int,
      isTv: true,
      title: title,
      posterPath: j['poster_path'] as String?,
      vote: ((j['vote_average'] ?? 0) as num).toDouble(),
      year: _year(j['first_air_date']),
      overview: j['overview'] as String?,
      popularity: ((j['popularity'] ?? 0) as num).toDouble(),
    );
  }

  /// search/multi için (movie/tv dışındakileri — person vs. — eler)
  static TitleSummary? fromMultiJson(Map<String, dynamic> j) {
    final t = j['media_type'];
    if (t == 'movie') return TitleSummary.fromMovieJson(j);
    if (t == 'tv') return TitleSummary.fromTvJson(j);
    return null;
  }

  static int? _year(dynamic dateStr) {
    final s = (dateStr ?? '').toString();
    if (s.length >= 4) {
      return int.tryParse(s.substring(0, 4));
    }
    return null;
  }

  @override
  String toString() =>
      'TitleSummary(id: $id, isTv: $isTv, title: $title, year: $year)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TitleSummary &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          isTv == other.isTv;

  @override
  int get hashCode => Object.hash(id, isTv);
}
