import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/profile_repository.dart';
import '../../widgets/primary_lottie_button.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _loading = false;
  bool _obscure = true;

  final _auth = AuthRepository();
  final _profiles = ProfileRepository();

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    final started = DateTime.now();

    String? error;
    bool ok = false;

    try {
      final res = await _auth.signInWithEmail(
        email: _email.text.trim(),
        password: _password.text,
      );
      final user = res.user ?? Supabase.instance.client.auth.currentUser;
      if (user == null) throw const AuthException('Giriş başarısız');
      await _profiles.ensureProfile(user);
      ok = true;
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

    if (ok) {
      context.go('/app/movies'); // <<< ÖNEMLİ: /discover yerine
    } else if (error != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error)));
    }
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
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
                constraints: const BoxConstraints(maxWidth: 420),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Giriş Yap',
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
                            obscureText: _obscure,
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
                                    () => setState(() => _obscure = !_obscure),
                                icon: Icon(
                                  _obscure
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
                          const SizedBox(height: 20),

                          PrimaryLottieButton(
                            loading: _loading,
                            text: 'Giriş Yap',
                            onPressed: _submit,
                          ),

                          const SizedBox(height: 16),
                          Center(
                            child: TextButton(
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.white,
                              ),
                              onPressed: () => context.go('/register'),
                              child: const Text('Hesabın yok mu? Kayıt ol'),
                            ),
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
