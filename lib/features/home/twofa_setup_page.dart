import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:qr_flutter/qr_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants/api_constants.dart';
import '../../core/services/language_settings.dart';
import '../../core/services/totp_service.dart';
import '../../shared/widgets/design/layout/custom_app_bar.dart';
import '../auth/auth_service.dart';

class TwoFaSetupPage extends StatefulWidget {
  const TwoFaSetupPage({super.key});

  @override
  State<TwoFaSetupPage> createState() => _TwoFaSetupPageState();
}

class _TwoFaSetupPageState extends State<TwoFaSetupPage> {
  static const Color _blue = Color(0xFF003B95);
  static const Color _accent = Color(0xFF0071C2);

  late final String _secret;
  late final String _qrData;
  final _codeController = TextEditingController();
  bool _verifying = false;
  bool _codeError = false;

  @override
  void initState() {
    super.initState();
    _secret = TotpService.generateSecret();
    final username = AuthService().username ?? 'user';
    _qrData = TotpService.buildOtpAuthUri(_secret, username);
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    final code = _codeController.text.trim();
    if (code.length != 6) {
      setState(() => _codeError = true);
      return;
    }
    setState(() {
      _verifying = true;
      _codeError = false;
    });

    final isValid = TotpService.verifyCode(_secret, code);
    if (!mounted) return;

    if (!isValid) {
      setState(() {
        _verifying = false;
        _codeError = true;
      });
      return;
    }

    // Code is valid locally — persist to server
    try {
      final token = AuthService().token;
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/2fa/setup'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'secret': _secret, 'code': code}),
      ).timeout(const Duration(seconds: 10));

      if (!mounted) return;

      if (response.statusCode == 200) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('2fa_enabled', true);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(LanguageSettings.instance.tr('2fa_success')),
            backgroundColor: Colors.green.shade700,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context, true);
      } else {
        String errorMsg = 'Error al activar 2FA (${response.statusCode})';
        try {
          final body = jsonDecode(response.body) as Map<String, dynamic>;
          errorMsg = body['error']?.toString() ?? errorMsg;
        } catch (_) {}
        _showSnackError(errorMsg);
        setState(() => _verifying = false);
      }
    } catch (e) {
      if (!mounted) return;
      _showSnackError('Error de conexión: $e');
      setState(() => _verifying = false);
    }
  }

  void _showSnackError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _copySecret() {
    Clipboard.setData(ClipboardData(text: _secret));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(LanguageSettings.instance.tr('twofa_copied')),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tr = LanguageSettings.instance.tr;

    return Scaffold(
      appBar: SkyTripAppBar(
        title: tr('2fa_setup_title'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _buildInfoBanner(tr),
            const SizedBox(height: 20),
            _buildQrCard(tr),
            const SizedBox(height: 20),
            _buildVerifyCard(tr),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoBanner(String Function(String) tr) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFEEF3FF),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFCCD8FF)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _blue,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.shield_outlined,
                color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              tr('twofa_info_banner'),
              style: const TextStyle(fontSize: 13, color: Color(0xFF2D3A5C)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQrCard(String Function(String) tr) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Step badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFEEF3FF),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              tr('twofa_step1'),
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: Color(0xFF003B95),
                letterSpacing: 1,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            tr('2fa_scan_qr'),
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            tr('2fa_scan_instructions'),
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13, color: Color(0xFF6B7A99)),
          ),
          const SizedBox(height: 24),
          // QR Code
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE8ECF4), width: 2),
            ),
            padding: const EdgeInsets.all(16),
            child: QrImageView(
              data: _qrData,
              version: QrVersions.auto,
              size: 200,
              backgroundColor: Colors.white,
              errorCorrectionLevel: QrErrorCorrectLevel.M,
              embeddedImageStyle: const QrEmbeddedImageStyle(size: Size(32, 32)),
            ),
          ),
          const SizedBox(height: 20),
          // Divider
          Row(
            children: [
              Expanded(child: Divider(color: Colors.grey.shade200)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  tr('2fa_manual_entry'),
                  style: const TextStyle(
                      fontSize: 12, color: Color(0xFF6B7A99)),
                ),
              ),
              Expanded(child: Divider(color: Colors.grey.shade200)),
            ],
          ),
          const SizedBox(height: 12),
          // Copyable secret
          GestureDetector(
            onTap: _copySecret,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFF0F4FF),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFDDE4F7)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Flexible(
                    child: Text(
                      _secret,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: _blue,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Icon(Icons.copy_rounded,
                      size: 18, color: _accent),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            tr('twofa_copy_hint'),
            style: const TextStyle(fontSize: 11, color: Color(0xFF9BA8C2)),
          ),
        ],
      ),
    );
  }

  Widget _buildVerifyCard(String Function(String) tr) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Step badge
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFF0FFF4),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              tr('twofa_step2'),
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1B8A4D),
                letterSpacing: 1,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            tr('2fa_verify_title'),
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            tr('2fa_verify_description'),
            style: const TextStyle(fontSize: 13, color: Color(0xFF6B7A99)),
          ),
          const SizedBox(height: 24),
          // Code input
          TextField(
            controller: _codeController,
            keyboardType: TextInputType.number,
            maxLength: 6,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w900,
              letterSpacing: 10,
              color: Color(0xFF1A1F36),
            ),
            decoration: InputDecoration(
              hintText: '000000',
              hintStyle: const TextStyle(
                color: Color(0xFFCDD5E8),
                fontSize: 32,
                letterSpacing: 10,
                fontWeight: FontWeight.w900,
              ),
              counterText: '',
              filled: true,
              fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    const BorderSide(color: Color(0xFFE0E7FF)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    const BorderSide(color: Color(0xFFE0E7FF)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    const BorderSide(color: _blue, width: 2),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    const BorderSide(color: Colors.red, width: 2),
              ),
              errorText: _codeError ? tr('2fa_invalid_code') : null,
            ),
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            onChanged: (_) {
              if (_codeError) setState(() => _codeError = false);
            },
            onSubmitted: (_) => _verify(),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _verifying ? null : _verify,
              icon: _verifying
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.verified_user_outlined, size: 20),
              label: Text(
                tr('2fa_verify_button'),
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w700),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: _blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
