import 'dart:async';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'home_page.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller; // controla animações
  late Animation<double> _fadeAnimation; // controla opacidade
  late Animation<double> _scaleAnimation; // controla escala (zoom)
  String _appVersion = ''; // versão do app

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );

    _controller.forward(); // inicia animação

    _loadAppVersion(); // carrega versão do app

    Timer(const Duration(seconds: 5), () {
      Navigator.of(context).pushReplacement(_createSlideRoute()); // vai para home após 5s
    });
  }

  Future<void> _loadAppVersion() async {
    final packageInfo = await PackageInfo.fromPlatform();
    setState(() {
      _appVersion = 'v${packageInfo.version}+${packageInfo.buildNumber}'; // exibe versão
    });
  }

  Route _createSlideRoute() {
    return PageRouteBuilder(
      transitionDuration: const Duration(milliseconds: 700),
      pageBuilder: (context, animation, secondaryAnimation) => const MyHomePage(title: 'Página Inicial'),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(1.0, 0.0); // desliza da direita
        const end = Offset.zero;
        final tween = Tween(begin: begin, end: end).chain(CurveTween(curve: Curves.easeInOut));

        return SlideTransition(
          position: animation.drive(tween), // aplica transição
          child: child,
        );
      },
    );
  }

  @override
  void dispose() {
    _controller.dispose(); // limpa controller ao fechar
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final backgroundColor = Theme.of(context).brightness == Brightness.dark
        ? Colors.black
        : const Color(0xFFF0F4F8);

    return Scaffold(
      backgroundColor: backgroundColor,
      body: Stack(
        children: [
          Center(
            child: FadeTransition( // aplica fade in
              opacity: _fadeAnimation,
              child: ScaleTransition( // aplica zoom
                scale: _scaleAnimation,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 30.0),
                  child: Image.asset(
                    'assets/images/home/logo_gps.png', // logo do app
                    width: 250,
                    fit: BoxFit.contain,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white
                        : const Color(0xFF00B4D8),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 16, // exibe versão no rodapé
            left: 0,
            right: 0,
            child: Center(
              child: Text(
                _appVersion,
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white70
                      : Colors.black54,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
