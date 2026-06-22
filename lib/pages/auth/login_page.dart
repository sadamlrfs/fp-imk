import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../context/app_context.dart';
import '../../utils/app_colors.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  bool _loading = false;
  String? _error;

  // Login fields
  final _loginEmailCtrl = TextEditingController();
  final _loginPassCtrl = TextEditingController();
  bool _loginPassVisible = false;

  // Register fields
  final _regNameCtrl = TextEditingController();
  final _regEmailCtrl = TextEditingController();
  final _regPassCtrl = TextEditingController();
  final _regLang = ValueNotifier<String>('id');
  bool _regPassVisible = false;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    _tabCtrl.addListener(() => setState(() => _error = null));
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _loginEmailCtrl.dispose();
    _loginPassCtrl.dispose();
    _regNameCtrl.dispose();
    _regEmailCtrl.dispose();
    _regPassCtrl.dispose();
    _regLang.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    final email = _loginEmailCtrl.text.trim();
    final pass = _loginPassCtrl.text.trim();
    if (email.isEmpty || pass.isEmpty) {
      setState(() => _error = 'Email dan password tidak boleh kosong');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await Supabase.instance.client.auth
          .signInWithPassword(email: email, password: pass);
      if (!mounted) return;
      await context.read<AppContext>().loadData();
      if (!mounted) return;
      context.go('/home');
    } on AuthException catch (e) {
      setState(() => _error = _translateAuthError(e.message));
    } catch (e) {
      setState(() => _error = 'Terjadi kesalahan. Coba lagi.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _register() async {
    final name = _regNameCtrl.text.trim();
    final email = _regEmailCtrl.text.trim();
    final pass = _regPassCtrl.text.trim();
    final lang = _regLang.value;

    if (name.isEmpty || email.isEmpty || pass.isEmpty) {
      setState(() => _error = 'Semua kolom wajib diisi');
      return;
    }
    if (pass.length < 6) {
      setState(() => _error = 'Password minimal 6 karakter');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await Supabase.instance.client.auth.signUp(
        email: email,
        password: pass,
        data: {'name': name, 'lang': lang},
      );
      if (!mounted) return;

      if (res.session != null) {
        // Email confirmation disabled — user is already signed in
        await context.read<AppContext>().loadData();
        if (!mounted) return;
        context.go('/home');
      } else {
        // Email confirmation required — redirect to login
        _loginEmailCtrl.text = email;
        _tabCtrl.animateTo(0);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Akun berhasil dibuat! Silakan masuk.'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 4),
          ),
        );
      }
    } on AuthException catch (e) {
      setState(() => _error = _translateAuthError(e.message));
    } catch (e) {
      setState(() => _error = 'Terjadi kesalahan. Coba lagi.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await Supabase.instance.client.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: 'io.supabase.imkprototype://callback',
      );
      // Auth state change listener in main.dart will call loadData() and
      // the router refreshListenable will navigate to /home automatically.
    } on AuthException catch (e) {
      if (mounted) setState(() => _error = _translateAuthError(e.message));
    } catch (e) {
      if (mounted) setState(() => _error = 'Gagal masuk dengan Google.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _translateAuthError(String msg) {
    if (msg.contains('Invalid login credentials')) return 'Email atau password salah';
    if (msg.contains('Email not confirmed')) return 'Konfirmasi email terlebih dahulu';
    if (msg.contains('User already registered')) return 'Email sudah terdaftar, silakan login';
    if (msg.contains('Password should be')) return 'Password minimal 6 karakter';
    return msg;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FF),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              width: double.infinity,
              color: AppColors.primary,
              padding: const EdgeInsets.fromLTRB(24, 40, 24, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: AppColors.surface.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.translate, color: Colors.white, size: 24),
                      ),
                      const SizedBox(width: 12),
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('IMK Translate',
                              style: TextStyle(
                                  color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                          Text('Chat & Panggilan Bilingual',
                              style: TextStyle(color: Colors.white70, fontSize: 12)),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  TabBar(
                    controller: _tabCtrl,
                    labelColor: Colors.white,
                    unselectedLabelColor: Colors.white54,
                    indicatorColor: Colors.white,
                    indicatorWeight: 3,
                    labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                    tabs: const [
                      Tab(text: 'Masuk'),
                      Tab(text: 'Daftar'),
                    ],
                  ),
                ],
              ),
            ),
            // Error banner
            if (_error != null)
              Container(
                width: double.infinity,
                color: Colors.red[50],
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(_error!, style: const TextStyle(color: Colors.red, fontSize: 13)),
                    ),
                  ],
                ),
              ),
            // Tab content
            Expanded(
              child: TabBarView(
                controller: _tabCtrl,
                children: [
                  _LoginForm(
                    emailCtrl: _loginEmailCtrl,
                    passCtrl: _loginPassCtrl,
                    passVisible: _loginPassVisible,
                    onTogglePass: () => setState(() => _loginPassVisible = !_loginPassVisible),
                    loading: _loading,
                    onSubmit: _login,
                    onGoogleSignIn: _signInWithGoogle,
                  ),
                  _RegisterForm(
                    nameCtrl: _regNameCtrl,
                    emailCtrl: _regEmailCtrl,
                    passCtrl: _regPassCtrl,
                    passVisible: _regPassVisible,
                    onTogglePass: () => setState(() => _regPassVisible = !_regPassVisible),
                    lang: _regLang,
                    loading: _loading,
                    onSubmit: _register,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoginForm extends StatelessWidget {
  final TextEditingController emailCtrl;
  final TextEditingController passCtrl;
  final bool passVisible;
  final VoidCallback onTogglePass;
  final bool loading;
  final VoidCallback onSubmit;
  final VoidCallback onGoogleSignIn;

  const _LoginForm({
    required this.emailCtrl,
    required this.passCtrl,
    required this.passVisible,
    required this.onTogglePass,
    required this.loading,
    required this.onSubmit,
    required this.onGoogleSignIn,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 8),
          Text('Selamat datang kembali',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
          const SizedBox(height: 4),
          Text('Masuk ke akun IMK Translate kamu',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
          const SizedBox(height: 28),
          _InputField(
            controller: emailCtrl,
            label: 'Email',
            icon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 16),
          _InputField(
            controller: passCtrl,
            label: 'Password',
            icon: Icons.lock_outline,
            obscure: !passVisible,
            suffixIcon: IconButton(
              icon: Icon(passVisible ? Icons.visibility_off : Icons.visibility,
                  color: AppColors.textSecondary, size: 20),
              onPressed: onTogglePass,
            ),
            onSubmitted: (_) => onSubmit(),
          ),
          const SizedBox(height: 32),
          SizedBox(
            height: 52,
            child: ElevatedButton(
              onPressed: loading ? null : onSubmit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              child: loading
                  ? const SizedBox(
                      width: 22, height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Masuk', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(child: Divider(color: AppColors.divider)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text('atau', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
              ),
              Expanded(child: Divider(color: AppColors.divider)),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 52,
            child: OutlinedButton.icon(
              onPressed: loading ? null : onGoogleSignIn,
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: AppColors.divider, width: 1.5),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                backgroundColor: AppColors.surface,
              ),
              icon: _GoogleLogo(),
              label: Text(
                'Masuk dengan Google',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _GoogleLogo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(4),
      ),
      child: const Center(
        child: Text(
          'G',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF4285F4),
          ),
        ),
      ),
    );
  }
}

class _RegisterForm extends StatelessWidget {
  final TextEditingController nameCtrl;
  final TextEditingController emailCtrl;
  final TextEditingController passCtrl;
  final bool passVisible;
  final VoidCallback onTogglePass;
  final ValueNotifier<String> lang;
  final bool loading;
  final VoidCallback onSubmit;

  const _RegisterForm({
    required this.nameCtrl,
    required this.emailCtrl,
    required this.passCtrl,
    required this.passVisible,
    required this.onTogglePass,
    required this.lang,
    required this.loading,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 8),
          Text('Buat akun baru',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
          const SizedBox(height: 4),
          Text('Mulai berkomunikasi tanpa batas bahasa',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
          const SizedBox(height: 28),
          _InputField(
            controller: nameCtrl,
            label: 'Nama Tampilan',
            icon: Icons.person_outline,
          ),
          const SizedBox(height: 16),
          _InputField(
            controller: emailCtrl,
            label: 'Email',
            icon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 16),
          _InputField(
            controller: passCtrl,
            label: 'Password (min. 6 karakter)',
            icon: Icons.lock_outline,
            obscure: !passVisible,
            suffixIcon: IconButton(
              icon: Icon(passVisible ? Icons.visibility_off : Icons.visibility,
                  color: AppColors.textSecondary, size: 20),
              onPressed: onTogglePass,
            ),
          ),
          const SizedBox(height: 16),
          // Language preference
          Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.divider),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                const Icon(Icons.language, color: AppColors.primary, size: 20),
                const SizedBox(width: 12),
                Text('Bahasa saya', style: TextStyle(fontSize: 14, color: AppColors.textSecondary)),
                const Spacer(),
                ValueListenableBuilder<String>(
                  valueListenable: lang,
                  builder: (_, value, child) => DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: value,
                      items: const [
                        DropdownMenuItem(value: 'id', child: Text('🇮🇩 Indonesia')),
                        DropdownMenuItem(value: 'en', child: Text('🇺🇸 English')),
                      ],
                      onChanged: (v) => lang.value = v ?? 'id',
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          SizedBox(
            height: 52,
            child: ElevatedButton(
              onPressed: loading ? null : onSubmit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              child: loading
                  ? const SizedBox(
                      width: 22, height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Buat Akun', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

class _InputField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final TextInputType keyboardType;
  final bool obscure;
  final Widget? suffixIcon;
  final void Function(String)? onSubmitted;

  const _InputField({
    required this.controller,
    required this.label,
    required this.icon,
    this.keyboardType = TextInputType.text,
    this.obscure = false,
    this.suffixIcon,
    this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        obscureText: obscure,
        onSubmitted: onSubmitted,
        style: TextStyle(fontSize: 14, color: AppColors.textPrimary),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(fontSize: 13, color: AppColors.textSecondary),
          prefixIcon: Icon(icon, color: AppColors.primary, size: 20),
          suffixIcon: suffixIcon,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }
}
