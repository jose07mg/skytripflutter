import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

import '../../core/constants/api_constants.dart';
import '../../core/constants/content_service.dart';
import '../../core/services/language_settings.dart';
import '../../shared/themes/color_scheme.dart';
import '../../shared/widgets/design/layout/footer.dart';

class AtencionClientePage extends StatefulWidget {
  const AtencionClientePage({super.key});

  @override
  State<AtencionClientePage> createState() => _AtencionClientePageState();
}

class _AtencionClientePageState extends State<AtencionClientePage> {
  static const Color _blue = Color(0xFF003B95);
  static const Color _accent = Color(0xFF0071C2);

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _subjectController = TextEditingController();
  final _messageController = TextEditingController();
  bool _isSending = false;
  bool _sent = false;
  List<Map<String, String>> _faqItems = [];
  List<Map<String, dynamic>> _canales = [];

  @override
  void initState() {
    super.initState();
    _loadFaq();
    _loadCanales();
    ContentService.instance.version.addListener(_loadFaq);
  }

  void _loadFaq() {
    if (!mounted) return;
    setState(() {
      _faqItems = ContentService.instance.getPageSections('atencion');
    });
  }

  Future<void> _loadCanales() async {
    try {
      final r = await http
          .get(Uri.parse('${ApiConstants.baseUrl}/contacto'))
          .timeout(const Duration(seconds: 8));
      if (r.statusCode == 200) {
        final data = jsonDecode(r.body)['data'];
        if (data is List && mounted) {
          setState(() {
            _canales = data
                .where((c) => c['activo'] != false && c['activo'] != 0)
                .map((c) => Map<String, dynamic>.from(c as Map))
                .toList();
          });
          return;
        }
      }
    } catch (_) {}
    // Fallback: defaults
    if (mounted) {
      setState(() {
        _canales = [
          {'tipo': 'chat',      'etiqueta': 'Chat en vivo',          'valor': 'https://skytrip.com/chat'},
          {'tipo': 'telefono',  'etiqueta': 'Teléfono',              'valor': 'tel:+34900123456'},
          {'tipo': 'email',     'etiqueta': 'Correo electrónico',    'valor': 'mailto:support@skytrip.com'},
          {'tipo': 'whatsapp',  'etiqueta': 'WhatsApp',              'valor': 'https://wa.me/34600123456'},
        ];
      });
    }
  }

