import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:projetogpsnovo/pages/tour/tour_pages.dart';
import 'package:projetogpsnovo/pages/navigation/navigation_map_selector.dart';
import 'package:provider/provider.dart';
import 'package:projetogpsnovo/providers/app_mode_manager.dart';
import 'package:projetogpsnovo/pages/settings/settings_page.dart';
import 'package:projetogpsnovo/pages/settings/language_settings_page.dart';

class MyHomePage extends StatelessWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    final TextStyle titleStyle = GoogleFonts.poppins(
      fontSize: 20,
      fontWeight: FontWeight.bold,
      color: Theme.of(context).brightness == Brightness.dark ? Colors.white : const Color(0xFF00B4D8),
    );

    return Scaffold(
      backgroundColor: Theme.of(context).brightness == Brightness.dark ? Colors.black : const Color(0xFFF0F4F8),
      body: SafeArea(
        child: Stack(
          children: [
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Semantics(
                      label: 'Definições',
                      hint: 'Abre a página de definições',
                      button: true,
                      child: IconButton(
                        icon: Icon(Icons.settings, size: 32, color: Theme.of(context).brightness == Brightness.dark ? Colors.white : const Color(0xFF00B4D8)),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const SettingsPage()),
                          );
                        },
                      ),
                    ),
                    Expanded(
                      child: Center(
                        child: Semantics(
                          label: 'Logótipo da aplicação Autónoma GPS',
                          child: Image.asset(
                            'assets/images/home/logo_gps.png',
                            height: 140,
                            color: Theme.of(context).brightness == Brightness.dark ? Colors.white : const Color(0xFF00B4D8),
                          ),
                        ),
                      ),
                    ),
                    Semantics(
                      label: 'Idioma',
                      hint: 'Abre a seleção de idioma',
                      button: true,
                      child: IconButton(
                        icon: Icon(Icons.language, size: 32, color: Theme.of(context).brightness == Brightness.dark ? Colors.white : const Color(0xFF00B4D8)),
                        onPressed: () {
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
            Align(
              alignment: Alignment.center,
              child: Padding(
                padding: const EdgeInsets.only(left: 20, right: 20, top: 90, bottom: 80),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 20),
                    Semantics(
                      label: 'Modo Navegação',
                      hint: 'Inicia a navegação com beacons pela universidade',
                      button: true,
                      child: CustomCardButton(
                        imagePath: 'assets/images/home/aluno.png',
                        text: 'my_home_page.mode_navigation'.tr(),
                        onPressed: () {
                          Provider.of<AppModeManager>(context, listen: false).setModo(AppMode.navegacao);
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const NavigationMapSelectorPage()),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 30),
                    Semantics(
                      label: 'Modo Visita',
                      hint: 'Inicia a visita guiada com informação sobre os espaços da universidade',
                      button: true,
                      child: CustomCardButton(
                        imagePath: 'assets/images/home/foto_camoes.png',
                        text: 'my_home_page.mode_visit'.tr(),
                        onPressed: () {
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
            Positioned(
              bottom: 30,
              left: 0,
              right: 0,
              child: Center(
                child: Semantics(
                  label: 'Texto de boas-vindas',
                  child: Text(
                    'my_home_page.welcome'.tr(),
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).brightness == Brightness.dark ? Colors.white : const Color(0xFF00B4D8),
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
}

class CustomCardButton extends StatelessWidget {
  final String imagePath;
  final String text;
  final VoidCallback onPressed;

  const CustomCardButton({
    super.key,
    required this.imagePath,
    required this.text,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: const Duration(milliseconds: 900),
      curve: Curves.easeOut,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, (1 - value) * 20),
            child: child,
          ),
        );
      },
      child: SizedBox(
        width: double.infinity,
        height: 150,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF00B4D8),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            elevation: 6,
            shadowColor: Colors.black38,
          ),
          onPressed: onPressed,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: Image.asset(
                  imagePath,
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                text,
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
