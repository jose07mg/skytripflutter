import 'package:flutter/material.dart';

import '../../core/constants/content_service.dart';
import '../../core/services/language_settings.dart';
import '../../shared/themes/color_scheme.dart';
import '../../shared/widgets/design/layout/custom_app_bar.dart';
import '../../shared/widgets/design/layout/footer.dart';

class CondicionesPage extends StatefulWidget {
  const CondicionesPage({super.key});

  @override
  State<CondicionesPage> createState() => _CondicionesPageState();
}

class _CondicionesPageState extends State<CondicionesPage> {
  List<Map<String, String>> _sections = [];

  @override
  void initState() {
    super.initState();
    _load();
    ContentService.instance.version.addListener(_load);
    LanguageSettings.instance.locale.addListener(_load);
  }

  @override
  void dispose() {
    ContentService.instance.version.removeListener(_load);
    LanguageSettings.instance.locale.removeListener(_load);
    super.dispose();
  }

  void _load() {
    if (!mounted) return;
    setState(() {
      _sections = ContentService.instance.getPageSections('condiciones');
    });
  }

  @override
  Widget build(BuildContext context) {
    final tr = LanguageSettings.instance.tr;
    return Scaffold(
      appBar: SkyTripAppBar(
        title: tr('terms_title'),
        backgroundColor: const Color(0xFF003B95),
        showMenu: false,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tr('terms_page_title'),
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 20),
                  ..._sections.map(
                    (s) => _buildSection(
                      s['title'] ?? '',
                      s['content'] ?? '',
                    ),
                  ),
                  const SizedBox(height: 40),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColorScheme.accentFor(context).withValues(alpha: 0.4)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tr('terms_contact_title'),
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColorScheme.titleFor(context),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          tr('terms_contact_body'),
                          style: TextStyle(fontSize: 14, color: Theme.of(context).colorScheme.onSurface),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const FooterWidget(),
        ],
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColorScheme.titleFor(context),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: TextStyle(
              fontSize: 16,
              height: 1.6,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}
