import 'package:shared_preferences/shared_preferences.dart';

class PreferencesHelper {
  // Salvar preferências de som, idioma, e tema
  Future<void> saveSoundSettings({
    required bool soundEnabled,
    required bool vibrationEnabled,
    required double voiceSpeed,
    required double voicePitch,
    required String selectedLanguageCode, // Novo parâmetro para o idioma
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('soundEnabled', soundEnabled);
    await prefs.setBool('vibrationEnabled', vibrationEnabled);
    await prefs.setDouble('voiceSpeed', voiceSpeed);
    await prefs.setDouble('voicePitch', voicePitch);
    await prefs.setString('selectedLanguageCode', selectedLanguageCode);  // Salvar o idioma
  }

  // Carregar preferências de som e idioma
  Future<Map<String, dynamic>> loadSoundSettings() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'soundEnabled': prefs.getBool('soundEnabled') ?? true,
      'vibrationEnabled': prefs.getBool('vibrationEnabled') ?? true,
      'voiceSpeed': prefs.getDouble('voiceSpeed') ?? 0.6,
      'voicePitch': prefs.getDouble('voicePitch') ?? 1.0,
      'selectedLanguageCode': prefs.getString('selectedLanguageCode') ?? 'pt-PT', // Carregar idioma
    };
  }

  // Salvar preferências de personalização (tema)
  Future<void> savePersonalizationSettings({
    required bool isDarkMode, // Modo claro ou escuro
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', isDarkMode);  // Salvar o estado do tema
  }

  // Carregar preferências de personalização (tema)
  Future<Map<String, dynamic>> loadPersonalizationSettings() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'isDarkMode': prefs.getBool('isDarkMode') ?? false, // Modo claro ou escuro
    };
  }

  // Salvar idioma selecionado
  Future<void> saveLanguageCode(String languageCode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selectedLanguageCode', languageCode);
  }

  // Carregar idioma selecionado
  Future<String> loadLanguageCode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('selectedLanguageCode') ?? 'pt-PT'; // Padrão é português
  }

  // Salvar destinos favoritos
  Future<void> saveFavorites(List<String> favoritos) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('favoritos', favoritos);  // Salvar lista de favoritos
  }

  // Carregar destinos favoritos
  Future<List<String>> loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList('favoritos') ?? [];  // Carregar lista de favoritos
  }
}
