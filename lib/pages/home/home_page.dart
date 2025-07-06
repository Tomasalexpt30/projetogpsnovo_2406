// Importa as bibliotecas necessárias
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:projetogpsnovo/pages/tour/tour_page.dart';
import 'package:projetogpsnovo/pages/navigation/navigation_page.dart';
import 'package:provider/provider.dart';
import 'package:projetogpsnovo/providers/app_mode_manager.dart';
import 'package:projetogpsnovo/pages/settings/settings_page.dart';
import 'package:projetogpsnovo/pages/settings/language_settings_page.dart';

/// Página inicial da aplicação
class MyHomePage extends StatelessWidget {
  const MyHomePage({super.key, required this.title});
  final String title; // Título da página

  @override
  Widget build(BuildContext context) {
    // Define o estilo do título, adaptando a cor ao tema (claro/escuro)
    final TextStyle titleStyle = GoogleFonts.poppins(
      fontSize: 20,
      fontWeight: FontWeight.bold,
      color: Theme.of(context).brightness == Brightness.dark ? Colors.white : const Color(0xFF00B4D8),
    );

    return Scaffold(
      backgroundColor: Theme.of(context).brightness == Brightness.dark ? Colors.black : const Color(0xFFF0F4F8), // Cor de fundo dinâmica
      body: SafeArea(
        child: Stack(
          children: [
            // Barra superior com ícones de definições, logótipo e idioma
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Botão das definições com acessibilidade
                    Semantics(
                      label: 'Definições',
                      hint: 'Abre a página de definições',
                      button: true,
                      child: IconButton(
                        icon: Icon(Icons.settings, size: 32, color: Theme.of(context).brightness == Brightness.dark ? Colors.white : const Color(0xFF00B4D8)),
                        onPressed: () {
                          // Navega para a página de definições
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const SettingsPage()),
                          );
                        },
                      ),
                    ),
                    // Logótipo central da aplicação com acessibilidade
                    Expanded(
                      child: Semantics(
                        label: 'Logótipo da aplicação Autónoma GPS',
                        child: Image.asset(
                          'assets/images/home/logo_gps.png',
                          height: 140,
                          color: Theme.of(context).brightness == Brightness.dark ? Colors.white : const Color(0xFF00B4D8),
                        ),
                      ),
                    ),
                    // Botão de seleção de idioma com acessibilidade
                    Semantics(
                      label: 'Idioma',
                      hint: 'Abre a seleção de idioma',
                      button: true,
                      child: IconButton(
                        icon: Icon(Icons.language, size: 32, color: Theme.of(context).brightness == Brightness.dark ? Colors.white : const Color(0xFF00B4D8)),
                        onPressed: () {
                          // Navega para a página de seleção de idioma
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const LanguageSettingsPage()),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Área central com os botões de seleção de modos
            Align(
              alignment: Alignment.center,
              child: Padding(
                padding: const EdgeInsets.only(left: 20, right: 20, top: 90, bottom: 80),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 20),
                    // Botão Modo Navegação com acessibilidade
                    Semantics(
                      label: 'Modo Navegação',
                      hint: 'Inicia a navegação com beacons pela universidade',
                      button: true,
                      child: CustomCardButton(
                        imagePath: 'assets/images/home/aluno.png',
                        text: 'my_home_page.mode_navigation'.tr(), // Tradução
                        onPressed: () {
                          // Define o modo como Navegação e abre a página de navegação
                          Provider.of<AppModeManager>(context, listen: false).setModo(AppMode.navegacao);
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const NavigationMapSelectorPage()),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 30),
                    // Botão Modo Visita com acessibilidade
                    Semantics(
                      label: 'Modo Visita',
                      hint: 'Inicia a visita guiada com informação sobre os espaços da universidade',
                      button: true,
                      child: CustomCardButton(
                        imagePath: 'assets/images/home/foto_camoes.png',
                        text: 'my_home_page.mode_visit'.tr(), // Tradução
                        onPressed: () {
                          // Define o modo como Visita Guiada e abre a página da tour
                          Provider.of<AppModeManager>(context, listen: false).setModo(AppMode.visita);
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const TourPage()),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Texto de boas-vindas no fundo do ecrã
            Positioned(
              bottom: 70,
              left: 0,
              right: 0,
              child: Center(
                child: Semantics(
                  label: 'Texto de boas-vindas',
                  child: Text(
                    'my_home_page.welcome'.tr(), // Tradução
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).brightness == Brightness.dark ? Colors.white : const Color(0xFF00B4D8),
                    ),
                  ),
                ),
              ),
            ),
            // Botão da Política de Privacidade no fundo do ecrã
            Positioned(
              bottom: 30,
              left: 0,
              right: 0,
              child: Center(
                child: TextButton(
                  onPressed: () {
                    _showPrivacyPolicy(context); // Abre o diálogo da Política de Privacidade
                  },
                  child: Text(
                    'privacy_policy.title'.tr(), // Tradução
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Theme.of(context).brightness == Brightness.dark ? Colors.white : const Color(0xFF00B4D8),
                      decoration: TextDecoration.underline,
                      decorationColor: Color(0xFF00B4D8),
                      decorationThickness: 1,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Mostra o diálogo da Política de Privacidade
  void _showPrivacyPolicy(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            'privacy_policy.title'.tr(), // Tradução
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Data da última atualização
                Text('privacy_policy.updated'.tr(), style: GoogleFonts.poppins(fontStyle: FontStyle.italic)),
                const SizedBox(height: 10),
                // Introdução da política
                Text('privacy_policy.intro'.tr(), style: GoogleFonts.poppins()),
                const SizedBox(height: 15),
                // Secções da política de privacidade
                _buildSection(context, 'privacy_policy.section1_title', 'privacy_policy.section1_body'),
                _buildSection(context, 'privacy_policy.section2_title', 'privacy_policy.section2_body'),
                _buildSection(context, 'privacy_policy.section3_title', 'privacy_policy.section3_body'),
                _buildSection(context, 'privacy_policy.section4_title', 'privacy_policy.section4_body'),
                _buildSection(context, 'privacy_policy.section5_title', 'privacy_policy.section5_body'),
                _buildSection(context, 'privacy_policy.section6_title', 'privacy_policy.section6_body'),
                _buildSection(context, 'privacy_policy.section7_title', 'privacy_policy.section7_body'),
                _buildSection(context, 'privacy_policy.section8_title', 'privacy_policy.section8_body'),
              ],
            ),
          ),
          actions: [
            // Botão para fechar o diálogo
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('privacy_policy.close'.tr(), style: GoogleFonts.poppins(color: const Color(0xFF00B4D8))),
            ),
          ],
        );
      },
    );
  }

  /// Constrói uma secção da Política de Privacidade com título e conteúdo
  Widget _buildSection(BuildContext context, String titleKey, String bodyKey) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(titleKey.tr(), style: GoogleFonts.poppins(fontWeight: FontWeight.bold)), // Título da secção
          Text(bodyKey.tr(), style: GoogleFonts.poppins()), // Conteúdo da secção
        ],
      ),
    );
  }
}

/// Botão personalizado com animação de entrada e estilo visual próprio
class CustomCardButton extends StatelessWidget {
  final String imagePath; // Caminho da imagem do botão
  final String text; // Texto apresentado no botão
  final VoidCallback onPressed; // Ação ao pressionar o botão

  const CustomCardButton({
    super.key,
    required this.imagePath,
    required this.text,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1), // Animação de opacidade e deslocação
      duration: const Duration(milliseconds: 900),
      curve: Curves.easeOut,
      builder: (context, value, child) {
        return Opacity(
          opacity: value, // Controla a opacidade
          child: Transform.translate(
            offset: Offset(0, (1 - value) * 20), // Animação de entrada vertical
            child: child,
          ),
        );
      },
      child: SizedBox(
        width: double.infinity,
        height: 150,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF00B4D8), // Cor de fundo do botão
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)), // Bordas arredondadas
            elevation: 6,
            shadowColor: Colors.black38, // Sombra do botão
          ),
          onPressed: onPressed, // Função ao clicar
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: Image.asset(
                  imagePath, // Imagem do botão
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                text, // Texto do botão
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }
}