  @override
  void dispose() {
    ContentService.instance.version.removeListener(_loadFaq);
    _nameController.dispose();
    _emailController.dispose();
    _subjectController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  // Returns (icon, color, badge) for a canal tipo
  (IconData, Color, String) _canalMeta(String tipo) {
    switch (tipo) {
      case 'telefono':
        return (Icons.phone_outlined, Colors.orange, '24/7');
      case 'email':
        return (Icons.email_outlined, _accent, '< 24h');
      case 'whatsapp':
        return (Icons.message_outlined, const Color(0xFF22C55E), '< 1h');
      case 'chat':
      default:
        return (Icons.chat_bubble_outline, const Color(0xFF22C55E), LanguageSettings.instance.tr('contact_badge_online'));
    }
  }

  String _canalSubtitle(String tipo, String valor) {
    if (tipo == 'telefono' || tipo == 'whatsapp') {
      return valor
          .replaceAll('tel:', '')
          .replaceAll('https://wa.me/', '+');
    }
    if (tipo == 'email') return valor.replaceAll('mailto:', '');
    return valor;
  }

  Future<void> _launchURL(String url) async {
    final uri = Uri.parse(url);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      }
    } catch (_) {
      // Ignore launch errors
    }
  }

  Future<void> _sendMessage() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSending = true);
    try {
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/contacto/mensaje'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'nombre': _nameController.text.trim(),
          'email': _emailController.text.trim(),
          'asunto': _subjectController.text.trim(),
          'mensaje': _messageController.text.trim(),
        }),
      ).timeout(const Duration(seconds: 10));

      if (!mounted) return;

      if (response.statusCode == 200 || response.statusCode == 201) {
        setState(() {
          _isSending = false;
          _sent = true;
        });
        _nameController.clear();
        _emailController.clear();
        _subjectController.clear();
        _messageController.clear();
      } else {
        setState(() => _isSending = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(LanguageSettings.instance.tr('contact_error_send')),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ));
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _isSending = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(LanguageSettings.instance.tr('contact_error_connection')),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: LanguageSettings.instance.locale,
      builder: (context, _, child) {
        final tr = LanguageSettings.instance.tr;
        return Scaffold(
      body: CustomScrollView(
        slivers: [
          // ── App bar ──────────────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 160,
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
                  Text(tr('contact_title'),
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
                        colors: [Color(0xFF00235B), Color(0xFF0057C8)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                  ),
                  Positioned(
                    top: -40,
                    right: -40,
                    child: Container(
                      width: 160,
                      height: 160,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.06),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 20,
                    bottom: 20,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(tr('contact_title'),
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 26,
                                fontWeight: FontWeight.w900)),
                        const SizedBox(height: 4),
                        Text(tr('contact_subtitle'),
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
                // ── Availability strip ───────────────────────────────
                Container(
                  color: const Color(0xFF22C55E),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 10),
                  child: Row(
                    children: [
                      const Icon(Icons.circle, color: Colors.white, size: 10),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(tr('contact_availability'),
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 13),
                            overflow: TextOverflow.ellipsis),
                      ),
                    ],
                  ),
                ),

                // ── Contact options ──────────────────────────────────
                _SectionHeader(tr('contact_channels')),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: _canales.map((c) {
                      final tipo = c['tipo']?.toString() ?? '';
                      final etiqueta = c['etiqueta']?.toString() ?? tipo;
                      final valor = c['valor']?.toString() ?? '';
                      final meta = _canalMeta(tipo);
                      return _ContactCard(
                        icon: meta.$1,
                        color: meta.$2,
                        title: etiqueta,
                        subtitle: _canalSubtitle(tipo, valor),
                        badge: meta.$3,
                        badgeColor: meta.$2,
                        onTap: () => _launchURL(valor),
                      );
                    }).toList(),
                  ),
                ),

                // ── Contact form ─────────────────────────────────────
                _SectionHeader(tr('contact_send_message_section')),
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.06),
                        blurRadius: 14,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: _sent
                      ? _buildSuccessState()
                      : _buildContactForm(),
                ),

                // ── FAQ ──────────────────────────────────────────────
                _SectionHeader(tr('contact_faq')),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 12,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Column(
                        children: _faqItems
                            .map((item) => _FAQItem(
                                  question: item['title'] ?? '',
                                  answer: item['content'] ?? '',
                                ))
                            .toList(),
                      ),
                    ),
                  ),
                ),

                // ── Response times info ──────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF003B95), Color(0xFF0057C8)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.access_time,
                                color: Colors.white, size: 20),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(tr('contact_response_times'),
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 16),
                                  overflow: TextOverflow.ellipsis),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        ...[
                          (tr('contact_rt_chat'), tr('contact_rt_immediate')),
                          (tr('contact_rt_phone'), tr('contact_rt_247')),
                          (tr('contact_rt_whatsapp'), tr('contact_rt_1h')),
                          (tr('contact_rt_email'), tr('contact_rt_24h')),
                        ].map(
                          (item) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              children: [
                                const Icon(Icons.check_circle_outline,
                                    color: Color(0xFF86EFAC), size: 16),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(item.$1,
                                      style: const TextStyle(
                                          color: Colors.white70,
                                          fontSize: 13)),
                                ),
                                Text(item.$2,
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 13)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),
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

  Widget _buildContactForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(LanguageSettings.instance.tr('contact_form_title'),
              style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                  color: AppColorScheme.titleFor(context))),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _FormField(
                  controller: _nameController,
                  label: LanguageSettings.instance.tr('contact_name'),
                  icon: Icons.person_outline,
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? LanguageSettings.instance.tr('field_required')
                      : null,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _FormField(
                  controller: _emailController,
                  label: 'Email',  // same in all languages
                  icon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return LanguageSettings.instance.tr('field_required');
                    if (!v.contains('@')) return LanguageSettings.instance.tr('email_invalid');
                    return null;
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _FormField(
            controller: _subjectController,
            label: LanguageSettings.instance.tr('contact_subject'),
            icon: Icons.subject_outlined,
            validator: (v) => (v == null || v.trim().isEmpty)
                ? LanguageSettings.instance.tr('field_required')
                : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _messageController,
            maxLines: 5,
            maxLength: 1000,
            validator: (v) => (v == null || v.trim().length < 10)
                ? LanguageSettings.instance.tr('contact_message_min')
                : null,
            decoration: InputDecoration(
              labelText: LanguageSettings.instance.tr('contact_message'),
              alignLabelWithHint: true,
              prefixIcon: const Padding(
                padding: EdgeInsets.only(bottom: 64),
                child: Icon(Icons.message_outlined, color: Color(0xFF6B7A99)),
              ),
              filled: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 4),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isSending ? null : _sendMessage,
              style: ElevatedButton.styleFrom(
                backgroundColor: _blue,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              child: _isSending
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2),
                    )
                  : Text(LanguageSettings.instance.tr('contact_send_btn'),
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 15)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessState() {
    return Column(
      children: [
        const SizedBox(height: 12),
        Container(
          width: 70,
          height: 70,
          decoration: const BoxDecoration(
            color: Color(0xFFDCFCE7),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.check_rounded,
              color: Color(0xFF16A34A), size: 40),
        ),
        const SizedBox(height: 16),
        Text(LanguageSettings.instance.tr('contact_sent_title'),
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColorScheme.titleFor(context))),
        const SizedBox(height: 8),
        Text(
          LanguageSettings.instance.tr('contact_sent_body'),
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 14, color: AppColorScheme.subtitleFor(context)),
        ),
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: () => setState(() => _sent = false),
          style: ElevatedButton.styleFrom(
              backgroundColor: _blue, foregroundColor: Colors.white),
          child: Text(LanguageSettings.instance.tr('contact_send_another')),
        ),
        const SizedBox(height: 12),
      ],
    );
  }
}

