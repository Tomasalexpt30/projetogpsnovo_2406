// Importações principais dos pacotes necessários
import 'package:flutter/material.dart'; // Framework principal do Flutter
import 'package:google_fonts/google_fonts.dart'; // Permite usar fontes do Google, como Poppins
import 'sound_settings_page.dart'; // Página de configurações de som
import 'accessibility_settings_page.dart'; // Página de acessibilidade
import 'map_settings_page.dart'; // Página de configurações de mapa
import 'personalization_page.dart'; // Página de personalização
import 'language_settings_page.dart'; // Página de configuração de idioma
import 'package:provider/provider.dart'; // Para gestão de estado com o Provider
import 'package:projetogpsnovo/providers/app_mode_manager.dart'; // Gestor de modo da app (claro/escuro, etc.)
import 'package:easy_localization/easy_localization.dart'; // Biblioteca para internacionalização (tradução)

// Definição da classe da página de definições, que é um widget sem estado
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key}); // Construtor constante para otimização

  @override
  Widget build(BuildContext context) {
    // Estilo do título reutilizável, com fonte Poppins, tamanho 20, negrito, e cor adaptada ao tema (claro ou escuro)
    final TextStyle titleStyle = GoogleFonts.poppins(
      fontSize: 20,
      fontWeight: FontWeight.bold,
      color: Theme.of(context).brightness == Brightness.dark
          ? Colors.white // Cor branca para modo escuro
          : const Color(0xFF00B4D8), // Azul para modo claro
    );

    // Scaffold é o layout base da página
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'settings_page.settings'.tr(), // Texto traduzido da chave definida em JSON
          style: titleStyle.copyWith(fontSize: 22), // Aplica o estilo do título com tamanho maior
        ),
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? Colors.black // Fundo preto no modo escuro
            : Colors.white, // Fundo branco no modo claro
        foregroundColor: const Color(0xFF00B4D8), // Cor dos ícones e texto no app bar
        elevation: 1, // Sombra leve sob o AppBar
      ),

      // Corpo da página com uma lista de opções
      body: ListView(
        children: [
          // Item de lista para configurações de som
          ListTile(
            leading: Icon(
              Icons.volume_up,
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white
                  : const Color(0xFF00B4D8),
            ),
            title: Text(
              'settings_page.sound'.tr(), // Tradução da chave correspondente
              style: titleStyle.copyWith(fontSize: 18), // Aplica estilo com tamanho ajustado
            ),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16), // Ícone à direita indicando navegação
            onTap: () {
              // Ao clicar, navega para a página de configurações de som
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SoundSettingsPage()),
              );
            },
          ),

          // Item de lista para configurações de acessibilidade
          ListTile(
            leading: Icon(
              Icons.accessibility,
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white
                  : const Color(0xFF00B4D8),
            ),
            title: Text(
              'settings_page.accessibility'.tr(),
              style: titleStyle.copyWith(fontSize: 18),
            ),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AccessibilitySettingsPage()),
              );
            },
          ),

          // Item de lista para configurações do mapa
          ListTile(
            leading: Icon(
              Icons.map,
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white
                  : const Color(0xFF00B4D8),
            ),
            title: Text(
              'settings_page.map'.tr(),
              style: titleStyle.copyWith(fontSize: 18),
            ),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const MapSettingsPage()),
              );
            },
          ),

          // Item de lista para personalização da aplicação
          ListTile(
            leading: Icon(
              Icons.settings_suggest,
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white
                  : const Color(0xFF00B4D8),
            ),
            title: Text(
              'settings_page.personalization'.tr(),
              style: titleStyle.copyWith(fontSize: 18),
            ),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PersonalizationPage()),
              );
            },
          ),

          // Item de lista para mudar o idioma da aplicação
          ListTile(
            leading: Icon(
              Icons.language,
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white
                  : const Color(0xFF00B4D8),
            ),
            title: Text(
              'settings_page.language'.tr(),
              style: titleStyle.copyWith(fontSize: 18),
            ),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const LanguageSettingsPage()),
              );
            },
          ),
        ],
      ),
    );
  }
}
