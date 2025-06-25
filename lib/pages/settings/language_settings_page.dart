import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart'; // Adicionado para a tradução
import 'package:google_fonts/google_fonts.dart';
import 'package:projetogpsnovo/helpers/preferences_helpers.dart';

class LanguageSettingsPage extends StatefulWidget {
  const LanguageSettingsPage({super.key});

  @override
  State<LanguageSettingsPage> createState() => _LanguageSettingsPageState();
}

class _LanguageSettingsPageState extends State<LanguageSettingsPage> {
  late Locale selectedLocale;
  final PreferencesHelper _preferencesHelper = PreferencesHelper();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    selectedLocale = context.locale;
  }

  @override
  Widget build(BuildContext context) {
    final List<Locale> supportedLocales = context.supportedLocales;

    final TextStyle titleStyle = GoogleFonts.poppins(
      fontSize: 18,
      fontWeight: FontWeight.bold,
      color: Theme.of(context).brightness == Brightness.dark ? Colors.white : const Color(0xFF00B4D8),
    );

    final TextStyle itemStyle = GoogleFonts.poppins(
      fontSize: 16,
      color: Theme.of(context).brightness == Brightness.dark ? Colors.white70 : Colors.black87,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text('language_settings_page.language'.tr(), style: titleStyle), // Tradução
        backgroundColor: Theme.of(context).brightness == Brightness.dark ? Colors.black : Colors.white,
        foregroundColor: const Color(0xFF00B4D8),
        elevation: 1,
      ),
      body: ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: supportedLocales.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final locale = supportedLocales[index];
          final isSelected = locale == selectedLocale;

          return RadioListTile<Locale>(
            value: locale,
            groupValue: selectedLocale,
            onChanged: (value) async {
              if (value != null) {
                setState(() {
                  selectedLocale = value;
                });
                context.setLocale(value);

                // Salvar o idioma selecionado no SharedPreferences
                await _preferencesHelper.saveLanguageCode(value.languageCode);
              }
            },
            activeColor: const Color(0xFF00B4D8),
            title: Text(
              _getLanguageName(locale.languageCode).tr(), // Tradução
              style: itemStyle.copyWith(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16),
          );
        },
      ),
    );
  }

  String _getLanguageName(String code) {
    switch (code) {
      case 'pt':
        return 'Português';
      case 'en':
        return 'English';
      case 'es':
        return 'Español';
      case 'fr':
        return 'Français';
      case 'de':
        return 'Deutsch';
      case 'it':
        return 'Italiano';
      case 'ru':
        return 'Русский';
      case 'uk':
        return 'Українська';
      case 'zh':
        return '中文';
      case 'nl':
        return 'Nederlands';
      case 'pl':
        return 'Polski';
      case 'ar':
        return 'العربية';
      case 'tr':
        return 'Türkçe';
      case 'cs':
        return 'Čeština';
      default:
        return code;
    }
  }
}
