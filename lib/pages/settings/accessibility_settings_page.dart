import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:easy_localization/easy_localization.dart'; // Adicionado para a tradução

class AccessibilitySettingsPage extends StatefulWidget {
  const AccessibilitySettingsPage({super.key});

  @override
  State<AccessibilitySettingsPage> createState() => _AccessibilitySettingsPageState();
}

class _AccessibilitySettingsPageState extends State<AccessibilitySettingsPage> {
  bool highContrast = false;
  bool screenReader = true;

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
        title: Text('accessibility_settings_page.vision'.tr(), style: titleStyle), // Tradução
        backgroundColor: Theme.of(context).brightness == Brightness.dark ? Colors.black : Colors.white,
        foregroundColor: const Color(0xFF00B4D8),
        elevation: 1,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('accessibility_settings_page.vision'.tr(), style: titleStyle), // Tradução
          const SizedBox(height: 10),
          SwitchListTile(
            title: Text('accessibility_settings_page.high_contrast'.tr(), style: subtitleStyle), // Tradução
            subtitle: Text('accessibility_settings_page.high_contrast_description'.tr(), style: subtitleStyle), // Tradução
            value: highContrast,
            activeColor: const Color(0xFF00B4D8),
            onChanged: (val) => setState(() => highContrast = val),
          ),
          const Divider(height: 32),
          Text('accessibility_settings_page.hearing'.tr(), style: titleStyle), // Tradução
          const SizedBox(height: 10),
          SwitchListTile(
            title: Text('accessibility_settings_page.screen_reader'.tr(), style: subtitleStyle), // Tradução
            subtitle: Text('accessibility_settings_page.screen_reader_description'.tr(), style: subtitleStyle), // Tradução
            value: screenReader,
            activeColor: const Color(0xFF00B4D8),
            onChanged: (val) => setState(() => screenReader = val),
          ),
        ],
      ),
    );
  }
}
