import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:projetogpsnovo/helpers/preferences_helpers.dart';
import 'package:provider/provider.dart';
import 'package:projetogpsnovo/providers/app_mode_manager.dart';
import 'package:easy_localization/easy_localization.dart'; // para tradução

class PersonalizationPage extends StatefulWidget {
  const PersonalizationPage({super.key});

  @override
  State<PersonalizationPage> createState() => _PersonalizationPageState();
}

class _PersonalizationPageState extends State<PersonalizationPage> {
  bool isDarkMode = false; // estado do tema

  final PreferencesHelper _preferencesHelper = PreferencesHelper(); // helper para guardar preferências

  @override
  void initState() {
    super.initState();
    _loadPreferences(); // carrega preferências salvas
  }

  Future<void> _loadPreferences() async {
    final settings = await _preferencesHelper.loadPersonalizationSettings(); // lê do storage
    setState(() {
      isDarkMode = settings['isDarkMode'] ?? false; // aplica valor salvo ou padrão
    });
  }

  Future<void> _savePreferences() async {
    await _preferencesHelper.savePersonalizationSettings(
      isDarkMode: isDarkMode, // salva estado atual
    );
  }

  @override
  Widget build(BuildContext context) {
    final TextStyle sectionTitleStyle = GoogleFonts.poppins(
      fontSize: 18,
      fontWeight: FontWeight.bold,
      color: isDarkMode ? Colors.white : const Color(0xFF00B4D8), // cor adaptada ao tema
    );

    final TextStyle subtitleStyle = GoogleFonts.poppins(
      fontSize: 14,
      color: isDarkMode ? Colors.white70 : Colors.black87, // cor adaptada ao tema
    );

    return Scaffold(
      appBar: AppBar(
        title: Text('personalization_page.theme'.tr(), style: sectionTitleStyle), // título traduzido
        backgroundColor: isDarkMode ? Colors.black : Colors.white,
        foregroundColor: const Color(0xFF00B4D8),
        elevation: 1,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('personalization_page.theme'.tr(), style: sectionTitleStyle), // secção tema
          const SizedBox(height: 4),
          Text('personalization_page.theme_description'.tr(), style: subtitleStyle), // descrição tema
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Column(
                children: [
                  Icon(Icons.wb_sunny, color: isDarkMode ? Colors.orangeAccent : Colors.orange), // ícone claro
                  SizedBox(height: 4),
                  Text('personalization_page.light_mode'.tr(), style: TextStyle(fontSize: 12, color: isDarkMode ? Colors.white : Colors.black)), // texto claro
                ],
              ),
              const SizedBox(width: 16),
              Switch(
                value: isDarkMode,
                activeColor: const Color(0xFF00B4D8),
                onChanged: (value) {
                  setState(() {
                    isDarkMode = value; // atualiza estado
                  });
                  Provider.of<AppModeManager>(context, listen: false).toggleTheme(); // troca tema na app
                  _savePreferences(); // guarda preferência
                },
              ),
              const SizedBox(width: 16),
              Column(
                children: [
                  Icon(Icons.nightlight_round, color: isDarkMode ? Colors.blueGrey : Colors.black), // ícone escuro
                  SizedBox(height: 4),
                  Text('personalization_page.dark_mode'.tr(), style: TextStyle(fontSize: 12, color: isDarkMode ? Colors.white : Colors.black)), // texto escuro
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
