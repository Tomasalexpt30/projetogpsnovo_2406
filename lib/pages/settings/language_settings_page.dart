import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart'; // para tradução
import 'package:google_fonts/google_fonts.dart';
import 'package:projetogpsnovo/helpers/preferences_helpers.dart';

class LanguageSettingsPage extends StatefulWidget {
  const LanguageSettingsPage({super.key});

  @override
  State<LanguageSettingsPage> createState() => _LanguageSettingsPageState();
}

class _LanguageSettingsPageState extends State<LanguageSettingsPage> {
  late Locale selectedLocale; // idioma selecionado
  final PreferencesHelper _preferencesHelper = PreferencesHelper(); // helper para guardar preferências

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    selectedLocale = context.locale; // obtém idioma atual do contexto
  }

  @override
  Widget build(BuildContext context) {
    final List<Locale> supportedLocales = context.supportedLocales; // lista de idiomas suportados

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
        title: Text('language_settings_page.language'.tr(), style: titleStyle), // título traduzido
        backgroundColor: Theme.of(context).brightness == Brightness.dark ? Colors.black : Colors.white,
        foregroundColor: const Color(0xFF00B4D8),
        elevation: 1,
      ),
      body: ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: supportedLocales.length, // número de idiomas
        separatorBuilder: (_, __) => const Divider(height: 1), // separador entre itens
        itemBuilder: (context, index) {
          final locale = supportedLocales[index];
          final isSelected = locale == selectedLocale; // verifica se está selecionado

          return RadioListTile<Locale>(
            value: locale,
            groupValue: selectedLocale,
            onChanged: (value) async {
              if (value != null) {
                setState(() {
                  selectedLocale = value; // atualiza seleção
                });
                context.setLocale(value); // aplica idioma
              }
            },
            activeColor: const Color(0xFF00B4D8),
            title: Text(
              _getLanguageName(locale.languageCode).tr(), // mostra nome do idioma
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
      case 'pt': return 'Português';
      case 'en': return 'English';
      case 'es': return 'Español';
      case 'fr': return 'Français';
      case 'de': return 'Deutsch';
      case 'it': return 'Italiano';
      case 'ru': return 'Русский';
      case 'uk': return 'Українська';
      case 'nl': return 'Nederlands';
      case 'pl': return 'Polski';
      case 'ar': return 'العربية';
      case 'tr': return 'Türkçe';
      case 'cs': return 'Čeština';
      default: return code; // retorna código se não estiver mapeado
    }
  }
}
