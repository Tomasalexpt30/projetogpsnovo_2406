// Importa bibliotecas essenciais
import 'dart:async';
import 'package:flutter/material.dart';
import 'home_page.dart';

/// Ecrã de introdução (Splash Screen) que aparece ao iniciar a aplicação
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller; // Controlador da animação
  late Animation<double> _fadeAnimation;// Animação de opacidade (fade in)
  late Animation<double> _scaleAnimation; // Animação de escala (zoom)

  @override
  void initState() {
    super.initState();

    // Inicializa o controlador da animação com duração de 2 segundos
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this, // Fornece o TickerProvider necessário
    );

    // Configura a animação de fade (de invisível para visível)
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );

    // Configura a animação de escala (de 80% para 100% com efeito elástico)
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );

    _controller.forward(); // Inicia as animações

    // Após 5 segundos, navega automaticamente para a página inicial
    Timer(const Duration(seconds: 5), () {
      Navigator.of(context).pushReplacement(_createSlideRoute());
    });
  }

  /// Função que cria a animação de transição entre a SplashScreen e a página inicial
  Route _createSlideRoute() {
    return PageRouteBuilder(
      transitionDuration: const Duration(milliseconds: 700), // Duração da transição
      pageBuilder: (context, animation, secondaryAnimation) => const MyHomePage(title: 'Página Inicial'),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(1.0, 0.0); // Começa fora do ecrã (à direita)
        const end = Offset.zero; // Termina no centro
        final tween = Tween(begin: begin, end: end).chain(
          CurveTween(curve: Curves.easeInOut), // Suaviza a animação
        );

        // Retorna uma transição deslizante da direita para o centro
        return SlideTransition(
          position: animation.drive(tween),
          child: child,
        );
      },
    );
  }

  @override
  void dispose() {
    // Liberta os recursos da animação ao destruir o ecrã
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Define a cor de fundo de acordo com o tema (claro ou escuro)
    final backgroundColor = Theme.of(context).brightness == Brightness.dark
        ? Colors.black
        : const Color(0xFFF0F4F8);

    return Scaffold(
      backgroundColor: backgroundColor,
      body: Center(
        // Animação de fade
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: ScaleTransition(
            // Animação de escala
            scale: _scaleAnimation,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30.0),
              child: Image.asset(
                'assets/images/home/logo_gps.png', // Logótipo da aplicação
                width: 250,
                fit: BoxFit.contain,
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white // Logótipo branco no modo escuro
                    : const Color(0xFF00B4D8), // Logótipo azul no modo claro
              ),
            ),
          ),
        ),
      ),
    );
  }
}
