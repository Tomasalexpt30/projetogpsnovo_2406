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
  // JSON carregado
  Map<String, dynamic> mensagens = {};
  Map<String, dynamic> beacons = {};
  Map<String, String> voiceCommandsMap = {};

  // Beacons ativos
  List<String> beaconsAtivos = ['Beacon 1', 'Beacon 3', 'Beacon 15'];

  // Estado
  String? destinoSelecionado;
  late stt.SpeechToText _speech;
  final FlutterTts _tts = FlutterTts();
  final AudioPlayer _audioPlayer = AudioPlayer();
  final PreferencesHelper _preferencesHelper = PreferencesHelper();
  bool _speechAvailable = false;
  bool _isListening = false;
  String selectedLanguageCode = 'pt-PT';
  bool soundEnabled = true;
  bool isSpeaking = false;
  String _speechStatus = '';

  // Favoritos
  List<String> favoritos = [];
  List<String> destinosDisponiveis = [];

  @override
  void initState() {
    super.initState();
    _initSpeech();
    _loadSettings();
    _loadFavorites();
  }

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

  Map<String, String> get destinosMap {
    Map<String, String> map = {};
    for (var entry in voiceCommandsMap.entries) {
      if (destinosComBeacon.contains(entry.value)) {
        map[entry.key] = entry.value;
      }
    }
    return map;
  }

  Future<void> _initSpeech() async {
    _speech = stt.SpeechToText();
    _speechAvailable = await _speech.initialize(
      onStatus: (status) {
        _speechStatus = status;
      },
      onError: (error) async {
        if (_isListening) {
          setState(() => _isListening = false);
          String mensagemErro = "";
          if (error.errorMsg == 'error_speech_timeout') {
            await _speech.stop();
            await _playStopRecordingSound();
            mensagemErro = _mensagem('timeout_alert');
          } else if (error.errorMsg == 'error_no_match') {
            await _speech.stop();
            await _playStopRecordingSound();
            mensagemErro = _mensagem('no_match_alert');
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
    await _tts.setLanguage(selectedLanguageCode);
    await _tts.setSpeechRate(0.5);
    await _loadMessages();
  }

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

    // Atualizar destinos disponíveis com base no JSON carregado
    destinosDisponiveis = destinosComBeacon.toList();
    destinosDisponiveis.removeWhere((destino) => favoritos.contains(destino));
  }

  String normalizarTexto(String texto) {
    return removeDiacritics(texto.toLowerCase().trim());
  }

  void _adicionarFavorito(String destino) {
    setState(() {
      if (!favoritos.contains(destino)) {
        favoritos.add(destino);
        destinosDisponiveis.remove(destino);
        _saveFavorites();
      }
    });
  }

  void _removerFavorito(String destino) {
    setState(() {
      favoritos.remove(destino);
      destinosDisponiveis.add(destino);
      _saveFavorites();
    });
  }

  Future<void> _saveFavorites() async {
    await _preferencesHelper.saveFavorites(favoritos);
  }

  Future<void> _loadFavorites() async {
    final favoritosGuardados = await _preferencesHelper.loadFavorites();
    setState(() {
      favoritos = favoritosGuardados;
      destinosDisponiveis.removeWhere((destino) => favoritos.contains(destino));
    });
  }

  String _mensagem(String chave, {String? valor}) {
    String raw = mensagens['alerts']?[chave] ?? mensagens[chave] ?? '';
    if (valor != null) {
      raw = raw.replaceAll('{destination}', valor);
    }
    return raw;
  }

  Future<void> _playStartRecordingSoundAndWait() async {
    await _audioPlayer.play(AssetSource('sounds/start_recording_sound.mp3'));
    await Future.delayed(const Duration(milliseconds: 700));
  }

  Future<void> _playStopRecordingSound() async {
    await _audioPlayer.play(AssetSource('sounds/stop_recording_sound.mp3'));
  }

  Future<void> _tratarComandoInvalido() async {
    await _speech.stop();
    await _playStopRecordingSound();

    setState(() => _isListening = false);

    if (soundEnabled) {
      await _tts.speak(_mensagem('voice_unavailable_alert'));
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
                await _tts.speak(_mensagem('voice_start_alert', valor: destino));
                await _tts.awaitSpeakCompletion(true);
              }
              await Future.delayed(const Duration(seconds: 1));
              if (!mounted) return;
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
        await _tratarComandoInvalido();
      },
    );

    int tentativas = 0;
    while (_speechStatus != 'listening' && tentativas < 20) {
      await Future.delayed(const Duration(milliseconds: 50));
      tentativas++;
    }

    await _playStartRecordingSoundAndWait();
  }

  String get imagemPiso => 'assets/images/map/00_piso.png';

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
                Center(
                  child: Text(
                    'navigation_map_selector.add_favorite'.tr(),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 19),
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
                        final destinosFiltrados = entry.value.where((destino) =>
                        destinosDisponiveis.contains(destino) && destinosComBeacon.contains(destino)).toList();

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
                                _adicionarFavorito(destino);
                                Navigator.of(context).pop();
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
                Center(
                  child: Text(
                    'navigation_map_selector.select_destination'.tr(),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 19),
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
                        final destinosFiltrados = entry.value.where((destino) => destinosComBeacon.contains(destino)).toList();

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
                                setState(() {
                                  destinoSelecionado = destino;
                                });
                                Navigator.of(context).pop();
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
            child: InteractiveViewer(
              panEnabled: true,
              scaleEnabled: true,
              minScale: 1.0,
              maxScale: 3.5,
              constrained: false,
              boundaryMargin: const EdgeInsets.all(100),
              child: Image.asset(
                imagemPiso,
                fit: BoxFit.none,
                alignment: Alignment.topLeft,
              ),
            ),
          ),
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
                      Text(
                        'navigation_map_selector.where_to_go'.tr(),
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10),
                      GestureDetector(
                        onTap: _mostrarPopupDestinos,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade600),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Center(
                            child: Text(
                              destinoSelecionado ?? 'navigation_map_selector.select_destination'.tr(),
                              style: TextStyle(fontSize: 16, color: destinoSelecionado == null ? Colors.grey.shade600 : Colors.black),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          ElevatedButton.icon(
                            onPressed: destinoSelecionado == null || isSpeaking
                                ? null
                                : () async {
                              String mensagemIniciar = mensagens['alerts']?['start_navigation_alert'] ?? 'Mensagem de início não encontrada';
                              mensagemIniciar = mensagemIniciar.replaceAll('{destination}', destinoSelecionado!);
                              await speakAndBlock(mensagemIniciar);

                              await Future.delayed(const Duration(milliseconds: 500));
                              if (!mounted) return;
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
                      const SizedBox(height: 10),
                      Text(
                        'navigation_map_selector.favorites'.tr(),
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            ...favoritos.map((favorito) {
                              return Padding(
                                padding: const EdgeInsets.only(right: 8, top: 4, bottom: 1),
                                child: Row(
                                  children: [
                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.orange,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                                      ),
                                      onPressed: () async {
                                        setState(() {
                                          destinoSelecionado = favorito;
                                        });
                                        await speakAndBlock(_mensagem('voice_selected_alert', valor: favorito));
                                      },
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(favorito),
                                          const SizedBox(width: 5),
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
                            Padding(
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
          Positioned(
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
