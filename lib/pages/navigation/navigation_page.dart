import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:audioplayers/audioplayers.dart';
import 'navigation_scan.dart';
import 'package:projetogpsnovo/helpers/preferences_helpers.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:diacritic/diacritic.dart';

/// Página principal de seleção de destinos no modo de navegação com beacons
class NavigationMapSelectorPage extends StatefulWidget {
  const NavigationMapSelectorPage({super.key});

  @override
  State<NavigationMapSelectorPage> createState() => _NavigationMapSelectorPageState();
}

/// Estado da NavigationMapSelectorPage com lógica de voz, favoritos e carregamento dinâmico de dados
class _NavigationMapSelectorPageState extends State<NavigationMapSelectorPage> {
  // JSON carregado com mensagens, dados dos beacons e comandos de voz
  Map<String, dynamic> mensagens = {};
  Map<String, dynamic> beacons = {};
  Map<String, String> voiceCommandsMap = {};

  // Lista de identificadores de beacons considerados operacionais
  List<String> beaconsAtivos = ['Beacon 1', 'Beacon 3', 'Beacon 15'];

  // Estado da navegação
  String? destinoSelecionado;
  late stt.SpeechToText _speech; // Reconhecimento de voz
  final FlutterTts _tts = FlutterTts(); // Síntese de voz
  final AudioPlayer _audioPlayer = AudioPlayer(); // Efeitos sonoros
  final PreferencesHelper _preferencesHelper = PreferencesHelper(); // Acesso às preferências do utilizador
  bool _speechAvailable = false; // Verifica se o reconhecimento de voz está disponível
  bool _isListening = false; // Indica se está a ouvir o utilizador
  String selectedLanguageCode = 'pt-PT'; // Código de idioma selecionado
  bool soundEnabled = true; // Indica se o som está ativado
  bool isSpeaking = false; // Indica se está atualmente a falar
  String _speechStatus = ''; // Estado do reconhecimento de voz

  // Listas de favoritos e destinos disponíveis
  List<String> favoritos = [];
  List<String> destinosDisponiveis = [];

  @override
  void initState() {
    super.initState();
    _initSpeech(); // Inicializa o reconhecimento de voz
    _loadSettings(); // Carrega definições de som e idioma
    _loadFavorites(); // Carrega destinos favoritos guardados
  }

  /// Retorna o conjunto de destinos disponíveis com base nos beacons ativos
  Set<String> get destinosComBeacon {
    Set<String> destinos = {};
    for (var beaconId in beaconsAtivos) {
      final beacon = beacons[beaconId];
      if (beacon != null && beacon['beacon_destinations'] != null) {
        destinos.addAll(List<String>.from(beacon['beacon_destinations']));
      }
    }
    return destinos;
  }

  /// Organiza os destinos por piso com base nos dados dos beacons
  Map<String, List<String>> get destinosPorPiso {
    Map<String, List<String>> pisos = {
      'Piso -1': [],
      'Piso 0': [],
      'Piso 1': [],
      'Piso 2': [],
      'Piso 3': [],
      'Piso 4': [],
    };

    for (var beaconId in beaconsAtivos) {
      final beacon = beacons[beaconId];
      if (beacon != null) {
        String piso = 'Piso ${beacon['beacon_floor']}';
        List<String> destinos = List<String>.from(beacon['beacon_destinations'] ?? []);
        if (pisos.containsKey(piso)) {
          pisos[piso]?.addAll(destinos);
        }
      }
    }

    return pisos;
  }

  /// Mapeia os comandos de voz reconhecidos para destinos válidos com beacon
  Map<String, String> get destinosMap {
    Map<String, String> map = {};
    for (var entry in voiceCommandsMap.entries) {
      if (destinosComBeacon.contains(entry.value)) {
        map[entry.key] = entry.value;
      }
    }
    return map;
  }

