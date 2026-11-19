import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../login.dart';

/// Header tunggal untuk semua halaman setelah login.
///
/// - Kiri  : tombol kembali (otomatis, hanya jika halaman bisa kembali)
///           + judul "Seduh Senja"
/// - Kanan : avatar akun. Jika ditekan, muncul menu dengan tombol "Keluar".
///
/// Pakai di Scaffold:  appBar: const SeduhAppBar(),
/// Jika halaman sudah punya tombol kembali sendiri: SeduhAppBar(showBack: false)
class SeduhAppBar extends StatelessWidget implements PreferredSizeWidget {
  const SeduhAppBar({super.key, this.showBack = true});

  final bool showBack;

  static const Color _bg = Color(0xFF995631);
  static const Color _dark = Color(0xFF5E3007);
  static const Color _cream = Color(0xFFFFD6A5);
  static const Color _red = Color(0xFF960909);
  static const Color _gold = Color(0xFFDBB345);

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  // Konfirmasi lalu keluar dari akun
  Future<void> _logout(BuildContext context) async {
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: _cream,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Keluar dari akun?',
            style: TextStyle(
              color: _dark,
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w700,
              fontSize: 18,
            ),
          ),
          content: const Text(
            'Kamu perlu login lagi untuk masuk kembali.',
            style: TextStyle(
              color: _dark,
              fontFamily: 'Poppins',
              fontSize: 14,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text(
                'Batal',
                style: TextStyle(color: _dark, fontFamily: 'Poppins'),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _red,
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Keluar'),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    try {
      await Supabase.instance.client.auth.signOut();
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Gagal keluar: $e'), backgroundColor: _dark),
      );
      return;
    }

    // Hapus semua halaman sebelumnya supaya tombol kembali tidak
    // membawa pengguna ke halaman yang butuh login.
    navigator.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginpageWidget()),
      (route) => false,
    );
  }

  Widget _accountButton(BuildContext context) {
    final email = Supabase.instance.client.auth.currentUser?.email;

    return PopupMenuButton<String>(
      tooltip: 'Akun',
      offset: const Offset(0, 48),
      color: _cream,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      onSelected: (value) {
        if (value == 'logout') _logout(context);
      },
      itemBuilder: (_) => [
        if (email != null && email.isNotEmpty) ...[
          PopupMenuItem<String>(
            enabled: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Masuk sebagai',
                  style: TextStyle(
                    color: _bg,
                    fontFamily: 'Poppins',
                    fontSize: 11,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                Text(
                  email,
                  style: const TextStyle(
                    color: _dark,
                    fontFamily: 'Poppins',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const PopupMenuDivider(),
        ],
        const PopupMenuItem<String>(
          value: 'logout',
          child: Row(
            children: [
              Icon(Icons.logout, color: _red, size: 20),
              SizedBox(width: 10),
              Text(
                'Keluar',
                style: TextStyle(
                  color: _red,
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
      child: Container(
        width: 40,
        height: 40,
        decoration: const BoxDecoration(
          color: _dark,
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.person_outline, color: _gold, size: 22),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: _bg,
      foregroundColor: _cream,
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      centerTitle: false,
      titleSpacing: 20,
      automaticallyImplyLeading: showBack,
      title: const Text(
        'Seduh Senja',
        style: TextStyle(
          color: _cream,
          fontSize: 24,
          fontWeight: FontWeight.w700,
          fontFamily: 'Poppins',
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 20),
          child: Center(child: _accountButton(context)),
        ),
      ],
    );
  }
}
