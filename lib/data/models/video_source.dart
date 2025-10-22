// lib/data/models/video_source.dart
class VideoSource {
  final String site; // 'YouTube' | 'Vimeo' | 'Dailymotion'
  final String id; // video key/id
  final String name; // "Official Trailer" vb.
  final String type; // 'Trailer' | 'Teaser' | 'Clip' | ...

  const VideoSource({
    required this.site,
    required this.id,
    required this.name,
    required this.type,
  });

  String get embedUrl {
    switch (site) {
      case 'YouTube':
        return 'https://www.youtube.com/embed/$id?autoplay=1';
      case 'Vimeo':
        return 'https://player.vimeo.com/video/$id?autoplay=1&playsinline=1';
      case 'Dailymotion':
        return 'https://www.dailymotion.com/embed/video/$id?autoplay=1';
      default:
        return '';
    }
  }

  bool get isYouTube => site == 'YouTube';
}

enum TrailerProvider { youtube, vimeo, dailymotion }

class TrailerSource {
  final TrailerProvider provider;
  final String videoId;
  final bool autoPlay;
  const TrailerSource({
    required this.provider,
    required this.videoId,
    this.autoPlay = true,
  });
}

class TrailerArgs {
  final String title;
  final TrailerSource source;
  const TrailerArgs({required this.title, required this.source});
}
