import 'package:flutter/material.dart';
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
    setState(() {
      loading = true;
      error = null;
    });

    try {
      final data = await supabase
          .from('account')
          .select('id, username, full_name, role')
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

  Widget kartuBarista(Map<String, dynamic> barista) {
    final nama = barista['full_name']?.toString() ?? 'Tanpa nama';
    final username = barista['username']?.toString() ?? '-';

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
          const Icon(Icons.coffee, color: darkBrown, size: 23),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: brown,
      appBar: AppBar(
        backgroundColor: brown,
        foregroundColor: cream,
        elevation: 0,
        title: const Text(
          'Seduh Senja',
          style: TextStyle(
            color: cream,
            fontSize: 24,
            fontWeight: FontWeight.w700,
            fontFamily: 'Poppins',
          ),
        ),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          color: brown,
          onRefresh: ambilBarista,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              const Text(
                'Pantau Barista',
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

// HALAMAN TAMBAH BARISTA
class TambahBarista extends StatefulWidget {
  const TambahBarista({super.key});

  @override
  State<TambahBarista> createState() => _TambahBaristaState();
}

class _TambahBaristaState extends State<TambahBarista> {
  final supabase = Supabase.instance.client;

  final namaController = TextEditingController();
  final usernameController = TextEditingController();
  final passwordController = TextEditingController();
  final konfirmasiController = TextEditingController();

  bool loading = false;
  bool tampilPassword = false;

  @override
  void dispose() {
    namaController.dispose();
    usernameController.dispose();
    passwordController.dispose();
    konfirmasiController.dispose();
    super.dispose();
  }

  // Menyimpan data profil barista ke tabel account
  Future<void> simpanBarista() async {
    final nama = namaController.text.trim();
    final username = usernameController.text.trim();
    final password = passwordController.text;
    final konfirmasi = konfirmasiController.text;

    if (nama.isEmpty ||
        username.isEmpty ||
        password.isEmpty ||
        konfirmasi.isEmpty) {
      tampilPesan('Semua kolom harus diisi.');
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

    // Password tidak disimpan ke tabel account.
    // Pembuatan akun login harus dilakukan melalui Supabase Auth
    // menggunakan proses backend yang aman.

    setState(() {
      loading = true;
    });

    try {
      await supabase.from('account').insert({
        'username': username,
        'full_name': nama,
        'role': 'barista',
      });

      if (!mounted) return;

      tampilPesan(
        'Data profil barista berhasil ditambahkan. '
        'Akun login Supabase Auth belum dibuat.',
      );

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      tampilPesan('Gagal menambahkan data: $e');
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
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextField(
        controller: controller,
        obscureText: password && !tampilPassword,
        style: const TextStyle(color: darkBrown, fontFamily: 'Poppins'),
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
      appBar: AppBar(
        backgroundColor: brown,
        foregroundColor: cream,
        elevation: 0,
        title: const Text(
          'Tambah Barista',
          style: TextStyle(
            color: cream,
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
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
                    child: const Icon(
                      Icons.person_add_alt_1,
                      color: cream,
                      size: 55,
                    ),
                  ),
                  const SizedBox(height: 25),

                  inputField('Nama Lengkap', namaController),
                  inputField('Username', usernameController),
                  inputField('Password', passwordController, password: true),
                  inputField(
                    'Konfirmasi Password',
                    konfirmasiController,
                    password: true,
                  ),

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
                          ? const CircularProgressIndicator(color: cream)
                          : const Text(
                              'Konfirmasi',
                              style: TextStyle(
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
