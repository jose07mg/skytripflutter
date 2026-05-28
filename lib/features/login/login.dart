import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/services/language_settings.dart';
import '../auth/auth_service.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _userController = TextEditingController();
  final _passwordController = TextEditingController();
  final _codeController = TextEditingController();
  final _authService = AuthService();

  bool _isLoading = false;
  bool _obscurePassword = true;
  // 1 = password step, 2 = 2FA step
  int _step = 1;

  @override
  void dispose() {
    _userController.dispose();
    _passwordController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (_isLoading) return;
    final username = _userController.text.trim();
    final password = _passwordController.text;

    if (username.isEmpty || password.isEmpty) {
      _showError(LanguageSettings.instance.tr('login_error_empty'));
      return;
    }

    setState(() => _isLoading = true);

    try {
      final needsTotp = await _authService.signInWithUsernameAndPassword(
        username: username,
        password: password,
      );
      if (!mounted) return;

      if (needsTotp) {
        setState(() {
          _step = 2;
          _isLoading = false;
        });
      } else {
        Navigator.pushReplacementNamed(context, '/home');
      }
    } on AuthException catch (e) {
      if (!mounted) return;
      _showError(e.message);
      _passwordController.clear();
      setState(() => _isLoading = false);
    }
  }

  Future<void> _verify2Fa() async {
    final code = _codeController.text.trim();
    if (code.length != 6) {
      _showError(LanguageSettings.instance.tr('login_2fa_invalid'));
      return;
    }
    setState(() => _isLoading = true);
    try {
      await _authService.completeLoginWithTotp(code);
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/home');
    } on AuthException catch (e) {
      if (!mounted) return;
      _showError(e.message);
      _codeController.clear();
      setState(() => _isLoading = false);
    }
  }

  void _backToPassword() {
    _authService.signOut();
    setState(() {
      _step = 1;
      _codeController.clear();
    });
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: LanguageSettings.instance.locale,
      builder: (context, locale, _) {
        return Scaffold(
          backgroundColor: const Color(0xFF003B95),
          body: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 350),
                  transitionBuilder: (child, anim) => SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(1, 0),
                      end: Offset.zero,
                    ).animate(CurvedAnimation(
                        parent: anim, curve: Curves.easeOutCubic)),
                    child: FadeTransition(opacity: anim, child: child),
                  ),
                  child: _step == 1
                      ? _buildPasswordStep()
                      : _buildTwoFaStep(),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPasswordStep() {
    final tr = LanguageSettings.instance.tr;
    return Column(
      key: const ValueKey('step1'),
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Logo
        Image.asset(
          'assets/images/logo.png',
          height: 150,
          errorBuilder: (ctx, err, stack) => const Icon(
            Icons.airplanemode_active,
            color: Colors.white,
            size: 100,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'SkyTrip',
          style: TextStyle(
            fontSize: 36,
            fontWeight: FontWeight.w900,
            color: Colors.white,
            letterSpacing: -1,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          tr('login_tagline'),
          style: const TextStyle(
            fontSize: 14,
            color: Colors.white70,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 40),

        // Username field
        _inputField(
          controller: _userController,
          hint: tr('login_username'),
          icon: Icons.person_outline,
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 16),

        // Password field
        _inputField(
          controller: _passwordController,
          hint: tr('login_password'),
          icon: Icons.lock_outline,
          obscure: _obscurePassword,
          suffix: IconButton(
            icon: Icon(
              _obscurePassword
                  ? Icons.visibility_outlined
                  : Icons.visibility_off_outlined,
              color: Colors.grey,
            ),
            onPressed: () =>
                setState(() => _obscurePassword = !_obscurePassword),
          ),
          onSubmitted: (_) => _login(),
        ),
        const SizedBox(height: 28),

        // Login button
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _login,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF003B95),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
              elevation: 0,
            ),
            child: _isLoading
                ? const SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(
                        strokeWidth: 2.5, color: Colors.white),
                  )
                : Text(
                    tr('login_button'),
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w700),
                  ),
          ),
        ),
        const SizedBox(height: 20),

        // Register link
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(tr('login_no_account'),
                style: const TextStyle(color: Colors.white70)),
            TextButton(
              onPressed: () => Navigator.pushNamed(context, '/register'),
              child: Text(
                tr('login_register'),
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),

        // About us link
        TextButton(
          onPressed: () => Navigator.pushNamed(context, '/about-us'),
          child: Text(
            tr('login_about'),
            style: const TextStyle(color: Colors.white60, fontSize: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildTwoFaStep() {
    final tr = LanguageSettings.instance.tr;
    return Column(
      key: const ValueKey('step2'),
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Icon
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.2),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.shield_outlined,
              color: Colors.white, size: 44),
        ),
        const SizedBox(height: 24),

        Text(
          tr('login_2fa_title'),
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          tr('login_2fa_subtitle'),
          style: const TextStyle(fontSize: 14, color: Colors.white70),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 36),

        // Code input
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.95),
            borderRadius: BorderRadius.circular(14),
          ),
          child: TextField(
            controller: _codeController,
            keyboardType: TextInputType.number,
            maxLength: 6,
            textAlign: TextAlign.center,
            autofocus: true,
            style: const TextStyle(
              fontSize: 34,
              fontWeight: FontWeight.w900,
              letterSpacing: 12,
              color: Color(0xFF1A1F36),
            ),
            decoration: const InputDecoration(
              hintText: '······',
              hintStyle: TextStyle(
                color: Color(0xFFCDD5E8),
                fontSize: 34,
                letterSpacing: 12,
                fontWeight: FontWeight.w900,
              ),
              counterText: '',
              border: InputBorder.none,
              contentPadding:
                  EdgeInsets.symmetric(vertical: 18, horizontal: 16),
            ),
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            onSubmitted: (_) => _verify2Fa(),
          ),
        ),
        const SizedBox(height: 20),

        // Verify button
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton.icon(
            onPressed: _verify2Fa,
            icon: const Icon(Icons.verified_user_outlined),
            label: Text(
              tr('login_2fa_button'),
              style: const TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w700),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF003B95),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
              elevation: 0,
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Back link
        TextButton.icon(
          onPressed: _backToPassword,
          icon: const Icon(Icons.arrow_back_ios_new,
              size: 14, color: Colors.white70),
          label: Text(
            tr('login_2fa_back'),
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
        ),
      ],
    );
  }

  Widget _inputField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    bool obscure = false,
    Widget? suffix,
    ValueChanged<String>? onSubmitted,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscure,
      style: const TextStyle(color: Colors.black87),
      onSubmitted: onSubmitted,
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: Colors.grey),
        suffixIcon: suffix,
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.grey),
        filled: true,
        fillColor: const Color(0xF0FFFFFF),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 16),
      ),
    );
  }
}
