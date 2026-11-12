import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class HistoryDetail extends StatefulWidget {
  const HistoryDetail({super.key});

  @override
  State<HistoryDetail> createState() => _HistoryDetailState();
}

class _HistoryDetailState extends State<HistoryDetail> {
  static const Color brown = Color(0xFF995631);
  static const Color darkBrown = Color(0xFF5E3007);
  static const Color cream = Color(0xFFFFD5A4);
  static const Color lightCream = Color(0xFFFFE5C4);

  bool loading = true;
  List<Map<String, dynamic>> expenses = [];

  final supabase = Supabase.instance.client;

  final List<String> months = [
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

  @override
  void initState() {
    super.initState();
    loadExpenses();
  }

  // Mengambil data pengeluaran dari Supabase
  Future<void> loadExpenses() async {
    if (mounted) {
      setState(() {
        loading = true;
      });
    }

    try {
      final data = await supabase
          .from('shopping_history')
          .select('id, name, quantity, price, total, date_time')
          .order('date_time', ascending: false);

      if (!mounted) return;

      setState(() {
        expenses = List<Map<String, dynamic>>.from(data);
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        loading = false;
      });

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Gagal mengambil data: $e')));
    }
  }

  // Format Rupiah
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

  // Mengubah tanggal dari Supabase
  DateTime? parseDate(dynamic value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString())?.toLocal();
  }

  // Nama bulan dan tahun
  String monthLabel(DateTime date) {
    return '${months[date.month - 1]} ${date.year}';
  }

  // Mengelompokkan pengeluaran berdasarkan bulan
  Map<String, List<Map<String, dynamic>>> get groupedExpenses {
    final Map<String, List<Map<String, dynamic>>> grouped = {};

    for (final expense in expenses) {
      final date = parseDate(expense['date_time']);
      if (date == null) continue;

      final key = '${date.year}-${date.month}';
      grouped.putIfAbsent(key, () => []);
      grouped[key]!.add(expense);
    }

    return grouped;
  }

  // Menghitung total pengeluaran dalam satu bulan
  double monthTotal(List<Map<String, dynamic>> data) {
    double total = 0;

    for (final item in data) {
      total += (item['total'] as num?)?.toDouble() ?? 0;
    }

    return total;
  }

