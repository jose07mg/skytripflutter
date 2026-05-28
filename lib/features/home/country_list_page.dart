import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../core/constants/api_constants.dart';
import '../../core/constants/favorites_service.dart';
import '../../shared/widgets/design/layout/custom_app_bar.dart';
import '../../shared/widgets/design/layout/footer.dart';
import 'alojamientos_page.dart';

class CountryListPage extends StatefulWidget {
  const CountryListPage({super.key});

  @override
  State<CountryListPage> createState() => _CountryListPageState();
}

class _CountryListPageState extends State<CountryListPage> {
  final List<Map<String, dynamic>> _countries = [];
  final FavoritesService _favoritesService = FavoritesService();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializePage();
  }

  Future<void> _initializePage() async {
    await _favoritesService.init();
    _favoritesService.addListener(_handleFavoritesChanged);
    await _loadCountries();
  }

  void _handleFavoritesChanged() {
    if (!mounted) {
      return;
    }
    setState(() {
      _sortCountriesByFavorites();
    });
  }

  @override
  void dispose() {
    _favoritesService.removeListener(_handleFavoritesChanged);
    super.dispose();
  }

  Future<void> _loadCountries() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http
          .get(Uri.parse('${ApiConstants.baseUrl}/hoteles'))
          .timeout(const Duration(seconds: 15));
      if (response.statusCode != 200) {
        debugPrint('Error cargando países: ${response.statusCode}');
        return;
      }

      final data = jsonDecode(response.body);
      if (data is! List) {
        return;
      }

      final Map<String, Map<String, dynamic>> grouped = {};

      for (final item in data) {
        final country = item['pais_nombre']?.toString() ?? 'País desconocido';
        final city = item['ciudad_nombre']?.toString() ?? 'Ciudad desconocida';

        final current = grouped.putIfAbsent(
          country,
          () => {
            'name': country,
            'destinationId': country,
            'hotels': 0,
            'cities': <String>{},
          },
        );

        current['hotels'] = (current['hotels'] as int) + 1;
        (current['cities'] as Set<String>).add(city);
      }

      final countries =
          grouped.values.map((country) {
            final cities = (country['cities'] as Set<String>).toList()..sort();
            return {
              'name': country['name'],
              'destinationId': country['name'],
              'hotels': country['hotels'],
              'cities': cities,
            };
          }).toList();

      countries.sort(
        (a, b) => a['name'].toString().compareTo(b['name'].toString()),
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _countries
          ..clear()
          ..addAll(countries);
        _sortCountriesByFavorites();
      });
    } catch (e) {
      debugPrint('Error cargando países: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _sortCountriesByFavorites() {
    _countries.sort((a, b) {
      final bool aIsFav = _favoritesService.isDestinationFavorite(
        a['destinationId'].toString(),
      );
      final bool bIsFav = _favoritesService.isDestinationFavorite(
        b['destinationId'].toString(),
      );

      if (aIsFav != bIsFav) {
        return aIsFav ? -1 : 1;
      }

      return a['name'].toString().compareTo(b['name'].toString());
    });
  }

  Future<void> _toggleFavorite(int index) async {
    final name = _countries[index]['name'].toString();
    final destinationId = _countries[index]['destinationId'].toString();
    final isFav = !_favoritesService.isDestinationFavorite(destinationId);

    await _favoritesService.toggleDestinationFavorite(destinationId);
    if (!mounted) return;

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isFav ? '$name añadido a favoritos' : '$name eliminado de favoritos',
        ),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: SkyTripAppBar(
        title: 'Destinos del Mundo',
      ),
      body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _countries.isEmpty
                    ? const Center(child: Text('No hay destinos disponibles.'))
                    : ListView.builder(
              itemCount: _countries.length,
              itemBuilder: (context, index) {
                final country = _countries[index];
                final cities = (country['cities'] as List<dynamic>)
                    .cast<String>();

                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: ListTile(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AlojamientosPage(
                          filtroPais: country['name'].toString(),
                        ),
                      ),
                    ),
                    leading: CircleAvatar(
                      backgroundColor: Colors.blue.shade100,
                      child: Text(
                        country['name'].toString().isNotEmpty
                            ? country['name'].toString()[0].toUpperCase()
                            : '?',
                        style: TextStyle(
                          color: Colors.blue.shade800,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    title: Text(
                      country['name'],
                      style: const TextStyle(fontSize: 18),
                    ),
                    subtitle: Text(
                      '${country['hotels']} hoteles · ${cities.length} ciudades\n'
                      '${cities.take(3).join(', ')}${cities.length > 3 ? '...' : ''}',
                    ),
                    isThreeLine: true,
                    trailing: IconButton(
                      icon: Icon(
                        _favoritesService.isDestinationFavorite(
                              country['destinationId'].toString(),
                            )
                            ? Icons.favorite
                            : Icons.favorite_border,
                        color: _favoritesService.isDestinationFavorite(
                              country['destinationId'].toString(),
                            )
                            ? Colors.red
                            : Colors.grey,
                      ),
                      onPressed: () => _toggleFavorite(index),
                    ),
                  ),
                );
              },
            ),
          ),
          const FooterWidget(),
        ],
      ),
    );
  }
}
