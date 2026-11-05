
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class UlasanPage extends StatefulWidget {
  const UlasanPage({super.key});

  @override
  State<UlasanPage> createState() => _UlasanPageState();
}

class _UlasanPageState extends State<UlasanPage> {
  static const Color background = Color(0xFF995631);
  static const Color cream = Color(0xFFFFD5A4);
  static const Color burgundy = Color(0xFF960909);
  static const Color darkBrown = Color(0xFF5E3007);
  static const Color lightCream = Color(0xFFFFE5C4);

  final SupabaseClient supabase = Supabase.instance.client;

  List<Map<String, dynamic>> products = [];
  List<Map<String, dynamic>> reviews = [];

  bool isLoading = true;
  bool isLoadingReviews = true;
  bool isSubmitting = false;

  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _loadProducts();
    _loadReviews();
  }

  // LOAD PRODUCTS
  Future<void> _loadProducts() async {
    try {
      final response = await supabase
          .from('menu')
          .select('id, name, calories, price')
          .order('name');

      if (!mounted) return;

      setState(() {
        products = List<Map<String, dynamic>>.from(response);
        isLoading = false;
        errorMessage = null;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        errorMessage = e.toString();
        isLoading = false;
      });
    }
  }

  // LOAD OTHER REVIEWS
  Future<void> _loadReviews() async {
    try {
      final response = await supabase
          .from('ulasan')
          .select('id, buyer_id, menu_id, subject, complaint_text, date_time')
          .order('date_time', ascending: false);

      if (!mounted) return;

      setState(() {
        reviews = List<Map<String, dynamic>>.from(response);
        isLoadingReviews = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoadingReviews = false;
      });
    }
  }

  num _number(dynamic value) {
    if (value is num) return value;
    return num.tryParse(value?.toString() ?? '') ?? 0;
  }

  String _formatPrice(dynamic value) {
    final price = _number(value).toInt();

    final formatted = price.toString().replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (match) => '.',
    );

    return 'Rp $formatted';
  }

  // SUBMIT REVIEW
  Future<void> _submitReview({
    required Map<String, dynamic> product,
    required String review,
  }) async {
    final user = supabase.auth.currentUser;

    if (user == null) {
      throw Exception('Silakan login terlebih dahulu.');
    }

    await supabase.from('complain').insert({
      'buyer_id': user.id,
      'menu_id': product['id'],
      'subject': 'Ulasan ${product['name']}',
      'complaint_text': review,
      'date_time': DateTime.now().toIso8601String(),
    });

    await _loadReviews();
  }

  // REVIEW FORM
  void _showReviewForm(Map<String, dynamic> product) {
    final reviewController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Container(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 28),
                decoration: const BoxDecoration(
                  color: cream,
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(28),
                  ),
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 42,
                          height: 5,
                          decoration: BoxDecoration(
                            color: background.withValues(alpha: 0.4),
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      const Text(
                        'TULIS ULASAN',
                        style: TextStyle(
                          color: darkBrown,
                          fontSize: 21,
                          fontWeight: FontWeight.w900,
                          fontFamily: 'Poppins',
                        ),
                      ),

                      const SizedBox(height: 6),

                      Text(
                        product['name']?.toString() ?? 'Produk',
                        style: const TextStyle(
                          color: burgundy,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'Poppins',
                        ),
                      ),

                      const SizedBox(height: 20),

                      const Text(
                        'Ceritakan pengalamanmu',
                        style: TextStyle(
                          color: darkBrown,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'Poppins',
                        ),
                      ),

                      const SizedBox(height: 10),

                      TextField(
                        controller: reviewController,
                        maxLines: 4,
                        maxLength: 500,
                        decoration: InputDecoration(
                          hintText: 'Tulis ulasanmu di sini...',
                          hintStyle: const TextStyle(
                            color: background,
                            fontSize: 12,
                            fontFamily: 'Poppins',
                          ),
                          filled: true,
                          fillColor: lightCream,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: background,
                            foregroundColor: cream,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                          ),
                          onPressed: isSubmitting
                              ? null
                              : () async {
                                  final review =
                                      reviewController.text.trim();

                                  if (review.isEmpty) {
                                    ScaffoldMessenger.of(context)
                                        .showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Silakan tulis ulasan terlebih dahulu.',
                                        ),
                                      ),
                                    );
                                    return;
                                  }

                                  setSheetState(() {
                                    isSubmitting = true;
                                  });

                                  try {
                                    await _submitReview(
                                      product: product,
                                      review: review,
                                    );

                                    if (!mounted) return;

                                    Navigator.pop(sheetContext);

                                    ScaffoldMessenger.of(this.context)
                                        .showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Ulasan berhasil dikirim!',
                                        ),
                                      ),
                                    );
                                  } catch (e) {
                                    setSheetState(() {
                                      isSubmitting = false;
                                    });

                                    ScaffoldMessenger.of(this.context)
                                        .showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'Gagal mengirim ulasan: $e',
                                        ),
                                      ),
                                    );
                                  }
                                },
                          child: isSubmitting
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: cream,
                                  ),
                                )
                              : const Text(
                                  'Kirim Ulasan',
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
              ),
            );
          },
        );
      },
    ).whenComplete(() {
      reviewController.dispose();
    });
  }

  // PRODUCT CARD
  Widget _buildProductCard(Map<String, dynamic> product) {
    return GestureDetector(
      onTap: () => _showReviewForm(product),
      child: Container(
        height: 120,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: cream,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              width: 94,
              height: 94,
              decoration: BoxDecoration(
                color: lightCream,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.local_cafe_rounded,
                color: background,
                size: 48,
              ),
            ),

            const SizedBox(width: 16),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    product['name']?.toString() ?? 'Produk',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: burgundy,
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'Poppins',
                    ),
                  ),

                  const SizedBox(height: 5),

                  Text(
                    _formatPrice(product['price']),
                    style: const TextStyle(
                      color: burgundy,
                      fontSize: 13,
                      fontStyle: FontStyle.italic,
                      fontFamily: 'Poppins',
                    ),
                  ),

                  const SizedBox(height: 3),

                  Text(
                    '${_number(product['calories']).toInt()} Kal',
                    style: const TextStyle(
                      color: burgundy,
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                      fontFamily: 'Poppins',
                    ),
                  ),

                  const SizedBox(height: 5),

                  const Text(
                    'Ketuk untuk mengulas',
                    style: TextStyle(
                      color: background,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ],
              ),
            ),

            const Icon(
              Icons.chevron_right_rounded,
              color: burgundy,
              size: 26,
            ),
          ],
        ),
      ),
    );
  }

  // OTHER REVIEWS CARD
  Widget _buildReviewCard(Map<String, dynamic> review) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cream,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            review['subject']?.toString() ?? 'Ulasan pelanggan',
            style: const TextStyle(
              color: burgundy,
              fontSize: 14,
              fontWeight: FontWeight.w800,
              fontFamily: 'Poppins',
            ),
          ),

          const SizedBox(height: 8),

          Text(
            review['complaint_text']?.toString() ?? '',
            style: const TextStyle(
              color: darkBrown,
              fontSize: 12,
              fontFamily: 'Poppins',
            ),
          ),

          const SizedBox(height: 8),

          Text(
            review['date_time']?.toString() ?? '',
            style: const TextStyle(
              color: background,
              fontSize: 10,
              fontFamily: 'Poppins',
            ),
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
        child: RefreshIndicator(
          onRefresh: () async {
            await Future.wait([
              _loadProducts(),
              _loadReviews(),
            ]);
          },
          color: background,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 30, 24, 32),
            children: [
              const SizedBox(height: 12),

              const Text(
                'Pilih produk yang akan diulas',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: cream,
                  fontSize: 21,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Poppins',
                ),
              ),

              const SizedBox(height: 32),

              if (isLoading)
                const Padding(
                  padding: EdgeInsets.all(40),
                  child: Center(
                    child: CircularProgressIndicator(
                      color: cream,
                    ),
                  ),
                )
              else if (errorMessage != null)
                Column(
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: cream,
                      size: 42,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      errorMessage!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: cream,
                        fontFamily: 'Poppins',
                      ),
                    ),
                    TextButton(
                      onPressed: _loadProducts,
                      child: const Text(
                        'Coba lagi',
                        style: TextStyle(color: cream),
                      ),
                    ),
                  ],
                )
              else if (products.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(30),
                  child: Text(
                    'Belum ada produk tersedia.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: cream,
                      fontFamily: 'Poppins',
                    ),
                  ),
                )
              else
                ...products.map(
                  (product) => Padding(
                    padding: const EdgeInsets.only(bottom: 15),
                    child: _buildProductCard(product),
                  ),
                ),

              const SizedBox(height: 24),

              Container(
                height: 48,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: cream,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Text(
                  'Ulasan Lain',
                  style: TextStyle(
                    color: burgundy,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Poppins',
                  ),
                ),
              ),

              const SizedBox(height: 16),

              if (isLoadingReviews)
                const Center(
                  child: CircularProgressIndicator(color: cream),
                )
              else if (reviews.isEmpty)
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: lightCream,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Column(
                    children: [
                      Icon(
                        Icons.rate_review_outlined,
                        color: background,
                        size: 36,
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Belum ada ulasan',
                        style: TextStyle(
                          color: darkBrown,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ],
                  ),
                )
              else
                ...reviews.map(_buildReviewCard),
            ],
          ),
        ),
      ),
    );
  }
}
