// Importações dos pacotes necessários
import 'package:flutter/material.dart';                             // Widgets e estrutura da UI
import 'package:google_fonts/google_fonts.dart';                   // Fonte personalizada (Poppins)
import 'package:projetogpsnovo/helpers/preferences_helpers.dart';  // Classe utilitária para carregar/salvar preferências
import 'package:provider/provider.dart';                           // Permite aceder e reagir a alterações de estado via Provider
import 'package:projetogpsnovo/providers/app_mode_manager.dart';   // Provider que controla o tema da aplicação
import 'package:easy_localization/easy_localization.dart';         // Permite usar traduções .tr()

class PersonalizationPage extends StatefulWidget {
  const PersonalizationPage({super.key});

  @override
  State<PersonalizationPage> createState() => _PersonalizationPageState();
}

class _PersonalizationPageState extends State<PersonalizationPage> {
  bool isDarkMode = false; // Estado booleano que indica se o modo escuro está ativo

  final PreferencesHelper _preferencesHelper = PreferencesHelper(); // Instância para carregar/salvar preferências

  @override
  void initState() {
    super.initState();
    _loadPreferences(); // Carrega preferências do tema ao iniciar
  }

  // Carregar preferências de tema
  Future<void> _loadPreferences() async {
    final settings = await _preferencesHelper.loadPersonalizationSettings(); // Lê as preferências
    setState(() {
      isDarkMode = settings['isDarkMode'] ?? false; // Atualiza o estado local com base no valor salvo (ou false por padrão)
    });
  }

  // Salvar preferências de tema
  Future<void> _savePreferences() async {
    await _preferencesHelper.savePersonalizationSettings(
      isDarkMode: isDarkMode, // Grava o estado atual do tema
    );
  }

  @override
  Widget build(BuildContext context) {
    final TextStyle sectionTitleStyle = GoogleFonts.poppins(
      fontSize: 18,
      fontWeight: FontWeight.bold,
      color: isDarkMode ? Colors.white : const Color(0xFF00B4D8), // Azul no modo claro, branco no escuro
    );

    final TextStyle subtitleStyle = GoogleFonts.poppins(
      fontSize: 14,
      color: isDarkMode ? Colors.white70 : Colors.black87, // Branco translúcido ou preto consoante o tema
    );

    return Scaffold(
      appBar: AppBar(
        title: Text('personalization_page.theme'.tr(), style: sectionTitleStyle), // Título traduzido
        backgroundColor: isDarkMode ? Colors.black : Colors.white,  // Fundo da AppBar de acordo com o tema
        foregroundColor: const Color(0xFF00B4D8), // Cor dos ícones e texto
        elevation: 1, // Sombra leve na AppBar
      ),
      body: ListView(
        padding: const EdgeInsets.all(16), // Espaçamento interno do conteúdo
        children: [
          // Removemos a parte de "Tamanho da Fonte" aqui.

          Text('personalization_page.theme'.tr(), style: sectionTitleStyle), // Título traduzido: "Tema"
          const SizedBox(height: 4),
          Text('personalization_page.theme_description'.tr(), style: subtitleStyle), // Descrição traduzida
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center, // Centraliza os elementos na linha
            children: [
              Column(
                children: [
                  Icon(Icons.wb_sunny, color: isDarkMode ? Colors.orangeAccent : Colors.orange), // Ícone do sol com cor distinta consoante o modo
                  SizedBox(height: 4),
                  Text(
                    'personalization_page.light_mode'.tr(), // Texto traduzido: "Modo Claro"
                    style: TextStyle(
                      fontSize: 12,
                      color: isDarkMode ? Colors.white : Colors.black, // Cor adaptada ao tema
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 16),
              Switch(
                value: isDarkMode, // Estado atual do modo
                activeColor: const Color(0xFF00B4D8), // Cor azul do switch
                onChanged: (value) {
                  setState(() {
                    isDarkMode = value; // Atualiza o estado local
                  });
                  Provider.of<AppModeManager>(context, listen: false).toggleTheme(); // Alterna o tema globalmente via Provider
                  _savePreferences(); // Grava a nova escolha do utilizador
                },
              ),
              const SizedBox(width: 16),
              Column(
                children: [
                  Icon(Icons.nightlight_round, color: isDarkMode ? Colors.blueGrey : Colors.black), // Ícone da lua com cor condicional
                  SizedBox(height: 4),
                  Text(
                    'personalization_page.dark_mode'.tr(), // Texto traduzido: "Modo Escuro"
                    style: TextStyle(
                      fontSize: 12,
                      color: isDarkMode ? Colors.white : Colors.black, // Cor adaptada ao tema
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

