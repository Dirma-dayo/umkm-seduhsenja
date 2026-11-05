import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProductsPage extends StatefulWidget {
  final void Function(List<Map<String, dynamic>> items)? onCheckout;

  const ProductsPage({super.key, this.onCheckout});

  @override
  State<ProductsPage> createState() => _ProductsPageState();
}

class _ProductsPageState extends State<ProductsPage> {
  static const Color background = Color(0xFF995631);
  static const Color cream = Color(0xFFFFD5A4);
  static const Color burgundy = Color(0xFF660710);
  static const Color darkBrown = Color(0xFF5E3007);
  static const Color muted = Color(0xFFCF9B84);
  static const Color lightCream = Color(0xFFFFE5C4);

  final SupabaseClient _supabase = Supabase.instance.client;

  List<Map<String, dynamic>> _products = [];
  final List<Map<String, dynamic>> _cart = [];

  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  num _number(dynamic value) {
    if (value is num) return value;
    return num.tryParse(value?.toString() ?? '') ?? 0;
  }

  String _formatPrice(num value) {
    final digits = value.toInt().toString();
    final result = StringBuffer();

    for (int i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) {
        result.write('.');
      }
      result.write(digits[i]);
    }

    return 'Rp ${result.toString()}';
  }

  Future<void> _loadProducts() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }

    try {
      final data = await _supabase
          .from('menu')
          .select('id, name, calories, toppings, price')
          .order('name');

      if (!mounted) return;

      setState(() {
        _products = List<Map<String, dynamic>>.from(data);
        _loading = false;
      });
    } catch (e, stackTrace) {
      debugPrint('Failed to load menu: $e');
      debugPrintStack(stackTrace: stackTrace);

      if (!mounted) return;

      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  num get _cartTotal {
    return _cart.fold<num>(
      0,
      (total, item) =>
          total + _number(item['unit_price']) * _number(item['quantity']),
    );
  }

  int get _cartCount {
    return _cart.fold<int>(
      0,
      (total, item) => total + (_number(item['quantity']).toInt()),
    );
  }

  void _addToCart(Map<String, dynamic> product, List<String> selectedToppings) {
    final productId = product['id'];

    final existingIndex = _cart.indexWhere((item) {
      final sameProduct = item['menu_id'] == productId;
      final existingToppings = List<String>.from(
        item['selected_toppings'] ?? [],
      );

      return sameProduct &&
          existingToppings.length == selectedToppings.length &&
          existingToppings.every(selectedToppings.contains);
    });

    setState(() {
      if (existingIndex != -1) {
        _cart[existingIndex]['quantity'] =
            _number(_cart[existingIndex]['quantity']).toInt() + 1;
      } else {
        _cart.add({
          'menu_id': productId,
          'menu_name': product['name']?.toString() ?? 'Menu',
          'quantity': 1,
          'unit_price': _number(product['price']),
          'selected_toppings': List<String>.from(selectedToppings),
        });
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${product['name']} ditambahkan ke keranjang.'),
        backgroundColor: darkBrown,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showMenuDetails(Map<String, dynamic> product) {
    final rawToppings = product['toppings'];
    final List<String> toppings = rawToppings is List
        ? rawToppings.map((item) => item.toString()).toList()
        : <String>[];

    final Set<String> selectedToppings = {};

    final String name = product['name']?.toString() ?? 'Menu';
    final num price = _number(product['price']);
    final String calories = product['calories']?.toString() ?? '-';

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: cream,
      barrierColor: Colors.black54,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return FractionallySizedBox(
              heightFactor: 0.90,
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  Container(
                    width: 42,
                    height: 5,
                    decoration: BoxDecoration(
                      color: background.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),

                  // Header
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 12, 8),
                    child: Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Detail Menu',
                            style: TextStyle(
                              color: darkBrown,
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              fontFamily: 'Poppins',
                            ),
                          ),
                        ),
                        IconButton(
                          tooltip: 'Tutup',
                          onPressed: () => Navigator.pop(sheetContext),
                          icon: const Icon(
                            Icons.close_rounded,
                            color: darkBrown,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Scrollable details
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
                      children: [
                        Container(
                          height: 160,
                          decoration: BoxDecoration(
                            color: lightCream,
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: const Icon(
                            Icons.local_cafe_rounded,
                            size: 90,
                            color: background,
                          ),
                        ),
                        const SizedBox(height: 18),

                        Text(
                          name,
                          style: const TextStyle(
                            color: burgundy,
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            fontFamily: 'Poppins',
                          ),
                        ),
                        const SizedBox(height: 6),

                        Text(
                          _formatPrice(price),
                          style: const TextStyle(
                            color: darkBrown,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'Poppins',
                          ),
                        ),
                        const SizedBox(height: 4),

                        Row(
                          children: [
                            const Icon(
                              Icons.local_fire_department_outlined,
                              size: 17,
                              color: background,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '$calories Kal',
                              style: const TextStyle(
                                color: background,
                                fontSize: 13,
                                fontFamily: 'Poppins',
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 24),

                        const Text(
                          'Pilih Topping',
                          style: TextStyle(
                            color: darkBrown,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            fontFamily: 'Poppins',
                          ),
                        ),
                        const SizedBox(height: 4),

                        const Text(
                          'Sesuaikan minumanmu dengan topping pilihan.',
                          style: TextStyle(
                            color: background,
                            fontSize: 12,
                            fontFamily: 'Poppins',
                          ),
                        ),
                        const SizedBox(height: 12),

                        if (toppings.isEmpty)
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: lightCream,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              'Belum ada topping untuk menu ini.',
                              style: TextStyle(
                                color: darkBrown,
                                fontFamily: 'Poppins',
                              ),
                            ),
                          )
                        else
                          ...toppings.map((topping) {
                            final selected = selectedToppings.contains(topping);

                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              decoration: BoxDecoration(
                                color: lightCream,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: CheckboxListTile(
                                value: selected,
                                activeColor: background,
                                checkColor: cream,
                                controlAffinity:
                                    ListTileControlAffinity.leading,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                ),
                                title: Text(
                                  topping,
                                  style: const TextStyle(
                                    color: darkBrown,
                                    fontWeight: FontWeight.w600,
                                    fontFamily: 'Poppins',
                                  ),
                                ),
                                onChanged: (value) {
                                  setSheetState(() {
                                    if (value == true) {
                                      selectedToppings.add(topping);
                                    } else {
                                      selectedToppings.remove(topping);
                                    }
                                  });
                                },
                              ),
                            );
                          }),
                      ],
                    ),
                  ),

                  // The only add-to-cart button
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                    decoration: const BoxDecoration(
                      color: cream,
                      border: Border(top: BorderSide(color: Color(0x33995631))),
                    ),
                    child: SizedBox(
                      height: 48,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: background,
                          foregroundColor: cream,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: () {
                          final chosenToppings = List<String>.from(
                            selectedToppings,
                          );

                          Navigator.pop(sheetContext);

                          _addToCart(product, chosenToppings);
                        },
                        child: const Text(
                          'Tambahkan ke keranjang',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _changeQuantity(int index, int change) {
    if (index < 0 || index >= _cart.length) return;

    setState(() {
      final quantity = _number(_cart[index]['quantity']).toInt() + change;

      if (quantity <= 0) {
        _cart.removeAt(index);
      } else {
        _cart[index]['quantity'] = quantity;
      }
    });
  }

  void _showCart() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black54,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return FractionallySizedBox(
              heightFactor: 0.78,
              child: Container(
                decoration: const BoxDecoration(
                  color: cream,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                ),
                child: Column(
                  children: [
                    const SizedBox(height: 12),

                    // Handle
                    Container(
                      width: 42,
                      height: 5,
                      decoration: BoxDecoration(
                        color: background.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),

                    // Header
                    Padding(
                      padding: const EdgeInsets.fromLTRB(22, 20, 16, 16),
                      child: Row(
                        children: [
                          Container(
                            width: 46,
                            height: 46,
                            decoration: BoxDecoration(
                              color: lightCream,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(
                              Icons.shopping_basket_rounded,
                              color: background,
                              size: 25,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Keranjang Pesanan',
                                  style: TextStyle(
                                    color: darkBrown,
                                    fontSize: 19,
                                    fontWeight: FontWeight.w900,
                                    fontFamily: 'Poppins',
                                  ),
                                ),
                                Text(
                                  '$_cartCount item dalam keranjang',
                                  style: const TextStyle(
                                    color: background,
                                    fontSize: 11,
                                    fontFamily: 'Poppins',
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.pop(sheetContext),
                            icon: const Icon(
                              Icons.close_rounded,
                              color: darkBrown,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const Divider(height: 1, color: Color(0x33995631)),

                    // Cart contents
                    Expanded(
                      child: _cart.isEmpty
                          ? const Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.shopping_basket_outlined,
                                    size: 64,
                                    color: background,
                                  ),
                                  SizedBox(height: 14),
                                  Text(
                                    'Keranjang masih kosong',
                                    style: TextStyle(
                                      color: darkBrown,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                      fontFamily: 'Poppins',
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    'Yuk, pilih minuman favoritmu!',
                                    style: TextStyle(
                                      color: background,
                                      fontSize: 12,
                                      fontFamily: 'Poppins',
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.fromLTRB(
                                20,
                                18,
                                20,
                                12,
                              ),
                              itemCount: _cart.length,
                              itemBuilder: (context, index) {
                                final item = _cart[index];
                                final toppings = List<String>.from(
                                  item['selected_toppings'] ?? [],
                                );
                                final quantity = _number(item['quantity'])
                                    .toInt();
                                final unitPrice = _number(item['unit_price']);

                                return Container(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: lightCream,
                                    borderRadius: BorderRadius.circular(18),
                                    border: Border.all(
                                      color: background.withValues(alpha: 0.12),
                                    ),
                                  ),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        width: 54,
                                        height: 54,
                                        decoration: BoxDecoration(
                                          color: cream,
                                          borderRadius: BorderRadius.circular(
                                            14,
                                          ),
                                        ),
                                        child: const Icon(
                                          Icons.local_cafe_rounded,
                                          color: background,
                                          size: 28,
                                        ),
                                      ),
                                      const SizedBox(width: 12),

                                      // Item information
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              item['menu_name'].toString(),
                                              style: const TextStyle(
                                                color: darkBrown,
                                                fontSize: 14,
                                                fontWeight: FontWeight.w800,
                                                fontFamily: 'Poppins',
                                              ),
                                            ),
                                            const SizedBox(height: 3),
                                            Text(
                                              _formatPrice(unitPrice),
                                              style: const TextStyle(
                                                color: background,
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                                fontFamily: 'Poppins',
                                              ),
                                            ),

                                            if (toppings.isNotEmpty) ...[
                                              const SizedBox(height: 5),
                                              Text(
                                                toppings.join(' · '),
                                                style: const TextStyle(
                                                  color: background,
                                                  fontSize: 10,
                                                  fontFamily: 'Poppins',
                                                ),
                                              ),
                                            ],

                                            const SizedBox(height: 9),

                                            Text(
                                              _formatPrice(
                                                unitPrice * quantity,
                                              ),
                                              style: const TextStyle(
                                                color: burgundy,
                                                fontSize: 14,
                                                fontWeight: FontWeight.w900,
                                                fontFamily: 'Poppins',
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),

                                      // Quantity controls
                                      Column(
                                        children: [
                                          Container(
                                            decoration: BoxDecoration(
                                              color: cream,
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                IconButton(
                                                  visualDensity:
                                                      VisualDensity.compact,
                                                  constraints:
                                                      const BoxConstraints(
                                                        minWidth: 32,
                                                        minHeight: 32,
                                                      ),
                                                  onPressed: () {
                                                    _changeQuantity(index, -1);
                                                    setSheetState(() {});
                                                  },
                                                  icon: const Icon(
                                                    Icons.remove_rounded,
                                                    size: 17,
                                                    color: background,
                                                  ),
                                                ),
                                                Text(
                                                  '$quantity',
                                                  style: const TextStyle(
                                                    color: darkBrown,
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.w800,
                                                    fontFamily: 'Poppins',
                                                  ),
                                                ),
                                                IconButton(
                                                  visualDensity:
                                                      VisualDensity.compact,
                                                  constraints:
                                                      const BoxConstraints(
                                                        minWidth: 32,
                                                        minHeight: 32,
                                                      ),
                                                  onPressed: () {
                                                    _changeQuantity(index, 1);
                                                    setSheetState(() {});
                                                  },
                                                  icon: const Icon(
                                                    Icons.add_rounded,
                                                    size: 17,
                                                    color: background,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                    ),

                    // Checkout section
                    Container(
                      padding: const EdgeInsets.fromLTRB(22, 16, 22, 20),
                      decoration: const BoxDecoration(
                        color: cream,
                        border: Border(
                          top: BorderSide(color: Color(0x33995631)),
                        ),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Subtotal',
                                style: TextStyle(
                                  color: darkBrown,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  fontFamily: 'Poppins',
                                ),
                              ),
                              Text(
                                _formatPrice(_cartTotal),
                                style: const TextStyle(
                                  color: burgundy,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w900,
                                  fontFamily: 'Poppins',
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: background,
                                foregroundColor: cream,
                                disabledBackgroundColor: background.withValues(
                                  alpha: 0.35,
                                ),
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15),
                                ),
                              ),
                              onPressed: _cart.isEmpty
                                  ? null
                                  : () {
                                      final items = _cart
                                          .map(
                                            (item) =>
                                                Map<String, dynamic>.from(item),
                                          )
                                          .toList();

                                      Navigator.pop(sheetContext);

                                      if (widget.onCheckout != null) {
                                        widget.onCheckout!(items);
                                      } else {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                              const SnackBar(
                                                content: Text(
                                                  'Checkout belum dihubungkan.',
                                                ),
                                              ),
                                            );
                                      }
                                    },
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'Lanjut ke checkout',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w800,
                                      fontFamily: 'Poppins',
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                  Icon(Icons.arrow_forward_rounded, size: 19),
                                ],
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
          },
        );
      },
    );
  }

  Widget _buildProductCard(Map<String, dynamic> product) {
    final name = product['name']?.toString() ?? 'Menu';
    final price = _number(product['price']);
    final calories = product['calories']?.toString() ?? '-';

    return Material(
      color: cream,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _showMenuDetails(product),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 86,
                height: 86,
                decoration: BoxDecoration(
                  color: lightCream,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.local_cafe_rounded,
                  size: 48,
                  color: background,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: burgundy,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        fontFamily: 'Poppins',
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      _formatPrice(price),
                      style: const TextStyle(
                        color: darkBrown,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'Poppins',
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '$calories Kal',
                      style: const TextStyle(
                        color: background,
                        fontSize: 12,
                        fontFamily: 'Poppins',
                      ),
                    ),
                    const SizedBox(height: 5),
                    const Text(
                      'Ketuk untuk melihat detail',
                      style: TextStyle(
                        color: background,
                        fontSize: 10,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              const Icon(
                Icons.chevron_right_rounded,
                color: background,
                size: 28,
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      body: SafeArea(
        child: RefreshIndicator(
          color: background,
          backgroundColor: cream,
          onRefresh: _loadProducts,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Center(
                        child: Column(
                          children: [
                            Text(
                              'Selamat Datang Di',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: cream,
                                fontSize: 19,
                                fontWeight: FontWeight.w600,
                                fontFamily: 'Poppins',
                              ),
                            ),
                            Text(
                              'Seduh Senja',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: cream,
                                fontSize: 27,
                                fontWeight: FontWeight.w900,
                                fontFamily: 'Poppins',
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Menu Kami',
                        style: TextStyle(
                          color: cream,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          fontFamily: 'Poppins',
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Pilih minuman favoritmu.',
                        style: TextStyle(
                          color: lightCream,
                          fontSize: 13,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              if (_loading)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(child: CircularProgressIndicator(color: cream)),
                )
              else if (_error != null)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.error_outline_rounded,
                            color: cream,
                            size: 48,
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Gagal memuat menu.',
                            style: TextStyle(
                              color: cream,
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              fontFamily: 'Poppins',
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _error!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: lightCream,
                              fontSize: 11,
                            ),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: _loadProducts,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Coba lagi'),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              else if (_products.isEmpty)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.coffee_outlined, color: cream, size: 60),
                          SizedBox(height: 12),
                          Text(
                            'Belum ada menu tersedia.',
                            style: TextStyle(
                              color: cream,
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              fontFamily: 'Poppins',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _buildProductCard(_products[index]),
                      );
                    }, childCount: _products.length),
                  ),
                ),
            ],
          ),
        ),
      ),

      // Persistent cart button
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(20, 8, 20, 12),
        child: SizedBox(
          height: 52,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: cream,
              foregroundColor: burgundy,
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            onPressed: _showCart,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.shopping_basket_outlined),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    _cartCount == 0
                        ? 'Lihat Keranjang'
                        : 'Lihat Pesanan ($_cartCount) · ${_formatPrice(_cartTotal)}',
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
