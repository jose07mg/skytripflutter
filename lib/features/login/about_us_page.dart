import 'package:flutter/material.dart';
import 'package:skytrip/core/services/language_settings.dart';
import 'package:skytrip/shared/widgets/design/layout/footer.dart';

class AboutUsPage extends StatelessWidget {
  const AboutUsPage({super.key});

  static const Color _blue = Color(0xFF003B95);
  static const Color _accent = Color(0xFF0071C2);

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: LanguageSettings.instance.locale,
      builder: (context, locale, child) {
        final tr = LanguageSettings.instance.tr;
        return Scaffold(
          body: CustomScrollView(
            slivers: [
              // ── Hero ──────────────────────────────────────────────────
              SliverAppBar(
                expandedHeight: 200,
                pinned: true,
                automaticallyImplyLeading: false,
                backgroundColor: _blue,
                foregroundColor: Colors.white,
                leading: Navigator.of(context).canPop()
                    ? IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new, size: 20),
                        onPressed: () => Navigator.pop(context),
                      )
                    : null,
                title: GestureDetector(
                  onTap: () => Navigator.pushNamedAndRemoveUntil(
                      context, '/home', (r) => false),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 26,
                        height: 26,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: Image.asset('assets/images/logo.png',
                              fit: BoxFit.contain,
                              errorBuilder: (_, _, _) => const Icon(
                                  Icons.flight_takeoff,
                                  color: Color(0xFF003B95),
                                  size: 16)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(tr('about_title'),
                          style: const TextStyle(
                              fontWeight: FontWeight.w800, fontSize: 17)),
                    ],
                  ),
                ),
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Color(0xFF001F5B), Color(0xFF0057C8)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                      ),
                      Positioned(
                        top: -40,
                        right: -40,
                        child: Container(
                          width: 200,
                          height: 200,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withValues(alpha: 0.05),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: -20,
                        left: -20,
                        child: Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withValues(alpha: 0.04),
                          ),
                        ),
                      ),
                      Positioned(
                        left: 24,
                        bottom: 28,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.flight_takeoff,
                                    color: Colors.white70, size: 18),
                                SizedBox(width: 8),
                                Text('SkyTrip',
                                    style: TextStyle(
                                        color: Colors.white54,
                                        fontSize: 13)),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(tr('about_hero_title'),
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 28,
                                    fontWeight: FontWeight.w900)),
                            const SizedBox(height: 4),
                            Text(tr('about_hero_subtitle'),
                                style: const TextStyle(
                                    color: Colors.white70, fontSize: 14)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Stats strip ────────────────────────────────────
                    Container(
                      color: Colors.white,
                      padding:
                          const EdgeInsets.symmetric(vertical: 20),
                      child: Row(
                        children: [
                          _stat('200+', tr('about_stat_hotels')),
                          _statDivider(),
                          _stat('50+', tr('about_stat_countries')),
                          _statDivider(),
                          _stat('4.8★', tr('about_stat_rating')),
                          _statDivider(),
                          _stat('24/7', tr('about_stat_support')),
                        ],
                      ),
                    ),

                    // ── Historia ──────────────────────────────────────
                    _sectionHeader(tr('about_section_history')),
                    Padding(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 20),
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color:
                                  Colors.black.withValues(alpha: 0.05),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: _blue.withValues(alpha: 0.1),
                                    borderRadius:
                                        BorderRadius.circular(10),
                                  ),
                                  child: const Icon(
                                      Icons.auto_stories_outlined,
                                      color: _blue,
                                      size: 20),
                                ),
                                const SizedBox(width: 12),
                                Text(tr('about_history_card_title'),
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 16,
                                        color: Color(0xFF1A1F36))),
                              ],
                            ),
                            const SizedBox(height: 14),
                            Text(
                              tr('about_history_p1'),
                              style: const TextStyle(
                                  fontSize: 14,
                                  height: 1.7,
                                  color: Color(0xFF4A5772)),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              tr('about_history_p2'),
                              style: const TextStyle(
                                  fontSize: 14,
                                  height: 1.7,
                                  color: Color(0xFF4A5772)),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // ── Misión ────────────────────────────────────────
                    _sectionHeader(tr('about_section_mission')),
                    Padding(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 20),
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              Color(0xFF003B95),
                              Color(0xFF0057C8)
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.rocket_launch_outlined,
                                color: Colors.white70, size: 28),
                            const SizedBox(height: 12),
                            Text(
                              tr('about_mission_quote'),
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  height: 1.5),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              tr('about_mission_body'),
                              style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 13,
                                  height: 1.7),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // ── Valores ───────────────────────────────────────
                    _sectionHeader(tr('about_section_values')),
                    Padding(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 20),
                      child: GridView.count(
                        shrinkWrap: true,
                        physics:
                            const NeverScrollableScrollPhysics(),
                        crossAxisCount: 2,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: 1.35,
                        children: [
                          _ValueCard(
                            icon: Icons.verified_outlined,
                            color: const Color(0xFF0071C2),
                            title: tr('about_value1_title'),
                            body: tr('about_value1_body'),
                          ),
                          _ValueCard(
                            icon: Icons.lightbulb_outline,
                            color: const Color(0xFFD97706),
                            title: tr('about_value2_title'),
                            body: tr('about_value2_body'),
                          ),
                          _ValueCard(
                            icon: Icons.diversity_3_outlined,
                            color: const Color(0xFF059669),
                            title: tr('about_value3_title'),
                            body: tr('about_value3_body'),
                          ),
                          _ValueCard(
                            icon: Icons.eco_outlined,
                            color: const Color(0xFF7C3AED),
                            title: tr('about_value4_title'),
                            body: tr('about_value4_body'),
                          ),
                        ],
                      ),
                    ),

                    // ── Equipo ────────────────────────────────────────
                    _sectionHeader(tr('about_section_team')),
                    Padding(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        children: [
                          Expanded(
                            child: _TeamCard(
                              initials: 'JM',
                              name: 'Jose Muñoz',
                              role: 'Full-Stack Dev',
                              color: _blue,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _TeamCard(
                              initials: 'JS',
                              name: 'Jesus Sanchez',
                              role: 'Full-Stack Dev',
                              color: _accent,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // ── Tecnología ────────────────────────────────────
                    _sectionHeader(tr('about_section_tech')),
                    Padding(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 20),
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color:
                                  Colors.black.withValues(alpha: 0.05),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(tr('about_tech_title'),
                                style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 15,
                                    color: Color(0xFF1A1F36))),
                            const SizedBox(height: 16),
                            const Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                _TechBadge(
                                    'Flutter', Color(0xFF027DFD)),
                                _TechBadge('Dart', Color(0xFF00B4AB)),
                                _TechBadge(
                                    'PHP / Slim', Color(0xFF8892BF)),
                                _TechBadge(
                                    'MySQL', Color(0xFF00618A)),
                                _TechBadge(
                                    'REST API', Color(0xFF059669)),
                                _TechBadge('XAMPP', Color(0xFFD97706)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                    // ── CTA ───────────────────────────────────────────
                    Padding(
                      padding:
                          const EdgeInsets.fromLTRB(20, 28, 20, 0),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              Color(0xFF6D28D9),
                              Color(0xFF003B95)
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(tr('about_cta_title'),
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.w900)),
                            const SizedBox(height: 8),
                            Text(
                              tr('about_cta_subtitle'),
                              style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 13),
                            ),
                            const SizedBox(height: 16),
                            GestureDetector(
                              onTap: () =>
                                  Navigator.pushNamedAndRemoveUntil(
                                      context, '/home', (r) => false),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 20, vertical: 12),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius:
                                      BorderRadius.circular(10),
                                ),
                                child: Text(tr('about_cta_button'),
                                    style: const TextStyle(
                                        color: Color(0xFF003B95),
                                        fontWeight: FontWeight.w800,
                                        fontSize: 14)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 28),
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

  static Widget _stat(String value, String label) => Expanded(
        child: Column(
          children: [
            Text(value,
                style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF003B95))),
            Text(label,
                style: const TextStyle(
                    fontSize: 11, color: Color(0xFF6B7A99))),
          ],
        ),
      );

  static Widget _statDivider() =>
      Container(width: 1, height: 36, color: const Color(0xFFE8ECF4));

  static Widget _sectionHeader(String title) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 28, 20, 14),
        child: Text(title,
            style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1A1F36))),
      );
}