  /// Inicializa o reconhecimento de voz e trata possíveis erros durante o processo
  Future<void> _initSpeech() async {
    _speech = stt.SpeechToText();
    _speechAvailable = await _speech.initialize(
      onStatus: (status) {
        _speechStatus = status; // Atualiza o estado do reconhecimento
      },
      onError: (error) async {
        if (_isListening) {
          setState(() => _isListening = false);
          String mensagemErro = "";

          // Trata erros comuns de tempo limite ou falta de correspondência
          if (error.errorMsg == 'error_speech_timeout') {
            await _speech.stop();
            await _playStopRecordingSound();
            mensagemErro = _mensagem('timeout_alert');
          } else if (error.errorMsg == 'error_no_match') {
            await _speech.stop();
            await _playStopRecordingSound();
            mensagemErro = _mensagem('no_match_alert');
          }

          // Fala a mensagem de erro se o som estiver ativado
          if (mensagemErro.isNotEmpty && soundEnabled) {
            await _tts.speak(mensagemErro);
            await _tts.awaitSpeakCompletion(true);
          }
        }
      },
    );
  }

  /// Carrega as definições do utilizador, como idioma e som
  Future<void> _loadSettings() async {
    final settings = await _preferencesHelper.loadSoundSettings();
    setState(() {
      selectedLanguageCode = settings['selectedLanguageCode'] ?? 'pt-PT';
      soundEnabled = settings['soundEnabled'];
    });

    // Configura o motor de texto para fala com o idioma e velocidade
    await _tts.setLanguage(selectedLanguageCode);
    await _tts.setSpeechRate(0.5);

    // Carrega as mensagens com base no idioma
    await _loadMessages();
  }

  /// Carrega mensagens, comandos de voz e dados dos beacons com base no idioma
  Future<void> _loadMessages() async {
    String langCode = selectedLanguageCode.toLowerCase().split('-')[0];
    String fullCode = selectedLanguageCode.toLowerCase().replaceAll('_', '-');

    List<String> paths = [
      'assets/tts/navigation/nav_$fullCode.json',
      'assets/tts/navigation/nav_$langCode.json',
      'assets/tts/navigation/nav_en.json',
    ];

    String? jsonString;
    for (String path in paths) {
      try {
        jsonString = await rootBundle.loadString(path);
        break;
      } catch (_) {}
    }

    setState(() {
      mensagens = jsonString != null ? json.decode(jsonString) : {};
      voiceCommandsMap = Map<String, String>.from(mensagens['voice_commands'] ?? {});
      beacons = mensagens['beacons'] ?? {};
    });

    // Atualiza a lista de destinos disponíveis, removendo os que já são favoritos
    destinosDisponiveis = destinosComBeacon.toList();
    destinosDisponiveis.removeWhere((destino) => favoritos.contains(destino));
  }

  /// Normaliza o texto removendo acentos e colocando em minúsculas
  String normalizarTexto(String texto) {
    return removeDiacritics(texto.toLowerCase().trim());
  }

  /// Adiciona um destino à lista de favoritos
  void _adicionarFavorito(String destino) {
    setState(() {
      if (!favoritos.contains(destino)) {
        favoritos.add(destino);
        destinosDisponiveis.remove(destino);
        _saveFavorites();
      }
    });
  }

  /// Remove um destino da lista de favoritos
  void _removerFavorito(String destino) {
    setState(() {
      favoritos.remove(destino);
      destinosDisponiveis.add(destino);
      _saveFavorites();
    });
  }

  /// Guarda a lista atualizada de favoritos nas preferências
  Future<void> _saveFavorites() async {
    await _preferencesHelper.saveFavorites(favoritos);
  }

  /// Carrega a lista de favoritos guardados nas preferências
  Future<void> _loadFavorites() async {
    final favoritosGuardados = await _preferencesHelper.loadFavorites();
    setState(() {
      favoritos = favoritosGuardados;
      destinosDisponiveis.removeWhere((destino) => favoritos.contains(destino));
    });
  }

