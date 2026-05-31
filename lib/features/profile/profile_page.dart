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
  String? _loadError;

  int? _reservasCount;
  int? _favoritosCount;
  int? _reviewsCount;

  // Valores originales guardados al entrar en modo edición
  Map<String, String> _snapshot = {};

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

  // ── Guardar snapshot y entrar en modo edición ──────────────
  void _enterEditMode() {
    _snapshot = {
      'usuario': _usuarioController.text,
      'email': _emailController.text,
      'direccion': _direccionController.text,
      'paisNacimiento': _paisNacimientoController.text,
      'fechaNacimiento': _fechaNacimientoController.text,
    };
    setState(() => _editMode = true);
  }

  // ── Cancelar edición y restaurar valores originales ────────
  void _cancelEditMode() {
    _usuarioController.text = _snapshot['usuario'] ?? '';
    _emailController.text = _snapshot['email'] ?? '';
    _direccionController.text = _snapshot['direccion'] ?? '';
    _paisNacimientoController.text = _snapshot['paisNacimiento'] ?? '';
    _fechaNacimientoController.text = _snapshot['fechaNacimiento'] ?? '';
    setState(() => _editMode = false);
  }

  // ── Cargar perfil y estadísticas ──────────────────────────
  Future<void> _loadProfile() async {
    if (!mounted) return;
    setState(() { _isLoading = true; _loadError = null; });

    final token = AuthService().token;
    if (token == null) {
      if (mounted) setState(() { _isLoading = false; _loadError = 'No autenticado'; });
      return;
    }

    final authHeaders = {'Authorization': 'Bearer $token'};
    try {
      final results = await Future.wait([
        http.get(Uri.parse('${ApiConstants.baseUrl}/me'), headers: authHeaders),
        http.get(Uri.parse('${ApiConstants.baseUrl}/reservas'), headers: authHeaders),
        http.get(Uri.parse('${ApiConstants.baseUrl}/favoritos'), headers: authHeaders),
        http.get(Uri.parse('${ApiConstants.baseUrl}/reviews/mine'), headers: authHeaders),
      ]).timeout(const Duration(seconds: 20));

      if (!mounted) return;

      // Perfil
      if (results[0].statusCode == 200) {
        final data = jsonDecode(results[0].body);
        if (data is Map) {
          _usuarioController.text = data['usuario']?.toString() ?? '';
          _emailController.text = data['email']?.toString() ?? '';
          _direccionController.text = data['direccion']?.toString() ?? '';
          _paisNacimientoController.text = data['pais_nacimiento']?.toString() ?? '';
          _fechaNacimientoController.text = data['fecha_nacimiento']?.toString() ?? '';
        }
      }

      // Reservas
      if (results[1].statusCode == 200) {
        final list = jsonDecode(results[1].body);
        _reservasCount = list is List
            ? list.length
            : (list is Map && list['data'] is List
                ? (list['data'] as List).length
                : 0);
      }

      // Favoritos
      if (results[2].statusCode == 200) {
        final list = jsonDecode(results[2].body);
        _favoritosCount = list is List ? list.length : 0;
      }

      // Reseñas (endpoint autenticado /reviews/mine)
      if (results[3].statusCode == 200) {
        final list = jsonDecode(results[3].body);
        _reviewsCount = list is List ? list.length : 0;
      }
    } catch (_) {
      if (mounted) _loadError = LanguageSettings.instance.tr('reservas_cancel_conn_error');
    }

    if (mounted) setState(() => _isLoading = false);
  }

  // ── Guardar cambios ────────────────────────────────────────
  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    // Bug fix: comprobar token ANTES de activar el spinner
    final token = AuthService().token;
    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(LanguageSettings.instance.tr('profile_connection_error')),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);
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
          'direccion': _direccionController.text.trim(),
          'pais_nacimiento': _paisNacimientoController.text.trim(),
          'fecha_nacimiento': _fechaNacimientoController.text.trim(),
        }),
      ).timeout(const Duration(seconds: 15));

      if (!mounted) return;

      if (response.statusCode == 200) {
        setState(() => _editMode = false);
        // Actualizar snapshot con los nuevos valores guardados
        _snapshot = {
          'usuario': _usuarioController.text,
          'email': _emailController.text,
          'direccion': _direccionController.text,
          'paisNacimiento': _paisNacimientoController.text,
          'fechaNacimiento': _fechaNacimientoController.text,
        };
        messenger.showSnackBar(SnackBar(
          content: Row(children: [
            const Icon(Icons.check_circle_outline, color: Colors.white),
            const SizedBox(width: 10),
            Text(tr('profile_updated_ok')),
          ]),
          backgroundColor: const Color(0xFF22C55E),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ));
      } else {
        String errMsg = tr('profile_updated_error');
        try {
          final b = jsonDecode(response.body) as Map<String, dynamic>;
          final s = b['error']?.toString() ?? '';
          if (s.isNotEmpty) errMsg = s;
        } catch (_) {}
        messenger.showSnackBar(SnackBar(
          content: Text(errMsg),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ));
      }
    } catch (_) {
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(
        content: Text(tr('profile_connection_error')),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ));
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

    if (_loadError != null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text(_loadError!),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadProfile,
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }

    return ValueListenableBuilder<String>(
      valueListenable: LanguageSettings.instance.locale,
      builder: (context, locale, child) {
        final tr = LanguageSettings.instance.tr;
        final isAdmin = AuthService().isAdmin;

        return Scaffold(
          body: CustomScrollView(
            slivers: [
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
                          child: Image.asset(
                            'assets/images/logo.png',
                            fit: BoxFit.contain,
                            errorBuilder: (_, _, _) => Icon(
                              Icons.flight_takeoff,
                              color: AppColorScheme.accentFor(context),
                              size: 16,
                            ),
                          ),
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
                    icon: Icon(_editMode ? Icons.close : Icons.edit_outlined),
                    tooltip: _editMode
                        ? tr('cancel')
                        : tr('profile_edit_tooltip'),
                    onPressed: _editMode ? _cancelEditMode : _enterEditMode,
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
                            color: Colors.white.withValues(alpha: 0.05),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 24,
                        left: 0,
                        right: 0,
                        child: ListenableBuilder(
                          listenable: _usuarioController,
                          builder: (context2, child2) => Column(
                            children: [
                              Container(
                                width: 80,
                                height: 80,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white.withValues(alpha: 0.15),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.5),
                                    width: 2.5,
                                  ),
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
                                      : Colors.white.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  isAdmin
                                      ? tr('profile_admin')
                                      : tr('profile_traveler'),
                                  style: TextStyle(
                                    color: isAdmin
                                        ? Theme.of(context)
                                            .colorScheme
                                            .onSurface
                                        : Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
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
                        // ── Stats ───────────────────────────────────────────
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surface,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.05),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              _statItem(Icons.book_online_outlined,
                                  tr('profile_stat_bookings'),
                                  _reservasCount?.toString() ?? '—'),
                              _divider(),
                              _statItem(Icons.favorite_outline,
                                  tr('profile_stat_favorites'),
                                  _favoritosCount?.toString() ?? '—'),
                              _divider(),
                              _statItem(Icons.star_outline,
                                  tr('profile_stat_reviews'),
                                  _reviewsCount?.toString() ?? '—'),
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),
                        _sectionLabel(tr('profile_section_personal')),

                        _buildField(
                          controller: _usuarioController,
                          label: tr('profile_username'),
                          icon: Icons.person_outline,
                          enabled: _editMode,
                          validator: (v) => (v == null || v.trim().isEmpty)
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

                        // ── Botón guardar ───────────────────────────────────
                        if (_editMode) ...[
                          const SizedBox(height: 28),
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              onPressed: _isSaving ? null : _saveProfile,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _blue,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14)),
                              ),
                              child: _isSaving
                                  ? const SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(
                                          color: Colors.white, strokeWidth: 2),
                                    )
                                  : Text(tr('profile_save'),
                                      style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w700)),
                            ),
                          ),
                        ],

                        // ── Cuenta ──────────────────────────────────────────
                        const SizedBox(height: 24),
                        _sectionLabel(tr('profile_section_account')),
                        Container(
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surface,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.04),
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
                                onTap: () =>
                                    Navigator.pushNamed(context, '/settings'),
                              ),
                              const Divider(height: 0, indent: 56),
                              _accountTile(
                                icon: Icons.shield_outlined,
                                color: const Color(0xFF7C3AED),
                                label: tr('profile_2fa'),
                                onTap: () =>
                                    Navigator.pushNamed(context, '/settings'),
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
              style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                  color: Theme.of(context).colorScheme.onSurface)),
          Text(label,
              style: TextStyle(
                  fontSize: 11,
                  color: Theme.of(context).colorScheme.onSurfaceVariant)),
        ],
      ),
    );
  }

  Widget _divider() => Container(
        width: 1,
        height: 40,
        color: Theme.of(context).colorScheme.outlineVariant,
      );

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
        prefixIcon: Icon(
          icon,
          color: enabled
              ? _accent
              : Theme.of(context).colorScheme.onSurfaceVariant,
          size: 20,
        ),
        filled: true,
        fillColor: enabled
            ? Theme.of(context).colorScheme.surface
            : Theme.of(context).colorScheme.surfaceContainerLow,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              const BorderSide(color: Color(0xFF0071C2), width: 1.5),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: Theme.of(context)
                .colorScheme
                .outlineVariant
                .withValues(alpha: 0.5),
          ),
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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
                  style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: Theme.of(context).colorScheme.onSurface)),
            ),
            Icon(Icons.chevron_right,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                size: 18),
          ],
        ),
      ),
    );
  }
}
