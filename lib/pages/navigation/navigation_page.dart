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

class NavigationMapSelectorPage extends StatefulWidget {
  const NavigationMapSelectorPage({super.key});

  @override
  State<NavigationMapSelectorPage> createState() => _NavigationMapSelectorPageState();
}

class _NavigationMapSelectorPageState extends State<NavigationMapSelectorPage> {
  Map<String, dynamic> mensagens = {}; // mensagens carregadas do JSON
  Map<String, dynamic> beacons = {}; // dados dos beacons
  Map<String, String> voiceCommandsMap = {}; // comandos de voz → destino

  List<String> beaconsAtivos = [
    // IDs dos beacons ativos no sistema
    'Beacon 1',
    'Beacon 3',
    'Beacon 4',
    'Beacon 5',
    'Beacon 6',
    'Beacon 7',
    'Beacon 8',
    'Beacon 9',
    'Beacon 10',
    'Beacon 11',
    'Beacon 12',
    'Beacon 13',
    'Beacon 14',
    'Beacon 15',
    'Beacon 16',
    'Beacon 17',
    'Beacon 18',
    'Beacon 19',
    'Beacon 20',
    'Beacon 21',
    'Beacon 22',
    'Beacon 23',
    'Beacon 24',
    'Beacon 25',
    'Beacon 26',
    'Beacon 27',
    'Beacon 28',
    'Beacon 29',
    'Beacon 30',
    'Beacon 31',
    'Beacon 32',
    'Beacon 33',
    'Beacon 36',
    'Beacon 37',
    'Beacon 38'
  ];

  String? destinoSelecionado; // destino escolhido pelo utilizador
  late stt.SpeechToText _speech; // reconhecimento de voz
  final FlutterTts _tts = FlutterTts(); // síntese de voz (text-to-speech)
  final AudioPlayer _audioPlayer = AudioPlayer(); // toca sons (ex.: bip de gravação)
  final PreferencesHelper _preferencesHelper = PreferencesHelper(); // carrega definições
  bool _speechAvailable = false; // indica se reconhecimento de voz está disponível
  bool _isListening = false; // indica se está a ouvir
  String selectedLanguageCode = 'pt-PT'; // idioma selecionado
  bool soundEnabled = true; // som ativado/desativado
  bool isSpeaking = false; // app está a falar?
  String _speechStatus = ''; // status atual do reconhecimento

  List<String> favoritos = []; // lista de favoritos
  List<String> destinosDisponiveis = []; // destinos encontrados nos beacons

  @override
  void initState() {
    super.initState();
    _initSpeech(); // inicializa reconhecimento de voz
    _loadSettings(); // carrega definições guardadas
    _loadFavorites(); // carrega favoritos guardados
  }

  Set<String> get destinosComBeacon {
    Set<String> destinos = {};
    for (var beaconId in beaconsAtivos) {
      final beacon = beacons[beaconId];
      if (beacon != null) {
        List<String> destinosFiltrados = List<String>.from(
            beacon['beacon_destinations'] ?? [])
            .where((d) =>
        d
            .trim()
            .isNotEmpty && d.toLowerCase() != 'none')
            .toList();
        destinos.addAll(destinosFiltrados);
      }
    }
    return destinos; // devolve conjunto único de destinos
  }

  Map<String, List<String>> get destinosPorPiso {
    Map<String, List<String>> pisos = {
      'Piso -1': [],
      'Piso 0': [],
      'Piso 1': [],
      'Piso 2': [],
      'Piso 3': [],
      'Piso 4': []
    };

    for (var beaconId in beaconsAtivos) {
      final beacon = beacons[beaconId];
      if (beacon != null) {
        String piso = 'Piso ${beacon['beacon_floor']}';
        List<String> destinos = List<String>.from(
            beacon['beacon_destinations'] ?? [])
            .where((d) =>
        d
            .trim()
            .isNotEmpty && d.toLowerCase() != 'none')
            .toList();
        if (pisos.containsKey(piso)) {
          pisos[piso]?.addAll(destinos);
        }
      }
    }

    pisos.updateAll((key, value) {
      final unique = value.toSet().toList()
        ..sort(); // remove duplicados e ordena
      return unique;
    });

    return pisos;
  }

  Map<String, String> get destinosMap {
    Map<String, String> map = {};
    for (var entry in voiceCommandsMap.entries) {
      if (destinosComBeacon.contains(entry.value)) {
        map[entry.key] = entry.value;
      }
    }
    return map; // mapeia comando de voz → destino válido
  }

