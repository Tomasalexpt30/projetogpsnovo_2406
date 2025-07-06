import 'package:shared_preferences/shared_preferences.dart';

/// Classe responsável por guardar e carregar preferências do utilizador
/// utilizando a biblioteca `SharedPreferences`, que permite armazenar dados
/// de forma persistente no dispositivo.
class PreferencesHelper {
  /// Função para guardar as definições de som, vibração, velocidade da voz,
  /// tom da voz e o idioma selecionado.
  ///
  /// Parâmetros:
  /// - [soundEnabled]: Define se o som está ativado.
  /// - [vibrationEnabled]: Define se a vibração está ativada.
  /// - [voiceSpeed]: Define a velocidade da voz no text-to-speech.
  /// - [voicePitch]: Define o tom da voz no text-to-speech.
  /// - [selectedLanguageCode]: Define o código do idioma selecionado.
  Future<void> saveSoundSettings({
    required bool soundEnabled,
    required bool vibrationEnabled,
    required double voiceSpeed,
    required double voicePitch,
    required String selectedLanguageCode,
  }) async {
    final prefs = await SharedPreferences.getInstance(); // Obtém a instância de SharedPreferences

    // Guarda as definições recebidas nos campos apropriados
    await prefs.setBool('soundEnabled', soundEnabled);
    await prefs.setBool('vibrationEnabled', vibrationEnabled);
    await prefs.setDouble('voiceSpeed', voiceSpeed);
    await prefs.setDouble('voicePitch', voicePitch);
    await prefs.setString('selectedLanguageCode', selectedLanguageCode);
  }

  /// Função para carregar as definições de som e idioma previamente guardadas.
  ///
  /// Retorna um mapa com todas as definições. Se não existirem valores guardados,
  /// são atribuídos valores por defeito.
  Future<Map<String, dynamic>> loadSoundSettings() async {
    final prefs = await SharedPreferences.getInstance(); // Obtém a instância de SharedPreferences

    // Recupera os valores guardados ou atribui os valores por defeito se não existirem
    return {
      'soundEnabled': prefs.getBool('soundEnabled') ?? true,
      'vibrationEnabled': prefs.getBool('vibrationEnabled') ?? true,
      'voiceSpeed': prefs.getDouble('voiceSpeed') ?? 0.6,
      'voicePitch': prefs.getDouble('voicePitch') ?? 1.0,
      'selectedLanguageCode': prefs.getString('selectedLanguageCode') ?? 'pt-PT',
    };
  }

  /// Função para guardar a preferência de personalização (modo claro ou escuro).
  ///
  /// Parâmetros:
  /// - [isDarkMode]: Define se o modo escuro está ativado.
  Future<void> savePersonalizationSettings({
    required bool isDarkMode,
  }) async {
    final prefs = await SharedPreferences.getInstance(); // Obtém a instância de SharedPreferences

    // Guarda a preferência do tema
    await prefs.setBool('isDarkMode', isDarkMode);
  }

  /// Função para carregar a preferência de personalização (modo claro ou escuro).
  ///
  /// Retorna um mapa com a preferência do tema. Se não existir valor guardado,
  /// o valor por defeito é `false` (modo claro).
  Future<Map<String, dynamic>> loadPersonalizationSettings() async {
    final prefs = await SharedPreferences.getInstance(); // Obtém a instância de SharedPreferences

    return {
      'isDarkMode': prefs.getBool('isDarkMode') ?? false,
    };
  }

  /// Função para guardar o código do idioma selecionado pelo utilizador.
  ///
  /// Parâmetros:
  /// - [languageCode]: Código do idioma (ex.: 'pt-PT', 'en-US').
  Future<void> saveLanguageCode(String languageCode) async {
    final prefs = await SharedPreferences.getInstance(); // Obtém a instância de SharedPreferences

    // Guarda o código do idioma selecionado
    await prefs.setString('selectedLanguageCode', languageCode);
  }

  /// Função para carregar o código do idioma selecionado.
  ///
  /// Retorna o código do idioma guardado ou 'pt-PT' se não existir valor guardado.
  Future<String> loadLanguageCode() async {
    final prefs = await SharedPreferences.getInstance(); // Obtém a instância de SharedPreferences

    return prefs.getString('selectedLanguageCode') ?? 'pt-PT';
  }

  /// Função para guardar uma lista de destinos favoritos.
  ///
  /// Parâmetros:
  /// - [favoritos]: Lista de strings que representa os destinos favoritos.
  Future<void> saveFavorites(List<String> favoritos) async {
    final prefs = await SharedPreferences.getInstance(); // Obtém a instância de SharedPreferences

    // Guarda a lista de favoritos
    await prefs.setStringList('favoriteKeys', favoritos);
  }

  /// Função para carregar a lista de destinos favoritos guardada.
  ///
  /// Retorna uma lista de strings com os favoritos ou uma lista vazia se não existirem favoritos guardados.
  Future<List<String>> loadFavorites() async {
    final prefs = await SharedPreferences.getInstance(); // Obtém a instância de SharedPreferences

    return prefs.getStringList('favoriteKeys') ?? [];
  }

  /// Função para limpar todos os favoritos guardados.
  Future<void> clearFavorites() async {
    final prefs = await SharedPreferences.getInstance(); // Obtém a instância de SharedPreferences

    // Remove a chave onde estão guardados os favoritos
    await prefs.remove('favoriteKeys');
  }
}