  /// Obtém a mensagem correspondente à chave fornecida, podendo substituir o placeholder {destination}
  String _mensagem(String chave, {String? valor}) {
    String raw = mensagens['alerts']?[chave] ?? mensagens[chave] ?? '';
    if (valor != null) {
      raw = raw.replaceAll('{destination}', valor);
    }
    return raw;
  }

  /// Toca o som de início de gravação e aguarda brevemente antes de continuar
  Future<void> _playStartRecordingSoundAndWait() async {
    await _audioPlayer.play(AssetSource('sounds/start_recording_sound.mp3'));
    await Future.delayed(const Duration(milliseconds: 700)); // Aguarda para sincronizar com a animação
  }

  /// Toca o som de finalização da gravação
  Future<void> _playStopRecordingSound() async {
    await _audioPlayer.play(AssetSource('sounds/stop_recording_sound.mp3'));
  }

  /// Trata comandos de voz inválidos (sem correspondência reconhecida)
  Future<void> _tratarComandoInvalido() async {
    await _speech.stop(); // Para a escuta
    await _playStopRecordingSound(); // Toca som de fim
    setState(() => _isListening = false); // Atualiza o estado

    // Dá feedback por voz ao utilizador se o som estiver ativado
    if (soundEnabled) {
      await _tts.speak(_mensagem('voice_unavailable_alert'));
      await _tts.awaitSpeakCompletion(true);
    }
  }

