import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'order_entry_page.dart';
import 'userdashboard.dart';

import 'signup.dart';

class LoginpageWidget extends StatefulWidget {
  const LoginpageWidget({super.key});

  @override
  State<LoginpageWidget> createState() => _LoginpageWidgetState();
}

class _LoginpageWidgetState extends State<LoginpageWidget> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _loading = false;

  static const backgroundColor = Color(0xFF995631);
  static const cardColor = Color(0xFF5E3007);
  static const accentColor = Color(0xFFFFD5A4);
  static const buttonTextColor = Color(0xFF660710);

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _message(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: cardColor),
    );
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    try {
      final supabase = Supabase.instance.client;

      // Login menggunakan Supabase Auth.
      final authResponse = await supabase.auth.signInWithPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      final user = authResponse.user;
      if (user == null) {
        throw Exception('Data akun tidak ditemukan setelah login.');
      }

      // Ambil role dari tabel account berdasarkan UUID user yang login.
      // Pastikan account.id berisi UUID yang sama dengan auth.users.id.
      final accountData = await supabase
          .from('account')
          .select('role')
          .eq('id', user.id)
          .maybeSingle();

      if (accountData == null) {
        await supabase.auth.signOut();
        if (mounted) {
          _message(
            'Data akun tidak ditemukan. Pastikan ID pada tabel account '
            'sama dengan ID pengguna Supabase Auth.',
          );
        }
        return;
      }

      final role = (accountData['role'] ?? '').toString().trim().toLowerCase();

      if (!mounted) return;

      // Arahkan halaman sesuai role yang tersimpan di tabel account.
      if (role == 'barista') {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const OrderEntryPage()),
        );
      } else if (role == 'user') {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const DashboardUser()),
        );
      } else {
        _message('Role akun "$role" belum memiliki halaman tujuan.');
        await supabase.auth.signOut();
      }
    } on AuthException catch (e) {
      if (mounted) _message(e.message);
    } catch (e) {
      if (mounted) _message('Terjadi kesalahan saat login.');
      debugPrint('Login error: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _forgotPassword() async {
    final email = _emailController.text.trim();

    if (email.isEmpty ||
        !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
      _message('Masukkan email yang valid terlebih dahulu.');
      return;
    }

    try {
      await Supabase.instance.client.auth.resetPasswordForEmail(email);

      if (mounted) {
        _message('Link reset password dikirim jika email terdaftar.');
      }
    } on AuthException catch (e) {
      if (mounted) _message(e.message);
    } catch (e) {
      if (mounted) _message('Gagal mengirim link reset password.');
    }
  }

  Future<void> _guestLogin() async {
    final nameController = TextEditingController();

    final name = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: accentColor,
        title: const Text(
          'Masuk sebagai Guest',
          style: TextStyle(color: cardColor),
        ),
        content: TextField(
          controller: nameController,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Nama pelanggan',
            hintText: 'Masukkan nama kamu',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Kembali'),
          ),
          ElevatedButton(
            onPressed: () {
              final name = nameController.text.trim();
              if (name.isNotEmpty) {
                Navigator.pop(dialogContext, name);
              }
            },
            child: const Text('Lanjut'),
          ),
        ],
      ),
    );

    nameController.dispose();

    if (!mounted || name == null) return;

    // Guest mode does not create a Supabase Auth account.
    // Pass this name to the customer/menu screen when it exists.
    _message('Selamat datang, $name!');
  }

  void _register() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SignuppageWidget()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final short = constraints.maxHeight < 650;

            return SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: 20,
                vertical: short ? 12 : 24,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - (short ? 24 : 48),
                ),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SvgPicture.asset(
                        'assets/images/logo.svg',
                        width: 126,
                        height: 104,
                        fit: BoxFit.contain,
                      ),
                      SizedBox(height: short ? 20 : 32),
                      Container(
                        width: double.infinity,
                        constraints: const BoxConstraints(maxWidth: 350),
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: cardColor,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Login',
                                style: TextStyle(
                                  color: accentColor,
                                  fontFamily: 'Poppins',
                                  fontSize: 36,
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Selamat datang kembali!',
                                style: TextStyle(
                                  color: backgroundColor,
                                  fontFamily: 'Poppins',
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 24),
                              _input(
                                controller: _emailController,
                                hint: 'Email',
                                icon: Icons.email_outlined,
                                validator: (value) {
                                  if (value == null ||
                                      !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$')
                                          .hasMatch(value.trim())) {
                                    return 'Masukkan email yang valid';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 12),
                              _input(
                                controller: _passwordController,
                                hint: 'Password',
                                icon: Icons.lock_outline,
                                obscure: _obscurePassword,
                                suffix: IconButton(
                                  onPressed: () => setState(
                                    () => _obscurePassword = !_obscurePassword,
                                  ),
                                  icon: Icon(
                                    _obscurePassword
                                        ? Icons.visibility_outlined
                                        : Icons.visibility_off_outlined,
                                    color: backgroundColor,
                                  ),
                                ),
                                validator: (value) =>
                                    value == null || value.isEmpty
                                    ? 'Password wajib diisi'
                                    : null,
                              ),
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton(
                                  onPressed: _loading ? null : _forgotPassword,
                                  child: const Text(
                                    'Lupa password?',
                                    style: TextStyle(
                                      color: accentColor,
                                      fontSize: 11,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              _button(
                                label: 'Masuk',
                                onPressed: _login,
                                loading: _loading,
                              ),
                              const SizedBox(height: 10),
                              _button(
                                label: 'Saya Guest',
                                onPressed: _guestLogin,
                                outlined: true,
                              ),
                              const SizedBox(height: 12),
                              Center(
                                child: Wrap(
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  children: [
                                    const Text(
                                      'Belum punya akun?',
                                      style: TextStyle(
                                        color: accentColor,
                                        fontSize: 11,
                                      ),
                                    ),
                                    TextButton(
                                      onPressed: _loading ? null : _register,
                                      child: const Text(
                                        'Daftar',
                                        style: TextStyle(
                                          color: accentColor,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _input({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    required String? Function(String?) validator,
    bool obscure = false,
    Widget? suffix,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      validator: validator,
      style: const TextStyle(color: buttonTextColor, fontFamily: 'Poppins'),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(
          color: backgroundColor,
          fontFamily: 'Poppins',
        ),
        prefixIcon: Icon(icon, color: backgroundColor, size: 20),
        suffixIcon: suffix,
        filled: true,
        fillColor: accentColor,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide.none,
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.red),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.red, width: 1.5),
        ),
      ),
    );
  }

  Widget _button({
    required String label,
    required VoidCallback onPressed,
    bool outlined = false,
    bool loading = false,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 44,
      child: ElevatedButton(
        onPressed: loading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: outlined ? Colors.transparent : accentColor,
          foregroundColor: outlined ? accentColor : buttonTextColor,
          elevation: 0,
          side: outlined
              ? const BorderSide(color: accentColor)
              : BorderSide.none,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
        ),
        child: loading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Text(label, style: const TextStyle(fontFamily: 'Poppins')),
      ),
    );
  }
}
