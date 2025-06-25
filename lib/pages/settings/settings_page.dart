import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'sound_settings_page.dart';
import 'accessibility_settings_page.dart';
import 'map_settings_page.dart';
import 'personalization_page.dart';
import 'language_settings_page.dart';
import 'package:provider/provider.dart';
import 'package:projetogpsnovo/providers/app_mode_manager.dart';
import 'package:easy_localization/easy_localization.dart'; // Adicionado para a tradução

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final TextStyle titleStyle = GoogleFonts.poppins(
      fontSize: 20,
      fontWeight: FontWeight.bold,
      color: Theme.of(context).brightness == Brightness.dark ? Colors.white : const Color(0xFF00B4D8),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text('settings_page.settings'.tr(), style: titleStyle.copyWith(fontSize: 22)), // Tradução
        backgroundColor: Theme.of(context).brightness == Brightness.dark ? Colors.black : Colors.white,
        foregroundColor: const Color(0xFF00B4D8),
        elevation: 1,
      ),
      body: ListView(
        children: [
          ListTile(
            leading: Icon(Icons.volume_up, color: Theme.of(context).brightness == Brightness.dark ? Colors.white : const Color(0xFF00B4D8)),
            title: Text('settings_page.sound'.tr(), style: titleStyle.copyWith(fontSize: 18)), // Tradução
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const SoundSettingsPage()));
            },
          ),
          ListTile(
            leading: Icon(Icons.accessibility, color: Theme.of(context).brightness == Brightness.dark ? Colors.white : const Color(0xFF00B4D8)),
            title: Text('settings_page.accessibility'.tr(), style: titleStyle.copyWith(fontSize: 18)), // Tradução
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const AccessibilitySettingsPage()));
            },
          ),
          ListTile(
            leading: Icon(Icons.map, color: Theme.of(context).brightness == Brightness.dark ? Colors.white : const Color(0xFF00B4D8)),
            title: Text('settings_page.map'.tr(), style: titleStyle.copyWith(fontSize: 18)), // Tradução
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const MapSettingsPage()));
            },
          ),
          ListTile(
            leading: Icon(Icons.settings_suggest, color: Theme.of(context).brightness == Brightness.dark ? Colors.white : const Color(0xFF00B4D8)),
            title: Text('settings_page.personalization'.tr(), style: titleStyle.copyWith(fontSize: 18)), // Tradução
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const PersonalizationPage()));
            },
          ),
          ListTile(
            leading: Icon(Icons.language, color: Theme.of(context).brightness == Brightness.dark ? Colors.white : const Color(0xFF00B4D8)),
            title: Text('settings_page.language'.tr(), style: titleStyle.copyWith(fontSize: 18)), // Tradução
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const LanguageSettingsPage()));
            },
          ),
        ],
      ),
    );
  }
}
