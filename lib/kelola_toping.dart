import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class KelolaTopping extends StatefulWidget {
  const KelolaTopping({super.key});

  @override
  State<KelolaTopping> createState() => _KelolaToppingState();
}

class _KelolaToppingState extends State<KelolaTopping> {
  final SupabaseClient supabase = Supabase.instance.client;

  static const Color brown = Color(0xFF995631);
  static const Color darkBrown = Color(0xFF5E3007);
  static const Color cream = Color(0xFFFFD5A4);
  static const Color background = Color(0xFFFFF8F0);

  final List<String> daftarTopping = [
    'LATTE ART',
    'COKELAT BUBUK',
    'WHIPPED CREAM',
    'COFFEE JELLY',
    'BOBA',
    'CINNAMON POWDER',
  ];

  List<Map<String, dynamic>> daftarMenu = [];
  List<String> toppingAktif = [];

  int? menuTerpilih;
  bool loading = true;
  bool saving = false;

  @override
  void initState() {
    super.initState();
    ambilMenu();
  }

  // Mengambil data menu dari Supabase
  Future<void> ambilMenu() async {
    try {
      final data = await supabase
          .from('menu')
          .select('id, name, toppings')
          .order('name');

      if (!mounted) return;

      final hasil = List<Map<String, dynamic>>.from(data);

      setState(() {
        daftarMenu = hasil;

        if (daftarMenu.isNotEmpty) {
          menuTerpilih = daftarMenu.first['id'] as int;

          final dataTopping = daftarMenu.first['toppings'];

          toppingAktif = dataTopping == null
              ? []
              : List<String>.from(dataTopping);
        }

        loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        loading = false;
      });

      tampilkanPesan('Gagal mengambil data: $e');
    }
  }

  // Memilih menu
  void pilihMenu(int? id) {
    if (id == null) return;

    final menu = daftarMenu.firstWhere((item) => item['id'] == id);

    final dataTopping = menu['toppings'];

    setState(() {
      menuTerpilih = id;

      toppingAktif = dataTopping == null ? [] : List<String>.from(dataTopping);
    });
  }

  // Mengubah status topping
  void ubahStatusTopping(String nama, bool aktif) {
    setState(() {
      if (aktif) {
        if (!toppingAktif.contains(nama)) {
          toppingAktif.add(nama);
        }
      } else {
        toppingAktif.remove(nama);
      }
    });
  }

  // Menyimpan perubahan ke Supabase
  Future<void> simpanPerubahan() async {
    if (menuTerpilih == null) {
      tampilkanPesan('Silakan pilih menu terlebih dahulu.');
      return;
    }

    setState(() {
      saving = true;
    });

    try {
      await supabase
          .from('menu')
          .update({'toppings': toppingAktif})
          .eq('id', menuTerpilih!);

      if (!mounted) return;

      setState(() {
        saving = false;

        final index = daftarMenu.indexWhere(
          (item) => item['id'] == menuTerpilih,
        );

        if (index != -1) {
          daftarMenu[index]['toppings'] = List<String>.from(toppingAktif);
        }
      });

      tampilkanPesan('Perubahan berhasil disimpan!');
    } catch (e) {
      if (!mounted) return;

      setState(() {
        saving = false;
      });

      tampilkanPesan('Gagal menyimpan perubahan: $e');
    }
  }

  // Menampilkan pesan
  void tampilkanPesan(String pesan) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(pesan),
        backgroundColor: darkBrown,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // Header halaman
  Widget header() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      color: brown,
      child: Row(
        children: [
          const Icon(Icons.coffee, color: Colors.white, size: 28),
          const SizedBox(width: 12),
          const Text(
            'Seduh Senja',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          IconButton(
            onPressed: () {
              Navigator.pop(context);
            },
            icon: const Icon(Icons.arrow_back, color: Colors.white),
          ),
        ],
      ),
    );
  }

  // Kartu menu yang dipilih
  Widget kartuMenu() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cream,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Pilih Menu',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: darkBrown,
            ),
          ),

          const SizedBox(height: 10),

          DropdownButtonFormField<int>(
            value: menuTerpilih,
            isExpanded: true,
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 12,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
            ),
            items: daftarMenu.map((item) {
              return DropdownMenuItem<int>(
                value: item['id'] as int,
                child: Text(item['name'].toString()),
              );
            }).toList(),
            onChanged: pilihMenu,
          ),

          const SizedBox(height: 15),

          const Text(
            'Atur topping untuk menu yang dipilih.',
            style: TextStyle(fontSize: 13, color: darkBrown),
          ),

          const SizedBox(height: 5),

          Text(
            '${toppingAktif.length} dari ${daftarTopping.length} topping aktif',
            style: const TextStyle(
              fontSize: 13,
              color: darkBrown,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // Item topping
  Widget itemTopping(String nama) {
    final bool aktif = toppingAktif.contains(nama);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: aktif ? brown : Colors.grey.shade300,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: cream,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.coffee, color: darkBrown, size: 23),
          ),

          const SizedBox(width: 14),

          Expanded(
            child: Text(
              nama,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: darkBrown,
              ),
            ),
          ),

          Switch(
            value: aktif,
            activeThumbColor: brown,
            onChanged: (value) {
              ubahStatusTopping(nama, value);
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      body: SafeArea(
        child: Column(
          children: [
            header(),

            Expanded(
              child: loading
                  ? const Center(child: CircularProgressIndicator())
                  : daftarMenu.isEmpty
                  ? const Center(child: Text('Belum ada data menu.'))
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Kelola Topping',
                            style: TextStyle(
                              fontSize: 25,
                              fontWeight: FontWeight.bold,
                              color: darkBrown,
                            ),
                          ),

                          const SizedBox(height: 8),

                          Text(
                            'Atur topping yang tersedia untuk setiap menu.',
                            style: TextStyle(
                              color: Colors.brown.shade400,
                              fontSize: 13,
                            ),
                          ),

                          const SizedBox(height: 22),

                          kartuMenu(),

                          const SizedBox(height: 25),

                          const Text(
                            'Daftar Topping',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: darkBrown,
                            ),
                          ),

                          const SizedBox(height: 15),

                          ...daftarTopping.map((nama) => itemTopping(nama)),

                          const SizedBox(height: 20),

                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              onPressed: saving ? null : simpanPerubahan,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: brown,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: saving
                                  ? const SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Text(
                                      'Simpan Perubahan',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                      ),
                                    ),
                            ),
                          ),

                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
