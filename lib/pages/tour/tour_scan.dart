import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:vibration/vibration.dart';
import 'package:easy_localization/easy_localization.dart';
import '../navigation/navigation_manager.dart';
import 'package:projetogpsnovo/helpers/preferences_helpers.dart';

class TourStop {
  final String id;
  final Offset position;
  final String piso;
  final String uuid;
  final int major;
  final int minor;
  final String macAddress;

  const TourStop({
    required this.id,
    required this.position,
    required this.piso,
    required this.uuid,
    required this.major,
    required this.minor,
    required this.macAddress,
  });

  bool matches(BeaconInfo beacon) {
    return beacon.uuid.toLowerCase() == uuid.toLowerCase() &&
        beacon.major == major &&
        beacon.minor == minor &&
        beacon.macAddress.toLowerCase() == macAddress.toLowerCase();
  }
}

class TourScanPage extends StatefulWidget {
  final List<TourStop> tourStops;

  const TourScanPage({super.key, required this.tourStops});

  @override
  State<TourScanPage> createState() => _TourScanPageState();
}

class _TourScanPageState extends State<TourScanPage> with TickerProviderStateMixin {
  final FlutterTts flutterTts = FlutterTts();
  final NavigationManager nav = NavigationManager();
  final PreferencesHelper _preferencesHelper = PreferencesHelper();

  late Map<String, dynamic> mensagens;
  int currentIndex = 0;
  bool chegou = false;
  bool tourStarted = false;
  bool isTourCanceled = false;
  bool entradaDetetada = false;

  String status = '';
  String selectedLanguageCode = 'pt-PT';
  bool soundEnabled = true;
  bool vibrationEnabled = true;
  double voiceSpeed = 0.6;
  double voicePitch = 1.0;

  DateTime? ultimaDetecao;
  final Duration cooldown = const Duration(seconds: 4);

  Offset currentPosition = const Offset(0, 0);
  Offset previousPosition = const Offset(0, 0);
  String currentFloor = 'Piso 0';
  double rotationAngle = 0.0;

  late AnimationController _cameraController;
  late Animation<Offset> _cameraAnimation;
  Offset cameraOffset = const Offset(0, 0);

  bool ignorarBeacons = false;
  bool estaAProucurar = true;
  bool mostrarCamoes = false;
  String textoAtual = '';
  Timer? avisoTimer;

  final Map<String, String> imagensPorPiso = {
    'Piso -1': 'assets/images/map/-01_piso.png',
    'Piso 0': 'assets/images/map/00_piso.png',
    'Piso 1': 'assets/images/map/01_piso.png',
    'Piso 2': 'assets/images/map/02_piso.png',
  };

  @override
  void initState() {
    super.initState();
    _cameraController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _initTour();
  }

  Future<void> _initTour() async {
    await pedirPermissoes();
    await _loadSettings();
    await _loadMensagensTTS();
    _setupInitialState();
    verificarLocalizacaoInicial();
  }

  Future<void> pedirPermissoes() async {
    await [
      Permission.bluetooth,
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.locationWhenInUse,
    ].request();
  }

  Future<void> _loadSettings() async {
    final settings = await _preferencesHelper.loadSoundSettings();
    setState(() {
      selectedLanguageCode = settings['selectedLanguageCode'] ?? 'pt-PT';
      soundEnabled = settings['soundEnabled'];
      vibrationEnabled = settings['vibrationEnabled'];
      voiceSpeed = settings['voiceSpeed'] ?? 0.6;
      voicePitch = settings['voicePitch'] ?? 1.0;
    });
  }

  Future<void> _loadMensagensTTS() async {
    String langCode = selectedLanguageCode.toLowerCase().split('-')[0];
    String fullCode = selectedLanguageCode.toLowerCase().replaceAll('_', '-');
    List<String> paths = [
      'assets/tts/tour/tour_$fullCode.json',
      'assets/tts/tour/tour_$langCode.json',
      'assets/tts/tour/tour_en.json',
    ];
    String? jsonStr;
    for (String path in paths) {
      try {
        jsonStr = await rootBundle.loadString(path);
        break;
      } catch (_) {}
    }
    setState(() {
      mensagens = jsonStr != null ? json.decode(jsonStr) : {};
    });
  }

  void _setupInitialState() {
    final firstStop = widget.tourStops[0];
    setState(() {
      currentFloor = firstStop.piso;
      currentPosition = firstStop.position;
      previousPosition = currentPosition;
      cameraOffset = currentPosition;
      textoAtual = _getTourPointText(firstStop.id);
      status = '';
    });
  }