// ── Value card ─────────────────────────────────────────────────────────────

class _ValueCard extends StatelessWidget {
  const _ValueCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.body,
  });
  final IconData icon;
  final Color color;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(height: 10),
          Text(title,
              style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: Color(0xFF1A1F36))),
          const SizedBox(height: 4),
          Expanded(
            child: Text(body,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    fontSize: 11,
                    height: 1.5,
                    color: Color(0xFF6B7A99))),
          ),
        ],
      ),
    );
  }
}

// ── Team card ──────────────────────────────────────────────────────────────

class _TeamCard extends StatelessWidget {
  const _TeamCard({
    required this.initials,
    required this.name,
    required this.role,
    required this.color,
  });
  final String initials;
  final String name;
  final String role;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: color.withValues(alpha: 0.15),
            child: Text(initials,
                style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w800,
                    fontSize: 18)),
          ),
          const SizedBox(height: 10),
          Text(name,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: Color(0xFF1A1F36))),
          const SizedBox(height: 3),
          Text(role,
              style: const TextStyle(
                  fontSize: 11, color: Color(0xFF6B7A99))),
        ],
      ),
    );
  }
}

// ── Tech badge ─────────────────────────────────────────────────────────────

class _TechBadge extends StatelessWidget {
  const _TechBadge(this.label, this.color);
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(label,
          style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color)),
    );
  }
}
