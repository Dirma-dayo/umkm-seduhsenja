import 'package:flutter/material.dart';
import 'widgets/seduh_app_bar.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Warna dari desain Figma
const Color _bg = Color(0xFF995631);
const Color _dark = Color(0xFF5E3007);
const Color _cream = Color(0xFFFFD6A5);
const Color _lightCream = Color(0xFFFFE5C4);
const Color _red = Color(0xFF960909);
const Color _muted = Color(0xFFCF9B84);
const Color _gold = Color(0xFFDBB345);
const Color _rowBrown = Color(0xFF7E421F);

TextStyle _ts(
  double size,
  FontWeight weight,
  Color color, {
  bool italic = false,
  double? height,
}) {
  return TextStyle(
    fontFamily: 'Poppins',
    fontSize: size,
    fontWeight: weight,
    color: color,
    fontStyle: italic ? FontStyle.italic : FontStyle.normal,
    height: height,
  );
}

// Mengubah nilai apa pun (num / String) menjadi angka
num _toNum(dynamic value) {
  if (value is num) return value;
  return num.tryParse(value?.toString() ?? '') ?? 0;
}

// 12.0 -> "12", 12.5 -> "12.5"
String _plainNumber(num value) {
  if (value == value.roundToDouble()) return value.toInt().toString();
  return value.toString();
}

// Format harga: Rp 15.000
String _rupiah(num value) {
  final text = value.round().toString();
  final buffer = StringBuffer();

  for (int i = 0; i < text.length; i++) {
    if (i > 0 && (text.length - i) % 3 == 0) {
      buffer.write('.');
    }
    buffer.write(text[i]);
  }

  return 'Rp $buffer';
}

List<String> _toppingList(dynamic raw) {
  if (raw is List) {
    return raw
        .map((item) => item.toString().trim())
        .where((item) => item.isNotEmpty)
        .toList();
  }
  return [];
}

// FOTO MENU
// Memakai kolom image_url jika ada. Jika tidak, memakai gambar di
// assets/images/menu/ berdasarkan nama menu. Jika tidak ada, ikon cangkir.
class _MenuPhoto extends StatelessWidget {
  const _MenuPhoto({
    required this.name,
    required this.size,
    this.url,
    this.radius = 12,
  });

  final String name;
  final String? url;
  final double size;
  final double radius;

  static const Map<String, String> _assets = {
    'cappuccino': 'cappuccino',
    'coffeelatte': 'coffee_latte',
    'latte': 'coffee_latte',
    'matcha': 'matcha',
    'kopihitam': 'kopi_hitam',
    'tehlemon': 'teh_lemon',
  };

  Widget _fallback() {
    return Container(
      width: size,
      height: size,
      color: _muted,
      child: Icon(Icons.local_cafe, color: _dark, size: size * 0.5),
    );
  }

  @override
  Widget build(BuildContext context) {
    final key = name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
    final imageUrl = url?.trim() ?? '';

    Widget child;

    if (imageUrl.isNotEmpty) {
      child = Image.network(
        imageUrl,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _fallback(),
      );
    } else if (_assets.containsKey(key)) {
      child = Image.asset(
        'assets/images/menu/${_assets[key]}.png',
        width: size,
        height: size,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => _fallback(),
      );
    } else {
      child = _fallback();
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: SizedBox(width: size, height: size, child: child),
    );
  }
}

// HALAMAN DAFTAR MENU
class OlahMenu extends StatefulWidget {
  const OlahMenu({super.key});

  @override
  State<OlahMenu> createState() => _OlahMenuState();
}

class _OlahMenuState extends State<OlahMenu> {
  final supabase = Supabase.instance.client;

