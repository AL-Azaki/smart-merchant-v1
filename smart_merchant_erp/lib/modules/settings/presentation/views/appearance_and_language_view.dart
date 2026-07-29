import 'package:flutter/material.dart';
import '../../../../shared/design_system/tokens/colors.dart';
import '../../../../shared/design_system/tokens/spacing.dart';

class AppearanceAndLanguageView extends StatefulWidget {
  const AppearanceAndLanguageView({super.key});

  @override
  State<AppearanceAndLanguageView> createState() => _AppearanceAndLanguageViewState();
}

class _AppearanceAndLanguageViewState extends State<AppearanceAndLanguageView> {
  String _selectedLanguage = 'العربية';
  String _selectedTheme = 'فاتح';

  void _showLanguageDialog() {
    showDialog<void>(
      context: context,
      builder: (context) {
        return SimpleDialog(
          title: const Text('اختر اللغة', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold)),
          children: [
            SimpleDialogOption(
              onPressed: () {
                setState(() => _selectedLanguage = 'العربية');
                Navigator.of(context).pop();
              },
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text('العربية', textAlign: TextAlign.center, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
            SimpleDialogOption(
              onPressed: () {
                setState(() => _selectedLanguage = 'English');
                Navigator.of(context).pop();
              },
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text('English', textAlign: TextAlign.center, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showThemeDialog() {
    showDialog<void>(
      context: context,
      builder: (context) {
        return SimpleDialog(
          title: const Text('اختر المظهر', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold)),
          children: [
            SimpleDialogOption(
              onPressed: () {
                setState(() => _selectedTheme = 'فاتح');
                Navigator.of(context).pop();
              },
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text('فاتح (Light)', textAlign: TextAlign.center, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
            SimpleDialogOption(
              onPressed: () {
                setState(() => _selectedTheme = 'داكن');
                Navigator.of(context).pop();
              },
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text('داكن (Dark)', textAlign: TextAlign.center, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
            SimpleDialogOption(
              onPressed: () {
                setState(() => _selectedTheme = 'النظام');
                Navigator.of(context).pop();
              },
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text('تلقائي (النظام)', textAlign: TextAlign.center, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? AppColors.surfaceDark : Colors.white;
    final bg = isDark ? AppColors.backgroundDark : const Color(0xFFF8FAFC);
    final textPrimary = isDark ? AppColors.textPrimaryDark : const Color(0xFF0F172A);
    final textSecondary = isDark ? AppColors.textSecondaryDark : const Color(0xFF64748B);
    final borderColor = isDark ? AppColors.borderDark : const Color(0xFFE2E8F0);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        title: const Text(
          'المظهر واللغة',
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: borderColor, height: 1),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 700),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: AppSpacing.md),
                Text(
                  'المظهر واللغة',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: textPrimary,
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),

                // Card Container
                Container(
                  decoration: BoxDecoration(
                    color: surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: borderColor),
                  ),
                  child: Column(
                    children: [
                      // Language Row
                      InkWell(
                        onTap: _showLanguageDialog,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                          child: Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF3B82F6).withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(Icons.language_rounded, color: Color(0xFF3B82F6), size: 20),
                              ),
                              const SizedBox(width: 14),
                              Text(
                                'اللغة',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: textPrimary,
                                ),
                              ),
                              const Spacer(),
                              Text(
                                _selectedLanguage,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: textSecondary,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Icon(Icons.chevron_left_rounded, color: textSecondary, size: 20),
                            ],
                          ),
                        ),
                      ),

                      Divider(height: 1, color: borderColor),

                      // Appearance Theme Row
                      InkWell(
                        onTap: _showThemeDialog,
                        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                          child: Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF3B82F6).withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(Icons.wb_sunny_outlined, color: Color(0xFF3B82F6), size: 20),
                              ),
                              const SizedBox(width: 14),
                              Text(
                                'المظهر',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: textPrimary,
                                ),
                              ),
                              const Spacer(),
                              Text(
                                _selectedTheme,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: textSecondary,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Icon(Icons.chevron_left_rounded, color: textSecondary, size: 20),
                            ],
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
      ),
    );
  }
}
