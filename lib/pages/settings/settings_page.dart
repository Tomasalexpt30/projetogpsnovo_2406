import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'sound_settings_page.dart';
import 'accessibility_settings_page.dart';
import 'map_settings_page.dart';
import 'personalization_page.dart';
import 'language_settings_page.dart';
import 'package:provider/provider.dart';
import 'package:projetogpsnovo/providers/app_mode_manager.dart';
import 'package:easy_localization/easy_localization.dart'; // para tradução

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final TextStyle titleStyle = GoogleFonts.poppins(
      fontSize: 20,
      fontWeight: FontWeight.bold,
      color: Theme.of(context).brightness == Brightness.dark ? Colors.white : const Color(0xFF00B4D8), // cor adaptada ao tema
    );

    return Scaffold(
      appBar: AppBar(
        title: Text('settings_page.settings'.tr(), style: titleStyle.copyWith(fontSize: 22)), // título traduzido
        backgroundColor: Theme.of(context).brightness == Brightness.dark ? Colors.black : Colors.white,
        foregroundColor: const Color(0xFF00B4D8),
        elevation: 1,
      ),
      body: ListView(
        children: [
          ListTile(
            leading: Icon(Icons.volume_up, color: Theme.of(context).brightness == Brightness.dark ? Colors.white : const Color(0xFF00B4D8)), // ícone som
            title: Text('settings_page.sound'.tr(), style: titleStyle.copyWith(fontSize: 18)), // som
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const SoundSettingsPage())); // vai para som
            },
          ),
          ListTile(
            leading: Icon(Icons.accessibility, color: Theme.of(context).brightness == Brightness.dark ? Colors.white : const Color(0xFF00B4D8)), // ícone acessibilidade
            title: Text('settings_page.accessibility'.tr(), style: titleStyle.copyWith(fontSize: 18)), // acessibilidade
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const AccessibilitySettingsPage())); // vai para acessibilidade
            },
          ),
          ListTile(
            leading: Icon(Icons.map, color: Theme.of(context).brightness == Brightness.dark ? Colors.white : const Color(0xFF00B4D8)), // ícone mapa
            title: Text('settings_page.map'.tr(), style: titleStyle.copyWith(fontSize: 18)), // mapa
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const MapSettingsPage())); // vai para mapa
            },
          ),
          ListTile(
            leading: Icon(Icons.settings_suggest, color: Theme.of(context).brightness == Brightness.dark ? Colors.white : const Color(0xFF00B4D8)), // ícone personalização
            title: Text('settings_page.personalization'.tr(), style: titleStyle.copyWith(fontSize: 18)), // personalização
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const PersonalizationPage())); // vai para personalização
            },
          ),
          ListTile(
            leading: Icon(Icons.language, color: Theme.of(context).brightness == Brightness.dark ? Colors.white : const Color(0xFF00B4D8)), // ícone idioma
            title: Text('settings_page.language'.tr(), style: titleStyle.copyWith(fontSize: 18)), // idioma
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const LanguageSettingsPage())); // vai para idioma
            },
          ),
        ],
      ),
    );
  }
}