  List<Map<String, dynamic>> menus = [];
  bool isLoading = true;

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
      SnackBar(content: Text(message), backgroundColor: _dark),
    );
  }

  // Menghitung jumlah menu aktif
  int get activeMenuCount {
    return menus.where((menu) => menu['availability'] == true).length;
  }

  // Membuka halaman tambah / edit menu (naik dari bawah)
  Future<void> openForm({Map<String, dynamic>? menu}) async {
    final saved = await Navigator.push<bool>(
      context,
      PageRouteBuilder<bool>(
        transitionDuration: const Duration(milliseconds: 350),
        reverseTransitionDuration: const Duration(milliseconds: 300),
        pageBuilder: (_, __, ___) => MenuFormPage(menu: menu),
        transitionsBuilder: (_, animation, __, child) {
          final curved = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
            reverseCurve: Curves.easeInCubic,
          );

          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 1),
              end: Offset.zero,
            ).animate(curved),
            child: child,
          );
        },
      ),
    );

    if (saved == true) {
      if (!mounted) return;
      showMessage('Menu berhasil disimpan.');
      await getMenus();
    }
  }

  // Menghapus menu
  Future<void> deleteMenu(dynamic id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: _cream,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text('Hapus Menu', style: _ts(18, FontWeight.w700, _dark)),
          content: Text(
            'Apakah kamu yakin ingin menghapus menu ini?',
            style: _ts(14, FontWeight.w400, _dark),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('Batal', style: _ts(14, FontWeight.w600, _dark)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _red,
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

  // Tombol kotak kecil (edit / hapus)
  Widget squareButton({
    required IconData icon,
    required Color background,
    required VoidCallback onTap,
    required String tooltip,
  }) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: background,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: SizedBox(
            width: 36,
            height: 36,
            child: Icon(icon, color: _cream, size: 16),
          ),
        ),
      ),
    );
  }

  // Kartu menu
  Widget menuCard(Map<String, dynamic> menu) {
    final name = menu['name']?.toString() ?? '-';
    final price = _toNum(menu['price']);
    final calories = _toNum(menu['calories']).toInt();
    final toppings = _toppingList(menu['toppings']);
    final available = menu['availability'] == true;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      constraints: const BoxConstraints(minHeight: 112),
      decoration: BoxDecoration(
        color: _cream,
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
          _MenuPhoto(name: name, url: menu['image_url']?.toString(), size: 84,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: _ts(16, FontWeight.w600, _red, height: 1.25),
                ),
                const SizedBox(height: 2),
                Text(
                  _rupiah(price),
                  style: _ts(
                    12,
                    FontWeight.w400,
                    _dark,
                    italic: true,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 2),
                Text.rich(
                  TextSpan(
                    style: _ts(
                      11,
                      FontWeight.w400,
                      _bg,
                      italic: true,
                      height: 1.3,
                    ),
                    children: [
                      TextSpan(text: '$calories Kal'),
                      const TextSpan(
                        text: '  •  ',
                        style: TextStyle(color: _muted),
                      ),
                      TextSpan(text: '${toppings.length} topping'),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                GestureDetector(
                  onTap: () => toggleAvailability(menu),
                  child: Container(
                    height: 25,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: available ? _dark : _red,
                      borderRadius: BorderRadius.circular(12.5),
                    ),
                    child: Text(
                      available ? 'Tersedia' : 'Tidak tersedia',
                      style: _ts(12, FontWeight.w600, _cream),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              squareButton(
                icon: Icons.edit_outlined,
                background: _dark,
                tooltip: 'Edit menu',
                onTap: () => openForm(menu: menu),
              ),
              const SizedBox(height: 8),
              squareButton(
                icon: Icons.delete_outline,
                background: _red,
                tooltip: 'Hapus menu',
                onTap: () => deleteMenu(menu['id']),
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
      backgroundColor: _bg,
      appBar: const SeduhAppBar(),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: getMenus,
          color: _dark,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            children: [
              // Judul halaman
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Olah Menu', style: _ts(20, FontWeight.w700, _cream)),
                  Container(
                    height: 25,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: _dark,
                      borderRadius: BorderRadius.circular(12.5),
                    ),
                    child: Text(
                      '$activeMenuCount menu aktif',
                      style: _ts(12, FontWeight.w600, _cream),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 4),

              Text(
                'Atur produk, harga, dan topping yang tersedia.',
                style: _ts(12, FontWeight.w400, _muted, italic: true),
              ),

              const SizedBox(height: 12),

              // Tombol tambah menu
              SizedBox(
                width: double.infinity,
                height: 42,
                child: ElevatedButton.icon(
                  onPressed: () => openForm(),
                  icon: const Icon(Icons.add, size: 18),
                  label: Text(
                    'Tambah menu baru',
                    style: _ts(14, FontWeight.w600, _dark),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _cream,
                    foregroundColor: _dark,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Daftar menu
              if (isLoading)
                const Padding(
                  padding: EdgeInsets.all(30),
                  child: Center(
                    child: CircularProgressIndicator(color: _cream),
                  ),
                )
              else if (menus.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(30),
                  child: Center(
                    child: Text(
                      'Belum ada menu.',
                      style: _ts(14, FontWeight.w400, _cream),
                    ),
                  ),
                )
              else
                ...menus.map(menuCard),
            ],
          ),
        ),
      ),
    );
  }
}

// HALAMAN TAMBAH / EDIT MENU (tampilan seperti Kelola topping)
class _ToppingItem {
  _ToppingItem(this.name, {this.selected = true});

  String name;
  bool selected;
}

class MenuFormPage extends StatefulWidget {
  const MenuFormPage({super.key, this.menu});

  // null = tambah menu baru, berisi data = edit menu
  final Map<String, dynamic>? menu;

  @override
  State<MenuFormPage> createState() => _MenuFormPageState();
}

class _MenuFormPageState extends State<MenuFormPage> {
  final supabase = Supabase.instance.client;

  late final TextEditingController nameController;
  late final TextEditingController priceController;
  late final TextEditingController caloriesController;

  late bool availability;
  late List<_ToppingItem> toppings;

  bool saving = false;

  bool get isEdit => widget.menu != null;

  @override
  void initState() {
    super.initState();

    final menu = widget.menu;

    nameController = TextEditingController(
      text: menu?['name']?.toString() ?? '',
    );
    priceController = TextEditingController(
      text: menu == null ? '' : _plainNumber(_toNum(menu['price'])),
    );
    caloriesController = TextEditingController(
      text: menu == null ? '' : _plainNumber(_toNum(menu['calories'])),
    );

    availability = menu?['availability'] != false;

    toppings = _toppingList(menu?['toppings'])
        .map((name) => _ToppingItem(name))
        .toList();

    // Supaya nama dan harga di bagian atas ikut berubah saat diketik
    nameController.addListener(_refresh);
    priceController.addListener(_refresh);
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    nameController.dispose();
    priceController.dispose();
    caloriesController.dispose();
    super.dispose();
  }

  void showMessage(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message), backgroundColor: _dark));
  }

  int get selectedCount => toppings.where((t) => t.selected).length;

  // Dialog nama topping (tambah / ubah)
  Future<String?> askToppingName({String initial = ''}) {
    return showDialog<String>(
      context: context,
      builder: (_) => _ToppingNameDialog(initial: initial),
    );
  }

  bool toppingExists(String name, {_ToppingItem? except}) {
    return toppings.any(
      (t) => t != except && t.name.toLowerCase() == name.toLowerCase(),
    );
  }

  Future<void> addTopping() async {
    final name = await askToppingName();
    if (name == null || !mounted) return;

    if (toppingExists(name)) {
      showMessage('Topping "$name" sudah ada.');
      return;
    }

    setState(() {
      toppings.add(_ToppingItem(name));
    });
  }

  Future<void> renameTopping(_ToppingItem item) async {
    final name = await askToppingName(initial: item.name);
    if (name == null || !mounted) return;

    if (toppingExists(name, except: item)) {
      showMessage('Topping "$name" sudah ada.');
      return;
    }

    setState(() {
      item.name = name;
    });
  }

  // Menyimpan ke Supabase
  Future<void> save() async {
    final name = nameController.text.trim();
    final price = double.tryParse(
      priceController.text.trim().replaceAll(',', '.'),
    );
    final caloriesText = caloriesController.text.trim();
    final calories = caloriesText.isEmpty ? 0 : int.tryParse(caloriesText);

    if (name.isEmpty ||
        price == null ||
        price < 0 ||
        calories == null ||
        calories < 0) {
      showMessage('Isi nama, harga, dan kalori dengan benar.');
      return;
    }

    setState(() {
      saving = true;
    });

    final data = {
      'name': name,
      'price': price,
      'calories': calories,
      'toppings': toppings.where((t) => t.selected).map((t) => t.name).toList(),
      'availability': availability,
    };

    try {
      if (isEdit) {
        await supabase.from('menu').update(data).eq('id', widget.menu!['id']);
      } else {
        await supabase.from('menu').insert(data);
      }

      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      setState(() {
        saving = false;
      });

      showMessage('Gagal menyimpan menu: $e');
    }
  }

  // Kolom isian
  Widget field(
    String label,
    TextEditingController controller, {
    TextInputType keyboardType = TextInputType.text,
    String? hint,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: _ts(12, FontWeight.w600, _cream)),
          const SizedBox(height: 4),
          TextField(
            controller: controller,
            keyboardType: keyboardType,
            style: _ts(14, FontWeight.w600, _dark),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: _ts(14, FontWeight.w400, const Color(0x99995631)),
              isDense: true,
              filled: true,
              fillColor: _cream,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 12,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Panel cokelat (Detail menu / Topping tersedia)
  Widget panel({
    required String title,
    required String subtitle,
    required List<Widget> children,
    Widget? trailing,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _bg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: _ts(17, FontWeight.w700, _cream)),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: _ts(12, FontWeight.w400, _muted, italic: true),
                    ),
                  ],
                ),
              ),
              if (trailing != null) ...[const SizedBox(width: 8), trailing],
            ],
          ),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }

  // Baris pilihan ketersediaan
  Widget availabilityRow() {
    return Container(
      height: 47,
      padding: const EdgeInsets.only(left: 14, right: 8),
      decoration: BoxDecoration(
        color: _rowBrown,
        border: Border.all(color: _gold),
        borderRadius: BorderRadius.circular(11.5),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              availability ? 'Menu tersedia' : 'Menu tidak tersedia',
              style: _ts(14, FontWeight.w600, _cream),
            ),
          ),
          Switch(
            value: availability,
            activeThumbColor: _cream,
            activeTrackColor: _bg,
            inactiveThumbColor: _muted,
            inactiveTrackColor: _dark,
            onChanged: (value) {
              setState(() {
                availability = value;
              });
            },
          ),
        ],
      ),
    );
  }

  // Satu baris topping
  Widget toppingRow(_ToppingItem item) {
    final on = item.selected;

    return GestureDetector(
      onTap: () {
        setState(() {
          item.selected = !item.selected;
        });
      },
      child: Container(
        height: 47,
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 8.5),
        decoration: BoxDecoration(
          color: on ? _rowBrown : _dark,
          border: Border.all(color: on ? _gold : _muted),
          borderRadius: BorderRadius.circular(11.5),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: on ? _bg : _cream,
                border: Border.all(color: on ? _cream : _bg, width: 2),
                borderRadius: BorderRadius.circular(9),
              ),
              child: on
                  ? const Icon(Icons.check, color: _cream, size: 26)
                  : null,
            ),
            const SizedBox(width: 7),
            Flexible(
              child: Container(
                width: 125,
                height: 32,
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  color: _cream,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  item.name.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: _ts(12, FontWeight.w800, _bg),
                ),
              ),
            ),
            const Spacer(),
            InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () => renameTopping(item),
              child: const Padding(
                padding: EdgeInsets.all(8),
                child: Icon(Icons.edit_outlined, color: _cream, size: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final name = nameController.text.trim();
    final price =
        double.tryParse(priceController.text.trim().replaceAll(',', '.')) ?? 0;

    final badgeText = toppings.isEmpty
        ? 'Belum ada topping'
        : '$selectedCount dari ${toppings.length} aktif';

    return Scaffold(
      backgroundColor: _bg,
      appBar: const SeduhAppBar(showBack: false),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 4),
            Expanded(
              child: Container(
                width: double.infinity,
                margin: const EdgeInsets.symmetric(horizontal: 20),
                decoration: const BoxDecoration(
                  color: _cream,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x33000000),
                      blurRadius: 12,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Tombol kembali + judul
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Material(
                            color: _lightCream,
                            borderRadius: BorderRadius.circular(12),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: saving
                                  ? null
                                  : () => Navigator.pop(context),
                              child: const SizedBox(
                                width: 40,
                                height: 40,
                                child: Icon(
                                  Icons.arrow_back,
                                  color: _bg,
                                  size: 22,
                                ),
                              ),
                            ),
                          ),
                          const Spacer(),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                isEdit ? 'Edit menu' : 'Tambah menu',
                                style: _ts(20, FontWeight.w700, _dark),
                              ),
                              Text(
                                availability ? 'Menu aktif' : 'Menu nonaktif',
                                style: _ts(12, FontWeight.w700, _bg),
                              ),
                            ],
                          ),
                        ],
                      ),

                      const SizedBox(height: 14),

                      // Foto + ringkasan
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          _MenuPhoto(
                            name: name,
                            url: widget.menu?['image_url']?.toString(),
                            size: 144,
                            radius: 16,
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  name.isEmpty ? 'Nama menu' : name,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: _ts(
                                    22,
                                    FontWeight.w800,
                                    _red,
                                    height: 1.2,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _rupiah(price),
                                  style: _ts(
                                    16,
                                    FontWeight.w400,
                                    _dark,
                                    italic: true,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  height: 25,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                  ),
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: _bg,
                                    borderRadius: BorderRadius.circular(12.5),
                                  ),
                                  child: Text(
                                    badgeText,
                                    style: _ts(12, FontWeight.w600, _cream),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Detail menu
                      panel(
                        title: 'Detail menu',
                        subtitle: 'Ubah nama, harga, dan kalori menu',
                        children: [
                          field(
                            'Nama menu',
                            nameController,
                            hint: 'Contoh: Coffee Latte',
                          ),
                          field(
                            'Harga (Rp)',
                            priceController,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            hint: 'Contoh: 17000',
                          ),
                          field(
                            'Kalori (Kal)',
                            caloriesController,
                            keyboardType: TextInputType.number,
                            hint: 'Contoh: 720',
                          ),
                          availabilityRow(),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Topping
                      panel(
                        title: 'Topping tersedia',
                        subtitle:
                            'Centang topping yang dapat dipilih pelanggan',
                        trailing: Material(
                          color: _dark,
                          borderRadius: BorderRadius.circular(12),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: addTopping,
                            child: const SizedBox(
                              width: 34,
                              height: 34,
                              child: Icon(Icons.add, color: _cream, size: 22),
                            ),
                          ),
                        ),
                        children: [
                          if (toppings.isEmpty)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Text(
                                'Belum ada topping. Tekan + untuk menambah.',
                                style: _ts(
                                  12,
                                  FontWeight.w400,
                                  _cream,
                                  italic: true,
                                ),
                              ),
                            )
                          else
                            ...toppings.map(toppingRow),
                        ],
                      ),

                      const SizedBox(height: 12),

                      // Catatan
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: _lightCream,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.info_outline,
                              color: _bg,
                              size: 18,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                isEdit
                                    ? 'Perubahan hanya berlaku untuk '
                                          '${name.isEmpty ? 'menu ini' : name}. '
                                          'Topping yang tidak dicentang akan '
                                          'dihapus dari menu ini.'
                                    : 'Menu baru akan langsung muncul di '
                                          'daftar menu. Topping yang tidak '
                                          'dicentang tidak disimpan.',
                                style: _ts(
                                  12,
                                  FontWeight.w400,
                                  _dark,
                                  italic: true,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 14),

                      // Tombol
                      Row(
                        children: [
                          Expanded(
                            flex: 140,
                            child: SizedBox(
                              height: 42,
                              child: TextButton(
                                onPressed: saving
                                    ? null
                                    : () => Navigator.pop(context),
                                child: Text(
                                  'Kembali',
                                  style: _ts(16, FontWeight.w600, _dark),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 178,
                            child: SizedBox(
                              height: 42,
                              child: ElevatedButton(
                                onPressed: saving ? null : save,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _bg,
                                  foregroundColor: _cream,
                                  disabledBackgroundColor: _bg,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                child: saving
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: _cream,
                                        ),
                                      )
                                    : Text(
                                        isEdit
                                            ? 'Simpan perubahan'
                                            : 'Tambah menu',
                                        style: _ts(16, FontWeight.w600, _cream),
                                      ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Dialog kecil untuk nama topping (mengelola controller-nya sendiri)
class _ToppingNameDialog extends StatefulWidget {
  const _ToppingNameDialog({required this.initial});

  final String initial;

  @override
  State<_ToppingNameDialog> createState() => _ToppingNameDialogState();
}

class _ToppingNameDialogState extends State<_ToppingNameDialog> {
  late final TextEditingController controller;

  @override
  void initState() {
    super.initState();
    controller = TextEditingController(text: widget.initial);
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void submit() {
    final value = controller.text.trim();
    if (value.isEmpty) return;
    Navigator.pop(context, value);
  }

  @override
  Widget build(BuildContext context) {
    final isNew = widget.initial.isEmpty;

    return AlertDialog(
      backgroundColor: _cream,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(
        isNew ? 'Tambah topping' : 'Ubah topping',
        style: _ts(18, FontWeight.w700, _dark),
      ),
      content: TextField(
        controller: controller,
        autofocus: true,
        textCapitalization: TextCapitalization.words,
        style: _ts(14, FontWeight.w600, _dark),
        onSubmitted: (_) => submit(),
        decoration: InputDecoration(
          hintText: 'Nama topping',
          hintStyle: _ts(14, FontWeight.w400, const Color(0x99995631)),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Batal', style: _ts(14, FontWeight.w600, _dark)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: _dark,
            foregroundColor: _cream,
          ),
          onPressed: submit,
          child: Text(isNew ? 'Tambah' : 'Simpan'),
        ),
      ],
    );
  }
}