  // Form tambah pengeluaran
  Future<void> showAddExpenseDialog() async {
    final nameController = TextEditingController();
    final quantityController = TextEditingController();
    final priceController = TextEditingController();

    await showDialog(
      context: context,
      builder: (dialogContext) {
        bool saving = false;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: cream,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: const Text(
                'Tambah entri baru',
                style: TextStyle(
                  color: darkBrown,
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w700,
                ),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    expenseInput(
                      controller: nameController,
                      label: 'Nama barang',
                      hint: 'Contoh: Kopi',
                    ),
                    const SizedBox(height: 12),
                    expenseInput(
                      controller: quantityController,
                      label: 'Jumlah barang',
                      hint: 'Contoh: 2',
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 12),
                    expenseInput(
                      controller: priceController,
                      label: 'Harga satuan',
                      hint: 'Contoh: 20000',
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: saving ? null : () => Navigator.pop(dialogContext),
                  child: const Text(
                    'Batal',
                    style: TextStyle(color: darkBrown),
                  ),
                ),
                ElevatedButton(
                  onPressed: saving
                      ? null
                      : () async {
                          final name = nameController.text.trim();
                          final quantity = int.tryParse(
                            quantityController.text.trim(),
                          );
                          final price = double.tryParse(
                            priceController.text.trim().replaceAll(',', '.'),
                          );

                          if (name.isEmpty ||
                              quantity == null ||
                              quantity <= 0 ||
                              price == null ||
                              price < 0) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Isi semua data dengan benar.'),
                              ),
                            );
                            return;
                          }

                          setDialogState(() {
                            saving = true;
                          });

                          try {
                            final total = quantity * price;

                            await supabase.from('shopping_history').insert({
                              'name': name,
                              'quantity': quantity,
                              'price': price,
                              'total': total,
                              'date_time': DateTime.now().toIso8601String(),
                            });

                            if (!dialogContext.mounted) return;
                            Navigator.pop(dialogContext);

                            await loadExpenses();

                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Pengeluaran berhasil ditambahkan.',
                                ),
                              ),
                            );
                          } catch (e) {
                            setDialogState(() {
                              saving = false;
                            });

                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Gagal menyimpan pengeluaran: $e',
                                ),
                              ),
                            );
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: darkBrown,
                    foregroundColor: cream,
                  ),
                  child: saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: cream,
                          ),
                        )
                      : const Text('Simpan'),
                ),
              ],
            );
          },
        );
      },
    );

    nameController.dispose();
    quantityController.dispose();
    priceController.dispose();
  }

  // Input pada form
  Widget expenseInput({
    required TextEditingController controller,
    required String label,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: const TextStyle(color: darkBrown, fontFamily: 'Poppins'),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: const TextStyle(color: darkBrown),
        hintStyle: const TextStyle(color: brown),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: brown),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: darkBrown, width: 2),
        ),
      ),
    );
  }

  // Kartu satu pengeluaran
  Widget expenseItem(Map<String, dynamic> expense) {
    final name = expense['name']?.toString() ?? 'Barang lainnya';
    final quantity = (expense['quantity'] as num?)?.toInt() ?? 0;
    final price = (expense['price'] as num?)?.toDouble() ?? 0;
    final total = (expense['total'] as num?)?.toDouble() ?? 0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 5,
            child: Text(
              '$name\n$quantity barang × ${money(price)}',
              style: const TextStyle(
                color: darkBrown,
                fontSize: 13,
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 4,
            child: Text(
              money(total),
              textAlign: TextAlign.end,
              style: const TextStyle(
                color: darkBrown,
                fontSize: 13,
                fontFamily: 'Poppins',
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Kartu pengeluaran per bulan
  Widget monthCard(String title, List<Map<String, dynamic>> data) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cream,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: darkBrown,
              fontSize: 16,
              fontWeight: FontWeight.w700,
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 16),

          if (data.isEmpty)
            const Text(
              'Belum ada pengeluaran.',
              style: TextStyle(color: darkBrown),
            )
          else
            ...data.map(expenseItem),

          const Divider(color: brown),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total',
                style: TextStyle(
                  color: darkBrown,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Poppins',
                ),
              ),
              Text(
                money(monthTotal(data)),
                style: const TextStyle(
                  color: darkBrown,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  fontFamily: 'Poppins',
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
    final grouped = groupedExpenses;
    final groupKeys = grouped.keys.toList()
      ..sort((a, b) {
        final dateA = a.split('-').map(int.parse).toList();
        final dateB = b.split('-').map(int.parse).toList();

        final valueA = dateA[0] * 100 + dateA[1];
        final valueB = dateB[0] * 100 + dateB[1];

        return valueB.compareTo(valueA);
      });

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
            onPressed: loading ? null : loadExpenses,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
              child: SizedBox(
                width: double.infinity,
                height: 42,
                child: ElevatedButton.icon(
                  onPressed: showAddExpenseDialog,
                  icon: const Icon(Icons.add),
                  label: const Text(
                    'Tambah entri baru',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: cream,
                    foregroundColor: darkBrown,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: cream,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                ),
                child: loading
                    ? const Center(
                        child: CircularProgressIndicator(color: brown),
                      )
                    : expenses.isEmpty
                    ? const Center(
                        child: Text(
                          'Belum ada data pengeluaran.',
                          style: TextStyle(
                            color: darkBrown,
                            fontFamily: 'Poppins',
                          ),
                        ),
                      )
                    : RefreshIndicator(
                        color: brown,
                        onRefresh: loadExpenses,
                        child: ListView(
                          padding: const EdgeInsets.all(16),
                          children: [
                            if (groupKeys.isNotEmpty)
                              ...groupKeys.map((key) {
                                final data = grouped[key]!;
                                final firstDate = parseDate(
                                  data.first['date_time'],
                                );

                                if (firstDate == null) {
                                  return const SizedBox.shrink();
                                }

                                final now = DateTime.now();
                                final isCurrentMonth =
                                    firstDate.year == now.year &&
                                    firstDate.month == now.month;

                                return monthCard(
                                  isCurrentMonth
                                      ? 'Pengeluaran Bulan Ini'
                                      : 'Pengeluaran Bulan ${monthLabel(firstDate)}',
                                  data,
                                );
                              }),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: lightCream,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(
                                    Icons.info_outline,
                                    color: darkBrown,
                                    size: 18,
                                  ),
                                  SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Entri baru akan tercatat sesuai tanggal saat pengeluaran ditambahkan.',
                                      style: TextStyle(
                                        color: darkBrown,
                                        fontSize: 11,
                                        fontStyle: FontStyle.italic,
                                        fontFamily: 'Poppins',
                                      ),
                                    ),
                                  ),
                                ],
                              ),
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