// ── Helper widgets ─────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title);
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w800,
          color: AppColorScheme.titleFor(context),
        ),
      ),
    );
  }
}

class _ContactCard extends StatelessWidget {
  const _ContactCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.badge,
    required this.badgeColor,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final String badge;
  final Color badgeColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: Theme.of(context).colorScheme.onSurface)),
                    Text(subtitle,
                        style: TextStyle(
                            fontSize: 13, color: AppColorScheme.subtitleFor(context))),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: badgeColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(badge,
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: badgeColor)),
              ),
              const SizedBox(width: 6),
              const Icon(Icons.arrow_forward_ios_outlined,
                  size: 14, color: Color(0xFF9CA8C0)),
            ],
          ),
        ),
      ),
    );
  }
}

class _FAQItem extends StatelessWidget {
  const _FAQItem({required this.question, required this.answer});
  final String question;
  final String answer;

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      tilePadding: const EdgeInsets.symmetric(horizontal: 16),
      childrenPadding:
          const EdgeInsets.fromLTRB(16, 0, 16, 16),
      title: Text(question,
          style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: Theme.of(context).colorScheme.onSurface)),
      iconColor: const Color(0xFF003B95),
      collapsedIconColor: const Color(0xFF6B7A99),
      children: [
        Text(answer,
            style: TextStyle(
                fontSize: 13, height: 1.6, color: AppColorScheme.subtitleFor(context))),
      ],
    );
  }
}

class _FormField extends StatelessWidget {
  const _FormField({
    required this.controller,
    required this.label,
    required this.icon,
    this.keyboardType,
    this.validator,
  });

  final TextEditingController controller;
  final String label;
  final IconData icon;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: const Color(0xFF6B7A99), size: 18),
        filled: true,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        isDense: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      ),
    );
  }
}
