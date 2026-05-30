import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../core/constants/api_constants.dart';
import '../../core/services/language_settings.dart';
import '../../features/auth/auth_service.dart';
import '../../shared/themes/color_scheme.dart';
import '../../shared/widgets/design/layout/custom_app_bar.dart';
import '../../shared/widgets/design/layout/footer.dart';

class ReviewsPage extends StatefulWidget {
  const ReviewsPage({super.key});

  @override
  State<ReviewsPage> createState() => _ReviewsPageState();
}

class _ReviewsPageState extends State<ReviewsPage> {
  static const Color _blue = Color(0xFF003B95);
  static const Color _accent = Color(0xFF0071C2);

  List<Map<String, dynamic>> _reviews = [];
  bool _isLoadingReviews = true;
  bool _isSubmitting = false;

  // Form state
  final TextEditingController _commentController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  int _selectedHotelId = 0;
  String _selectedHotelName = '';
  double _rating = 5.0;
  List<Map<String, dynamic>> _hoteles = [];
  bool _formExpanded = false;
  String _filterQuery = '';

  static const List<Map<String, dynamic>> _mockReviews = [
    {
      'id': 1,
      'hotelName': 'Hotel Paradiso',
      'userName': 'María García',
      'userInitial': 'M',
      'rating': 4.5,
      'comment':
          'Excelente ubicación y servicio. Las habitaciones son muy cómodas y el personal muy atento.',
      'daysAgo': 5,
    },
    {
      'id': 2,
      'hotelName': 'Costa Azul Resort',
      'userName': 'Carlos Rodríguez',
      'userInitial': 'C',
      'rating': 5.0,
      'comment':
          'Increíble experiencia. El spa es maravilloso y la comida exquisita. Repetiré sin duda.',
      'daysAgo': 12,
    },
    {
      'id': 3,
      'hotelName': 'Mountain View Hotel',
      'userName': 'Ana López',
      'userInitial': 'A',
      'rating': 3.5,
      'comment':
          'Buena relación calidad-precio. Las vistas son espectaculares pero el WiFi era lento.',
      'daysAgo': 20,
    },
    {
      'id': 4,
      'hotelName': 'Grand Plaza',
      'userName': 'Luis Martínez',
      'userInitial': 'L',
      'rating': 4.0,
      'comment':
          'Hotel céntrico con instalaciones modernas. El desayuno buffet está muy bien.',
      'daysAgo': 30,
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadReviews();
    _loadHoteles();
  }

  @override
  void dispose() {
    _commentController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadHoteles() async {
    try {
      final response = await http
          .get(Uri.parse('${ApiConstants.baseUrl}/hoteles'))
          .timeout(const Duration(seconds: 15));

      if (!mounted) return;
      if (response.statusCode != 200) return;

      final body = jsonDecode(response.body);
      if (body is! List) return;

      setState(() {
        _hoteles = body
            .whereType<Map>()
            .map<Map<String, dynamic>>((h) => {
                  'id': _parseInt(h['id_hotel']),
                  'name': h['nombre']?.toString() ?? 'Hotel',
                  'city': h['ciudad_nombre']?.toString() ?? '',
                })
            .toList();
      });
    } catch (_) {
      // Hotels list is optional for viewing reviews; fail silently
    }
  }

  Future<void> _loadReviews() async {
    if (!mounted) return;
    setState(() {
      _isLoadingReviews = true;
    });

    try {
      final response = await http
          .get(Uri.parse('${ApiConstants.baseUrl}/reviews'))
          .timeout(const Duration(seconds: 15));

      if (!mounted) return;

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        final raw = body is List
            ? body
            : body is Map && body['data'] is List
                ? body['data'] as List
                : null;

        if (raw != null) {
          final reviews = raw
              .whereType<Map>()
              .map<Map<String, dynamic>>((r) {
                DateTime date;
                try {
                  date = r['fecha'] != null
                      ? DateTime.parse(r['fecha'].toString())
                      : DateTime.now();
                } catch (_) {
                  date = DateTime.now();
                }
                final name = r['usuario_nombre']?.toString() ?? 'Usuario';
                final hotel = r['hotel_nombre']?.toString() ??
                    _hoteles.firstWhere(
                      (h) => _parseInt(h['id']) == _parseInt(r['id_hotel']),
                      orElse: () => {'name': 'Hotel'},
                    )['name']?.toString() ?? 'Hotel';
                return {
                  'id': _parseInt(r['id_review']),
                  'hotelName': hotel,
                  'userName': name,
                  'userInitial': name.isNotEmpty ? name[0].toUpperCase() : '?',
                  'rating': _parseDouble(r['puntuacion']),
                  'comment': r['comentario']?.toString() ?? '',
                  'date': date,
                };
              })
              .toList();

          setState(() {
            _reviews = reviews;
            _isLoadingReviews = false;
          });
          return;
        }
      }
      // Fall through to mock data if endpoint is unavailable or returns unexpected format
      _useMockReviews();
    } catch (_) {
      if (!mounted) return;
      _useMockReviews();
    }
  }

  void _useMockReviews() {
    setState(() {
      _reviews = _mockReviews.map<Map<String, dynamic>>((r) => {
            ...r,
            'date': DateTime.now()
                .subtract(Duration(days: r['daysAgo'] as int)),
          }).toList();
      _isLoadingReviews = false;
    });
  }

  Future<void> _submitReview() async {
    if (_selectedHotelId == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(LanguageSettings.instance.tr('reviews_select_hotel_alert')),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    if (_commentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(LanguageSettings.instance.tr('reviews_add_comment_alert')),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final token = AuthService().token;
    if (token == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(LanguageSettings.instance.tr('reviews_login_required')),
          backgroundColor: Colors.orange,
        ),
      );
      setState(() => _isSubmitting = false);
      return;
    }

    try {
      final response = await http
          .post(
            Uri.parse('${ApiConstants.baseUrl}/reviews'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode({
              'id_hotel': _selectedHotelId,
              'puntuacion': _rating,
              'comentario': _commentController.text.trim(),
              'fecha': DateTime.now().toIso8601String(),
            }),
          )
          .timeout(const Duration(seconds: 15));

      if (!mounted) return;

      if (response.statusCode == 200 || response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(LanguageSettings.instance.tr('reviews_thanks')),
            backgroundColor: Colors.green,
          ),
        );
        _commentController.clear();
        setState(() {
          _selectedHotelId = 0;
          _selectedHotelName = '';
          _rating = 5.0;
          _formExpanded = false;
        });
        _loadReviews();
      } else {
        throw Exception('HTTP ${response.statusCode}');
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(LanguageSettings.instance.tr('reviews_submit_error')),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _deleteReview(int idReview) async {
    final token = AuthService().token;
    if (token == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(LanguageSettings.instance.tr('reviews_delete_title')),
        content: Text(LanguageSettings.instance.tr('reviews_delete_confirm')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(LanguageSettings.instance.tr('cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(LanguageSettings.instance.tr('reviews_delete_btn'),
                style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      final response = await http.delete(
        Uri.parse('${ApiConstants.baseUrl}/reviews?id_review=$idReview'),
        headers: {'Authorization': 'Bearer $token'},
      ).timeout(const Duration(seconds: 15));

      if (!mounted) return;

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(LanguageSettings.instance.tr('reviews_deleted')),
            backgroundColor: Colors.green,
          ),
        );
        _loadReviews();
      } else {
        throw Exception('HTTP ${response.statusCode}');
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(LanguageSettings.instance.tr('reviews_delete_error')),
          backgroundColor: Colors.red,
        ),
      );
    }
  }


  // Muestra un diálogo para buscar hotel con lupa
  Future<void> _showHotelSearch(BuildContext context) async {
    final searchCtrl = TextEditingController();
    Map<String, dynamic>? selected;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlg) {
          final query = searchCtrl.text.toLowerCase();
          final filtered = _hoteles.where((h) {
            final name = h['name'].toString().toLowerCase();
            final city = h['city'].toString().toLowerCase();
            return query.isEmpty || name.contains(query) || city.contains(query);
          }).toList();

          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Text(LanguageSettings.instance.tr('reviews_select_hotel')),
            contentPadding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            content: SizedBox(
              width: double.maxFinite,
              height: 380,
              child: Column(
                children: [
                  TextField(
                    controller: searchCtrl,
                    autofocus: true,
                    decoration: InputDecoration(
                      hintText: LanguageSettings.instance.tr('reviews_search_hotel_hint'),
                      prefixIcon: const Icon(Icons.search, color: Color(0xFF6B7A99)),
                      filled: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    ),
                    onChanged: (_) => setDlg(() {}),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: filtered.isEmpty
                        ? const Center(child: Text('Sin resultados'))
                        : ListView.builder(
                            itemCount: filtered.length,
                            itemBuilder: (_, i) {
                              final h = filtered[i];
                              final isSelected = selected?['id'] == h['id'];
                              return ListTile(
                                dense: true,
                                selected: isSelected,
                                selectedTileColor: const Color(0xFFEEF3FF),
                                leading: Icon(
                                  Icons.hotel_outlined,
                                  size: 18,
                                  color: isSelected ? const Color(0xFF003B95) : const Color(0xFF9BA8C2),
                                ),
                                title: Text(h['name'].toString(),
                                    style: TextStyle(
                                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                      fontSize: 14,
                                    )),
                                subtitle: Text(h['city'].toString(),
                                    style: const TextStyle(fontSize: 12, color: Color(0xFF9BA8C2))),
                                onTap: () => setDlg(() => selected = h),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(LanguageSettings.instance.tr('cancel')),
              ),
              ElevatedButton(
                onPressed: selected == null ? null : () => Navigator.pop(ctx, true),
                style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF003B95), foregroundColor: Colors.white),
                child: Text(LanguageSettings.instance.tr('save')),
              ),
            ],
          );
        },
      ),
    );

    searchCtrl.dispose();
    if (selected != null && mounted) {
      setState(() {
        _selectedHotelId = _parseInt(selected!['id']);
        _selectedHotelName = '${selected!['name']} – ${selected!['city']}';
      });
    }
  }

  bool _matchesFilter(Map<String, dynamic> r) {
    if (_filterQuery.isEmpty) return true;
    final hotel = (r['hotelName'] ?? '').toString().toLowerCase();
    final user  = (r['userName']  ?? '').toString().toLowerCase();
    final comment = (r['comment'] ?? '').toString().toLowerCase();
    return hotel.contains(_filterQuery) ||
           user.contains(_filterQuery)  ||
           comment.contains(_filterQuery);
  }

  int _parseInt(dynamic v) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v?.toString() ?? '') ?? 0;
  }

  double _parseDouble(dynamic v) {
    if (v is num) return v.toDouble();
    return double.tryParse(v?.toString() ?? '') ?? 0.0;
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: LanguageSettings.instance.locale,
      builder: (context, locale, child) {
        final tr = LanguageSettings.instance.tr;
        return Scaffold(
          appBar: SkyTripAppBar(
            title: tr('reviews_title'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_outlined),
            tooltip: tr('reviews_update_tooltip'),
            onPressed: _loadReviews,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              children: [
                // ── Summary stats strip ─────────────────────────────
                if (_reviews.isNotEmpty) _buildStatsStrip(),

                // ── Write a review panel ────────────────────────────
                _buildReviewForm(),

                // ── Reviews list ────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          tr('reviews_traveler_opinions'),
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                      ),
                      if (!_isLoadingReviews)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFF003B95),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            _filterQuery.isEmpty
                                ? '${_reviews.length}'
                                : '${_reviews.where((r) => _matchesFilter(r)).length}',
                            style: const TextStyle(
                                color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700),
                          ),
                        ),
                    ],
                  ),
                ),
                // Buscador de reseñas con lupa
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: tr('reviews_search_hint'),
                      prefixIcon: const Icon(Icons.search, color: Color(0xFF6B7A99), size: 20),
                      suffixIcon: _filterQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.close, size: 18, color: Color(0xFF9BA8C2)),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _filterQuery = '');
                              },
                            )
                          : null,
                      filled: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                    onChanged: (v) => setState(() => _filterQuery = v.toLowerCase()),
                  ),
                ),
                const SizedBox(height: 12),
                if (_isLoadingReviews)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 40),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (_reviews.isEmpty)
                  _buildEmptyReviews()
                else ...[
                  ...(_reviews.where(_matchesFilter).map((r) => Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                        child: _buildReviewCard(r),
                      ))),
                  if (_filterQuery.isNotEmpty && !_reviews.any(_matchesFilter))
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 32),
                      child: Center(
                        child: Text(tr('reviews_no_results'),
                            style: TextStyle(color: AppColorScheme.subtitleFor(context))),
                      ),
                    ),
                ],
                const FooterWidget(),
              ],
            ),
          ),
        ],
      ),
        );
      },
    );
  }

  Widget _buildStatsStrip() {
    final avg = _reviews.isEmpty
        ? 0.0
        : _reviews.fold<double>(
                0, (s, r) => s + _parseDouble(r['rating'])) /
            _reviews.length;
    final dist = List.generate(5, (i) {
      final star = 5 - i;
      return _reviews.where((r) => _parseDouble(r['rating']).round() == star).length;
    });

    return Container(
      color: Theme.of(context).colorScheme.surface,
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          // Big score
          Column(
            children: [
              Text(
                avg.toStringAsFixed(1),
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.w900,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              Row(
                children: List.generate(
                  5,
                  (i) => Icon(
                    i < avg.round() ? Icons.star : Icons.star_border,
                    color: const Color(0xFFFFB700),
                    size: 18,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text('${_reviews.length} ${LanguageSettings.instance.tr('reviews_count_label')}',
                  style: TextStyle(
                      fontSize: 12, color: AppColorScheme.subtitleFor(context))),
            ],
          ),
          const SizedBox(width: 24),
          // Bar chart
          Expanded(
            child: Column(
              children: List.generate(5, (i) {
                final star = 5 - i;
                final count = dist[i];
                final pct =
                    _reviews.isEmpty ? 0.0 : count / _reviews.length;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    children: [
                      Text('$star',
                          style: TextStyle(
                              fontSize: 12, color: AppColorScheme.subtitleFor(context))),
                      const SizedBox(width: 4),
                      const Icon(Icons.star,
                          size: 11, color: Color(0xFFFFB700)),
                      const SizedBox(width: 6),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: pct,
                            backgroundColor: const Color(0xFFEEF1F8),
                            color: const Color(0xFFFFB700),
                            minHeight: 8,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      SizedBox(
                        width: 20,
                        child: Text('$count',
                            textAlign: TextAlign.right,
                            style: TextStyle(
                                fontSize: 11,
                                color: AppColorScheme.subtitleFor(context))),
                      ),
                    ],
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewForm() {
    return Container(
      color: Theme.of(context).colorScheme.surface,
      margin: const EdgeInsets.only(bottom: 10),
      child: Column(
        children: [
          // Toggle header
          InkWell(
            onTap: () => setState(() => _formExpanded = !_formExpanded),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 20, vertical: 16),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: _blue,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.rate_review_outlined,
                        color: Colors.white, size: 18),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(LanguageSettings.instance.tr('reviews_write'),
                            style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                                color: Theme.of(context).colorScheme.onSurface)),
                        Text(LanguageSettings.instance.tr('reviews_share'),
                            style: TextStyle(
                                fontSize: 12,
                                color: AppColorScheme.subtitleFor(context))),
                      ],
                    ),
                  ),
                  AnimatedRotation(
                    turns: _formExpanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(Icons.keyboard_arrow_down,
                        color: AppColorScheme.accentFor(context)),
                  ),
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 220),
            crossFadeState: _formExpanded
                ? CrossFadeState.showFirst
                : CrossFadeState.showSecond,
            secondChild: const SizedBox.shrink(),
            firstChild: Padding(
              padding:
                  const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(height: 1, color: Color(0xFFEAEFF8)),
                  const SizedBox(height: 16),
                  // Hotel selector con buscador
                  if (_hoteles.isNotEmpty) ...[
                    Text(LanguageSettings.instance.tr('reviews_hotel_label'),
                        style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                            color: Theme.of(context).colorScheme.onSurface)),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: () => _showHotelSearch(context),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.search, color: const Color(0xFF6B7A99), size: 20),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                _selectedHotelName.isEmpty
                                    ? LanguageSettings.instance.tr('reviews_select_hotel')
                                    : _selectedHotelName,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: _selectedHotelName.isEmpty
                                      ? const Color(0xFF9BA8C2)
                                      : Theme.of(context).colorScheme.onSurface,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Icon(Icons.arrow_drop_down, color: const Color(0xFF9BA8C2)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  // Star rating
                  Text(LanguageSettings.instance.tr('reviews_rating'),
                      style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          color: Theme.of(context).colorScheme.onSurface)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      ...List.generate(5, (i) {
                        return GestureDetector(
                          onTap: () =>
                              setState(() => _rating = i + 1.0),
                          child: Padding(
                            padding: const EdgeInsets.only(right: 4),
                            child: Icon(
                              i < _rating
                                  ? Icons.star
                                  : Icons.star_border,
                              color: const Color(0xFFFFB700),
                              size: 32,
                            ),
                          ),
                        );
                      }),
                      const SizedBox(width: 8),
                      Text(
                        _rating == 5.0
                            ? LanguageSettings.instance.tr('rating_exceptional')
                            : _rating >= 4.0
                                ? LanguageSettings.instance.tr('rating_very_good')
                                : _rating >= 3.0
                                    ? LanguageSettings.instance.tr('rating_good')
                                    : _rating >= 2.0
                                        ? LanguageSettings.instance.tr('rating_fair')
                                        : LanguageSettings.instance.tr('rating_bad'),
                        style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).colorScheme.onSurface),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Comment
                  Text(LanguageSettings.instance.tr('reviews_comment'),
                      style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          color: Theme.of(context).colorScheme.onSurface)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _commentController,
                    maxLines: 4,
                    maxLength: 500,
                    decoration: InputDecoration(
                      hintText: LanguageSettings.instance.tr('reviews_comment_hint'),
                      filled: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : _submitReview,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _blue,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(
                            vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      child: _isSubmitting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2),
                            )
                          : Text(LanguageSettings.instance.tr('reviews_publish'),
                              style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyReviews() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
        children: [
          const Icon(Icons.rate_review_outlined,
              size: 64, color: Color(0xFFCDD5E8)),
          const SizedBox(height: 16),
          Text(LanguageSettings.instance.tr('reviews_none'),
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColorScheme.subtitleFor(context))),
          const SizedBox(height: 6),
          Text(LanguageSettings.instance.tr('reviews_be_first'),
              style: TextStyle(fontSize: 13, color: AppColorScheme.subtitleFor(context))),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => setState(() => _formExpanded = true),
            style: ElevatedButton.styleFrom(
                backgroundColor: _blue, foregroundColor: Colors.white),
            child: Text(LanguageSettings.instance.tr('reviews_write_btn')),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewCard(Map<String, dynamic> r) {
    final rating = _parseDouble(r['rating']);
    final DateTime date = r['date'] is DateTime
        ? r['date'] as DateTime
        : DateTime.now();
    final initial = r['userInitial'] as String? ?? '?';
    final userName = r['userName'] as String? ?? 'Usuario';
    final hotelName = r['hotelName'] as String? ?? 'Hotel';
    final comment = r['comment'] as String? ?? '';

    final colors = [
      _blue,
      _accent,
      const Color(0xFF7C3AED),
      const Color(0xFF059669),
      const Color(0xFFDC2626),
    ];
    final color = colors[initial.codeUnitAt(0) % colors.length];

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User row
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: color,
                  child: Text(initial,
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 16)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(userName,
                          style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                              color: Theme.of(context).colorScheme.onSurface)),
                      Text(
                        '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}',
                        style: TextStyle(
                            fontSize: 11, color: AppColorScheme.subtitleFor(context)),
                      ),
                    ],
                  ),
                ),
                // Rating badge
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 9, vertical: 5),
                  decoration: BoxDecoration(
                    color: _blue,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(8),
                      topRight: Radius.circular(8),
                      bottomRight: Radius.circular(8),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.star,
                          color: Color(0xFFFFB700), size: 12),
                      const SizedBox(width: 3),
                      Text(rating.toStringAsFixed(1),
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 13)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            // Hotel name chip
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1E2A40) : const Color(0xFFF0F4FF),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.hotel_outlined,
                      size: 12, color: AppColorScheme.accentFor(context)),
                  const SizedBox(width: 4),
                  Text(hotelName,
                      style: TextStyle(
                          fontSize: 12,
                          color: AppColorScheme.accentFor(context),
                          fontWeight: FontWeight.w500)),
                ],
              ),
            ),
            const SizedBox(height: 10),
            // Comment
            Text(comment,
                style: TextStyle(
                    fontSize: 14,
                    height: 1.55,
                    color: AppColorScheme.subtitleFor(context))),
            const SizedBox(height: 10),
            if (AuthService().isAdmin)
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () => _deleteReview(r['id'] as int),
                  icon: const Icon(Icons.delete_outline, size: 16, color: Colors.red),
                  label: Text(LanguageSettings.instance.tr('reviews_delete_btn'), style: const TextStyle(color: Colors.red, fontSize: 12)),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ),
            // Stars visual
            Row(
              children: List.generate(5, (i) {
                final filled = i < rating;
                final half = !filled && i < rating + 0.5;
                return Icon(
                  filled
                      ? Icons.star
                      : half
                          ? Icons.star_half
                          : Icons.star_border,
                  color: const Color(0xFFFFB700),
                  size: 16,
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}
