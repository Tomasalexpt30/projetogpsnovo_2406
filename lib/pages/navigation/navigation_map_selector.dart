import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'beacon_scan_tts.dart';
import 'package:projetogpsnovo/helpers/preferences_helpers.dart';
import 'package:easy_localization/easy_localization.dart';

class NavigationMapSelectorPage extends StatefulWidget {
  const NavigationMapSelectorPage({super.key});

  @override
  State<NavigationMapSelectorPage> createState() =>
      _NavigationMapSelectorPageState();
}

class _NavigationMapSelectorPageState extends State<NavigationMapSelectorPage> {
  final Map<String, String> destinosMap = {
    'entrada': 'Entrada',
    'pátio': 'Pátio',
    'corredor 1': 'Corredor 1',
  };

  final Set<String> destinosComBeacon = {'Entrada', 'Pátio', 'Corredor 1'};

  String? destinoSelecionado;
  late stt.SpeechToText _speech;
  final FlutterTts _tts = FlutterTts();
  final PreferencesHelper _preferencesHelper = PreferencesHelper();
  bool _speechAvailable = false;
  bool _isListening = false;
  String selectedLanguageCode = 'pt-PT';
  Map<String, dynamic> mensagens = {};
  bool soundEnabled = true;

  List<String> favoritos = [];
  List<String> destinosDisponiveis = [
    'Entrada',
    'Corredor 1',
    'Pátio',
  ];

  @override
  void initState() {
    super.initState();
    _initSpeech();
    _loadSettings();
    _loadFavorites();
  }

  Future<void> _initSpeech() async {
    _speech = stt.SpeechToText();
    _speechAvailable = await _speech.initialize(
      onStatus: (status) => print('[STATUS] $status'),
      onError: (error) => print('[ERRO] $error'),
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
    final lang = selectedLanguageCode.startsWith('en') ? 'en' : 'pt';
    final path = 'assets/tts/navigation/nav_$lang.json';
    final jsonString = await rootBundle.loadString(path);
    setState(() {
      mensagens = json.decode(jsonString);
    });
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

  void _mostrarAdicionarFavorito() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('navigation_map_selector.add_favorite'.tr()),
          content: SingleChildScrollView(
            child: ListBody(
              children: destinosDisponiveis.map((destino) {
                return ListTile(
                  title: Text(destino),
                  onTap: () {
                    _adicionarFavorito(destino);
                    Navigator.of(context).pop();
                  },
                );
              }).toList(),
            ),
          ),
        );
      },
    );
  }

  String _mensagem(String chave, {String? valor}) {
    String raw = mensagens['alerts']?[chave] ?? mensagens[chave] ?? '';
    if (valor != null) {
      raw = raw.replaceAll('{destination}', valor);
    }
    return raw;
  }

  Future<void> _ouvirComando() async {
    if (!_speechAvailable) return;

    setState(() => _isListening = true);

    await _speech.listen(
      localeId: selectedLanguageCode,
      listenMode: stt.ListenMode.dictation,
      onResult: (result) async {
        final textoReconhecido = result.recognizedWords.toLowerCase().trim();
        for (final entrada in destinosMap.entries) {
          if (textoReconhecido.contains(entrada.key)) {
            final destino = entrada.value;

            if (destinosComBeacon.contains(destino)) {
              setState(() {
                destinoSelecionado = destino;
                _isListening = false;
              });
              await _speech.stop();
              if (soundEnabled) {
                await _tts.speak(_mensagem('voice_start'));
              }
              await Future.delayed(const Duration(seconds: 2));
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

        await _speech.stop();
        setState(() => _isListening = false);
        if (soundEnabled) {
          await _tts.speak(_mensagem('voice_unavailable'));
        }
      },
    );
  }

  String get imagemPiso => 'assets/images/map/00_piso.png';

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
                      DropdownButtonFormField<String>(
                        decoration: const InputDecoration(border: OutlineInputBorder()),
                        value: destinoSelecionado,
                        hint: Text('navigation_map_selector.select_destination'.tr()),
                        items: destinosMap.entries
                            .map((entry) => DropdownMenuItem(
                          value: entry.value,
                          child: Text(entry.value),
                        ))
                            .toList(),
                        onChanged: (value) {
                          setState(() {
                            destinoSelecionado = value;
                          });
                        },
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          ElevatedButton.icon(
                            onPressed: destinoSelecionado == null
                                ? null
                                : () async {
                              if (soundEnabled) {
                                await _tts.speak(_mensagem('start_navigation'));
                              }
                              await Future.delayed(const Duration(seconds: 2));
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
                                      onPressed: () {
                                        setState(() {
                                          destinoSelecionado = favorito;
                                        });
                                        if (soundEnabled) {
                                          _tts.speak(_mensagem('voice_selected', valor: favorito));
                                        }
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
