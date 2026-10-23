import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'menupage.dart';

class DashboardUser extends StatefulWidget {
  final VoidCallback? onOpenMenu;
  final VoidCallback? onGiveReview;

  const DashboardUser({super.key, this.onOpenMenu, this.onGiveReview});

  @override
  State<DashboardUser> createState() => _DashboardUserState();
}

class _DashboardUserState extends State<DashboardUser> {
  static const Color background = Color(0xFF995631);
  static const Color cardColor = Color(0xFF5E3007);
  static const Color cream = Color(0xFFFFD5A4);
  static const Color muted = Color(0xFFCF9B84);

  final SupabaseClient _supabase = Supabase.instance.client;

  bool _loading = true;
  String? _error;

  String _fullName = 'Pelanggan';
  int _nextOrderNumber = 1;
  int _totalProducts = 0;
  double _totalSpending = 0;
  double _monthlySpending = 0;

  List<Map<String, dynamic>> _monthlyItems = [];
  List<Map<String, dynamic>> _allTimeItems = [];

  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }

  double _number(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  int _integer(dynamic value) {
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  DateTime? _date(dynamic value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString())?.toLocal();
  }

  String _rupiah(num value) {
    final amount = value.round().toString();
    final result = StringBuffer();

    for (int i = 0; i < amount.length; i++) {
      result.write(amount[i]);

      final remaining = amount.length - i - 1;
      if (remaining > 0 && remaining % 3 == 0) {
        result.write('.');
      }
    }

    return 'Rp$result';
  }

  String get _monthName {
    const months = [
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember',
    ];

    final now = DateTime.now();
    return '${months[now.month - 1]} ${now.year}';
  }

  Future<void> _loadDashboard() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }

    try {
      final user = _supabase.auth.currentUser;

      if (user == null) {
        throw Exception('Kamu belum login. Silakan login terlebih dahulu.');
      }

      // 1. Get the customer's profile.
      final profile = await _supabase
          .from('account')
          .select('full_name, times_bought')
          .eq('id', user.id)
          .maybeSingle();

      final fullName =
          profile?['full_name']?.toString().trim() ??
          user.userMetadata?['full_name']?.toString().trim() ??
          '';

      final timesBought = _integer(profile?['times_bought']);

      // 2. Fetch only this customer's orders.
      final response = await _supabase
          .from('order_entry')
          .select('id, total, date_time, customer_order_number, status')
          .eq('buyer_id', user.id)
          .order('date_time', ascending: false);

      final orders = List<Map<String, dynamic>>.from(response);

      // Completed orders are used for historical statistics.
      final completedOrders = orders
          .where((order) => order['status'] == 'completed')
          .toList();

      // 3. Calculate the latest registered order number.
      int nextOrderNumber = timesBought + 1;

      if (orders.isNotEmpty) {
        final latestNumber = orders.first['customer_order_number'];

        if (latestNumber != null) {
          nextOrderNumber = _integer(latestNumber);
        }
      }

      // 4. Calculate completed-order totals.
      double totalSpending = 0;
      double monthlySpending = 0;
      int totalProducts = 0;

      final now = DateTime.now();
      final monthStart = DateTime(now.year, now.month, 1);
      final nextMonth = DateTime(now.year, now.month + 1, 1);

      final completedOrderIds = <dynamic>[];
      final monthlyOrderIds = <dynamic>{};
      final orderDates = <dynamic, DateTime>{};

      for (final order in completedOrders) {
        final id = order['id'];
        final date = _date(order['date_time']);

        if (id != null) {
          completedOrderIds.add(id);
          if (date != null) {
            orderDates[id] = date;
          }
        }

        totalSpending += _number(order['total']);

        if (date != null &&
            !date.isBefore(monthStart) &&
            date.isBefore(nextMonth)) {
          monthlySpending += _number(order['total']);

          if (id != null) {
            monthlyOrderIds.add(id);
          }
        }
      }

      // 5. Fetch items belonging to completed orders.
      final itemRows = completedOrderIds.isEmpty
          ? <Map<String, dynamic>>[]
          : List<Map<String, dynamic>>.from(
              await _supabase
                  .from('order_items')
                  .select(
                    'order_id, menu_name, quantity, unit_price, line_total',
                  )
                  .inFilter('order_id', completedOrderIds),
            );

      final allTimeTotals = <String, Map<String, dynamic>>{};
      final monthlyTotals = <String, Map<String, dynamic>>{};

      for (final item in itemRows) {
        final name = item['menu_name']?.toString().trim().isNotEmpty == true
            ? item['menu_name'].toString()
            : 'Menu tanpa nama';

        final quantity = _integer(item['quantity']);
        final lineTotal = item['line_total'] != null
            ? _number(item['line_total'])
            : _number(item['unit_price']) * quantity;

        totalProducts += quantity;

        void addItem(Map<String, Map<String, dynamic>> target) {
          final entry = target.putIfAbsent(
            name,
            () => {'name': name, 'quantity': 0, 'spending': 0.0},
          );

          entry['quantity'] = (entry['quantity'] as int) + quantity;
          entry['spending'] = (entry['spending'] as double) + lineTotal;
        }

        addItem(allTimeTotals);

        if (monthlyOrderIds.contains(item['order_id'])) {
          addItem(monthlyTotals);
        }
      }

      List<Map<String, dynamic>> sortedItems(
        Map<String, Map<String, dynamic>> source,
      ) {
        final result = source.values.toList();

        result.sort(
          (a, b) => (b['quantity'] as int).compareTo(a['quantity'] as int),
        );

        return result;
      }

      if (!mounted) return;

      setState(() {
        _fullName = fullName.isEmpty ? 'Pelanggan' : fullName;
        _nextOrderNumber = nextOrderNumber;
        _totalProducts = totalProducts;
        _totalSpending = totalSpending;
        _monthlySpending = monthlySpending;
        _monthlyItems = sortedItems(monthlyTotals);
        _allTimeItems = sortedItems(allTimeTotals);
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _error = error.toString();
        _loading = false;
      });
    }
  }

  void _handleAction(VoidCallback? callback, String message) {
    if (callback != null) {
      callback();
      return;
    }

    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Widget _sectionTitle(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: cream,
        fontSize: 15,
        fontFamily: 'Poppins',
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _metricCard({
    required String title,
    required String value,
    bool highlighted = false,
  }) {
    final color = highlighted ? cream : cardColor;
    final textColor = highlighted ? background : cream;
    final labelColor = highlighted ? background : muted;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: labelColor,
              fontSize: 12,
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: textColor,
              fontSize: 19,
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _purchaseCard({
    required String title,
    required List<Map<String, dynamic>> items,
    required String emptyMessage,
    required double total,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cream,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: cardColor,
              fontSize: 15,
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          if (items.isEmpty)
            Text(
              emptyMessage,
              style: const TextStyle(
                color: cardColor,
                fontSize: 13,
                fontFamily: 'Poppins',
              ),
            )
          else
            ...items.map((item) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        item['name'].toString(),
                        style: const TextStyle(
                          color: cardColor,
                          fontSize: 13,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _rupiah(item['spending'] as double),
                      style: const TextStyle(
                        color: cardColor,
                        fontSize: 12,
                        fontFamily: 'Poppins',
                      ),
                    ),
                    const SizedBox(width: 12),
                    SizedBox(
                      width: 38,
                      child: Text(
                        '${item['quantity']}x',
                        textAlign: TextAlign.right,
                        style: const TextStyle(
                          color: cardColor,
                          fontSize: 12,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          const Divider(color: muted, height: 24),
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Total',
                  style: TextStyle(
                    color: cardColor,
                    fontSize: 14,
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Flexible(
                child: Text(
                  _rupiah(total),
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    color: cardColor,
                    fontSize: 17,
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _actionButton({
    required String text,
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 19),
        label: Text(
          text,
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w600,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: cream,
          foregroundColor: cardColor,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final favorite = _allTimeItems.isEmpty
        ? 'Belum ada'
        : _allTimeItems.first['name'].toString();

    return Scaffold(
      backgroundColor: background,
      body: SafeArea(
        child: RefreshIndicator(
          color: cardColor,
          backgroundColor: cream,
          onRefresh: _loadDashboard,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Seduh Senja',
                      style: const TextStyle(
                        color: cream,
                        fontSize: 24,
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Container(
                    width: 42,
                    height: 42,
                    decoration: const BoxDecoration(
                      color: cardColor,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      tooltip: 'Refresh dashboard',
                      onPressed: _loadDashboard,
                      icon: const Icon(Icons.refresh_rounded, color: cream),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 26),
              const Text(
                'Dashboard Pelanggan',
                style: TextStyle(
                  color: muted,
                  fontSize: 13,
                  fontFamily: 'Poppins',
                  fontStyle: FontStyle.italic,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Selamat datang, $_fullName!',
                style: const TextStyle(
                  color: cream,
                  fontSize: 17,
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 20),
              _sectionTitle('History Kamu'),
              const SizedBox(height: 12),

              if (_loading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 60),
                  child: Center(child: CircularProgressIndicator(color: cream)),
                )
              else if (_error != null)
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.error_outline, color: cream, size: 30),
                      const SizedBox(height: 10),
                      const Text(
                        'Dashboard gagal dimuat',
                        style: TextStyle(
                          color: cream,
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _error!,
                        style: const TextStyle(
                          color: muted,
                          fontSize: 12,
                          fontFamily: 'Poppins',
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextButton.icon(
                        onPressed: _loadDashboard,
                        icon: const Icon(Icons.refresh, color: cream),
                        label: const Text(
                          'Coba lagi',
                          style: TextStyle(color: cream),
                        ),
                      ),
                    ],
                  ),
                )
              else ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'PESANAN TERAKHIR KAMU',
                        style: TextStyle(
                          color: muted,
                          fontSize: 12,
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '#$_nextOrderNumber',
                        style: const TextStyle(
                          color: cream,
                          fontSize: 24,
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Nomor pesanan akun kamu',
                        style: TextStyle(
                          color: muted,
                          fontSize: 11,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                _metricCard(
                  title: 'TOTAL PEMBELIAN',
                  value: '$_totalProducts produk',
                ),
                const SizedBox(height: 14),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final cardWidth = (constraints.maxWidth - 12) / 2;

                    return Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        SizedBox(
                          width: cardWidth,
                          child: _metricCard(
                            title: 'TOTAL PEMBAYARAN',
                            value: _rupiah(_totalSpending),
                          ),
                        ),
                        SizedBox(
                          width: cardWidth,
                          child: _metricCard(
                            title: 'PRODUK FAVORIT',
                            value: favorite,
                            highlighted: true,
                          ),
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 22),
                _purchaseCard(
                  title: 'Pembelian Bulan Ini - $_monthName',
                  items: _monthlyItems.take(5).toList(),
                  emptyMessage: 'Belum ada pembelian bulan ini.',
                  total: _monthlySpending,
                ),
                const SizedBox(height: 16),
                _purchaseCard(
                  title: 'History All Time',
                  items: _allTimeItems.take(5).toList(),
                  emptyMessage: 'Belum ada riwayat pembelian.',
                  total: _totalSpending,
                ),
              ],
              const SizedBox(height: 22),
              _actionButton(
                text: 'Buka Menu',
                icon: Icons.restaurant_menu_rounded,
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const ProductsPage()),
                  );
                },
              ),
              const SizedBox(height: 12),
              _actionButton(
                text: 'Beri Ulasan',
                icon: Icons.rate_review_outlined,
                onPressed: () => _handleAction(
                  widget.onGiveReview,
                  'Halaman ulasan belum dihubungkan.',
                ),
              ),
              const SizedBox(height: 20),
              const Center(
                child: Text(
                  'Seduh Senja · Dibuat dengan hangat',
                  style: TextStyle(
                    color: muted,
                    fontSize: 11,
                    fontFamily: 'Poppins',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
