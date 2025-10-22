import 'dart:math';
import 'package:image_picker/image_picker.dart';
import 'package:mime/mime.dart';
import 'package:path/path.dart' as p;
import 'package:supabase_flutter/supabase_flutter.dart';

class ProfileRepository {
  final SupabaseClient _client = Supabase.instance.client;

  // -------- Profiles --------

  Future<Map<String, dynamic>?> getProfile(String userId) async {
    final resp =
        await _client.from('profiles').select().eq('id', userId).maybeSingle();
    return resp;
  }

  Future<Map<String, dynamic>?> getMyProfile() async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return null;
    return getProfile(uid);
  }

  Future<bool> _usernameExists(String username) async {
    final res = await _client
        .from('profiles')
        .select('id')
        .eq('username', username)
        .limit(1);
    return (res.isNotEmpty);
  }

  String _sanitize(String input) {
    final clean = input.replaceAll(RegExp(r'[^a-zA-Z0-9_.-]'), '');
    if (clean.isEmpty) return 'user';
    return clean;
  }

  Future<void> ensureProfile(User user) async {
    final existing = await getProfile(user.id);
    if (existing != null) return;

    final md = user.userMetadata ?? {};
    final fullName = (md['full_name'] ?? md['name'] ?? '').toString().trim();
    var username = (md['username'] ?? '').toString().trim();

    if (username.isEmpty) {
      final email = user.email ?? 'user';
      username = email.split('@').first;
    }

    username = _sanitize(username);
    if (username.length < 3) username = ('${username}___').substring(0, 3);
    if (username.length > 30) username = username.substring(0, 30);

    if (await _usernameExists(username)) {
      const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
      final rnd = Random();
      final suffix =
          List.generate(4, (_) => chars[rnd.nextInt(chars.length)]).join();
      final base = username.length > 25 ? username.substring(0, 25) : username;
      username = '${base}_$suffix';
    }

    await _client.from('profiles').insert({
      'id': user.id,
      'username': username,
      'display_name': fullName.isNotEmpty ? fullName : username,
      'avatar_url': null,
      'bio': null,
    });
  }

  Future<void> updateProfile({
    String? userId, // verilmezse currentUser kullanılır
    String? username,
    String? displayName,
    String? avatarUrl,
    String? bio,
  }) async {
    final uid = userId ?? _client.auth.currentUser?.id;
    if (uid == null) throw Exception('Not authenticated');

    final payload = <String, dynamic>{
      if (username != null) 'username': username,
      if (displayName != null) 'display_name': displayName,
      if (avatarUrl != null) 'avatar_url': avatarUrl,
      if (bio != null) 'bio': bio,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    };

    await _client.from('profiles').update(payload).eq('id', uid);
  }

  // -------- Avatar / Storage --------

  Future<XFile?> pickImage() async {
    final picker = ImagePicker();
    return picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 90,
      maxWidth: 1024,
    );
  }

  /// 'avatars' bucket'ına yükler ve **cache-bust** public URL döner.
  Future<String> uploadAvatar(XFile file) async {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception('Not authenticated');

    final bytes = await file.readAsBytes();
    final ext = p.extension(file.path).replaceFirst('.', '').toLowerCase();
    final mime = lookupMimeType(file.path, headerBytes: bytes) ?? 'image/$ext';

    final storagePath = '${user.id}/avatar.$ext'; // overwrite için sabit isim

    await _client.storage
        .from('avatars')
        .uploadBinary(
          storagePath,
          bytes,
          fileOptions: FileOptions(
            upsert: true,
            contentType: mime,
            // CDN/Browser cache’ini kırmak için:
            cacheControl: '0',
          ),
        );

    final base = _client.storage.from('avatars').getPublicUrl(storagePath);
    final v = DateTime.now().millisecondsSinceEpoch; // cache-bust
    return '$base?v=$v';
  }
}
