import 'package:cinetv/widgets/app_snackbar.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/repositories/profile_repository.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _displayName = TextEditingController();
  final _username = TextEditingController();
  final _repo = ProfileRepository();

  bool _loading = false;
  String? _avatarUrl;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final p = await _repo.getMyProfile();
    if (!mounted) return;
    if (p != null) {
      _displayName.text = (p['display_name'] ?? '') as String;
      _username.text = (p['username'] ?? '') as String;
      _avatarUrl = p['avatar_url'] as String?;
      setState(() {});
    }
  }

  String? _validateUsername(String? v) {
    if (v == null || v.trim().isEmpty) return 'Kullanıcı adı gerekli';
    final clean = v.trim();
    if (clean.length < 3) return 'En az 3 karakter';
    if (!RegExp(r'^[a-zA-Z0-9_.-]+$').hasMatch(clean)) {
      return 'Sadece harf, rakam, . _ -';
    }
    return null;
  }

  Future<void> _pickAndUpload() async {
    final x = await _repo.pickImage();
    if (x == null) return;

    setState(() => _loading = true);
    try {
      final newUrl = await _repo.uploadAvatar(x);

      // Eski resmi ImageCache’ten temizle
      if (_avatarUrl != null && _avatarUrl!.isNotEmpty) {
        final old = NetworkImage(_avatarUrl!);
        await old.evict();
      }

      await _repo.updateProfile(avatarUrl: newUrl);

      if (!mounted) return;
      setState(() => _avatarUrl = newUrl);

      AppSnack.avatarUpdated(context);
    } catch (_) {
      if (!mounted) return;
      AppSnack.show(
        context,
        title: 'Avatar yüklenemedi',
        type: AppSnackType.danger,
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await _repo.updateProfile(
        displayName: _displayName.text.trim(),
        username: _username.text.trim(),
      );
      if (!mounted) return;
      AppSnack.profileSaved(
        context,
        message:
            _displayName.text.trim().isNotEmpty
                ? _displayName.text.trim()
                : null,
      );
    } catch (_) {
      if (!mounted) return;
      AppSnack.show(
        context,
        title: 'Bir hata oluştu',
        message: 'Profil kaydedilemedi',
        type: AppSnackType.danger,
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _displayName.dispose();
    _username.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fieldFill =
        isDark
            ? Colors.white.withValues(alpha: 0.08)
            : Colors.black.withValues(alpha: 0.06);
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
    );

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF7C3AED), Color(0xFF06B6D4)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Profil',
                      style: Theme.of(
                        context,
                      ).textTheme.headlineMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Avatar + edit (ikon DIŞARIDA)
                    SizedBox(
                      width: 120,
                      height: 120,
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Align(
                            alignment: Alignment.center,
                            child: CircleAvatar(
                              key: ValueKey(_avatarUrl),
                              radius: 56,
                              backgroundColor: Colors.white.withValues(
                                alpha: .25,
                              ),
                              backgroundImage:
                                  (_avatarUrl != null && _avatarUrl!.isNotEmpty)
                                      ? NetworkImage(_avatarUrl!)
                                      : null,
                              child:
                                  (_avatarUrl == null || _avatarUrl!.isEmpty)
                                      ? const Icon(
                                        Icons.person,
                                        size: 48,
                                        color: Colors.white,
                                      )
                                      : null,
                            ),
                          ),
                          Positioned(
                            right: -10, // DIŞA taşır
                            bottom: -6,
                            child: GestureDetector(
                              onTap: _loading ? null : _pickAndUpload,
                              child: Container(
                                width: 44,
                                height: 44,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white,
                                ),
                                child: const Icon(
                                  Icons.edit,
                                  color: Color(0xFF7C3AED),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Form
                    Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          TextFormField(
                            controller: _displayName,
                            textCapitalization: TextCapitalization.words,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              labelText: 'Ad Soyad',
                              labelStyle: TextStyle(
                                color: Colors.white.withValues(alpha: 0.9),
                              ),
                              filled: true,
                              fillColor: fieldFill,
                              enabledBorder: border,
                              focusedBorder: border.copyWith(
                                borderSide: const BorderSide(
                                  color: Colors.white,
                                ),
                              ),
                              prefixIcon: const Icon(
                                Icons.badge,
                                color: Colors.white,
                              ),
                            ),
                            validator:
                                (v) =>
                                    (v == null || v.trim().length < 2)
                                        ? 'Geçerli ad-soyad'
                                        : null,
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _username,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              labelText: 'Kullanıcı Adı',
                              labelStyle: TextStyle(
                                color: Colors.white.withValues(alpha: 0.9),
                              ),
                              filled: true,
                              fillColor: fieldFill,
                              enabledBorder: border,
                              focusedBorder: border.copyWith(
                                borderSide: const BorderSide(
                                  color: Colors.white,
                                ),
                              ),
                              prefixIcon: const Icon(
                                Icons.alternate_email,
                                color: Colors.white,
                              ),
                            ),
                            validator: _validateUsername,
                          ),

                          const SizedBox(height: 16),

                          // Daha küçük "Kaydet"
                          Align(
                            alignment: Alignment.center,
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(minWidth: 240),
                              child: SizedBox(
                                height: 44,
                                child: ElevatedButton(
                                  onPressed: _loading ? null : _save,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(
                                      0xFF7C3AED,
                                    ), // MOR — Daha Fazla Göster ile aynı
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    elevation: 0,
                                  ),
                                  child:
                                      _loading
                                          ? const SizedBox(
                                            width: 22,
                                            height: 22,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              valueColor:
                                                  AlwaysStoppedAnimation<Color>(
                                                    Colors.white,
                                                  ),
                                            ),
                                          )
                                          : const Text(
                                            'Kaydet',
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 12),
                          TextButton.icon(
                            onPressed: () async {
                              await Supabase.instance.client.auth.signOut();
                              if (context.mounted) context.go('/login');
                            },
                            icon: const Icon(Icons.logout, color: Colors.white),
                            label: const Text(
                              'Çıkış Yap',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 28),

                    // ---- Favorilerim (AYRI SAYFA) ----
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Favorilerim',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: () => context.push('/app/favorites'),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: .12),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.white24),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.favorite, color: Colors.white),
                            SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Favorileri görüntüle',
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                            Icon(Icons.chevron_right, color: Colors.white),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
