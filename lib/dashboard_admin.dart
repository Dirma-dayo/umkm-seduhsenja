import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'olah_menu.dart';
import 'kelola_toping.dart';
import 'history_detail1.dart';
import 'list_barista.dart';

class DashboardAdmin extends StatefulWidget {
  const DashboardAdmin({super.key});

  @override
  State<DashboardAdmin> createState() => _DashboardAdminState();
}

class _DashboardAdminState extends State<DashboardAdmin> {
  static const Color brown = Color(0xFF995631);
  static const Color darkBrown = Color(0xFF5E3007);
  static const Color cream = Color(0xFFFFD5A4);
  static const Color muted = Color(0xFFCF9B84);
  static const Color red = Color(0xFF960909);

  bool loading = true;
  String? error;
  String adminName = 'Admin';

  double totalIncome = 0;
  double monthIncome = 0;
  double todayIncome = 0;

  double totalExpense = 0;
  double monthExpense = 0;

  int todayOrderCount = 0;

  final Map<String, int> todayMenuSales = {};
  final List<Map<String, dynamic>> monthExpenses = [];

  @override
  void initState() {
    super.initState();
    loadDashboard();
  }

  DateTime get today {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  DateTime get monthStart {
    final now = DateTime.now();
    return DateTime(now.year, now.month, 1);
  }

  String money(num value) {
    final digits = value.round().toString();
    final result = StringBuffer();

    for (int i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) {
        result.write('.');
      }
      result.write(digits[i]);
    }

    return 'Rp$result';
  }

