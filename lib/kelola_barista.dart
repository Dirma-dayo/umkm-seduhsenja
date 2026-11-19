import 'package:flutter/material.dart';
import 'widgets/seduh_app_bar.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const Color brown = Color(0xFF995631);
const Color darkBrown = Color(0xFF5E3007);
const Color cream = Color(0xFFFFD5A4);
const Color red = Color(0xFF960909);

class ListBarista extends StatefulWidget {
  const ListBarista({super.key});

  @override
  State<ListBarista> createState() => _ListBaristaState();
}

class _ListBaristaState extends State<ListBarista> {
  final supabase = Supabase.instance.client;

  List<Map<String, dynamic>> daftarBarista = [];
  bool loading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    ambilBarista();
  }

  // Mengambil pengguna yang memiliki role barista
  Future<void> ambilBarista() async {
    if (!mounted) return;

    setState(() {
      loading = true;
      error = null;
    });

    try {
      final data = await supabase
          .from('account')
          .select('id, username, full_name, role, email')
          .eq('role', 'barista')
          .order('full_name');

      if (!mounted) return;

      setState(() {
        daftarBarista = List<Map<String, dynamic>>.from(data);
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        error = e.toString();
        loading = false;
      });
    }
  }

  // Membuka form tambah barista
  Future<void> bukaFormTambah() async {
    final hasil = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const TambahBarista()),
    );

    if (hasil == true) {
      ambilBarista();
    }
  }

  // Membuka form edit barista (terisi otomatis)
  Future<void> bukaFormEdit(Map<String, dynamic> barista) async {
    final hasil = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => TambahBarista(barista: barista)),
    );

    if (hasil == true) {
      ambilBarista();
    }
  }

  // Hapus akun barista (konfirmasi dulu), lewat Edge Function "delete-barista"
  Future<void> hapusBarista(Map<String, dynamic> barista) async {
    final nama = barista['full_name']?.toString() ?? 'barista ini';

    final yakin = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: cream,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Hapus Barista',
          style: TextStyle(
            color: darkBrown,
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Text(
          'Yakin ingin menghapus akun $nama? Tindakan ini tidak bisa dibatalkan.',
          style: const TextStyle(color: darkBrown, fontFamily: 'Poppins'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              'Batal',
              style: TextStyle(color: brown, fontFamily: 'Poppins'),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Hapus',
              style: TextStyle(
                color: red,
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );

    if (yakin != true) return;

    try {
      await supabase.functions.invoke(
        'delete-barista',
        body: {'id': barista['id']},
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Barista berhasil dihapus.')),
      );
      ambilBarista();
    } on FunctionException catch (e) {
      if (!mounted) return;
      final details = e.details;
      final pesan = details is Map && details['error'] != null
          ? details['error'].toString()
          : 'Gagal menghapus barista (${e.status}).';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(pesan)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menghapus data: $e')),
      );
    }
  }

  Widget kartuBarista(Map<String, dynamic> barista) {
    final nama = barista['full_name']?.toString() ?? 'Tanpa nama';
    final username = barista['username']?.toString() ?? '-';
    final email = barista['email']?.toString();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cream,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 45,
            height: 45,
            decoration: const BoxDecoration(
              color: darkBrown,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.person, color: cream, size: 27),
          ),
          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  nama,
                  style: const TextStyle(
                    color: darkBrown,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Poppins',
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '@$username',
                  style: const TextStyle(
                    color: brown,
                    fontSize: 12,
                    fontFamily: 'Poppins',
                  ),
                ),
                if (email != null && email.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    email,
                    style: const TextStyle(
                      color: darkBrown,
                      fontSize: 11,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ],
                const SizedBox(height: 3),
                const Text(
                  'Barista',
                  style: TextStyle(
                    color: darkBrown,
                    fontSize: 11,
                    fontFamily: 'Poppins',
                  ),
                ),
              ],
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              InkWell(
                onTap: () => bukaFormEdit(barista),
                borderRadius: BorderRadius.circular(5),
                child: Container(
                  width: 35,
                  height: 28,
                  decoration: BoxDecoration(
                    color: cream,
                    borderRadius: BorderRadius.circular(5),
                    border: Border.all(color: brown),
                  ),
                  child: const Icon(
                    Icons.edit_outlined,
                    color: brown,
                    size: 20,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              InkWell(
                onTap: () => hapusBarista(barista),
                borderRadius: BorderRadius.circular(5),
                child: Container(
                  width: 36,
                  height: 29,
                  decoration: BoxDecoration(
                    color: red,
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: const Icon(
                    Icons.delete_outline,
                    color: cream,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: brown,
      appBar: const SeduhAppBar(),
      body: SafeArea(
        child: RefreshIndicator(
          color: brown,
          onRefresh: ambilBarista,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              const Text(
                'List Barista',
                style: TextStyle(
                  color: cream,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Poppins',
                ),
              ),
              const SizedBox(height: 5),
              const Text(
                'Daftar pengguna dengan role barista',
                style: TextStyle(
                  color: cream,
                  fontSize: 13,
                  fontFamily: 'Poppins',
                ),
              ),
              const SizedBox(height: 18),

              SizedBox(
                height: 45,
                child: ElevatedButton.icon(
                  onPressed: bukaFormTambah,
                  icon: const Icon(Icons.add),
                  label: const Text('Tambah Barista Baru'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: cream,
                    foregroundColor: darkBrown,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    textStyle: const TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              if (loading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(30),
                    child: CircularProgressIndicator(color: cream),
                  ),
                )
              else if (error != null)
                Text(
                  'Gagal mengambil data: $error',
                  style: const TextStyle(color: cream),
                )
              else if (daftarBarista.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(25),
                  child: Center(
                    child: Text(
                      'Belum ada barista.',
                      style: TextStyle(color: cream, fontFamily: 'Poppins'),
                    ),
                  ),
                )
              else ...[
                Text(
                  'Jumlah Barista: ${daftarBarista.length}',
                  style: const TextStyle(
                    color: cream,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Poppins',
                  ),
                ),
                const SizedBox(height: 12),

                ...daftarBarista.map(kartuBarista),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// HALAMAN TAMBAH / EDIT BARISTA
class TambahBarista extends StatefulWidget {
  final Map<String, dynamic>? barista; // null = tambah, isi = edit

  const TambahBarista({super.key, this.barista});

  @override
  State<TambahBarista> createState() => _TambahBaristaState();
}

class _TambahBaristaState extends State<TambahBarista> {
  final supabase = Supabase.instance.client;

  late final TextEditingController namaController;
  late final TextEditingController usernameController;
  late final TextEditingController emailController;
  final passwordController = TextEditingController();
  final konfirmasiController = TextEditingController();

  bool loading = false;
  bool tampilPassword = false;

  bool get modeEdit => widget.barista != null;

  @override
  void initState() {
    super.initState();
    final b = widget.barista;
    namaController = TextEditingController(
      text: b?['full_name']?.toString() ?? '',
    );
    usernameController = TextEditingController(
      text: b?['username']?.toString() ?? '',
    );
    emailController = TextEditingController(
      text: b?['email']?.toString() ?? '',
    );
  }

  @override
  void dispose() {
    namaController.dispose();
    usernameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    konfirmasiController.dispose();
    super.dispose();
  }

  // Tambah: buat akun lewat Edge Function "create-barista"
  // Edit: update full_name & username di tabel account
  Future<void> simpanBarista() async {
    final nama = namaController.text.trim();
    final username = usernameController.text.trim();
    final email = emailController.text.trim().toLowerCase();
    final password = passwordController.text;
    final konfirmasi = konfirmasiController.text;

    if (nama.isEmpty || username.isEmpty) {
      tampilPesan('Nama dan username harus diisi.');
      return;
    }

    if (username.contains('@') || username.contains(' ')) {
      tampilPesan('Username tidak boleh mengandung @ atau spasi.');
      return;
    }

    if (!modeEdit) {
      if (email.isEmpty || password.isEmpty || konfirmasi.isEmpty) {
        tampilPesan('Semua kolom harus diisi.');
        return;
      }

      if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
        tampilPesan('Format email tidak valid.');
        return;
      }

      if (password.length < 6) {
        tampilPesan('Password minimal 6 karakter.');
        return;
      }

      if (password != konfirmasi) {
        tampilPesan('Konfirmasi password tidak sama.');
        return;
      }
    }

    setState(() {
      loading = true;
    });

    try {
      if (modeEdit) {
        await supabase
            .from('account')
            .update({'full_name': nama, 'username': username})
            .eq('id', widget.barista!['id']);

        if (!mounted) return;
        tampilPesan('Data barista berhasil diperbarui.');
      } else {
        await supabase.functions.invoke(
          'create-barista',
          body: {
            'full_name': nama,
            'username': username,
            'email': email,
            'password': password,
          },
        );

        if (!mounted) return;
        tampilPesan(
          'Barista berhasil ditambahkan. Bisa login dengan '
          'email atau username.',
        );
      }

      Navigator.pop(context, true);
    } on FunctionException catch (e) {
      if (!mounted) return;

      final details = e.details;
      final pesan = details is Map && details['error'] != null
          ? details['error'].toString()
          : 'Gagal menambahkan barista (${e.status}).';

      tampilPesan(pesan);
    } on PostgrestException catch (e) {
      if (!mounted) return;
      tampilPesan(
        e.code == '23505'
            ? 'Username sudah dipakai.'
            : 'Gagal memperbarui data: ${e.message}',
      );
    } catch (e) {
      if (!mounted) return;
      tampilPesan('Gagal menyimpan data: $e');
    } finally {
      if (mounted) {
        setState(() {
          loading = false;
        });
      }
    }
  }

  void tampilPesan(String pesan) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(pesan)));
  }

  Widget inputField(
    String label,
    TextEditingController controller, {
    bool password = false,
    bool enabled = true,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextField(
        controller: controller,
        enabled: enabled,
        obscureText: password && !tampilPassword,
        keyboardType: keyboardType,
        autocorrect: false,
        style: TextStyle(
          color: enabled ? darkBrown : brown,
          fontFamily: 'Poppins',
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: brown, fontFamily: 'Poppins'),
          suffixIcon: password
              ? IconButton(
                  onPressed: () {
                    setState(() {
                      tampilPassword = !tampilPassword;
                    });
                  },
                  icon: Icon(
                    tampilPassword ? Icons.visibility_off : Icons.visibility,
                    color: brown,
                  ),
                )
              : null,
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: brown),
          ),
          disabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: brown.withOpacity(0.5)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: darkBrown, width: 2),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: brown,
      appBar: const SeduhAppBar(),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              modeEdit ? 'Edit Barista' : 'Tambah Barista',
              style: const TextStyle(
                color: cream,
                fontSize: 20,
                fontWeight: FontWeight.w700,
                fontFamily: 'Poppins',
              ),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: cream,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Container(
                    width: 110,
                    height: 110,
                    decoration: const BoxDecoration(
                      color: darkBrown,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      modeEdit ? Icons.person : Icons.person_add_alt_1,
                      color: cream,
                      size: 55,
                    ),
                  ),
                  const SizedBox(height: 25),

                  inputField('Nama Lengkap', namaController),
                  inputField('Username', usernameController),
                  inputField(
                    'Email',
                    emailController,
                    enabled: !modeEdit, // email = akun login, tidak diubah di sini
                    keyboardType: TextInputType.emailAddress,
                  ),
                  if (!modeEdit) ...[
                    inputField('Password', passwordController, password: true),
                    inputField(
                      'Konfirmasi Password',
                      konfirmasiController,
                      password: true,
                    ),
                  ],

                  const SizedBox(height: 10),

                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: loading ? null : simpanBarista,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: brown,
                        foregroundColor: cream,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: loading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: cream,
                              ),
                            )
                          : Text(
                              modeEdit ? 'Simpan Perubahan' : 'Konfirmasi',
                              style: const TextStyle(
                                fontFamily: 'Poppins',
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
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