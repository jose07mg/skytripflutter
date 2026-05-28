import 'package:flutter/material.dart';
import 'package:skytrip/core/services/language_settings.dart';
import 'package:skytrip/features/auth/auth_service.dart';
import 'package:skytrip/features/home/condiciones_page.dart';
import 'package:skytrip/features/home/atencion_cliente_page.dart';
import 'package:skytrip/features/home/destinos_page.dart';
import 'package:skytrip/features/home/alojamientos_page.dart';
import 'package:skytrip/features/home/mis_reservas_page.dart';
import 'package:skytrip/features/home/favoritos_page.dart';
import 'package:skytrip/features/home/reviews_page.dart';

/// Reusable AppBar leading widget: back arrow when history exists, home icon otherwise.
Widget skyTripLogoLeading(BuildContext context) {
  final canPop = Navigator.canPop(context);
  return GestureDetector(
    onTap: () => Navigator.pushNamedAndRemoveUntil(
        context, '/home', (r) => false),
    child: Padding(
      padding: const EdgeInsets.all(10),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          canPop ? Icons.arrow_back_ios_new : Icons.flight_takeoff,
          color: Colors.white,
          size: 18,
        ),
      ),
    ),
  );
}

class FooterWidget extends StatelessWidget {
  const FooterWidget({super.key});

  static const Color _footerBg = Color(0xFF1A3A6B);

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: LanguageSettings.instance.locale,
      builder: (context, locale, child) {
        final tr = LanguageSettings.instance.tr;
        return Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF00235B), _footerBg, Color(0xFF1E4D8C)],
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 2,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              GestureDetector(
                                onTap: () =>
                                    Navigator.pushNamedAndRemoveUntil(
                                        context, '/home', (r) => false),
                                child: const Row(
                                  children: [
                                    SizedBox(
                                      width: 36,
                                      height: 36,
                                      child: DecoratedBox(
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.all(
                                              Radius.circular(8)),
                                        ),
                                        child: Icon(
                                          Icons.flight_takeoff,
                                          color: Color(0xFF003B95),
                                          size: 20,
                                        ),
                                      ),
                                    ),
                                    SizedBox(width: 10),
                                    Text(
                                      'SkyTrip',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 22,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: -0.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                tr('footer_description'),
                                style: const TextStyle(
                                  color: Colors.white60,
                                  fontSize: 13,
                                  height: 1.6,
                                ),
                              ),
                              const SizedBox(height: 16),
                            ],
                          ),
                        ),
                        const SizedBox(width: 24),
                        Expanded(
                          flex: 3,
                          child: Wrap(
                            spacing: 12,
                            runSpacing: 6,
                            alignment: WrapAlignment.end,
                            children: [
                              _buildFooterLink(context, tr('footer_terms'),
                                  () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CondicionesPage()))),
                              _buildFooterLink(context, tr('footer_support'),
                                  () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AtencionClientePage()))),
                              _buildFooterLink(context, tr('footer_destinations'),
                                  () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DestinosPage()))),
                              _buildFooterLink(context, tr('footer_accommodations'),
                                  () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AlojamientosPage()))),
                              if (AuthService().isAuthenticated)
                                _buildFooterLink(context, tr('footer_bookings'),
                                    () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MisReservasPage()))),
                              _buildFooterLink(context, tr('footer_favorites'),
                                  () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FavoritosPage()))),
                              _buildFooterLink(context, tr('footer_reviews'),
                                  () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ReviewsPage()))),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                color: Colors.black.withValues(alpha: 0.15),
                padding: const EdgeInsets.symmetric(
                    horizontal: 24, vertical: 14),
                child: const Row(
                  children: [
                    Text(
                      '© 2026 SkyTrip',
                      style:
                          TextStyle(color: Colors.white54, fontSize: 12),
                    ),
                    Spacer(),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFooterLink(
      BuildContext context, String title, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        child: Text(
          title,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
