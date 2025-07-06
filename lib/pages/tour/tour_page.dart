import 'dart:convert'; // Importa biblioteca para decodificar JSON
import 'package:flutter/material.dart'; // Importa widgets principais do Flutter
import 'package:flutter/services.dart'; // Necessário para ler assets da aplicação
import 'package:flutter_tts/flutter_tts.dart'; // Biblioteca de Text-to-Speech
import 'tour_scan.dart'; // Importa a próxima página da visita guiada
import 'package:projetogpsnovo/helpers/preferences_helpers.dart'; // Helper para guardar e ler preferências
import 'package:easy_localization/easy_localization.dart'; // Biblioteca para tradução automática

// Widget principal da página de introdução à visita guiada
class TourPage extends StatefulWidget {
  const TourPage({super.key}); // Construtor padrão com chave opcional

  @override
  State<TourPage> createState() => _TourPageState(); // Associa estado ao widget
}

// Estado associado ao widget TourPage
class _TourPageState extends State<TourPage> {
  Map<String, dynamic> mensagens = {}; // Armazena mensagens do JSON
  final FlutterTts _tts = FlutterTts(); // Instância do motor de voz
  final PreferencesHelper _preferencesHelper = PreferencesHelper(); // Instância de helper para preferências

  String selectedLanguageCode = 'pt-PT'; // Idioma por defeito
  bool soundEnabled = true; // Flag para verificar se som está ativo
  bool isSpeaking = false; // Flag para saber se TTS está atualmente a falar

  @override
  void initState() {
    super.initState(); // Chama initState da superclasse
    _loadSettings(); // Carrega definições guardadas
  }

  // Carrega as preferências do utilizador (idioma e som) e configura o TTS
  Future<void> _loadSettings() async {
    final settings = await _preferencesHelper.loadSoundSettings(); // Lê ficheiro de preferências
    setState(() {
      selectedLanguageCode = settings['selectedLanguageCode'] ?? 'pt-PT'; // Atualiza idioma
      soundEnabled = settings['soundEnabled']; // Atualiza flag do som
    });
    await _tts.setLanguage(selectedLanguageCode); // Define idioma no TTS
    await _tts.setSpeechRate(0.5); // Define velocidade da voz
    await _loadMessages(); // Carrega as mensagens da visita
  }

  // Carrega ficheiros JSON com mensagens para o idioma atual
  Future<void> _loadMessages() async {
    String langCode = selectedLanguageCode.toLowerCase().split('-')[0]; // Ex: pt
    String fullCode = selectedLanguageCode.toLowerCase().replaceAll('_', '-'); // Ex: pt-pt
    List<String> paths = [
      'assets/tts/tour/tour_$fullCode.json', // Caminho com idioma completo
      'assets/tts/tour/tour_$langCode.json', // Caminho com apenas idioma base
      'assets/tts/tour/tour_en.json', // Caminho de fallback (inglês)
    ];
    String? jsonString; // String para guardar conteúdo do ficheiro
    for (String path in paths) {
      try {
        jsonString = await rootBundle.loadString(path); // Tenta ler ficheiro
        break; // Se conseguir, sai do ciclo
      } catch (_) {} // Ignora erros e tenta o próximo
    }
    setState(() {
      mensagens = jsonString != null ? json.decode(jsonString) : {}; // Decodifica JSON
    });
  }

  // Fala o texto passado e espera até terminar
  Future<void> speakAndBlock(String texto) async {
    if (soundEnabled) { // Só fala se som estiver ativo
      setState(() {
        isSpeaking = true; // Atualiza flag para indicar que está a falar
      });
      await _tts.speak(texto); // Inicia fala
      await _tts.awaitSpeakCompletion(true); // Espera até que termine
      setState(() {
        isSpeaking = false; // Marca como terminou
      });
    }
  }

  // Mostra popup com a descrição da visita
  void _mostrarPopupDescricaoVisita() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            'tour_page.guided_tour_popup'.tr(), // Título traduzido
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            textAlign: TextAlign.center,
          ),
          content: Text(
            'tour_page.guided_tour_info_description'.tr(), // Corpo traduzido
            style: const TextStyle(fontSize: 15),
            textAlign: TextAlign.left, // Alinhado à esquerda
          ),
          actionsAlignment: MainAxisAlignment.center, // Centraliza botão
          actions: [
            GestureDetector(
              onTap: () => Navigator.of(context).pop(), // Fecha popup
              child: Padding(
                padding: const EdgeInsets.all(5),
                child: Text(
                  'privacy_policy.close'.tr(), // Texto traduzido
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // Getter com caminho da imagem do piso base da visita
  String get imagemPiso => 'assets/images/map/00_piso.png';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Camada base com o mapa interativo
          Positioned.fill(
            child: InteractiveViewer(
              panEnabled: true, // Permite arrastar
              scaleEnabled: true, // Permite zoom
              minScale: 1.0, // Zoom mínimo
              maxScale: 3.5, // Zoom máximo
              constrained: false, // Sem restrições de tamanho
              boundaryMargin: const EdgeInsets.all(100), // Margem de navegação
              child: Image.asset(
                imagemPiso, // Caminho da imagem do piso
                fit: BoxFit.none, // Não ajusta a imagem ao tamanho
                alignment: Alignment.topLeft, // Alinha no canto superior esquerdo
              ),
            ),
          ),

          // Painel inferior que pode ser expandido ou recolhido
          DraggableScrollableSheet(
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
                          'tour_page.guided_tour_title'.tr(),
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Center(
                        child: Text(
                          'tour_page.guided_tour_description'.tr(),
                          style: TextStyle(fontSize: 16, color: Colors.grey.shade700),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 30),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          // Botão para iniciar visita
                          ElevatedButton.icon(
                            onPressed: isSpeaking ? null : () async {
                              String mensagemIniciar = mensagens['alerts']?['guided_tour_start_alert'] ?? 'Vamos iniciar a visita guiada pela Universidade Autónoma de Lisboa.';
                              await _tts.speak(mensagemIniciar);
                              await _tts.awaitSpeakCompletion(true);
                              if (!mounted) return;
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => TourScanPage(
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
                          // Botão para mostrar popup informativo
                          ElevatedButton.icon(
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

          // Botão "voltar" no topo esquerdo
          Positioned(
            top: 40,
            left: 10,
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black),
              onPressed: () {
                Navigator.pop(context); // Volta à página anterior
              },
            ),
          ),
        ],
      ),
    );
  }
}
