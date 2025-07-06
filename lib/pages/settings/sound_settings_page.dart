import 'package:flutter/material.dart'; // Interface gráfica principal
import 'package:flutter_tts/flutter_tts.dart'; // Biblioteca para Text-to-Speech
import 'package:google_fonts/google_fonts.dart'; // Para usar fontes personalizadas (ex: Poppins)
import 'package:easy_localization/easy_localization.dart'; // Permite internacionalização (traduções)
import 'package:vibration/vibration.dart'; // Usado para ativar a vibração no dispositivo
import 'package:projetogpsnovo/helpers/preferences_helpers.dart'; // Helper personalizado para guardar/ler preferências


class SoundSettingsPage extends StatefulWidget {
  const SoundSettingsPage({super.key}); // Construtor constante e seguro

  @override
  State<SoundSettingsPage> createState() => _SoundSettingsPageState();
}

class _SoundSettingsPageState extends State<SoundSettingsPage> {
  final FlutterTts flutterTts = FlutterTts(); // Instância para TTS
  final PreferencesHelper _preferencesHelper = PreferencesHelper(); // Helper para guardar preferências

  // Estado das preferências
  bool soundEnabled = true;
  bool vibrationEnabled = true;
  String selectedLanguageCode = 'pt-PT'; // Código de idioma inicial
  double voiceSpeed = 0.5; // Velocidade da fala (TTS)
  double voicePitch = 1.0; // Tom da fala

  // Frases de teste de voz por idioma
  final Map<String, String> voiceTests = {
    'en-US': 'This is a voice test.',
    'pt-PT': 'Isto é um teste de voz.',
    'ru-RU': 'Это тест голоса.',
    'es-ES': 'Esto es una prueba de voz.',
    'pl-PL': 'To jest test głosu.',
    'tr-TR': 'Bu bir ses testidir.',
    'de-DE': 'Dies ist ein Sprachtest.',
    'fr-FR': 'Ceci est un test de voix.',
    'nl-NL': 'Dit is een stemtest.',
    'it-IT': 'Questo è un test della voce.',
  };

  // Opções visíveis de idioma
  final Map<String, String> voiceOptions = {
    'en-US': 'English',
    'pt-PT': 'Português',
    'ru-RU': 'Русский',
    'es-ES': 'Español',
    'pl-PL': 'Polski',
    'tr-TR': 'Türkçe',
    'de-DE': 'Deutsch',
    'fr-FR': 'Français',
    'nl-NL': 'Nederlands',
    'it-IT': 'Italiano',
  };

  @override
  void initState() {
    super.initState();
    _loadSoundSettings(); // Carrega configurações guardadas
    _configurarTTS(); // Aplica as configurações ao TTS
  }

  Future<void> _configurarTTS() async {
    if (soundEnabled) {
      await flutterTts.setLanguage(selectedLanguageCode); // Define idioma
      await flutterTts.setSpeechRate(voiceSpeed); // Define velocidade
      await flutterTts.setPitch(voicePitch); // Define tom
    }
  }

  Future<void> _saveSoundSettings() async {
    // Chama o metodo do helper para guardar os valores atuais das preferências
    await _preferencesHelper.saveSoundSettings(
      soundEnabled: soundEnabled, // Guarda se o som está ativado
      vibrationEnabled: vibrationEnabled, // Guarda se a vibração está ativada
      voiceSpeed: voiceSpeed, // Guarda a velocidade da voz
      voicePitch: voicePitch, // Guarda o tom da voz
      selectedLanguageCode: selectedLanguageCode, // Guarda o código do idioma selecionado
    );
  }

  Future<void> _loadSoundSettings() async {
    final settings = await _preferencesHelper.loadSoundSettings(); // Lê as preferências do armazenamento local

    setState(() {
      // Atualiza o estado da interface com os valores carregados
      soundEnabled = settings['soundEnabled'];
      vibrationEnabled = settings['vibrationEnabled'];
      voiceSpeed = settings['voiceSpeed'];
      voicePitch = settings['voicePitch'];
      selectedLanguageCode = settings['selectedLanguageCode'];
    });
  }