  /// Inicia a escuta de comandos de voz e processa o resultado
  Future<void> _ouvirComando() async {
    if (!_speechAvailable) return; // Ignora se a funcionalidade não estiver disponível

    await _tts.stop(); // Para qualquer fala anterior
    setState(() => _isListening = true); // Atualiza o estado

    _speechStatus = '';

    // Inicia o reconhecimento de voz
    await _speech.listen(
      localeId: selectedLanguageCode,
      listenMode: stt.ListenMode.dictation,
      listenFor: const Duration(minutes: 5),
      pauseFor: const Duration(minutes: 2),
      onResult: (result) async {
        if (!result.finalResult) return; // Apenas processa resultado final

        final textoReconhecido = normalizarTexto(result.recognizedWords);

        // Verifica se algum comando reconhecido corresponde a comandos válidos
        for (final entrada in voiceCommandsMap.entries) {
          if (textoReconhecido.contains(normalizarTexto(entrada.key))) {
            final destino = entrada.value;
            if (destinosComBeacon.contains(destino)) {
              setState(() {
                destinoSelecionado = destino;
                _isListening = false;
              });

              await _speech.stop();
              await _playStopRecordingSound();

              // Dá feedback verbal antes de iniciar a navegação
              if (soundEnabled) {
                await _tts.speak(_mensagem('voice_start_alert', valor: destino));
                await _tts.awaitSpeakCompletion(true);
              }

              await Future.delayed(const Duration(seconds: 1));
              if (!mounted) return;

              // Navega para a página de navegação com o destino selecionado
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => BeaconScanPage(
                    destino: destino,
                    destinosMap: destinosMap,
                  ),
                ),
              );
              return;
            }
          }
        }

        await _tratarComandoInvalido(); // Se nenhum comando corresponder, trata como inválido
      },
    );

    // Aguarda até que o estado se torne 'listening' (ou atinja limite de tentativas)
    int tentativas = 0;
    while (_speechStatus != 'listening' && tentativas < 20) {
      await Future.delayed(const Duration(milliseconds: 50));
      tentativas++;
    }

    // Toca o som indicando que a gravação começou
    await _playStartRecordingSoundAndWait();
  }
  /// Caminho da imagem a apresentar para o piso atual
  String get imagemPiso => 'assets/images/map/00_piso.png';

  /// Fala o texto indicado e bloqueia a interação durante a fala
  Future<void> speakAndBlock(String texto) async {
    if (soundEnabled) {
      setState(() {
        isSpeaking = true;
      });

      await _tts.speak(texto);
      await _tts.awaitSpeakCompletion(true);

      setState(() {
        isSpeaking = false;
      });
    }
  }

  /// Mostra um diálogo com a lista de destinos para adicionar aos favoritos
  void _mostrarAdicionarFavorito() {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 50, vertical: 80),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Título
                Center(
                  child: Text(
                    'navigation_map_selector.add_favorite'.tr(),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 19),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 16),
                const Divider(),
                // Lista de destinos por piso
                SizedBox(
                  height: 325,
                  child: SingleChildScrollView(
                    child: Column(
                      children: destinosPorPiso.entries.expand((entry) {
                        final destinosFiltrados = entry.value.where((destino) =>
                        destinosDisponiveis.contains(destino) && destinosComBeacon.contains(destino)
                        ).toList();

                        if (destinosFiltrados.isEmpty) return <Widget>[];

                        return [
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Text(
                              entry.key,
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          ),
                          ...destinosFiltrados.map((destino) {
                            return ListTile(
                              title: Text(destino),
                              onTap: () {
                                _adicionarFavorito(destino); // Adiciona destino aos favoritos
                                Navigator.of(context).pop(); // Fecha o diálogo
                              },
                            );
                          }).toList(),
                          const Divider(),
                        ];
                      }).toList(),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                // Botão de fechar
                Center(
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(
                      'privacy_policy.close'.tr(),
                      style: const TextStyle(fontSize: 14, color: Colors.black),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }


  /// Mostra um diálogo para o utilizador selecionar um destino disponível com base nos beacons ativos
  void _mostrarPopupDestinos() {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 50, vertical: 80),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Título do popup
                Center(
                  child: Text(
                    'navigation_map_selector.select_destination'.tr(),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 19),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 16),
                const Divider(),
                // Lista de destinos agrupados por piso
                SizedBox(
                  height: 325,
                  child: SingleChildScrollView(
                    child: Column(
                      children: destinosPorPiso.entries.expand((entry) {
                        // Filtra apenas os destinos com beacon válido
                        final destinosFiltrados = entry.value.where((destino) => destinosComBeacon.contains(destino)).toList();

                        if (destinosFiltrados.isEmpty) return <Widget>[];

                        return [
                          // Nome do piso
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Text(
                              entry.key,
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          ),
                          // Lista de destinos clicáveis
                          ...destinosFiltrados.map((destino) {
                            return ListTile(
                              title: Text(destino),
                              onTap: () {
                                setState(() {
                                  destinoSelecionado = destino; // Atualiza o destino selecionado
                                });
                                Navigator.of(context).pop(); // Fecha o diálogo
                              },
                            );
                          }).toList(),
                          const Divider(),
                        ];
                      }).toList(),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                // Botão de fechar
                Center(
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(
                      'privacy_policy.close'.tr(),
                      style: const TextStyle(fontSize: 14, color: Colors.black),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Mapa interativo que permite zoom e movimento do utilizador
          Positioned.fill(
            child: InteractiveViewer(
              panEnabled: true,
              scaleEnabled: true,
              minScale: 1.0,
              maxScale: 3.5,
              constrained: false,
              boundaryMargin: const EdgeInsets.all(100),
              child: Image.asset(
                imagemPiso, // Caminho da imagem do piso atual
                fit: BoxFit.none,
                alignment: Alignment.topLeft,
              ),
            ),
          ),

          // Painel inferior deslizante com opções de navegação
          DraggableScrollableSheet(
            minChildSize: 0.20,
            maxChildSize: 0.40,
            initialChildSize: 0.40,
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
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Título da secção "Para onde deseja ir?"
                      Text(
                        'navigation_map_selector.where_to_go'.tr(),
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10),

                      // Campo interativo para selecionar destino
                      GestureDetector(
                        onTap: _mostrarPopupDestinos, // Abre popup de seleção
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade600),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Center(
                            child: Text(
                              destinoSelecionado ?? 'navigation_map_selector.select_destination'.tr(),
                              style: TextStyle(
                                fontSize: 16,
                                color: destinoSelecionado == null
                                    ? Colors.grey.shade600 // Texto em cinzento se nenhum destino for selecionado
                                    : Colors.black,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Linha de botões para iniciar navegação ou utilizar comando por voz
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Botão de iniciar navegação
                          ElevatedButton.icon(
                            onPressed: destinoSelecionado == null || isSpeaking
                                ? null // Desativado se nenhum destino selecionado ou se já estiver a falar
                                : () async {
                              // Substitui o marcador {destination} na mensagem e fala
                              String mensagemIniciar = mensagens['alerts']?['start_navigation_alert'] ?? 'Mensagem de início não encontrada';
                              mensagemIniciar = mensagemIniciar.replaceAll('{destination}', destinoSelecionado!);
                              await speakAndBlock(mensagemIniciar);

                              await Future.delayed(const Duration(milliseconds: 500));
                              if (!mounted) return;

                              // Inicia a navegação para a página de scanning
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => BeaconScanPage(
                                    destino: destinoSelecionado!,
                                    destinosMap: destinosMap,
                                  ),
                                ),
                              );
                            },
                            icon: const Icon(Icons.navigation),
                            label: Text('navigation_map_selector.start_navigation'.tr()),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                            ),
                          ),

                          // Botão para ativar comando de voz
                          ElevatedButton.icon(
                            onPressed: _ouvirComando,
                            icon: const Icon(Icons.mic),
                            label: Text('navigation_map_selector.by_voice'.tr()),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 10),  // Espaçamento vertical antes do título "Favoritos"

                      // Título da secção "Favoritos" com estilo em negrito
                      Text(
                        'navigation_map_selector.favorites'.tr(),   // Texto traduzido com easy_localization
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),

                      // Scroll horizontal para apresentar os botões de favoritos
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            // Geração dinâmica dos botões de favoritos
                            ...favoritos.map((favorito) {
                              return Padding(
                                padding: const EdgeInsets.only(right: 8, top: 4, bottom: 1),
                                child: Row(
                                  children: [
                                    // Botão para selecionar um destino favorito
                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.orange,  // Cor de fundo do botão
                                        foregroundColor: Colors.white,  // Cor do texto e ícones
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                                      ),
                                      onPressed: () async {
                                        // Atualiza o estado ao selecionar um destino
                                        setState(() {
                                          destinoSelecionado = favorito;
                                        });
                                        // Fala o nome do destino selecionado
                                        await speakAndBlock(_mensagem('voice_selected_alert', valor: favorito));
                                      },
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          // Nome do destino favorito
                                          Text(favorito),
                                          const SizedBox(width: 5),
                                          // Ícone para remover o favorito
                                          GestureDetector(
                                            onTap: () {
                                              _removerFavorito(favorito);
                                            },
                                            child: const SizedBox(
                                              width: 22,
                                              height: 22,
                                              child: Center(
                                                child: Icon(Icons.cancel, size: 18, color: Colors.white),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),

                            // Botão final para adicionar um novo favorito
                            Padding(
                              padding: const EdgeInsets.only(right: 10, top: 5),
                              child: ElevatedButton(
                                onPressed: _mostrarAdicionarFavorito,  // Abre diálogo ou ação para adicionar
                                child: const Icon(Icons.add),   // Ícone "+"
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.orange,
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),

          // Botão de navegação "voltar", posicionado no canto superior esquerdo do ecrã
          Positioned(
            top: 40,  // Distância do topo
            left: 10,  // Distância da esquerda
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black),  // Ícone de seta para trás
              onPressed: () {
                Navigator.pop(context);  // Fecha o ecrã atual e volta ao anterior
              },
            ),
          ),
        ],
      ),
    );
  }
}
