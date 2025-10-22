import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/profile_repository.dart';
import '../../widgets/primary_lottie_button.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});
  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _fullName = TextEditingController();
  final _username = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();

  bool _loading = false;
  bool _obscure1 = true;
  bool _obscure2 = true;

  final _auth = AuthRepository();
  final _profiles = ProfileRepository();

  String? _validateUsername(String? v) {
    if (v == null || v.trim().isEmpty) return 'Kullanıcı adı gerekli';
    final clean = v.trim();
    if (clean.length < 3) return 'En az 3 karakter';
    if (!RegExp(r'^[a-zA-Z0-9_.-]+$').hasMatch(clean)) {
      return 'Sadece harf, rakam, . _ -';
    }
    return null;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    final started = DateTime.now();

    String? nextRoute;
    String? error;

    try {
      final res = await _auth.signUpWithEmail(
        email: _email.text.trim(),
        password: _password.text,
        fullName: _fullName.text.trim(),
        username: _username.text.trim(),
      );

      final user = res.user ?? Supabase.instance.client.auth.currentUser;
      if (user != null) {
        await _profiles.ensureProfile(user);
        nextRoute = '/app/movies'; // <<< ÖNEMLİ
      } else {
        nextRoute = '/login';
      }
    } on AuthException catch (e) {
      error = e.message;
    } catch (_) {
      error = 'Bir hata oluştu';
    }

    final elapsed = DateTime.now().difference(started).inMilliseconds;
    final remain = 3200 - elapsed;
    if (remain > 0) await Future.delayed(Duration(milliseconds: remain));

    if (!mounted) return;
    setState(() => _loading = false);

    if (nextRoute != null) {
      if (nextRoute == '/login') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Kayıt tamamlandı. Lütfen giriş yap.')),
        );
      }
      context.go(nextRoute);
    } else if (error != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error)));
    }
  }

  @override
  void dispose() {
    _fullName.dispose();
    _username.dispose();
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
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
                      'Kayıt Ol',
                      style: Theme.of(
                        context,
                      ).textTheme.headlineMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          TextFormField(
                            controller: _fullName,
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
                                Icons.person,
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
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _email,
                            keyboardType: TextInputType.emailAddress,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              labelText: 'E-posta',
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
                                Icons.mail,
                                color: Colors.white,
                              ),
                            ),
                            validator:
                                (v) =>
                                    (v == null || !v.contains('@'))
                                        ? 'Geçerli e-posta'
                                        : null,
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _password,
                            obscureText: _obscure1,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              labelText: 'Şifre',
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
                                Icons.lock,
                                color: Colors.white,
                              ),
                              suffixIcon: IconButton(
                                onPressed:
                                    () =>
                                        setState(() => _obscure1 = !_obscure1),
                                icon: Icon(
                                  _obscure1
                                      ? Icons.visibility
                                      : Icons.visibility_off,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            validator:
                                (v) =>
                                    (v == null || v.length < 6)
                                        ? 'En az 6 karakter'
                                        : null,
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _confirm,
                            obscureText: _obscure2,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              labelText: 'Şifre (tekrar)',
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
                                Icons.lock_outline,
                                color: Colors.white,
                              ),
                              suffixIcon: IconButton(
                                onPressed:
                                    () =>
                                        setState(() => _obscure2 = !_obscure2),
                                icon: Icon(
                                  _obscure2
                                      ? Icons.visibility
                                      : Icons.visibility_off,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            validator:
                                (v) =>
                                    (v != _password.text)
                                        ? 'Şifreler uyuşmuyor'
                                        : null,
                          ),
                          const SizedBox(height: 20),

                          PrimaryLottieButton(
                            loading: _loading,
                            text: 'Kayıt Ol',
                            onPressed: _submit,
                          ),

                          const SizedBox(height: 10),
                          TextButton(
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.white,
                            ),
                            onPressed: () => context.go('/login'),
                            child: const Text('Giriş sayfasına dön'),
                          ),
                        ],
                      ),
                    ),
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
