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
  List<int> _tableNumbers = [];
  int? _selectedTableNum;

  final SupabaseClient _supabase = Supabase.instance.client;

  List<Map<String, dynamic>> _products = [];
  final List<Map<String, dynamic>> _cart = [];

  bool _loading = true;
  String? _error;

@override
  void initState() {
    super.initState();
    _loadProducts();
    _loadTables();
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


  Future<void> _loadTables() async {
    try {
      final response = await Supabase.instance.client
          .from('cafe_table')
          .select('num')
          .eq('is_available', true)
          .order('num');

      if (!mounted) return;

      setState(() {
        _tableNumbers = response
            .map<int>((table) => (table['num'] as num).toInt())
            .toList();

        _selectedTableNum = _tableNumbers.isNotEmpty
            ? _tableNumbers.first
            : null;
      });
    } catch (e) {
      debugPrint('Error loading tables: $e');
    }
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

  void _addToCart(
    Map<String, dynamic> product,
    List<String> selectedToppings, {
    int quantity = 1,
  }) {
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
            _number(_cart[existingIndex]['quantity']).toInt() + quantity;
      } else {
        _cart.add({
          'menu_id': productId,
          'menu_name': product['name']?.toString() ?? 'Menu',
          'quantity': quantity,
          'unit_price': _number(product['price']),
          'selected_toppings': List<String>.from(selectedToppings),
        });
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '$quantity x ${product['name']} ditambahkan ke keranjang.',
        ),
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
    int quantity = 1;

    final String name = product['name']?.toString() ?? 'Menu';
    final num price = _number(product['price']);
    final String calories = product['calories']?.toString() ?? '-';

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
              heightFactor: 0.90,
              child: Container(
                decoration: const BoxDecoration(
                  color: cream,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                ),
              child: Column(
                children: [
                  const SizedBox(height: 12),

                    // Drag indicator
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
                      padding: const EdgeInsets.fromLTRB(22, 16, 12, 12),
                    child: Row(
                      children: [
                          const Icon(
                            Icons.arrow_back_rounded,
                            color: darkBrown,
                          ),
                          const SizedBox(width: 12),
                        const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Kelola Topping',
                                  style: TextStyle(
                                    color: darkBrown,
                                    fontSize: 20,
                                    fontWeight: FontWeight.w900,
                                    fontFamily: 'Poppins',
                                  ),
                                ),
                                Text(
                                  'Menu aktif',
                                  style: TextStyle(
                                    color: background,
                                    fontSize: 12,
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

                  Expanded(
                    child: ListView(
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                      children: [
                          // Product information
                        Container(
                            padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: lightCream,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 76,
                                  height: 76,
                                  decoration: BoxDecoration(
                                    color: cream,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(
                                    Icons.local_cafe_rounded,
                                    size: 42,
                                    color: background,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        name,
                                        style: const TextStyle(
                                          color: burgundy,
                                          fontSize: 17,
                                          fontWeight: FontWeight.w900,
                                          fontFamily: 'Poppins',
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        _formatPrice(price),
                                        style: const TextStyle(
                                          color: darkBrown,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                          fontFamily: 'Poppins',
                                        ),
                                      ),
                                      Text(
                                        '$calories Kal',
                                        style: const TextStyle(
                                          color: background,
                                          fontSize: 11,
                                          fontFamily: 'Poppins',
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 22),

                          // Topping header
                        const Text(
                            'Topping tersedia',
                          style: TextStyle(
                            color: darkBrown,
                            fontSize: 18,
                              fontWeight: FontWeight.w900,
                            fontFamily: 'Poppins',
                          ),
                        ),

                        const SizedBox(height: 4),

                        const Text(
                            'Centang topping yang ingin ditambahkan.',
                          style: TextStyle(
                            color: background,
                              fontSize: 11,
                            fontFamily: 'Poppins',
                          ),
                        ),

                        const SizedBox(height: 12),

                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Text(
                                '${selectedToppings.length} dari ${toppings.length} dipilih',
                                style: const TextStyle(
                                  color: background,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  fontFamily: 'Poppins',
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 8),

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
                              final selected = selectedToppings.contains(
                                topping,
                              );

                            return Container(
                                margin: const EdgeInsets.only(bottom: 9),
                              decoration: BoxDecoration(
                                color: lightCream,
                                borderRadius: BorderRadius.circular(12),
                              ),
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(12),
                                  onTap: () {
                                    setSheetState(() {
                                      if (selected) {
                                        selectedToppings.remove(topping);
                                      } else {
                                        selectedToppings.add(topping);
                                      }
                                    });
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 10,
                                    ),
                                    child: Row(
                                      children: [
                                        Checkbox(
                                          value: selected,
                                          activeColor: background,
                                          checkColor: cream,
                                          side: const BorderSide(
                                            color: background,
                                            width: 1.5,
                                          ),
                                          visualDensity: VisualDensity.compact,
                                          onChanged: (value) {
                                            setSheetState(() {
                                              if (value == true) {
                                                selectedToppings.add(topping);
                                              } else {
                                                selectedToppings.remove(
                                                  topping,
                                                );
                                              }
                                            });
                                          },
                                        ),

                                        const SizedBox(width: 6),

                                        Expanded(
                                          child: Text(
                                            topping,
                                            style: const TextStyle(
                                              color: darkBrown,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w700,
                                              fontFamily: 'Poppins',
                                            ),
                                          ),
                                        ),

                                        // Topping prices are not in the
                                        // current Supabase menu query.
                                        const Text(
                                          'Gratis',
                                          style: TextStyle(
                                            color: background,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            fontFamily: 'Poppins',
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            }),

                          const SizedBox(height: 18),

                          // Quantity
                          const Text(
                            'Jumlah pesanan',
                            style: TextStyle(
                              color: darkBrown,
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              fontFamily: 'Poppins',
                            ),
                          ),

                          const SizedBox(height: 10),

                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              IconButton(
                                onPressed: quantity > 1
                                    ? () {
                                        setSheetState(() {
                                          quantity--;
                                        });
                                    }
                                    : null,
                                style: IconButton.styleFrom(
                                  backgroundColor: lightCream,
                                  foregroundColor: background,
                                ),
                                icon: const Icon(Icons.remove_rounded),
                              ),

                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                ),
                                child: Text(
                                  '$quantity',
                                  style: const TextStyle(
                                    color: darkBrown,
                                    fontSize: 20,
                                    fontWeight: FontWeight.w900,
                                    fontFamily: 'Poppins',
                                  ),
                                ),
                              ),

                              IconButton(
                                onPressed: () {
                                  setSheetState(() {
                                    quantity++;
                                  });
                                },
                                style: IconButton.styleFrom(
                                  backgroundColor: lightCream,
                                  foregroundColor: background,
                              ),
                                icon: const Icon(Icons.add_rounded),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),

                    // Bottom action
                  Container(
                    width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 18),
                    decoration: const BoxDecoration(
                      color: cream,
                        border: Border(
                          top: BorderSide(color: Color(0x33995631)),
                        ),
                    ),
                    child: SizedBox(
                        height: 50,
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

                            _addToCart(
                              product,
                              chosenToppings,
                              quantity: quantity,
                            );
                        },
                        child: const Text(
                          'Tambahkan ke keranjang',
                          style: TextStyle(
                            fontSize: 14,
                              fontWeight: FontWeight.w800,
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ),
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
              heightFactor: 0.94,
              child: Container(
                decoration: const BoxDecoration(
                  color: cream,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                ),
                child: Column(
                  children: [
                    const SizedBox(height: 28),

                    // Header
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 28),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'ISI PESANAN',
                          style: TextStyle(
                            color: darkBrown,
                            fontSize: 21,
                            fontWeight: FontWeight.w900,
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 14),

                    // Divider
                    Container(
                      height: 1,
                      margin: const EdgeInsets.symmetric(horizontal: 24),
                      color: Colors.white,
                    ),

                    const SizedBox(height: 20),

                    // Order items
                    Expanded(
                      child: _cart.isEmpty
                          ? const Center(
                              child: Text(
                                'Keranjang masih kosong.',
                                style: TextStyle(
                                  color: darkBrown,
                                  fontSize: 14,
                                  fontFamily: 'Poppins',
                                ),
                              ),
                            )
                          : ListView(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 30,
                              ),
                              children: [
                                ..._cart.map((item) {
                                  final quantity = _number(item['quantity'])
                                      .toInt();
                                  final unitPrice = _number(item['unit_price']);
                                  final toppings = List<String>.from(
                                    item['selected_toppings'] ?? [],
                                  );

                                  final name = item['menu_name'].toString();

                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 13,
                                  ),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                      children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                                '${quantity}x $name',
                                              style: const TextStyle(
                                                color: darkBrown,
                                                fontSize: 14,
                                                  fontWeight: FontWeight.w600,
                                                fontFamily: 'Poppins',
                                              ),
                                            ),

                                              if (toppings.isNotEmpty)
                                                Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                        top: 2,
                                                      ),
                                                  child: Text(
                                                    toppings.join(', '),
                                                    style: const TextStyle(
                                                      color: background,
                                                      fontSize: 10,
                                                      fontFamily: 'Poppins',
                                                    ),
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ),

                                        const SizedBox(width: 12),

                                        Text(
                                          _formatPrice(unitPrice * quantity),
                                          style: const TextStyle(
                                            color: darkBrown,
                                            fontSize: 13,
                                            fontStyle: FontStyle.italic,
                                            fontFamily: 'Poppins',
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }),
                              ],
                            ),
                    ),

                    // Total and table information
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 24),
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: background,
                        borderRadius: BorderRadius.circular(13),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'TOTAL',
                                style: TextStyle(
                                  color: cream,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  fontFamily: 'Poppins',
                                ),
                              ),
                              Text(
                                _formatPrice(_cartTotal),
                                style: const TextStyle(
                                  color: cream,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w900,
                                  fontFamily: 'Poppins',
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 14),

                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Meja anda:',
                                style: TextStyle(
                                  color: cream,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  fontFamily: 'Poppins',
                                ),
                              ),

                              // Placeholder matching the SVG.
                              // Connect this to the selected cafe_table later.
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: cream,
                                  borderRadius: BorderRadius.circular(7),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<int>(
                                    value: _selectedTableNum,
                                    hint: const Text(
                                      'Pilih meja',
                                      style: TextStyle(
                                        color: darkBrown,
                                        fontSize: 13,
                                        fontFamily: 'Poppins',
                                      ),
                                    ),
                                    icon: const Icon(
                                      Icons.keyboard_arrow_down_rounded,
                                      color: darkBrown,
                                      size: 19,
                                    ),
                                    dropdownColor: cream,
                                    borderRadius: BorderRadius.circular(7),
                                    style: const TextStyle(
                                      color: darkBrown,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w800,
                                      fontFamily: 'Poppins',
                                    ),
                                    items: _tableNumbers.map((num) {
                                      return DropdownMenuItem<int>(
                                        value: num,
                                        child: Text(
                                          num.toString().padLeft(2, '0'),
                                        ),
                                      );
                                    }).toList(),
                                    onChanged: (value) {
                                      if (value == null) return;

                                      setSheetState(() {
                                        _selectedTableNum = value;
                                      });
                                    },
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const Spacer(),

                    // Confirmation prompt
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20),
                      child: Text(
                        'Apakah pesanan sudah sesuai?',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: darkBrown,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Confirmation buttons
                    Padding(
                      padding: const EdgeInsets.fromLTRB(28, 0, 28, 24),
                      child: Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: background,
                                side: const BorderSide(
                                  color: background,
                                  width: 1.5,
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 13,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                              ),
                              onPressed: () {
                                Navigator.pop(sheetContext);
                              },
                              child: const Text(
                                'Belum',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  fontFamily: 'Poppins',
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(width: 14),

                          Expanded(
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: background,
                                foregroundColor: cream,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 13,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
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
                              child: const Text(
                                'Sudah',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  fontFamily: 'Poppins',
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