  String _getTourPointText(String id) => mensagens['tour_points']?[id]?['text'] ?? '';
  String _getTourPointName(String id) => mensagens['tour_points']?[id]?['name'] ?? '';
  String _alertTTS(String key) => mensagens['alerts']?[key] ?? '';

  void verificarLocalizacaoInicial() {
    FlutterBluePlus.startScan();
    FlutterBluePlus.scanResults.listen((results) {
      if (tourStarted || isTourCanceled) return;

      for (final result in results) {
        final beacon = nav.parseBeaconData(result);
        if (beacon == null) continue;

        final agora = DateTime.now();
        if (ultimaDetecao != null && agora.difference(ultimaDetecao!) < cooldown) {
          continue;
        }
        ultimaDetecao = agora;

        for (final stop in widget.tourStops) {
          if (stop.matches(beacon)) {
            final newPosition = stop.position;
            final delta = newPosition - currentPosition;
            final angle = math.atan2(delta.dy, delta.dx) + math.pi / 2;

            _cameraAnimation = Tween<Offset>(begin: cameraOffset, end: newPosition).animate(
              CurvedAnimation(parent: _cameraController, curve: Curves.easeInOut),
            )..addListener(() {
              setState(() {
                cameraOffset = _cameraAnimation.value;
              });
            });

            _cameraController.forward(from: 0);

            setState(() {
              previousPosition = currentPosition;
              currentPosition = newPosition;
              rotationAngle = angle;
              currentFloor = stop.piso;
              estaAProucurar = false;
              textoAtual = _getTourPointText(stop.id);
            });

            if (stop == widget.tourStops[0]) {
              iniciarScan();
              tourStarted = true;
              entradaDetetada = true;
              ignorarBeacons = false;
              cancelarAvisoRepetido();
              mostrarCamoes = true;
              status = '';
              if (soundEnabled) {
                flutterTts.setLanguage(selectedLanguageCode);
                flutterTts.setSpeechRate(voiceSpeed);
                flutterTts.setPitch(voicePitch);
                flutterTts.speak(_alertTTS('voice_entrance'));
              }
            } else {
              if (!ignorarBeacons) {
                ignorarBeacons = true;
                entradaDetetada = false;
                status = '';
                if (soundEnabled) {
                  flutterTts.setLanguage(selectedLanguageCode);
                  flutterTts.setSpeechRate(voiceSpeed);
                  flutterTts.setPitch(voicePitch);
                  flutterTts.speak(_alertTTS('go_to_entrance'));
                }
                iniciarAvisoRepetido();
              }
            }
            break;
          }
        }
      }
    });
  }