  DateTime? parseDate(dynamic value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString())?.toLocal();
  }

  Future<void> loadDashboard() async {
    if (!mounted) return;

    setState(() {
      loading = true;
      error = null;
    });

    try {
      final supabase = Supabase.instance.client;
      final currentUser = supabase.auth.currentUser;

      // 1. DATA ADMIN
      if (currentUser != null) {
        final account = await supabase
            .from('account')
            .select('full_name')
            .eq('id', currentUser.id)
            .maybeSingle();

        final name = account?['full_name']?.toString();

        if (name != null && name.trim().isNotEmpty) {
          adminName = name;
        }
      }

      // 2. DATA PEMASUKAN
      final history = await supabase
          .from('order_history')
          .select('income, date_time');

      double newTotalIncome = 0;
      double newMonthIncome = 0;
      double newTodayIncome = 0;
      int newTodayOrderCount = 0;

      for (final row in List<Map<String, dynamic>>.from(history)) {
        final amount = (row['income'] as num?)?.toDouble() ?? 0;
        final date = parseDate(row['date_time']);

        newTotalIncome += amount;

        if (date != null) {
          if (!date.isBefore(today) &&
              date.isBefore(today.add(const Duration(days: 1)))) {
            newTodayIncome += amount;
            newTodayOrderCount++;
          }

          if (!date.isBefore(monthStart)) {
            newMonthIncome += amount;
          }
        }
      }

      // 3. DATA PENGELUARAN
      final shoppingData = await supabase
          .from('shopping_history')
          .select('id, name, quantity, price, total, date_time')
          .order('date_time', ascending: false);

      double newTotalExpense = 0;
      double newMonthExpense = 0;

      final newMonthExpenses = <Map<String, dynamic>>[];

      for (final row in List<Map<String, dynamic>>.from(shoppingData)) {
        final amount = (row['total'] as num?)?.toDouble() ?? 0;
        final date = parseDate(row['date_time']);

        newTotalExpense += amount;

        if (date != null &&
            !date.isBefore(monthStart) &&
            date.isBefore(DateTime.now().add(const Duration(seconds: 1)))) {
          newMonthExpense += amount;

          newMonthExpenses.add({
            'id': row['id'],
            'name': row['name'] ?? 'Barang lainnya',
            'quantity': row['quantity'] ?? 0,
            'price': row['price'] ?? 0,
            'total': amount,
            'date_time': date,
          });
        }
      }

      // 4. PESANAN HARI INI
      final orderData = await supabase
          .from('order_entry')
          .select('id, date_time');

      final todayOrderIds = <int>[];

      for (final row in List<Map<String, dynamic>>.from(orderData)) {
        final date = parseDate(row['date_time']);

        if (date != null &&
            !date.isBefore(today) &&
            date.isBefore(today.add(const Duration(days: 1)))) {
          final id = row['id'];

          if (id is num) {
            todayOrderIds.add(id.toInt());
          }
        }
      }

      // 5. MENU TERJUAL
      final newMenuSales = <String, int>{};

      if (todayOrderIds.isNotEmpty) {
        final itemData = await supabase
            .from('order_items')
            .select('order_id, menu_name, quantity')
            .inFilter('order_id', todayOrderIds);

        for (final row in List<Map<String, dynamic>>.from(itemData)) {
          final name = (row['menu_name'] ?? 'Menu lainnya').toString();
          final quantity = (row['quantity'] as num?)?.toInt() ?? 0;

          newMenuSales[name] = (newMenuSales[name] ?? 0) + quantity;
        }
      }

      if (!mounted) return;

      setState(() {
        totalIncome = newTotalIncome;
        monthIncome = newMonthIncome;
        todayIncome = newTodayIncome;

        totalExpense = newTotalExpense;
        monthExpense = newMonthExpense;

        todayOrderCount = newTodayOrderCount;

        todayMenuSales
          ..clear()
          ..addAll(newMenuSales);

        monthExpenses
          ..clear()
          ..addAll(newMonthExpenses);

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

  String dateLabel(DateTime date) {
    const months = [
      'JANUARI',
      'FEBRUARI',
      'MARET',
      'APRIL',
      'MEI',
      'JUNI',
      'JULI',
      'AGUSTUS',
      'SEPTEMBER',
      'OKTOBER',
      'NOVEMBER',
      'DESEMBER',
    ];

    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  Widget summaryCard(
    String title,
    String value, {
    Color background = darkBrown,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: muted,
                fontSize: 12,
                fontWeight: FontWeight.w900,
                fontFamily: 'Poppins',
              ),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                color: cream,
                fontSize: 16,
                fontWeight: FontWeight.w700,
                fontFamily: 'Poppins',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget panel(String title, Widget child) {
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
              color: darkBrown,
              fontSize: 16,
              fontWeight: FontWeight.w600,
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget dataRow(String name, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              name,
              style: const TextStyle(
                color: darkBrown,
                fontSize: 14,
                fontFamily: 'Poppins',
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            value,
            style: const TextStyle(
              color: darkBrown,
              fontSize: 14,
              fontWeight: FontWeight.w600,
              fontFamily: 'Poppins',
            ),
          ),
        ],
      ),
    );
  }

  // TOMBOL NAVIGASI
  Widget navigationButton(String title, VoidCallback onPressed) {
    return SizedBox(
      width: double.infinity,
      height: 42,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: cream,
          foregroundColor: darkBrown,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Text(
          title,
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  // PANTAU BARISTA
  Widget tombolPantauBarista() {
    return navigationButton('Pantau Barista', () {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => ListBarista()),
      );
    });
  }

  // TAMBAH BARISTA
  Widget tombolTambahBarista() {
    return navigationButton('Tambah Barista', () {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => ListBarista()),
      );
    });
  }

  // OLAH MENU
  Widget tombolOlahMenu() {
    return navigationButton('Olah Menu', () {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const OlahMenu()),
      );
    });
  }

  // KELOLA TOPPING
  Widget tombolKelolaTopping() {
    return navigationButton('Kelola Topping', () {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const KelolaTopping()),
      );
    });
  }

  // RIWAYAT PESANAN
  Widget tombolRiwayatPesanan() {
    return navigationButton('Riwayat Pesanan', () {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => HistoryDetail()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();

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
        actions: [
          IconButton(
            onPressed: loading ? null : loadDashboard,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh dashboard',
          ),
        ],
      ),
      body: SafeArea(
        child: loading
            ? const Center(child: CircularProgressIndicator(color: cream))
            : RefreshIndicator(
                color: brown,
                onRefresh: loadDashboard,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
                  children: [
                    const Text(
                      'Dashboard Pemilik',
                      style: TextStyle(
                        color: muted,
                        fontSize: 14,
                        fontStyle: FontStyle.italic,
                        fontFamily: 'Poppins',
                      ),
                    ),

                    const SizedBox(height: 6),

                    Text(
                      'Selamat datang, $adminName!',
                      style: const TextStyle(
                        color: cream,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Poppins',
                      ),
                    ),

                    const SizedBox(height: 4),

                    const Text(
                      'Kelola keuangan hari ini',
                      style: TextStyle(
                        color: cream,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Poppins',
                      ),
                    ),

                    if (error != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: cream,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Gagal mengambil data: $error',
                          style: const TextStyle(color: red, fontSize: 12),
                        ),
                      ),
                    ],

                    const SizedBox(height: 16),

                    // TOTAL UANG
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: darkBrown,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'TOTAL UANG',
                            style: TextStyle(
                              color: muted,
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                              fontFamily: 'Poppins',
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            money(totalIncome - totalExpense),
                            style: const TextStyle(
                              color: cream,
                              fontSize: 30,
                              fontWeight: FontWeight.w700,
                              fontFamily: 'Poppins',
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // PEMASUKAN DAN PENGELUARAN
                    Row(
                      children: [
                        summaryCard('PEMASUKAN', money(monthIncome)),
                        const SizedBox(width: 12),
                        summaryCard(
                          'PENGELUARAN',
                          money(monthExpense),
                          background: red,
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // RINCIAN PENGELUARAN
                    panel(
                      'Pengeluaran Bulan Ini - ${dateLabel(now)}',
                      Column(
                        children: [
                          if (monthExpenses.isEmpty)
                            const Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                'Belum ada pengeluaran bulan ini.',
                                style: TextStyle(color: darkBrown),
                              ),
                            )
                          else
                            ...monthExpenses.map((expense) {
                              return Column(
                                children: [
                                  dataRow(
                                    expense['name'].toString(),
                                    money(expense['total'] as num),
                                  ),
                                  Align(
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      '${expense['quantity']} barang × '
                                      '${money(expense['price'] as num)}',
                                      style: const TextStyle(
                                        color: darkBrown,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                ],
                              );
                            }),
                          const Divider(color: brown),
                          dataRow('Total Pengeluaran', money(monthExpense)),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // PEMASUKAN HARI INI
                    panel(
                      'Pemasukan Hari Ini - ${dateLabel(now)}',
                      Column(
                        children: [
                          dataRow('Total', money(todayIncome)),
                          const Divider(color: brown),

                          if (todayMenuSales.isEmpty)
                            const Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                'Belum ada penjualan menu hari ini.',
                                style: TextStyle(color: darkBrown),
                              ),
                            )
                          else
                            ...todayMenuSales.entries.map(
                              (entry) =>
                                  dataRow(entry.key, entry.value.toString()),
                            ),

                          const Divider(color: brown),

                          dataRow(
                            'Jumlah transaksi',
                            todayOrderCount.toString(),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // MENU DASHBOARD
                    tombolPantauBarista(),

                    const SizedBox(height: 10),

                    tombolTambahBarista(),

                    const SizedBox(height: 10),

                    navigationButton('Kelola Keuangan', () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Kelola Keuangan belum dihubungkan.'),
                        ),
                      );
                    }),

                    const SizedBox(height: 10),

                    tombolOlahMenu(),

                    const SizedBox(height: 10),

                    tombolKelolaTopping(),

                    const SizedBox(height: 10),

                    tombolRiwayatPesanan(),
                  ],
                ),
              ),
      ),
    );
  }
}
