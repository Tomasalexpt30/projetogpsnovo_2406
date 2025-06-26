import 'package:flutter/material.dart';
import 'package:projetogpsnovo/pages/home/splash_screen.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:provider/provider.dart';
import 'package:projetogpsnovo/providers/app_mode_manager.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:projetogpsnovo/helpers/preferences_helpers.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();

  // Solicitar permissões para Bluetooth e Localização
  await [
    Permission.location,
    Permission.bluetoothScan,
    Permission.bluetoothConnect,
  ].request();

  runApp(
    EasyLocalization(
      supportedLocales: const [
        Locale('en'),
        Locale('pt'),
        Locale('ru'),
        Locale('es'),
        Locale('pl'),
        Locale('tr'),
        Locale('de'),
        Locale('fr'),
        Locale('nl'),
        Locale('it'),
      ],
      path: 'assets/lang',
      fallbackLocale: const Locale('pt'),
      child: ChangeNotifierProvider(
        create: (_) => AppModeManager()..loadPreferences(), // Carregar preferências de tema
        child: const MyApp(),
      ),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppModeManager>(
      builder: (context, appModeManager, child) {
        final bool isDarkMode = appModeManager.isDarkMode;
        final ThemeMode themeMode = isDarkMode ? ThemeMode.dark : ThemeMode.light;

        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Flutter GPS',
          themeMode: themeMode, // Aplica o tema dinâmico
          theme: ThemeData(
            brightness: isDarkMode ? Brightness.dark : Brightness.light,
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.deepPurple,
              brightness: isDarkMode ? Brightness.dark : Brightness.light,
            ),
            useMaterial3: true,
          ),
          darkTheme: ThemeData(
            brightness: Brightness.dark,
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.deepPurple,
              brightness: Brightness.dark,
            ),
            useMaterial3: true,
          ),
          localizationsDelegates: context.localizationDelegates,
          supportedLocales: context.supportedLocales,
          locale: context.locale,
          home: const SplashScreen(),
        );
      },
    );
  }
}
