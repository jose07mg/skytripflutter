import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:skytrip/features/auth/auth_service.dart';

import '../../core/constants/api_constants.dart';
import '../../core/services/language_settings.dart';
import '../../shared/themes/color_scheme.dart';
import '../../shared/widgets/design/layout/footer.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  static const Color _blue = Color(0xFF003B95);
  static const Color _accent = Color(0xFF0071C2);

  final _formKey = GlobalKey<FormState>();
  final _usuarioController = TextEditingController();
  final _emailController = TextEditingController();
  final _direccionController = TextEditingController();
  final _paisNacimientoController = TextEditingController();
  final _fechaNacimientoController = TextEditingController();
  bool _isLoading = true;
  bool _isSaving = false;
  bool _editMode = false;

  String? _orNull(String v) {
    final s = v.trim();
    return s.isEmpty ? null : s;
  }

  String get _initials {
    final name = _usuarioController.text.trim();
    if (name.isEmpty) return '?';
    final parts = name.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name[0].toUpperCase();
  }

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _usuarioController.dispose();
    _emailController.dispose();
    _direccionController.dispose();
    _paisNacimientoController.dispose();
    _fechaNacimientoController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    final token = AuthService().token;
    if (token == null) {
      setState(() => _isLoading = false);
      return;
    }
    try {
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/me'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final user = (data is Map) ? data : null;
        if (user != null) {
          _usuarioController.text = user['usuario']?.toString() ?? '';
          _emailController.text = user['email']?.toString() ?? '';
          _direccionController.text = user['direccion']?.toString() ?? '';
          _paisNacimientoController.text =
              user['pais_nacimiento']?.toString() ?? '';
          _fechaNacimientoController.text =
              user['fecha_nacimiento']?.toString() ?? '';
        }
      }
    } catch (_) {}
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    final token = AuthService().token;
    if (token == null) return;
    final messenger = ScaffoldMessenger.of(context);
    final tr = LanguageSettings.instance.tr;
    try {
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/user/update'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'usuario': _usuarioController.text.trim(),
          'email': _emailController.text.trim(),
          'direccion': _orNull(_direccionController.text),
          'pais_nacimiento': _orNull(_paisNacimientoController.text),
          'fecha_nacimiento': _orNull(_fechaNacimientoController.text),
        }),
      );
      if (!mounted) return;
      if (response.statusCode == 200) {
        setState(() => _editMode = false);
        messenger.showSnackBar(SnackBar(
          content: Row(children: [
            const Icon(Icons.check_circle_outline, color: Colors.white),
            const SizedBox(width: 10),
            Text(tr('profile_updated_ok')),
          ]),
          backgroundColor: const Color(0xFF22C55E),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10)),
        ));
      } else {
        messenger.showSnackBar(SnackBar(
          content: Text(tr('profile_updated_error')),
          backgroundColor: Colors.red,
        ));
      }
    } catch (_) {
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(
          content: Text(tr('profile_connection_error'))));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return ValueListenableBuilder<String>(
      valueListenable: LanguageSettings.instance.locale,
      builder: (context, locale, child) {
        final tr = LanguageSettings.instance.tr;
        final auth = AuthService();
        final isAdmin = auth.isAdmin;

        return Scaffold(
          body: CustomScrollView(
            slivers: [
              // ── Hero app bar ──────────────────────────────────────────
              SliverAppBar(
                expandedHeight: 220,
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
                              errorBuilder: (_, _, _) => Icon(
                                  Icons.flight_takeoff,
                                  color: AppColorScheme.accentFor(context),
                                  size: 16)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(tr('profile_title'),
                          style: const TextStyle(
                              fontWeight: FontWeight.w800, fontSize: 17)),
                    ],
                  ),
                ),
                actions: [
                  IconButton(
                    icon: Icon(
                        _editMode ? Icons.close : Icons.edit_outlined),
                    tooltip: _editMode
                        ? tr('cancel')
                        : tr('profile_edit_tooltip'),
                    onPressed: () =>
                        setState(() => _editMode = !_editMode),
                  ),
                ],
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
                        top: -30,
                        right: -30,
                        child: Container(
                          width: 180,
                          height: 180,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color:
                                Colors.white.withValues(alpha: 0.05),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 24,
                        left: 0,
                        right: 0,
                        child: Column(
                          children: [
                            Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white
                                    .withValues(alpha: 0.15),
                                border: Border.all(
                                    color: Colors.white
                                        .withValues(alpha: 0.5),
                                    width: 2.5),
                              ),
                              child: Center(
                                child: Text(
                                  _initials,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 30,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              _usuarioController.text.isEmpty
                                  ? tr('profile_title')
                                  : _usuarioController.text,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 4),
                              decoration: BoxDecoration(
                                color: isAdmin
                                    ? const Color(0xFFFFB700)
                                    : Colors.white
                                        .withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                isAdmin
                                    ? tr('profile_admin')
                                    : tr('profile_traveler'),
                                style: TextStyle(
                                  color: isAdmin
                                      ? Theme.of(context).colorScheme.onSurface
                                      : Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
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

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ── Stats strip ──────────────────────────────────
                        Container(
                          padding:
                              const EdgeInsets.symmetric(vertical: 16),
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
                          child: Row(
                            children: [
                              _statItem(Icons.book_online_outlined,
                                  tr('profile_stat_bookings'), '—'),
                              _divider(),
                              _statItem(Icons.favorite_outline,
                                  tr('profile_stat_favorites'), '—'),
                              _divider(),
                              _statItem(Icons.star_outline,
                                  tr('profile_stat_reviews'), '—'),
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),
                        _sectionLabel(tr('profile_section_personal')),

                        // ── Fields ───────────────────────────────────────
                        _buildField(
                          controller: _usuarioController,
                          label: tr('profile_username'),
                          icon: Icons.person_outline,
                          enabled: _editMode,
                          validator: (v) =>
                              (v == null || v.trim().isEmpty)
                                  ? tr('profile_required')
                                  : null,
                        ),
                        const SizedBox(height: 12),
                        _buildField(
                          controller: _emailController,
                          label: tr('profile_email'),
                          icon: Icons.email_outlined,
                          enabled: _editMode,
                          keyboardType: TextInputType.emailAddress,
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) {
                              return tr('profile_required');
                            }
                            if (!v.contains('@')) {
                              return tr('profile_email_invalid');
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 24),
                        _sectionLabel(tr('profile_section_extra')),
                        _buildField(
                          controller: _direccionController,
                          label: tr('profile_address'),
                          icon: Icons.home_outlined,
                          enabled: _editMode,
                        ),
                        const SizedBox(height: 12),
                        _buildField(
                          controller: _paisNacimientoController,
                          label: tr('profile_birth_country'),
                          icon: Icons.public_outlined,
                          enabled: _editMode,
                        ),
                        const SizedBox(height: 12),
                        _buildField(
                          controller: _fechaNacimientoController,
                          label: tr('profile_birth_date'),
                          icon: Icons.cake_outlined,
                          enabled: _editMode,
                          hint: 'YYYY-MM-DD',
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) return null;
                            final reg = RegExp(r'^\d{4}-\d{2}-\d{2}$');
                            if (!reg.hasMatch(v.trim())) {
                              return tr('profile_date_format');
                            }
                            final parts = v.trim().split('-');
                            final year = int.tryParse(parts[0]) ?? 0;
                            final month = int.tryParse(parts[1]) ?? 0;
                            final day = int.tryParse(parts[2]) ?? 0;
                            if (year < 1900 || year > DateTime.now().year) {
                              return tr('profile_year_invalid');
                            }
                            if (month < 1 || month > 12) {
                              return tr('profile_month_invalid');
                            }
                            if (day < 1 || day > 31) {
                              return tr('profile_day_invalid');
                            }
                            return null;
                          },
                        ),

                        // ── Save button ──────────────────────────────────
                        if (_editMode) ...[
                          const SizedBox(height: 28),
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              onPressed:
                                  _isSaving ? null : _saveProfile,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _blue,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                    borderRadius:
                                        BorderRadius.circular(14)),
                              ),
                              child: _isSaving
                                  ? const SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2),
                                    )
                                  : Text(tr('profile_save'),
                                      style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w700)),
                            ),
                          ),
                        ],

                        // ── Account card ─────────────────────────────────
                        const SizedBox(height: 24),
                        _sectionLabel(tr('profile_section_account')),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color:
                                    Colors.black.withValues(alpha: 0.04),
                                blurRadius: 10,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              _accountTile(
                                icon: Icons.lock_outline,
                                color: _accent,
                                label: tr('profile_change_password'),
                                onTap: () => Navigator.pushNamed(
                                    context, '/settings'),
                              ),
                              const Divider(height: 0, indent: 56),
                              _accountTile(
                                icon: Icons.shield_outlined,
                                color: const Color(0xFF7C3AED),
                                label: tr('profile_2fa'),
                                onTap: () => Navigator.pushNamed(
                                    context, '/settings'),
                              ),
                              const Divider(height: 0, indent: 56),
                              _accountTile(
                                icon: Icons.logout,
                                color: Colors.red,
                                label: tr('profile_logout'),
                                onTap: () async {
                                  final nav = Navigator.of(context);
                                  await AuthService().signOut();
                                  nav.pushNamedAndRemoveUntil(
                                      '/login', (r) => false);
                                },
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 32),
                        const FooterWidget(),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _statItem(IconData icon, String label, String value) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: _blue, size: 22),
          const SizedBox(height: 4),
          Text(value,
              style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                  color: Color(0xFF1A1F36))),
          Text(label,
              style: const TextStyle(
                  fontSize: 11, color: Color(0xFF6B7A99))),
        ],
      ),
    );
  }

  Widget _divider() =>
      Container(width: 1, height: 40, color: const Color(0xFFE8ECF4));

  Widget _sectionLabel(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Text(text,
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Color(0xFF003B95),
                letterSpacing: 0.3)),
      );

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool enabled = true,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    String? hint,
  }) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon:
            Icon(icon, color: enabled ? _accent : Colors.grey, size: 20),
        filled: true,
        fillColor: enabled ? Colors.white : const Color(0xFFF5F7FB),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE8ECF4)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              const BorderSide(color: Color(0xFF0071C2), width: 1.5),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFF0F0F0)),
        ),
      ),
    );
  }

  Widget _accountTile({
    required IconData icon,
    required Color color,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(width: 14),
            Expanded(
                child: Text(label,
                    style: const TextStyle(
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF1A1F36)))),
            const Icon(Icons.chevron_right,
                color: Color(0xFF9CA8C0), size: 18),
          ],
        ),
      ),
    );
  }
}