  void iniciarAvisoRepetido() {
    avisoTimer?.cancel();
    avisoTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      if (!entradaDetetada && soundEnabled && !tourStarted) {
        flutterTts.setLanguage(selectedLanguageCode);
        flutterTts.setSpeechRate(voiceSpeed);
        flutterTts.setPitch(voicePitch);
        flutterTts.speak(_alertTTS('repeat_entrance'));
      }
    });
  }

  void cancelarAvisoRepetido() {
    avisoTimer?.cancel();
    avisoTimer = null;
  }

  void iniciarScan() {
    FlutterBluePlus.stopScan();
    FlutterBluePlus.startScan();
    FlutterBluePlus.scanResults.listen((results) {
      if (chegou || isTourCanceled) return;

      for (final result in results) {
        final beacon = nav.parseBeaconData(result);
        if (beacon == null) continue;

        final agora = DateTime.now();
        if (ultimaDetecao != null && agora.difference(ultimaDetecao!) < cooldown) {
          continue;
        }
        final stop = widget.tourStops[currentIndex];
        if (stop.matches(beacon)) {
          ultimaDetecao = agora;

          _anunciarParagem(stop);

          final newPosition = stop.position;
          final delta = newPosition - currentPosition;
          final angle = math.atan2(delta.dy, delta.dx) + math.pi / 2;

          _cameraAnimation = Tween<Offset>(begin: cameraOffset, end: newPosition).animate(
            CurvedAnimation(parent: _cameraController, curve: Curves.easeInOut),
          )..addListener(() {
            setState(() {
              cameraOffset = _cameraAnimation.value;
            });
          });

          _cameraController.forward(from: 0);

          setState(() {
            previousPosition = currentPosition;
            currentPosition = newPosition;
            rotationAngle = angle;
            currentFloor = stop.piso;
            textoAtual = _getTourPointText(stop.id);
          });

          if (currentIndex == widget.tourStops.length - 1) {
            finalizar();
          } else {
            setState(() {
              currentIndex++;
            });
          }
          break;
        }
      }
    });
  }

  void _anunciarParagem(TourStop stop) async {
    if (soundEnabled) {
      await flutterTts.setLanguage(selectedLanguageCode);
      await flutterTts.setSpeechRate(voiceSpeed);
      await flutterTts.setPitch(voicePitch);
      await flutterTts.speak(_getTourPointText(stop.id));
    }
    if (vibrationEnabled) {
      if (await Vibration.hasVibrator() ?? false) {
        Vibration.vibrate(duration: 600);
      }
    }
  }

  void finalizar() {
    FlutterBluePlus.stopScan();
    chegou = true;
    cancelarAvisoRepetido();
    flutterTts.setLanguage(selectedLanguageCode);
    flutterTts.setSpeechRate(voiceSpeed);
    flutterTts.setPitch(voicePitch);
    flutterTts.speak(_alertTTS('tour_completed'));
  }

  void cancelarTour() {
    setState(() {
      isTourCanceled = true;
    });
    FlutterBluePlus.stopScan();
    flutterTts.stop();
    cancelarAvisoRepetido();
    Vibration.vibrate(duration: 600);
    Navigator.pop(context);
  }

  @override
  void dispose() {
    flutterTts.stop();
    FlutterBluePlus.stopScan();
    cancelarAvisoRepetido();
    _cameraController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    String localAtual = '';
    String proximaParagem = '';

    if (tourStarted) {
      if (currentIndex == 0) {
        localAtual = _getTourPointName(widget.tourStops[0].id);
        proximaParagem = _getTourPointName(widget.tourStops[1].id);
      } else {
        localAtual = _getTourPointName(widget.tourStops[currentIndex - 1].id);
        if (currentIndex < widget.tourStops.length) {
          proximaParagem = _getTourPointName(widget.tourStops[currentIndex].id);
        } else {
          proximaParagem = tr('tour_scan_page.next');
        }
      }
    }

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Semantics(
              label: 'Mapa da visita guiada',
              child: InteractiveViewer(
                panEnabled: true,
                scaleEnabled: true,
                minScale: 1.0,
                maxScale: 3.5,
                constrained: false,
                boundaryMargin: const EdgeInsets.all(100),
                child: Stack(
                  children: [
                    Transform.translate(
                      offset: Offset(-cameraOffset.dx + 150, -cameraOffset.dy + 320),
                      child: Stack(
                        children: [
                          Image.asset(
                            imagensPorPiso[currentFloor]!,
                            fit: BoxFit.none,
                            alignment: Alignment.topLeft,
                          ),
                          if (!estaAProucurar)
                            AnimatedPositioned(
                              duration: const Duration(milliseconds: 1000),
                              curve: Curves.easeInOut,
                              left: currentPosition.dx,
                              top: currentPosition.dy,
                              child: Transform.rotate(
                                angle: rotationAngle,
                                child: Semantics(
                                  label: 'Seta de localização',
                                  hint: 'Indica a posição atual e direção no tour',
                                  child: const Icon(Icons.navigation, size: 40, color: Colors.red),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (mostrarCamoes)
            Positioned(
              top: 40,
              right: 20,
              child: Image.asset(
                'assets/images/home/foto_camoes.png',
                width: 80,
                height: 80,
              ),
            ),
          if (mostrarCamoes)
            Positioned(
              top: 130,
              right: 20,
              left: 20,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 6)],
                ),
                child: Text(
                  textoAtual,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
              ),
            ),
          DraggableScrollableSheet(
            minChildSize: 0.20,
            maxChildSize: 0.32,
            initialChildSize: 0.32,
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
                      const SizedBox(height: 20),
                      estaAProucurar
                          ? Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.yellow[100],
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.search, color: Colors.orange, size: 30),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Center(
                                child: Text(
                                  mensagens['alerts']?['searching'] ?? 'À procura de beacons...',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                          : ignorarBeacons
                          ? Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.yellow[100],
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.warning, color: Colors.orange, size: 30),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Center(
                                child: Text(
                                  mensagens['alerts']?['go_to_entrance'] ?? 'Dirija-se até à entrada para iniciar a visita guiada.',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                          : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.blue[50],
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Column(
                                children: [
                                  Text(
                                    'tour_scan_page.current_location'.tr(),
                                    style: const TextStyle(fontSize: 16, color: Colors.black54),
                                  ),
                                  const SizedBox(height: 5),
                                  Text(
                                    localAtual,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 15),
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.green[50],
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Column(
                                children: [
                                  Text(
                                    'tour_scan_page.next'.tr(),
                                    style: const TextStyle(fontSize: 16, color: Colors.black54),
                                  ),
                                  const SizedBox(height: 5),
                                  Text(
                                    proximaParagem,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton.icon(
                        onPressed: cancelarTour,
                        icon: const Icon(Icons.cancel),
                        label: Text('tour_scan_page.cancel_btn'.tr()),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.redAccent,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
