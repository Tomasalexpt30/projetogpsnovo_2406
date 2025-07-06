// Importa pacotes necessários
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:easy_localization/easy_localization.dart'; // Permite utilizar traduções com `.tr()`


// Declaração do widget da página de acessibilidade
class AccessibilitySettingsPage extends StatefulWidget {
  const AccessibilitySettingsPage({super.key});

  @override
  State<AccessibilitySettingsPage> createState() => _AccessibilitySettingsPageState();
}

class _AccessibilitySettingsPageState extends State<AccessibilitySettingsPage> {
  bool highContrast = false; // Variável para controlar se o modo de alto contraste está ativado
  bool screenReader = true; // Variável para controlar se o modo de leitor de ecrã está ativado


  @override
  Widget build(BuildContext context) {
    final TextStyle titleStyle = GoogleFonts.poppins(
      fontSize: 18,
      fontWeight: FontWeight.bold,
      color: Theme.of(context).brightness == Brightness.dark
          ? Colors.white // Se o tema for escuro, usa branco
          : const Color(0xFF00B4D8), // Caso contrário, azul vibrante
    );

    final TextStyle subtitleStyle = GoogleFonts.poppins(
      fontSize: 14,
      color: Theme.of(context).brightness == Brightness.dark
          ? Colors.white70  // Texto mais suave no tema escuro
          : Colors.black87, // Preto quase total no tema claro
    );

    return Scaffold(
      appBar: AppBar(
        // Título da AppBar, traduzido do JSON com .tr()
        title: Text('accessibility_settings_page.vision'.tr(), style: titleStyle),
        // Cor de fundo muda consoante o tema
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? Colors.black
            : Colors.white,
        foregroundColor: const Color(0xFF00B4D8), // Cor dos ícones e título da AppBar
        elevation: 1, // Sombra leve abaixo da AppBar
      ),
      body: ListView(
        padding: const EdgeInsets.all(16), // Espaçamento interno da página
        children: [
          Text(
            'accessibility_settings_page.vision'.tr(), // "Visão" traduzido
            style: titleStyle,
          ),
          const SizedBox(height: 10), // Espaço abaixo do título
          SwitchListTile(
          title: Text(
          'accessibility_settings_page.high_contrast'.tr(), // Título traduzido
          style: subtitleStyle,
          ),
          subtitle: Text(
          'accessibility_settings_page.high_contrast_description'.tr(), // Descrição traduzida
          style: subtitleStyle,
          ),
          value: highContrast, // Estado atual do switch
          activeColor: const Color(0xFF00B4D8), // Cor quando ativado
          onChanged: (val) => setState(() => highContrast = val), // Atualiza o estado visual
          ),
          const Divider(height: 32), // Linha horizontal com espaço
          Text(
            'accessibility_settings_page.hearing'.tr(), // "Audição" traduzido
            style: titleStyle,
          ),
          const SizedBox(height: 10), // Espaço abaixo do título
          SwitchListTile(
            title: Text(
              'accessibility_settings_page.screen_reader'.tr(), // Título traduzido
              style: subtitleStyle,
            ),
            subtitle: Text(
              'accessibility_settings_page.screen_reader_description'.tr(), // Descrição traduzida
              style: subtitleStyle,
            ),
            value: screenReader, // Estado atual do switch
            activeColor: const Color(0xFF00B4D8), // Cor quando ativado
            onChanged: (val) => setState(() => screenReader = val), // Atualiza o estado visual
          ),
        ],
      ),
    );
  }
}
