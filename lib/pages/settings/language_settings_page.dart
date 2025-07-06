// Importação dos pacotes necessários
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart'; // Para suporte multilingue
import 'package:google_fonts/google_fonts.dart'; // Para uso da fonte Poppins
import 'package:projetogpsnovo/helpers/preferences_helpers.dart'; // Acesso às preferências da app


class LanguageSettingsPage extends StatefulWidget {
  const LanguageSettingsPage({super.key});

  @override
  State<LanguageSettingsPage> createState() => _LanguageSettingsPageState();
}

class _LanguageSettingsPageState extends State<LanguageSettingsPage> {
  late Locale selectedLocale; // Guarda o idioma atualmente selecionado
  final PreferencesHelper _preferencesHelper = PreferencesHelper(); // Instância para gerir preferências locais


  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Inicializa a variável selectedLocale com o idioma atual da app
    selectedLocale = context.locale;
  }

  @override
  Widget build(BuildContext context) {
    final List<Locale> supportedLocales = context.supportedLocales;

    final TextStyle titleStyle = GoogleFonts.poppins(
      fontSize: 18,
      fontWeight: FontWeight.bold,
      color: Theme.of(context).brightness == Brightness.dark
          ? Colors.white            // Cor branca se tema escuro
          : const Color(0xFF00B4D8), // Azul se tema claro
    );


    final TextStyle itemStyle = GoogleFonts.poppins(
      fontSize: 16,
      color: Theme.of(context).brightness == Brightness.dark
          ? Colors.white70       // Branco translúcido no escuro
          : Colors.black87,      // Preto quase puro no claro
    );


    return Scaffold(
      appBar: AppBar(
        title: Text(
          'language_settings_page.language'.tr(), // Título traduzido (ex: "Idioma")
          style: titleStyle,
        ),
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? Colors.black : Colors.white, // Cor da AppBar depende do tema
        foregroundColor: const Color(0xFF00B4D8), // Cor do ícone e texto
        elevation: 1, // Sombra leve
      ),
      body: ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 8), // Espaço acima/abaixo da lista
        itemCount: supportedLocales.length,               // Número de idiomas disponíveis
        separatorBuilder: (_, __) => const Divider(height: 1), // Separador entre os idiomas
        itemBuilder: (context, index) {
          final locale = supportedLocales[index];       // Idioma atual da iteração
          final isSelected = locale == selectedLocale;  // Verifica se é o idioma atual

          return RadioListTile<Locale>(
            value: locale,                // Valor do rádio atual
            groupValue: selectedLocale,  // Idioma atualmente selecionado
            onChanged: (value) async {
              if (value != null) {
                setState(() {
                  selectedLocale = value; // Atualiza visualmente
                });
                context.setLocale(value); // Aplica o novo idioma em toda a app
              }
            },
            activeColor: const Color(0xFF00B4D8), // Cor do rádio ativo
            title: Text(
              _getLanguageName(locale.languageCode).tr(), // Mostra o nome do idioma (ex: "Français")
              style: itemStyle.copyWith(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, // Negrito se selecionado
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16), // Margem lateral
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
        return code; // Se não reconhecido, retorna o próprio código (ex: "ja")
    }
  }
}