  Future<void> _initSpeech() async {
    _speech = stt.SpeechToText();
    _speechAvailable = await _speech.initialize(
      onStatus: (status) {
        _speechStatus = status; // atualiza status
      },
      onError: (error) async {
        if (_isListening) {
          setState(() => _isListening = false);
          String mensagemErro = "";
          if (error.errorMsg == 'error_speech_timeout') {
            await _speech.stop();
            await _playStopRecordingSound();
            mensagemErro = _mensagem('timeout_alert'); // alerta timeout
          } else if (error.errorMsg == 'error_no_match') {
            await _speech.stop();
            await _playStopRecordingSound();
            mensagemErro =
                _mensagem('no_match_alert'); // alerta sem correspondência
          }
          if (mensagemErro.isNotEmpty && soundEnabled) {
            await _tts.speak(mensagemErro);
            await _tts.awaitSpeakCompletion(true);
          }
        }
      },
    );
  }

  Future<void> _loadSettings() async {
    final settings = await _preferencesHelper.loadSoundSettings();
    setState(() {
      selectedLanguageCode = settings['selectedLanguageCode'] ?? 'pt-PT';
      soundEnabled = settings['soundEnabled'];
    });
    await _tts.setLanguage(selectedLanguageCode); // configura TTS
    await _tts.setSpeechRate(0.5);
    await _loadMessages(); // carrega mensagens de texto
  }

  Future<void> _loadMessages() async {
    String langCode = selectedLanguageCode.toLowerCase().split(
        '-')[0]; // ex.: pt
    String fullCode = selectedLanguageCode.toLowerCase().replaceAll(
        '_', '-'); // ex.: pt-PT
    List<String> paths = [
      'assets/tts/navigation/nav_$fullCode.json',
      'assets/tts/navigation/nav_$langCode.json',
      'assets/tts/navigation/nav_en.json',
    ];
    String? jsonString;
    for (String path in paths) {
      try {
        jsonString = await rootBundle.loadString(path); // tenta carregar JSON
        break;
      } catch (_) {}
    }
    setState(() {
      mensagens =
      jsonString != null ? json.decode(jsonString) : {}; // guarda mensagens
      voiceCommandsMap = Map<String, String>.from(
          mensagens['voice_commands'] ?? {}); // comandos voz
      beacons = mensagens['beacons'] ?? {}; // info beacons
    });

    destinosDisponiveis = destinosComBeacon.toList()
      ..sort(); // ordena destinos
    destinosDisponiveis.removeWhere((destino) =>
        favoritos.contains(destino)); // tira favoritos
  }

  String normalizarTexto(String texto) {
    return removeDiacritics(
        texto.toLowerCase().trim()); // remove acentos, minúsculas
  }

  void _adicionarFavorito(String destino) {
    setState(() {
      if (!favoritos.contains(destino)) {
        favoritos.add(destino); // adiciona aos favoritos
        destinosDisponiveis.remove(destino); // tira da lista geral
        _saveFavorites(); // guarda no storage
      }
    });
  }

  void _removerFavorito(String destino) {
    setState(() {
      favoritos.remove(destino); // remove dos favoritos
      destinosDisponiveis.add(destino); // volta à lista geral
      _saveFavorites();
    });
  }

  Future<void> _saveFavorites() async {
    await _preferencesHelper.saveFavorites(favoritos); // grava no storage
  }

  Future<void> _loadFavorites() async {
    final favoritosGuardados = await _preferencesHelper.loadFavorites();
    setState(() {
      favoritos = favoritosGuardados;
      destinosDisponiveis.removeWhere((destino) =>
          favoritos.contains(destino)); // atualiza listas
    });
  }

  String _mensagem(String chave, {String? valor}) {
    String raw = mensagens['alerts']?[chave] ?? mensagens[chave] ??
        ''; // busca texto
    if (valor != null) {
      raw = raw.replaceAll('{destination}', valor); // substitui {destination}
    }
    return raw;
  }

  Future<void> _playStartRecordingSoundAndWait() async {
    await _audioPlayer.play(
        AssetSource('sounds/start_recording_sound.mp3')); // som início
    await Future.delayed(const Duration(milliseconds: 700)); // espera terminar
  }

  Future<void> _playStopRecordingSound() async {
    await _audioPlayer.play(
        AssetSource('sounds/stop_recording_sound.mp3')); // som parar
  }