  Future<void> _testarVoz() async {
    if (soundEnabled) {
      await _configurarTTS(); // Aplica novamente as configurações antes do teste
      // Fala a frase de teste correspondente ao idioma selecionado
      await flutterTts.speak(
          voiceTests[selectedLanguageCode] ?? 'Voice test.' // Frase padrão se o idioma não estiver mapeado
      );
      // Mostra uma notificação (SnackBar) indicando que a voz foi reproduzida
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Voz reproduzida')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Estilo principal dos títulos
    final TextStyle titleStyle = GoogleFonts.poppins(
      fontSize: 18,
      fontWeight: FontWeight.bold,
      color: Theme.of(context).brightness == Brightness.dark
          ? Colors.white
          : const Color(0xFF00B4D8),
    );

    // Estilo secundário para descrições
    final TextStyle subtitleStyle = GoogleFonts.poppins(
      fontSize: 14,
      color: Theme.of(context).brightness == Brightness.dark
          ? Colors.white70
          : Colors.black87,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'sound_settings_page.sound'.tr(), // Título traduzido
          style: titleStyle, // Aplica estilo
        ),
        // Define a cor de fundo do AppBar com base no tema atual (modo escuro ou claro)
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? Colors.black // Se estiver em modo escuro, usa fundo preto
            : Colors.white, // Caso contrário, usa branco
        // Define a cor dos ícones e texto no AppBar (como o título ou o botão voltar)
        foregroundColor: const Color(0xFF00B4D8), // Azul claro, usado em toda a app para coerência visual
        elevation: 1, // Pequena sombra por baixo do AppBar para destacar visualmente
      ),
      // Corpo da página
      body: ListView(
        padding: const EdgeInsets.all(16), // Espaçamento interno de 16 em todos os lados
        children: [
          // Título da secção "Preferências Gerais"
          Text(
            'sound_settings_page.general_preferences'.tr(), // Texto traduzido da chave do ficheiro JSON
            style: titleStyle, // Aplica o estilo principal definido anteriormente (Poppins, azul ou branco)
          ),
          const SizedBox(height: 8), // Espaço vertical entre o título e o conteúdo seguinte

          // Toggle de ativação/desativação do som
          SwitchListTile(
            title: Text('sound_settings_page.sound'.tr()), // Título do switch (ex: "Som")
            subtitle: Text(
              'sound_settings_page.sound_description'.tr(), // Descrição explicativa
              style: subtitleStyle, // Estilo secundário (ex: cor cinza no modo claro)
            ),
            value: soundEnabled, // Estado atual do switch (true = som ativo)
            activeColor: const Color(0xFF00B4D8), // Cor do botão quando está ativado
            onChanged: (val) {
              setState(() {
                soundEnabled = val; // Atualiza o estado local
              });
              _saveSoundSettings(); // Guarda as alterações nas preferências
            },
          ),

          // Toggle para ativar/desativar a vibração
          SwitchListTile(
            title: Text('sound_settings_page.vibration'.tr()), // Título (ex: "Vibração")
            subtitle: Text(
              'sound_settings_page.vibration_description'.tr(), // Texto explicativo
              style: subtitleStyle,
            ),
            value: vibrationEnabled, // Estado atual do switch (true = vibração ativa)
            activeColor: const Color(0xFF00B4D8),
            onChanged: (val) async {
              setState(() {
                vibrationEnabled = val; // Atualiza o estado
              });

              // Verifica se o dispositivo tem suporte para vibrar
              if (vibrationEnabled) {
                if (await Vibration.hasVibrator()) {
                  Vibration.vibrate(); // Executa breve vibração
                }
              }

              _saveSoundSettings(); // Guarda as alterações nas preferências
            },
          ),

          const Divider(height: 32), // Linha divisória para separar secções visuais

          // Título da secção "Voz"
          Text('sound_settings_page.voice'.tr(), style: titleStyle),
          const SizedBox(height: 8),

          // Seletor de idioma da voz
          ListTile(
            title: Text('sound_settings_page.language'.tr()), // Título da entrada
            subtitle: Text(
              'sound_settings_page.current_language'.tr(
                namedArgs: {
                  'language': voiceOptions[selectedLanguageCode] ?? selectedLanguageCode
                },
              ), // Mostra o nome do idioma atualmente selecionado
            ),
            trailing: const Icon(Icons.arrow_forward_ios), // Ícone de seta para a direita
            onTap: () async {
              // Mostra um diálogo com as opções de idioma
              final selected = await showDialog<String>(
                context: context,
                builder: (_) => SimpleDialog(
                  title: Text('sound_settings_page.select_language'.tr()),
                  children: voiceOptions.entries
                      .map((entry) => SimpleDialogOption(
                    child: Text(entry.value), // Nome do idioma (ex: "Español")
                    onPressed: () => Navigator.pop(context, entry.key), // Retorna o código selecionado
                  ))
                      .toList(),
                ),
              );

              if (selected != null) {
                setState(() {
                  selectedLanguageCode = selected; // Atualiza o idioma da voz
                });

                await _preferencesHelper.clearFavorites(); // Limpa favoritos por segurança (dependem de idioma)
                await _configurarTTS(); // Reconfigura TTS com novo idioma
                await _saveSoundSettings(); // Guarda configurações

                // Mostra alerta informativo ao utilizador
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Os favoritos foram limpos devido à mudança de idioma.')),
                );
              }
            },
          ),

          const SizedBox(height: 16), // Espaçamento antes do próximo slider

          // Slider para controlar a velocidade da voz
          Text(
            'sound_settings_page.voice_speed'.tr(
              namedArgs: {'speed': voiceSpeed.toStringAsFixed(1)},
            ), // Mostra a velocidade atual, ex: "Velocidade da voz (0.8)"
            style: subtitleStyle,
          ),
          Slider(
            value: voiceSpeed, // Valor atual
            min: 0, // Valor mínimo permitido
            max: 2.0, // Valor máximo permitido
            divisions: 20, // Define passos de 0.1 (20 divisões entre 0 e 2)
            label: '${voiceSpeed.toStringAsFixed(1)}x', // Etiqueta visível durante o arraste
            activeColor: const Color(0xFF00B4D8), // Cor da barra ativa
            onChanged: (value) {
              setState(() {
                voiceSpeed = value; // Atualiza o valor local
              });
              _configurarTTS(); // Aplica novo valor ao TTS
              _saveSoundSettings(); // Guarda alteração
            },
          ),

          const SizedBox(height: 8),

          // Slider para controlar o tom da voz
          Text(
            'sound_settings_page.voice_pitch'.tr(
              namedArgs: {'pitch': voicePitch.toStringAsFixed(1)},
            ), // Ex: "Tom da voz (1.0)"
            style: subtitleStyle,
          ),
          Slider(
            value: voicePitch,
            min: 0.5,
            max: 2.0,
            divisions: 6, // Passos de 0.25 (divisões entre 0.5 e 2.0)
            label: voicePitch.toStringAsFixed(1), // Mostra o valor atual do pitch
            activeColor: const Color(0xFF00B4D8),
            onChanged: (value) {
              setState(() {
                voicePitch = value; // Atualiza valor local
              });
              _configurarTTS(); // Aplica nova configuração
              _saveSoundSettings(); // Guarda nova configuração
            },
          ),

          const SizedBox(height: 24), // Espaço antes do botão

          // Botão para testar a voz com as configurações atuais
          ElevatedButton.icon(
            onPressed: _testarVoz, // Chama o metodo de teste de voz
            icon: const Icon(Icons.volume_up), // Ícone de som
            label: Text('sound_settings_page.test_voice'.tr()), // Texto traduzido (ex: "Testar voz")
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00B4D8), // Cor de fundo do botão
              foregroundColor: Colors.white, // Cor do texto e ícone
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20), // Espaçamento interno
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10), // Bordas arredondadas
              ),
            ),
          ),
        ],
      ),
    );
  }
}
