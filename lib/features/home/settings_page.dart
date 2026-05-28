import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:skytrip/features/auth/auth_service.dart';
import 'package:skytrip/core/constants/api_constants.dart';
import 'package:skytrip/core/theme_settings.dart';
import 'package:skytrip/core/services/language_settings.dart';
import 'package:skytrip/shared/themes/color_scheme.dart';
import 'package:skytrip/shared/widgets/design/layout/custom_app_bar.dart';
import 'package:skytrip/shared/widgets/design/layout/footer.dart';
import 'twofa_setup_page.dart';

// ---- Currency settings singleton ----
class CurrencySettings {
  static final instance = CurrencySettings._();
  CurrencySettings._();

  final ValueNotifier<String> currency = ValueNotifier('EUR');

  final Map<String, String> symbols = const {
    'EUR': '€',
    'USD': '\$',
    'GBP': '£',
    'JPY': '¥',
    'MXN': '\$',
  };

  final Map<String, double> rates = const {
    'EUR': 1.0,
    'USD': 1.08,
    'GBP': 0.85,
    'JPY': 163.5,
    'MXN': 18.4,
  };

  final List<String> available = const ['EUR', 'USD', 'GBP', 'JPY', 'MXN'];

  String getSymbol() => symbols[currency.value] ?? '€';

  String getConvertedPrice(num priceInEur) {
    final rate = rates[currency.value] ?? 1.0;
    final converted = priceInEur * rate;
    final decimals = currency.value == 'JPY' ? 0 : 2;
    return converted.toStringAsFixed(decimals);
  }

  double convertFromEur(num priceInEur) {
    final rate = rates[currency.value] ?? 1.0;
    return priceInEur * rate;
  }

  double convertToEur(num priceInCurrentCurrency) {
    final rate = rates[currency.value] ?? 1.0;
    if (rate == 0) return priceInCurrentCurrency.toDouble();
    return priceInCurrentCurrency / rate;
  }
}

