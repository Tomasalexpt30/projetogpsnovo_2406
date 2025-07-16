import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart'; // síntese de voz
import 'tour_scan.dart'; // página que faz o scan durante a visita
import 'package:projetogpsnovo/helpers/preferences_helpers.dart';
import 'package:easy_localization/easy_localization.dart'; // para traduções

class TourPage extends StatefulWidget {
  const TourPage({super.key});

  @override
  State<TourPage> createState() => _TourPageState();
}

class _TourPageState extends State<TourPage> {
  Map<String, dynamic> mensagens = {}; // mensagens carregadas do JSON
  final FlutterTts _tts = FlutterTts(); // controlador TTS
  final PreferencesHelper _preferencesHelper = PreferencesHelper(); // helper para preferências

  String selectedLanguageCode = 'pt-PT'; // idioma selecionado
  bool soundEnabled = true; // som ativado/desativado
  bool isSpeaking = false; // indica se está a falar

  @override
  void initState() {
    super.initState();
    _loadSettings(); // carrega definições ao iniciar
  }

  Future<void> _loadSettings() async {
    final settings = await _preferencesHelper.loadSoundSettings(); // lê preferências guardadas
    setState(() {
      selectedLanguageCode = settings['selectedLanguageCode'] ?? 'pt-PT';
      soundEnabled = settings['soundEnabled'];
    });
    await _tts.setLanguage(selectedLanguageCode); // define idioma TTS
    await _tts.setSpeechRate(0.5); // define velocidade TTS
    await _loadMessages(); // carrega mensagens do JSON
  }

  Future<void> _loadMessages() async {
    String langCode = selectedLanguageCode.toLowerCase().split('-')[0];
    String fullCode = selectedLanguageCode.toLowerCase().replaceAll('_', '-');
    List<String> paths = [
      'assets/tts/tour/tour_$fullCode.json',
      'assets/tts/tour/tour_$langCode.json',
      'assets/tts/tour/tour_en.json',
    ];
    String? jsonString;
    for (String path in paths) {
      try {
        jsonString = await rootBundle.loadString(path); // tenta carregar o ficheiro
        break;
      } catch (_) {}
    }
    setState(() {
      mensagens = jsonString != null ? json.decode(jsonString) : {}; // guarda mensagens
    });
  }

  Future<void> speakAndBlock(String texto) async {
    if (soundEnabled) {
      setState(() {
        isSpeaking = true;
      });
      await _tts.speak(texto); // fala o texto
      await _tts.awaitSpeakCompletion(true); // espera até terminar
      setState(() {
        isSpeaking = false;
      });
    }
  }

  void _mostrarPopupDescricaoVisita() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            'tour_page.guided_tour_popup'.tr(), // título traduzido
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            textAlign: TextAlign.center,
          ),
          content: Text(
            'tour_page.guided_tour_info_description'.tr(), // descrição traduzida
            style: const TextStyle(fontSize: 15),
            textAlign: TextAlign.left,
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            GestureDetector(
              onTap: () => Navigator.of(context).pop(), // fecha popup
              child: Padding(
                padding: const EdgeInsets.all(5),
                child: Text(
                  'privacy_policy.close'.tr(), // botão fechar
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  String get imagemPiso => 'assets/images/map/00_piso.png'; // imagem inicial do mapa

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: InteractiveViewer( // permite zoom e mover mapa
              panEnabled: true,
              scaleEnabled: true,
              minScale: 1.0,
              maxScale: 3.5,
              constrained: false,
              boundaryMargin: const EdgeInsets.all(100),
              child: Image.asset(
                imagemPiso, // imagem do piso atual
                fit: BoxFit.none,
                alignment: Alignment.topLeft,
              ),
            ),
          ),
          DraggableScrollableSheet( // painel inferior arrastável
            minChildSize: 0.20,
            maxChildSize: 0.35,
            initialChildSize: 0.35,
            builder: (context, controller) {
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.95),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                  boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 6)],
                ),
                child: SingleChildScrollView(
                  controller: controller,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Center(
                        child: Text(
                          'tour_page.guided_tour_title'.tr(), // título da secção
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Center(
                        child: Text(
                          'tour_page.guided_tour_description'.tr(), // descrição da visita
                          style: TextStyle(fontSize: 16, color: Colors.grey.shade700),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 30),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          ElevatedButton.icon( // botão iniciar visita
                            onPressed: isSpeaking ? null : () async {
                              String mensagemIniciar = mensagens['alerts']?['guided_tour_start_alert']
                                  ?? 'Vamos iniciar a visita guiada pela Universidade Autónoma de Lisboa.';

                              await _tts.speak(mensagemIniciar); // fala mensagem inicial
                              await _tts.awaitSpeakCompletion(true);

                              if (!mounted) return;

                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => TourScanPage( // abre página de scan
                                    destino: 'Visita',
                                    destinosMap: {},
                                  ),
                                ),
                              );
                            },
                            icon: const Icon(Icons.play_arrow),
                            label: Text('tour_page.start_guided_tour'.tr()),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                            ),
                          ),
                          ElevatedButton.icon( // botão info
                            onPressed: _mostrarPopupDescricaoVisita,
                            icon: const Icon(Icons.info_outline),
                            label: Text('tour_page.guided_tour_info'.tr()),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          Positioned( // botão voltar no topo
            top: 40,
            left: 10,
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black),
              onPressed: () {
                Navigator.pop(context); // volta para trás
              },
            ),
          ),
        ],
      ),
    );
  }
}
