
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SignuppageWidget extends StatefulWidget {
  const SignuppageWidget({super.key});

  @override
  State<SignuppageWidget> createState() => _SignuppageWidgetState();
}

class _SignuppageWidgetState extends State<SignuppageWidget> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _loading = false;

  static const backgroundColor = Color(0xFF995631);
  static const cardColor = Color(0xFF5E3007);
  static const accentColor = Color(0xFFFFD5A4);
  static const buttonTextColor = Color(0xFF660710);

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  void _message(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: cardColor,
      ),
    );
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    try {
      final response = await Supabase.instance.client.auth.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        data: {
          'username': _usernameController.text.trim(),
          'full_name': _nameController.text.trim(),
        },
      );

      if (!mounted) return;

      if (response.session == null) {
        _message(
          'Akun dibuat. Periksa email untuk mengonfirmasi pendaftaran.',
        );
      } else {
        _message('Pendaftaran berhasil!');
      }

      // Return to the login screen.
      Navigator.pop(context);
    } on AuthException catch (e) {
      if (mounted) _message(e.message);
    } catch (e) {
      if (mounted) _message('Pendaftaran gagal. Coba lagi.');
      debugPrint('Registration error: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        foregroundColor: accentColor,
        elevation: 0,
        title: const Text(
          'Daftar',
          style: TextStyle(fontFamily: 'Poppins'),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 350),
              child: Column(
                children: [
                  SvgPicture.asset(
                    'assets/images/logo.svg',
                    width: 112,
                    height: 92,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(height: 20),
                  Container(
                    width: double.infinity,
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
                            'Sign up',
                            style: TextStyle(
                              color: accentColor,
                              fontFamily: 'Poppins',
                              fontSize: 36,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Selamat datang!',
                            style: TextStyle(
                              color: backgroundColor,
                              fontFamily: 'Poppins',
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 24),
                          _input(
                            controller: _nameController,
                            hint: 'Nama lengkap',
                            icon: Icons.person_outline,
                            validator: (v) =>
                                v == null || v.trim().isEmpty
                                    ? 'Nama wajib diisi'
                                    : null,
                          ),
                          const SizedBox(height: 12),
                          _input(
                            controller: _usernameController,
                            hint: 'Username',
                            icon: Icons.alternate_email,
                            validator: (v) {
                              if (v == null ||
                                  !RegExp(r'^[a-zA-Z0-9_]{3,20}$')
                                      .hasMatch(v.trim())) {
                                return '3-20 karakter: huruf, angka, atau _';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),
                          _input(
                            controller: _emailController,
                            hint: 'Email',
                            icon: Icons.email_outlined,
                            validator: (v) {
                              if (v == null ||
                                  !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$')
                                      .hasMatch(v.trim())) {
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
                            validator: (v) {
                              if (v == null || v.length < 8) {
                                return 'Password minimal 8 karakter';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),
                          _input(
                            controller: _confirmController,
                            hint: 'Masukkan kembali password',
                            icon: Icons.lock_reset_outlined,
                            obscure: _obscureConfirm,
                            suffix: IconButton(
                              onPressed: () => setState(
                                () => _obscureConfirm = !_obscureConfirm,
                              ),
                              icon: Icon(
                                _obscureConfirm
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                                color: backgroundColor,
                              ),
                            ),
                            validator: (v) {
                              if (v != _passwordController.text) {
                                return 'Password tidak cocok';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
                            height: 44,
                            child: ElevatedButton(
                              onPressed: _loading ? null : _register,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: accentColor,
                                foregroundColor: buttonTextColor,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                              ),
                              child: _loading
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Text(
                                      'Daftar',
                                      style: TextStyle(
                                        fontFamily: 'Poppins',
                                        fontSize: 14,
                                      ),
                                    ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Center(
                            child: TextButton(
                              onPressed: _loading
                                  ? null
                                  : () => Navigator.pop(context),
                              child: const Text(
                                'Sudah punya akun? Login',
                                style: TextStyle(
                                  color: accentColor,
                                  fontFamily: 'Poppins',
                                ),
                              ),
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
      style: const TextStyle(
        color: buttonTextColor,
        fontFamily: 'Poppins',
        fontSize: 14,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(
          color: backgroundColor,
          fontFamily: 'Poppins',
          fontSize: 14,
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
}
