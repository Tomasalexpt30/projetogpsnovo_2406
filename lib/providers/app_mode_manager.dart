import 'package:flutter/material.dart';
import 'package:projetogpsnovo/helpers/preferences_helpers.dart';

/// Define os dois modos possíveis da aplicação.
enum AppMode {
  navegacao,
  visita,
}

/// Um ChangeNotifier que guarda o modo atual e notifica os widgets interessados.
class AppModeManager with ChangeNotifier {
  AppMode _modoAtual = AppMode.navegacao;
  bool _isDarkMode = false;  // Variável que controla o modo claro/escuro

  final PreferencesHelper _preferencesHelper = PreferencesHelper();

  AppMode get modoAtual => _modoAtual;
  bool get isDarkMode => _isDarkMode;

  // Carregar preferências de tema (modo claro/escuro)
  Future<void> loadPreferences() async {
    final settings = await _preferencesHelper.loadPersonalizationSettings();
    _isDarkMode = settings['isDarkMode'] ?? false;  // Carregar a configuração de tema
    notifyListeners();  // Notificar para que a UI seja atualizada
  }

  // Alterar o modo de navegação/visita
  void setModo(AppMode novoModo) {
    if (_modoAtual != novoModo) {
      _modoAtual = novoModo;
      notifyListeners();
    }
  }

  // Alternar entre modo claro e escuro
  void toggleTheme() async {
    _isDarkMode = !_isDarkMode;
    await _preferencesHelper.savePersonalizationSettings(
      isDarkMode: _isDarkMode,  // Apenas salvar a configuração de tema
    );
    notifyListeners();  // Notificar para que o tema seja alterado imediatamente
  }
}