// ---- Settings Page ----
class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  static const Color _blue = Color(0xFF003B95);
  static const Color _accent = Color(0xFF0071C2);

  final _auth = AuthService();
  bool _twoFaEnabled = false;

  @override
  void initState() {
    super.initState();
    _load2FaStatus();
  }

  Future<void> _load2FaStatus() async {
    // First check local cache for instant render
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() => _twoFaEnabled = prefs.getBool('2fa_enabled') ?? false);
    }
    // Then verify against server (source of truth)
    final token = _auth.token;
    if (token == null) return;
    try {
      final r = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/2fa/status'),
        headers: {'Authorization': 'Bearer $token'},
      ).timeout(const Duration(seconds: 8));
      if (r.statusCode == 200) {
        final body = jsonDecode(r.body);
        final enabled = body['totp_enabled'] == true || body['data']?['totp_enabled'] == true;
        await prefs.setBool('2fa_enabled', enabled);
        if (mounted) setState(() => _twoFaEnabled = enabled);
      }
    } catch (_) {}
  }

  // ---- Dialogs ----

  void _showChangePasswordDialog() {
    final tr = LanguageSettings.instance.tr;
    final oldCtrl = TextEditingController();
    final newCtrl = TextEditingController();

    final messenger = ScaffoldMessenger.of(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(tr('settings_change_password'),
            style: const TextStyle(fontWeight: FontWeight.w700)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: oldCtrl,
              decoration: InputDecoration(
                labelText: tr('settings_current_password'),
                prefixIcon: const Icon(Icons.lock_outline),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: newCtrl,
              decoration: InputDecoration(
                labelText: tr('settings_new_password'),
                prefixIcon: const Icon(Icons.lock_reset_outlined),
              ),
              obscureText: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(tr('cancel')),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: _blue, foregroundColor: Colors.white),
            onPressed: () async {
              try {
                await _auth.changePassword(oldCtrl.text, newCtrl.text);
                if (!ctx.mounted) return;
                Navigator.pop(ctx);
                messenger.showSnackBar(
                  SnackBar(
                    content: Text(tr('settings_password_updated')),
                    backgroundColor: Colors.green,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              } catch (e) {
                if (!ctx.mounted) return;
                messenger.showSnackBar(
                  SnackBar(
                    content: Text(e.toString()),
                    backgroundColor: Colors.red,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            child: Text(tr('save')),
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountDialog() {
    final tr = LanguageSettings.instance.tr;
    final messenger = ScaffoldMessenger.of(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(tr('settings_delete_title'),
            style: const TextStyle(
                color: Colors.red, fontWeight: FontWeight.w700)),
        content: Text(tr('settings_delete_content')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(tr('cancel')),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              try {
                await _auth.deleteAccount();
                if (!ctx.mounted) return;
                Navigator.of(ctx)
                    .pushNamedAndRemoveUntil('/login', (r) => false);
              } catch (e) {
                if (!ctx.mounted) return;
                messenger.showSnackBar(
                  SnackBar(
                    content: Text(tr('settings_delete_error')),
                    backgroundColor: Colors.red,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            child: Text(tr('settings_delete_btn'),
                style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _disable2Fa() async {
    final tr = LanguageSettings.instance.tr;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(tr('settings_2fa_disable_title'),
            style: const TextStyle(fontWeight: FontWeight.w700)),
        content: Text(tr('settings_2fa_disable_content')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(tr('cancel')),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(tr('settings_2fa_disable_confirm')),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      final token = _auth.token;
      if (token != null) {
        try {
          await http.post(
            Uri.parse('${ApiConstants.baseUrl}/2fa/disable'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode({}),
          ).timeout(const Duration(seconds: 8));
        } catch (_) {}
      }
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('2fa_secret');
      await prefs.setBool('2fa_enabled', false);
      if (!mounted) return;
      setState(() => _twoFaEnabled = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(tr('2fa_disabled_success')),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // ---- Build ----

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: LanguageSettings.instance.locale,
      builder: (context, currentLocale, _) {
        final tr = LanguageSettings.instance.tr;
        final username = _auth.username ?? 'Usuario';
        final role = _auth.role ?? 'Viajero';

        return Scaffold(
          appBar: SkyTripAppBar(
            title: tr('settings_title'),
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (_auth.isAuthenticated) ...[
                _sectionHeader(tr('settings_account')),
                _buildAccountCard(username, role),
                const SizedBox(height: 24),
              ],
              _sectionHeader(tr('settings_language')),
              _buildLanguageCard(tr),
              if (_auth.isAuthenticated) ...[
                const SizedBox(height: 24),
                _sectionHeader(tr('settings_regional')),
                _buildCurrencyCard(tr),
                const SizedBox(height: 24),
                _sectionHeader(tr('settings_customization')),
                _buildThemeCard(tr),
                const SizedBox(height: 24),
                _sectionHeader(tr('settings_security')),
                _buildSecurityCard(tr),
              ],
              const SizedBox(height: 40),
              const FooterWidget(),
            ],
          ),
        );
      },
    );
  }

  Widget _sectionHeader(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, left: 4),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          color: AppColorScheme.accentFor(context),
          letterSpacing: 1,
        ),
      ),
    );
  }

  Widget _buildAccountCard(String username, String role) {
    final tr = LanguageSettings.instance.tr;
    return _card(
      child: Column(
        children: [
          const SizedBox(height: 8),
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF003B95), Color(0xFF0071C2)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF003B95).withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(Icons.person, size: 40, color: Colors.white),
          ),
          const SizedBox(height: 16),
          Text(
            username,
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColorScheme.titleFor(context)),
          ),
          const SizedBox(height: 4),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFEEF3FF),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              role.toUpperCase(),
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: AppColorScheme.accentFor(context),
                  letterSpacing: 1),
            ),
          ),
          const SizedBox(height: 16),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.person_outline, color: _accent),
            title: Text(tr('settings_username'),
                style: TextStyle(fontSize: 13, color: AppColorScheme.subtitleFor(context))),
            subtitle: Text(username,
                style: const TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w600)),
            dense: true,
          ),
          ListTile(
            leading: const Icon(Icons.verified_user_outlined, color: _accent),
            title: Text(tr('settings_role'),
                style: TextStyle(fontSize: 13, color: AppColorScheme.subtitleFor(context))),
            subtitle: Text(role.toUpperCase(),
                style: const TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w600)),
            dense: true,
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageCard(String Function(String) tr) {
    return _card(
      child: ValueListenableBuilder<String>(
        valueListenable: LanguageSettings.instance.locale,
        builder: (context, currentLocale, _) {
          return Column(
            children: [
              ListTile(
                leading: const Icon(Icons.language_outlined, color: _accent),
                title: Text(tr('settings_language'),
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text(
                  currentLocale == 'es' ? 'Español' : 'English',
                  style: TextStyle(color: AppColorScheme.subtitleFor(context)),
                ),
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    _langButton(
                      label: 'Español',
                      flag: '🇪🇸',
                      selected: currentLocale == 'es',
                      onTap: () => LanguageSettings.instance.setLocale('es'),
                    ),
                    const SizedBox(width: 12),
                    _langButton(
                      label: 'English',
                      flag: '🇬🇧',
                      selected: currentLocale == 'en',
                      onTap: () => LanguageSettings.instance.setLocale('en'),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _langButton({
    required String label,
    required String flag,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: selected ? _blue : (Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1E2A40) : const Color(0xFFF0F4FF)),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? _blue : (Theme.of(context).brightness == Brightness.dark ? const Color(0xFF2D3E5A) : const Color(0xFFDDE4F7)),
              width: selected ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              Text(flag, style: const TextStyle(fontSize: 24)),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: selected ? Colors.white : Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCurrencyCard(String Function(String) tr) {
    final cs = CurrencySettings.instance;
    return _card(
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              leading: const Icon(Icons.attach_money_outlined, color: _accent),
              title: Text(tr('settings_currency'),
                  style: const TextStyle(fontWeight: FontWeight.w600)),
            ),
            ValueListenableBuilder<String>(
              valueListenable: cs.currency,
              builder: (context, currentCurrency, _) {
                return Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFE8ECF4)),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: currentCurrency,
                        isExpanded: true,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        borderRadius: BorderRadius.circular(10),
                        items: cs.available
                            .map((v) => DropdownMenuItem(
                                  value: v,
                                  child: Row(
                                    children: [
                                      Text(cs.symbols[v] ?? '',
                                          style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w700,
                                              color: _blue)),
                                      const SizedBox(width: 10),
                                      Text(v,
                                          style: const TextStyle(
                                              fontWeight: FontWeight.w600)),
                                    ],
                                  ),
                                ))
                            .toList(),
                        onChanged: (newValue) {
                          if (newValue != null) {
                            cs.currency.value = newValue;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content:
                                    Text('${LanguageSettings.instance.tr('settings_currency_changed')}$newValue'),
                                behavior: SnackBarBehavior.floating,
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          }
                        },
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeCard(String Function(String) tr) {
    return _card(
      child: ValueListenableBuilder<ThemeMode>(
        valueListenable: ThemeSettings.instance.themeMode,
        builder: (context, mode, _) {
          final isDark = mode == ThemeMode.dark;
          return ListTile(
            leading: Icon(
              isDark ? Icons.dark_mode : Icons.light_mode_outlined,
              color: _accent,
            ),
            title: Text(tr('settings_dark_mode'),
                style: const TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Text(
                isDark
                    ? tr('settings_dark_mode_on')
                    : tr('settings_dark_mode_off'),
                style: TextStyle(color: AppColorScheme.subtitleFor(context))),
            trailing: Switch(
              value: isDark,
              onChanged: (_) => unawaited(ThemeSettings.instance.toggleTheme()),
              activeThumbColor: _blue,
            ),
          );
        },
      ),
    );
  }

  Widget _buildSecurityCard(String Function(String) tr) {
    return _card(
      child: Column(
        children: [
          // Change password
          ListTile(
            leading: const Icon(Icons.lock_outline, color: _accent),
            title: Text(tr('settings_change_password'),
                style: const TextStyle(fontWeight: FontWeight.w600)),
            trailing: const Icon(Icons.chevron_right,
                color: Color(0xFF9BA8C2)),
            onTap: _showChangePasswordDialog,
          ),
          const Divider(height: 1, indent: 16),
          // Notifications
          ListTile(
            leading:
                const Icon(Icons.notifications_none, color: _accent),
            title: Text(tr('settings_notifications'),
                style: const TextStyle(fontWeight: FontWeight.w600)),
            trailing: Switch(
              value: _auth.notificationsEnabled,
              onChanged: (val) {
                setState(() => _auth.setNotifications(val));
              },
              activeThumbColor: _blue,
            ),
          ),
          const Divider(height: 1, indent: 16),
          // 2FA
          _build2FaTile(tr),
          const Divider(height: 1, indent: 16),
          // Delete account
          ListTile(
            leading:
                const Icon(Icons.delete_forever, color: Colors.red),
            title: Text(tr('settings_delete_account'),
                style: const TextStyle(
                    color: Colors.red, fontWeight: FontWeight.w600)),
            trailing: const Icon(Icons.chevron_right,
                color: Colors.red),
            onTap: _showDeleteAccountDialog,
          ),
        ],
      ),
    );
  }

  Widget _build2FaTile(String Function(String) tr) {
    return ListTile(
      leading: Icon(
        _twoFaEnabled
            ? Icons.verified_user
            : Icons.shield_outlined,
        color: _twoFaEnabled ? Colors.green.shade600 : _accent,
      ),
      title: Text(tr('settings_2fa'),
          style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _twoFaEnabled
                ? tr('settings_2fa_enabled')
                : tr('settings_2fa_disabled'),
            style: TextStyle(
              color: _twoFaEnabled
                  ? Colors.green.shade700
                  : const Color(0xFF9BA8C2),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          Text(tr('settings_2fa_description'),
              style: TextStyle(
                  fontSize: 12, color: AppColorScheme.subtitleFor(context))),
        ],
      ),
      isThreeLine: true,
      trailing: _twoFaEnabled
          ? OutlinedButton(
              onPressed: _disable2Fa,
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.orange,
                side: const BorderSide(color: Colors.orange),
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 6),
              ),
              child: Text(tr('settings_2fa_disable'),
                  style: const TextStyle(fontSize: 12)),
            )
          : ElevatedButton(
              onPressed: () async {
                final result = await Navigator.push<bool?>(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const TwoFaSetupPage()),
                );
                if (result == true) _load2FaStatus();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 6),
              ),
              child: Text(tr('settings_2fa_setup'),
                  style: const TextStyle(fontSize: 12)),
            ),
    );
  }

  Widget _card({required Widget child}) {
    return Container(
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
      child: child,
    );
  }
}
