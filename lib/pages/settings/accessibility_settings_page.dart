import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:easy_localization/easy_localization.dart'; // para tradução

class AccessibilitySettingsPage extends StatefulWidget {
  const AccessibilitySettingsPage({super.key});

  @override
  State<AccessibilitySettingsPage> createState() => _AccessibilitySettingsPageState();
}

class _AccessibilitySettingsPageState extends State<AccessibilitySettingsPage> {
  bool highContrast = false; // contraste elevado
  bool screenReader = true; // leitor de ecrã

  @override
  Widget build(BuildContext context) {
    final TextStyle titleStyle = GoogleFonts.poppins(
      fontSize: 18,
      fontWeight: FontWeight.bold,
      color: Theme.of(context).brightness == Brightness.dark ? Colors.white : const Color(0xFF00B4D8),
    );

    final TextStyle subtitleStyle = GoogleFonts.poppins(
      fontSize: 14,
      color: Theme.of(context).brightness == Brightness.dark ? Colors.white70 : Colors.black87,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text('accessibility_settings_page.vision'.tr(), style: titleStyle), // título visão
        backgroundColor: Theme.of(context).brightness == Brightness.dark ? Colors.black : Colors.white,
        foregroundColor: const Color(0xFF00B4D8),
        elevation: 1,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('accessibility_settings_page.vision'.tr(), style: titleStyle), // secção visão
          const SizedBox(height: 10),
          SwitchListTile(
            title: Text('accessibility_settings_page.high_contrast'.tr(), style: subtitleStyle), // opção contraste
            subtitle: Text('accessibility_settings_page.high_contrast_description'.tr(), style: subtitleStyle), // descrição contraste
            value: highContrast,
            activeColor: const Color(0xFF00B4D8),
            onChanged: (val) => setState(() => highContrast = val), // ativa/desativa contraste
          ),
          const Divider(height: 32),
          Text('accessibility_settings_page.hearing'.tr(), style: titleStyle), // secção audição
          const SizedBox(height: 10),
          SwitchListTile(
            title: Text('accessibility_settings_page.screen_reader'.tr(), style: subtitleStyle), // opção leitor ecrã
            subtitle: Text('accessibility_settings_page.screen_reader_description'.tr(), style: subtitleStyle), // descrição leitor ecrã
            value: screenReader,
            activeColor: const Color(0xFF00B4D8),
            onChanged: (val) => setState(() => screenReader = val), // ativa/desativa leitor
          ),
        ],
      ),
    );
  }
}