  Future<void> _tratarComandoInvalido() async {
    await _speech.stop();
    await _playStopRecordingSound(); // som de parar
    setState(() => _isListening = false);
    if (soundEnabled) {
      await _tts.speak(
          _mensagem('voice_unavailable_alert')); // alerta voz não reconhecida
      await _tts.awaitSpeakCompletion(true);
    }
  }

  Future<void> _ouvirComando() async {
    if (!_speechAvailable) return;
    await _tts.stop();
    setState(() => _isListening = true);

    _speechStatus = '';
    await _speech.listen(
      localeId: selectedLanguageCode,
      // idioma de escuta
      listenMode: stt.ListenMode.dictation,
      listenFor: const Duration(minutes: 5),
      pauseFor: const Duration(minutes: 2),
      onResult: (result) async {
        if (!result.finalResult) return;
        final textoReconhecido = normalizarTexto(result.recognizedWords);
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
              if (soundEnabled) {
                await _tts.speak(_mensagem(
                    'voice_start_alert', valor: destino)); // fala destino
                await _tts.awaitSpeakCompletion(true);
              }
              await Future.delayed(const Duration(seconds: 1));
              if (!mounted) return;
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      BeaconScanPage(
                        destino: destino,
                        destinosMap: destinosMap,
                      ),
                ),
              );
              return;
            }
          }
        }
        await _tratarComandoInvalido(); // se não encontrou destino
      },
    );

    int tentativas = 0;
    while (_speechStatus != 'listening' && tentativas < 20) {
      await Future.delayed(const Duration(milliseconds: 50));
      tentativas++; // espera confirmação que está a ouvir
    }

    await _playStartRecordingSoundAndWait(); // toca som início
  }

  String get imagemPiso => 'assets/images/map/00_piso.png'; // imagem inicial

  Future<void> speakAndBlock(String texto) async {
    if (soundEnabled) {
      setState(() {
        isSpeaking = true;
      });
      await _tts.speak(texto);
      await _tts.awaitSpeakCompletion(true); // espera acabar de falar
      setState(() {
        isSpeaking = false;
      });
    }
  }

  void _mostrarAdicionarFavorito() {
    // Mostra popup para adicionar favorito
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          insetPadding: const EdgeInsets.symmetric(
              horizontal: 50, vertical: 80), // margem do dialog
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            // padding interno
            child: Column(
              mainAxisSize: MainAxisSize.min, // altura mínima necessária
              children: [
                Center(
                  child: Text(
                    'navigation_map_selector.add_favorite'.tr(),
                    // título traduzido
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 19),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 16),
                const Divider(),
                SizedBox(
                  height: 325, // altura fixa para scroll
                  child: SingleChildScrollView(
                    child: Column(
                      children: destinosPorPiso.entries.expand((entry) {
                        final destinosFiltrados = entry.value
                            .where((destino) =>
                        destinosDisponiveis.contains(destino) &&
                            destinosComBeacon.contains(destino))
                            .toList()
                          ..sort(); // destinos disponíveis e com beacon, ordenados

                        if (destinosFiltrados.isEmpty)
                          return <Widget>[]; // ignora piso vazio

                        return [
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Text(
                              entry.key, // nome do piso
                              style: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          ),
                          ...destinosFiltrados.map((destino) {
                            return ListTile(
                              title: Text(destino), // nome do destino
                              onTap: () {
                                _adicionarFavorito(
                                    destino); // adiciona favorito
                                Navigator.of(context).pop(); // fecha dialog
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
                Center(
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    // botão fechar
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

  void _mostrarPopupDestinos() {
    // Mostra popup para selecionar destino
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          insetPadding: const EdgeInsets.symmetric(
              horizontal: 50, vertical: 80),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: Text(
                    'navigation_map_selector.select_destination'.tr(),
                    // título traduzido
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 19),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 16),
                const Divider(),
                SizedBox(
                  height: 325,
                  child: SingleChildScrollView(
                    child: Column(
                      children: destinosPorPiso.entries.expand((entry) {
                        final destinosFiltrados = entry.value
                            .where((destino) =>
                            destinosComBeacon.contains(destino))
                            .toList()
                          ..sort(); // destinos com beacon, ordenados

                        if (destinosFiltrados.isEmpty)
                          return <Widget>[]; // ignora piso vazio

                        return [
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Text(
                              entry.key, // nome do piso
                              style: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          ),
                          ...destinosFiltrados.map((destino) {
                            return ListTile(
                              title: Text(destino),
                              onTap: () {
                                setState(() {
                                  destinoSelecionado =
                                      destino; // guarda seleção
                                });
                                Navigator.of(context).pop(); // fecha dialog
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
                Center(
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    // botão fechar
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
          Positioned.fill(
            child: InteractiveViewer( // Permite zoom e arrastar o mapa
              panEnabled: true,
              scaleEnabled: true,
              minScale: 1.0,
              maxScale: 3.5,
              constrained: false,
              boundaryMargin: const EdgeInsets.all(100),
              child: Image.asset(
                imagemPiso, // Mostra o mapa do piso atual
                fit: BoxFit.none,
                alignment: Alignment.topLeft,
              ),
            ),
          ),
          DraggableScrollableSheet( // Painel inferior arrastável
            minChildSize: 0.20,
            maxChildSize: 0.40,
            initialChildSize: 0.40,
            builder: (context, controller) {
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.95),
                  borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(12)),
                  boxShadow: const [
                    BoxShadow(color: Colors.black26, blurRadius: 6)
                  ],
                ),
                child: SingleChildScrollView(
                  controller: controller,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'navigation_map_selector.where_to_go'.tr(),
                        // Título "Para onde deseja ir"
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10),
                      GestureDetector( // Campo para selecionar destino
                        onTap: _mostrarPopupDestinos,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 16),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade600),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Center(
                            child: Text(
                              destinoSelecionado ??
                                  'navigation_map_selector.select_destination'
                                      .tr(),
                              style: TextStyle(fontSize: 16,
                                  color: destinoSelecionado == null ? Colors
                                      .grey.shade600 : Colors.black),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          ElevatedButton.icon( // Botão iniciar navegação
                            onPressed: destinoSelecionado == null || isSpeaking
                                ? null
                                : () async {
                              String mensagemIniciar = mensagens['alerts']?['start_navigation_alert'] ??
                                  'Mensagem de início não encontrada';
                              mensagemIniciar = mensagemIniciar.replaceAll(
                                  '{destination}', destinoSelecionado!);
                              await speakAndBlock(mensagemIniciar);
                              await Future.delayed(
                                  const Duration(milliseconds: 500));
                              if (!mounted) return;
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      BeaconScanPage(
                                        destino: destinoSelecionado!,
                                        destinosMap: destinosMap,
                                      ),
                                ),
                              );
                            },
                            icon: const Icon(Icons.navigation),
                            label: Text(
                                'navigation_map_selector.start_navigation'
                                    .tr()),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                            ),
                          ),
                          ElevatedButton.icon( // Botão comando por voz
                            onPressed: _ouvirComando,
                            icon: const Icon(Icons.mic),
                            label: Text(
                                'navigation_map_selector.by_voice'.tr()),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'navigation_map_selector.favorites'.tr(),
                        // Título "Favoritos"
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      SingleChildScrollView( // Lista horizontal de favoritos
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            ...favoritos.map((favorito) {
                              return Padding(
                                padding: const EdgeInsets.only(
                                    right: 8, top: 4, bottom: 1),
                                child: Row(
                                  children: [
                                    ElevatedButton( // Botão de favorito
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.orange,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 10, vertical: 0),
                                      ),
                                      onPressed: () async {
                                        setState(() {
                                          destinoSelecionado = favorito;
                                        });
                                        await speakAndBlock(_mensagem(
                                            'voice_selected_alert',
                                            valor: favorito));
                                      },
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(favorito),
                                          const SizedBox(width: 5),
                                          GestureDetector( // Ícone para remover favorito
                                            onTap: () {
                                              _removerFavorito(favorito);
                                            },
                                            child: const SizedBox(
                                              width: 22,
                                              height: 22,
                                              child: Center(
                                                child: Icon(
                                                    Icons.cancel, size: 18,
                                                    color: Colors.white),
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
                            Padding( // Botão para adicionar novo favorito
                              padding: const EdgeInsets.only(right: 10, top: 5),
                              child: ElevatedButton(
                                onPressed: _mostrarAdicionarFavorito,
                                child: const Icon(Icons.add),
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
          Positioned( // Botão voltar (seta no topo esquerdo)
            top: 40,
            left: 10,
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
          ),
        ],
      ),
    );
  }
}