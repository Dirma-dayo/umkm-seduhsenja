import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Halaman daftar pesanan dari tabel `order_entry` di Supabase.
///
/// Pastikan Supabase.initialize(...) sudah dijalankan di main.dart
/// sebelum halaman ini dibuka.
class OrderEntryPage extends StatefulWidget {
  const OrderEntryPage({super.key});

  @override
  State<OrderEntryPage> createState() => _OrderEntryPageState();
}

class _OrderEntryPageState extends State<OrderEntryPage> {
  static const Color _brown = Color(0xFF995631);
  static const Color _darkBrown = Color(0xFF5E3007);
  static const Color _cream = Color(0xFFFFD5A4);

  late Future<List<Map<String, dynamic>>> _ordersFuture;

  @override
  void initState() {
    super.initState();
    _ordersFuture = _loadOrders();
  }

  Future<List<Map<String, dynamic>>> _loadOrders() async {
    final response = await Supabase.instance.client
        .from('order_entry')
        .select(
          'id, buyer_id, customer_name, order_type, table_num, '
          'subtotal, discount_amount, total, customer_order_number, '
          'status, date_time',
        )
        .order('date_time', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  }

  Future<void> _refreshOrders() async {
    final newFuture = _loadOrders();
    setState(() {
      _ordersFuture = newFuture;
    });
    await newFuture;
  }

  String _rupiah(dynamic value) {
    final amount = (value as num?)?.toDouble() ?? 0;
    final rounded = amount.round();
    final digits = rounded.toString();
    final result = StringBuffer();

    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) {
        result.write('.');
      }
      result.write(digits[i]);
    }
    return 'Rp$result';
  }

  String _dateTime(dynamic value) {
    if (value == null) return '-';

    final date = DateTime.tryParse(value.toString())?.toLocal();
    if (date == null) return value.toString();

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

    final day = date.day.toString().padLeft(2, '0');
    final month = months[date.month - 1];
    final year = date.year;
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');

    return '$day $month $year • $hour:$minute';
  }

  String _statusLabel(dynamic value) {
    final status = (value ?? 'Belum ada status').toString().trim();
    if (status.isEmpty) return 'Belum ada status';

    // Tampilkan nilai asli dari database agar tidak mengubah status pesanan.
    return status
        .replaceAll('_', ' ')
        .split(' ')
        .map((word) => word.isEmpty
            ? word
            : '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}')
        .join(' ');
  }

  String _orderType(dynamic value) {
    final type = (value ?? '').toString().trim();
    return type.isEmpty ? '-' : type;
  }

  Widget _infoRow(String label, String value, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: _brown,
                fontSize: 14,
                fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                color: _brown,
                fontSize: 14,
                fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _orderCard(Map<String, dynamic> order) {
    final tableNum = order['table_num'];
    final orderNumber = order['customer_order_number'];
    final customerName =
        (order['customer_name'] ?? 'Pelanggan').toString();
    final status = _statusLabel(order['status']);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _brown,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  orderNumber == null
                      ? 'Pesanan #${order['id']}'
                      : 'Pesanan #$orderNumber',
                  style: const TextStyle(
                    color: _cream,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: _cream,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    status,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: _brown,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _dateTime(order['date_time']),
            style: const TextStyle(
              color: _cream,
              fontSize: 12,
              fontWeight: FontWeight.w300,
            ),
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: _cream,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  customerName,
                  style: const TextStyle(
                    color: _brown,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
                _infoRow(
                  'Jenis pesanan',
                  _orderType(order['order_type']),
                ),
                _infoRow(
                  'Nomor meja',
                  tableNum == null ? '-' : 'Meja $tableNum',
                ),
                const Divider(color: _brown, height: 18),
                _infoRow('Subtotal', _rupiah(order['subtotal'])),
                _infoRow(
                  'Diskon',
                  _rupiah(order['discount_amount']),
                ),
                const Divider(color: _brown, height: 18),
                _infoRow('Total', _rupiah(order['total']), bold: true),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _brown,
      appBar: AppBar(
        backgroundColor: _brown,
        foregroundColor: _cream,
        elevation: 0,
        title: const Text(
          'Seduh Senja',
          style: TextStyle(
            color: _cream,
            fontSize: 22,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Muat ulang pesanan',
            onPressed: _refreshOrders,
            icon: const Icon(Icons.refresh, color: _cream),
          ),
        ],
      ),
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          color: _cream,
          borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
        ),
        child: FutureBuilder<List<Map<String, dynamic>>>(
          future: _ordersFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: _brown),
              );
            }

            if (snapshot.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error_outline,
                          color: _brown, size: 42),
                      const SizedBox(height: 12),
                      const Text(
                        'Gagal mengambil data pesanan.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: _brown,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        snapshot.error.toString(),
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: _brown, fontSize: 12),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _refreshOrders,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Coba lagi'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _brown,
                          foregroundColor: _cream,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            final orders = snapshot.data ?? [];

            if (orders.isEmpty) {
              return RefreshIndicator(
                color: _brown,
                onRefresh: _refreshOrders,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: const [
                    SizedBox(height: 180),
                    Icon(Icons.receipt_long, color: _brown, size: 54),
                    SizedBox(height: 12),
                    Center(
                      child: Text(
                        'Belum ada pesanan.',
                        style: TextStyle(
                          color: _brown,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }

            return RefreshIndicator(
              color: _brown,
              onRefresh: _refreshOrders,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
                children: [
                  const Text(
                    'Daftar Pesanan',
                    style: TextStyle(
                      color: _brown,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${orders.length} pesanan',
                    style: const TextStyle(
                      color: _brown,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ...orders.map(_orderCard),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
