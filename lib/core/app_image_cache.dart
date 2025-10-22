// lib/core/app_image_cache.dart
import 'package:flutter/foundation.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

/// Uygulama genelinde TEK bir cache yöneticisi (singleton).
class AppImageCache extends CacheManager {
  static AppImageCache? _instance;

  // ⬇⬇⬇ E K L E ⬇⬇⬇
  /// Geriye dönük uyumluluk: poster_card gibi yerlerde kullanılan instance getter'ı.
  static AppImageCache get instance => AppImageCache();
  // ⬆⬆⬆ E K L E ⬆⬆⬆

  /// Tüm isteklerde gönderilecek varsayılan header’lar.
  static Map<String, String> _defaultHeaders = <String, String>{};

  /// Varsayılan headers’ı tamamen değiştirir.
  static void setDefaultHeaders(Map<String, String> headers) {
    _defaultHeaders = Map<String, String>.from(headers);
  }

  /// Kolay kullanım için Bearer ekler/siler.
  static void setAuthBearer(String? token) {
    if (token == null || token.isEmpty) {
      _defaultHeaders.remove('Authorization');
    } else {
      _defaultHeaders['Authorization'] = 'Bearer $token';
    }
  }

  /// Tekil erişim — her çağrıda aynı örnek döner.
  factory AppImageCache() {
    return _instance ??= AppImageCache._internal();
  }

  AppImageCache._internal()
    : super(
        Config(
          'appImageCache-v1',
          stalePeriod: const Duration(days: 30),
          maxNrOfCacheObjects: 400,
          repo: JsonCacheInfoRepository(databaseName: 'app_image_cache'),
          fileService: _HeaderAwareHttpFileService(
            () => Map<String, String>.from(_defaultHeaders),
          ),
        ),
      );

  /// URL geçerliyse hafif bir warmup/precache yapar (opsiyonel).
  Future<FileInfo?> precache(String? url) async {
    final u = url?.trim();
    if (u == null || u.isEmpty) return null;
    try {
      final cached = await getFileFromCache(u);
      if (cached != null) return cached;

      // 3.x: downloadFile doğrudan FileInfo döner; header’lar fileService’ten de geçer.
      final fi = await downloadFile(u, key: u, authHeaders: _defaultHeaders);
      return fi;
    } catch (e) {
      if (kDebugMode) {
        // debugPrint('precache error: $e');
      }
      return null;
    }
  }

  /// Eski/boş girdileri temizlemek için.
  Future<void> compact() async {
    try {
      await emptyCache();
    } catch (_) {
      // sessiz geç
    }
  }
}

/// flutter_cache_manager’ın HttpFileService’ine dinamik header eklemek için
class _HeaderAwareHttpFileService extends HttpFileService {
  _HeaderAwareHttpFileService(this.headersProvider);

  final Map<String, String> Function() headersProvider;

  @override
  Future<FileServiceResponse> get(String url, {Map<String, String>? headers}) {
    final merged = <String, String>{
      ...headersProvider(),
      if (headers != null) ...headers,
    };
    return super.get(url, headers: merged);
  }
}
