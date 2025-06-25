import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:easy_localization/easy_localization.dart'; // Adicionado para a tradução

class MapSettingsPage extends StatefulWidget {
  const MapSettingsPage({super.key});

  @override
  State<MapSettingsPage> createState() => _MapSettingsPageState();
}

class _MapSettingsPageState extends State<MapSettingsPage> {
  bool darkMap = false;
  String iconStyle = 'Padrão';

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
        title: Text('map_settings_page.map_appearance'.tr(), style: titleStyle), // Tradução
        backgroundColor: Theme.of(context).brightness == Brightness.dark ? Colors.black : Colors.white,
        foregroundColor: const Color(0xFF00B4D8),
        elevation: 1,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('map_settings_page.map_appearance'.tr(), style: titleStyle), // Tradução
          const SizedBox(height: 8),
          SwitchListTile(
            title: Text('map_settings_page.dark_map'.tr(), style: subtitleStyle), // Tradução
            subtitle: Text('map_settings_page.dark_map_description'.tr(), style: subtitleStyle), // Tradução
            value: darkMap,
            activeColor: const Color(0xFF00B4D8),
            onChanged: (val) => setState(() => darkMap = val),
          ),
          const Divider(height: 32),
          Text('map_settings_page.icon_style'.tr(), style: titleStyle), // Tradução
          const SizedBox(height: 8),
          RadioListTile<String>(
            value: 'Padrão',
            groupValue: iconStyle,
            activeColor: const Color(0xFF00B4D8),
            title: Row(
              children: [
                Icon(Icons.location_on_outlined, color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.grey),
                SizedBox(width: 10),
                Text('map_settings_page.default_style'.tr(), style: subtitleStyle), // Tradução
              ],
            ),
            onChanged: (value) {
              setState(() {
                iconStyle = value!;
              });
            },
          ),
          RadioListTile<String>(
            value: 'Acessível',
            groupValue: iconStyle,
            activeColor: const Color(0xFF00B4D8),
            title: Row(
              children: [
                Icon(Icons.accessibility_new, color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.grey),
                SizedBox(width: 10),
                Text('map_settings_page.accessible_style'.tr(), style: subtitleStyle), // Tradução
              ],
            ),
            onChanged: (value) {
              setState(() {
                iconStyle = value!;
              });
            },
          ),
        ],
      ),
    );
  }
}
