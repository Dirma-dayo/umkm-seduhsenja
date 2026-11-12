import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class OlahMenu extends StatefulWidget {
  const OlahMenu({super.key});

  @override
  State<OlahMenu> createState() => _OlahMenuState();
}

class _OlahMenuState extends State<OlahMenu> {
  final supabase = Supabase.instance.client;

  List<Map<String, dynamic>> menus = [];
  bool isLoading = true;

  static const backgroundColor = Color(0xFF995631);
  static const cardColor = Color(0xFF5E3007);
  static const accentColor = Color(0xFFFFD5A4);
  static const redColor = Color(0xFF960909);

  @override
  void initState() {
    super.initState();
    getMenus();
  }

  // Mengambil data menu dari Supabase
  Future<void> getMenus() async {
    try {
      final data = await supabase
          .from('menu')
          .select()
          .order('id', ascending: true);

      if (!mounted) return;

      setState(() {
        menus = List<Map<String, dynamic>>.from(data);
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
      });

      showMessage('Gagal mengambil data menu: $e');
    }
  }

  // Menampilkan pesan
  void showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: cardColor),
    );
  }

  // Menghitung jumlah menu aktif
  int get activeMenuCount {
    return menus.where((menu) => menu['availability'] == true).length;
  }

  // Format harga
  String formatPrice(dynamic price) {
    final value = (price as num).toInt();
    final text = value.toString();
    final buffer = StringBuffer();

    for (int i = 0; i < text.length; i++) {
      if (i > 0 && (text.length - i) % 3 == 0) {
        buffer.write('.');
      }
      buffer.write(text[i]);
    }

    return 'Rp ${buffer.toString()}';
  }

  // Dialog tambah dan edit menu
  Future<void> showMenuDialog({Map<String, dynamic>? menu}) async {
    final isEdit = menu != null;

    final nameController = TextEditingController(
      text: menu?['name']?.toString() ?? '',
    );

    final priceController = TextEditingController(
      text: menu?['price']?.toString() ?? '',
    );

    final caloriesController = TextEditingController(
      text: menu?['calories']?.toString() ?? '',
    );

    final toppingsController = TextEditingController(
      text: menu != null ? (menu['toppings'] as List? ?? []).join(', ') : '',
    );

    bool availability = menu?['availability'] ?? true;

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: accentColor,
              title: Text(
                isEdit ? 'Edit Menu' : 'Tambah Menu Baru',
                style: const TextStyle(
                  color: cardColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    buildDialogInput(
                      controller: nameController,
                      label: 'Nama Menu',
                    ),
                    const SizedBox(height: 12),
                    buildDialogInput(
                      controller: priceController,
                      label: 'Harga',
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 12),
                    buildDialogInput(
                      controller: caloriesController,
                      label: 'Kalori',
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 12),
                    buildDialogInput(
                      controller: toppingsController,
                      label: 'Topping (pisahkan dengan koma)',
                    ),
                    const SizedBox(height: 8),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text(
                        'Menu tersedia',
                        style: TextStyle(color: cardColor),
                      ),
                      activeThumbColor: cardColor,
                      value: availability,
                      onChanged: (value) {
                        setDialogState(() {
                          availability = value;
                        });
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(dialogContext);
                  },
                  child: const Text(
                    'Batal',
                    style: TextStyle(color: cardColor),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: cardColor,
                    foregroundColor: accentColor,
                  ),
                  onPressed: () {
                    final name = nameController.text.trim();
                    final price = double.tryParse(priceController.text.trim());
                    final calories = int.tryParse(
                      caloriesController.text.trim(),
                    );

                    if (name.isEmpty ||
                        price == null ||
                        calories == null ||
                        price < 0 ||
                        calories < 0) {
                      ScaffoldMessenger.of(dialogContext).showSnackBar(
                        const SnackBar(
                          content: Text('Isi semua data dengan benar.'),
                        ),
                      );
                      return;
                    }

                    final toppings = toppingsController.text
                        .split(',')
                        .map((item) => item.trim())
                        .where((item) => item.isNotEmpty)
                        .toList();

                    Navigator.pop(dialogContext, {
                      'name': name,
                      'price': price,
                      'calories': calories,
                      'toppings': toppings,
                      'availability': availability,
                    });
                  },
                  child: Text(isEdit ? 'Simpan' : 'Tambah'),
                ),
              ],
            );
          },
        );
      },
    );

    nameController.dispose();
    priceController.dispose();
    caloriesController.dispose();
    toppingsController.dispose();

    if (result == null) return;

    if (isEdit) {
      await updateMenu(menu['id'], result);
    } else {
      await addMenu(result);
    }
  }

  // Input pada dialog
  Widget buildDialogInput({
    required TextEditingController controller,
    required String label,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: const TextStyle(color: cardColor),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: cardColor),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  // Menambahkan menu
  Future<void> addMenu(Map<String, dynamic> data) async {
    try {
      await supabase.from('menu').insert(data);

      if (!mounted) return;

      showMessage('Menu berhasil ditambahkan.');
      await getMenus();
    } catch (e) {
      if (!mounted) return;
      showMessage('Gagal menambahkan menu: $e');
    }
  }

  // Mengedit menu
  Future<void> updateMenu(dynamic id, Map<String, dynamic> data) async {
    try {
      await supabase.from('menu').update(data).eq('id', id);

      if (!mounted) return;

      showMessage('Menu berhasil diperbarui.');
      await getMenus();
    } catch (e) {
      if (!mounted) return;
      showMessage('Gagal mengedit menu: $e');
    }
  }

  // Menghapus menu
  Future<void> deleteMenu(dynamic id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: accentColor,
          title: const Text('Hapus Menu', style: TextStyle(color: cardColor)),
          content: const Text(
            'Apakah kamu yakin ingin menghapus menu ini?',
            style: TextStyle(color: cardColor),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Batal', style: TextStyle(color: cardColor)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: redColor,
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Hapus'),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    try {
      await supabase.from('menu').delete().eq('id', id);

      if (!mounted) return;

      showMessage('Menu berhasil dihapus.');
      await getMenus();
    } catch (e) {
      if (!mounted) return;
      showMessage('Gagal menghapus menu: $e');
    }
  }

  // Mengubah status ketersediaan menu
  Future<void> toggleAvailability(Map<String, dynamic> menu) async {
    try {
      final currentStatus = menu['availability'] == true;

      await supabase
          .from('menu')
          .update({'availability': !currentStatus})
          .eq('id', menu['id']);

      await getMenus();
    } catch (e) {
      if (!mounted) return;
      showMessage('Gagal mengubah status menu: $e');
    }
  }

  // Kartu menu
  Widget menuCard(Map<String, dynamic> menu) {
    final name = menu['name']?.toString() ?? '-';
    final price = menu['price'] ?? 0;
    final calories = menu['calories'] ?? 0;
    final toppings = (menu['toppings'] as List? ?? []);
    final available = menu['availability'] == true;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: accentColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x24542500),
            blurRadius: 14,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 84,
            height: 84,
            decoration: BoxDecoration(
              color: const Color(0xFFCF9B84),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.local_cafe, color: cardColor, size: 42),
          ),
          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: redColor,
                    fontSize: 16,
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  formatPrice(price),
                  style: const TextStyle(
                    color: cardColor,
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$calories Kal • ${toppings.length} topping',
                  style: const TextStyle(
                    color: backgroundColor,
                    fontSize: 11,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const SizedBox(height: 6),
                GestureDetector(
                  onTap: () => toggleAvailability(menu),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: available ? cardColor : redColor,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      available ? 'Tersedia' : 'Tidak tersedia',
                      style: const TextStyle(
                        color: accentColor,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 8),

          Column(
            children: [
              IconButton(
                onPressed: () => showMenuDialog(menu: menu),
                icon: const Icon(Icons.edit, color: accentColor),
                style: IconButton.styleFrom(
                  backgroundColor: cardColor,
                  fixedSize: const Size(36, 36),
                ),
                iconSize: 18,
              ),
              const SizedBox(height: 6),
              IconButton(
                onPressed: () => deleteMenu(menu['id']),
                icon: const Icon(Icons.delete_outline, color: Colors.white),
                style: IconButton.styleFrom(
                  backgroundColor: redColor,
                  fixedSize: const Size(36, 36),
                ),
                iconSize: 18,
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
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: getMenus,
          color: cardColor,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Seduh Senja',
                    style: TextStyle(
                      color: accentColor,
                      fontSize: 24,
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Container(
                    width: 40,
                    height: 40,
                    decoration: const BoxDecoration(
                      color: cardColor,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.coffee, color: accentColor),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Judul halaman
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Olah Menu',
                    style: TextStyle(
                      color: accentColor,
                      fontSize: 20,
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      '$activeMenuCount menu aktif',
                      style: const TextStyle(
                        color: accentColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 4),

              const Text(
                'Atur produk, harga, dan topping yang tersedia.',
                style: TextStyle(
                  color: Color(0xFFCF9B84),
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
              ),

              const SizedBox(height: 16),

              // Tombol tambah menu
              SizedBox(
                width: double.infinity,
                height: 42,
                child: ElevatedButton.icon(
                  onPressed: () => showMenuDialog(),
                  icon: const Icon(Icons.add),
                  label: const Text(
                    'Tambah menu baru',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accentColor,
                    foregroundColor: cardColor,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Daftar menu
              if (isLoading)
                const Padding(
                  padding: EdgeInsets.all(30),
                  child: Center(
                    child: CircularProgressIndicator(color: accentColor),
                  ),
                )
              else if (menus.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(30),
                  child: Center(
                    child: Text(
                      'Belum ada menu.',
                      style: TextStyle(color: accentColor, fontSize: 14),
                    ),
                  ),
                )
              else
                ...menus.map((menu) => menuCard(menu)),
            ],
          ),
        ),
      ),
    );
  }
}
