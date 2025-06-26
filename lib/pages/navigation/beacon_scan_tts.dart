import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:vibration/vibration.dart';
import 'navigation_manager.dart';
import 'package:projetogpsnovo/helpers/preferences_helpers.dart';
import 'package:easy_localization/easy_localization.dart';

class BeaconScanPage extends StatefulWidget {
  final String destino;
  final Map<String, String> destinosMap;

  const BeaconScanPage({super.key, required this.destino, required this.destinosMap});

  @override
  State<BeaconScanPage> createState() => _BeaconScanPageState();
}

class _BeaconScanPageState extends State<BeaconScanPage> with TickerProviderStateMixin {
  final FlutterTts flutterTts = FlutterTts();
  final NavigationManager nav = NavigationManager();
  final PreferencesHelper _preferencesHelper = PreferencesHelper();

  Map<String, dynamic> mensagens = {};

  String? localAtual;
  List<String> rota = [];
  int proximoPasso = 0;
  bool chegou = false;
  bool isNavigationCanceled = false;

  DateTime? ultimaDetecao;
  final Duration cooldown = const Duration(seconds: 4);
  String selectedLanguageCode = 'pt-PT';
  bool soundEnabled = true;
  bool vibrationEnabled = true;

  Offset currentPosition = const Offset(300, 500);
  Offset previousPosition = const Offset(300, 500);
  Offset cameraOffset = const Offset(300, 500);
  double rotationAngle = 0.0;

  bool mostrarSeta = false;

  late AnimationController _cameraController;
  late Animation<Offset> _cameraAnimation;

  String currentFloor = 'Piso 0';

  final Map<String, String> imagensPorPiso = {
    'Piso -1': 'assets/images/map/-01_piso.png',
    'Piso 0': 'assets/images/map/00_piso.png',
    'Piso 1': 'assets/images/map/01_piso.png',
    'Piso 2': 'assets/images/map/02_piso.png',
  };

  String status = '';

  final Map<String, Offset> beaconPositions = {
    'Entrada': Offset(300, 500),
    'Pátio': Offset(300, 250),
    'Corredor 1': Offset(380, 95),
  };

  @override
  void initState() {
    super.initState();
    _cameraController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    pedirPermissoes();
  }

  Future<void> pedirPermissoes() async {
    await [
      Permission.bluetooth,
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.locationWhenInUse,
    ].request();

    await _loadSettings();
    await _carregarMensagens();
    await nav.carregarInstrucoes(selectedLanguageCode);
    iniciarScan();
  }

  Future<void> _loadSettings() async {
    final settings = await _preferencesHelper.loadSoundSettings();
    setState(() {
      selectedLanguageCode = settings['selectedLanguageCode'] ?? 'pt-PT';
      soundEnabled = settings['soundEnabled'];
      vibrationEnabled = settings['vibrationEnabled'];
    });
  }

  Future<void> _carregarMensagens() async {
    final lang = context.locale.languageCode.startsWith('en') ? 'en' : 'pt';
    final path = 'assets/tts/navigation/nav_$lang.json';
    final String jsonString = await rootBundle.loadString(path);
    setState(() {
      mensagens = json.decode(jsonString);
      status = mensagens['alerts']?['searching'] ?? '';
    });
  }

  void iniciarScan() {
    FlutterBluePlus.startScan();

    FlutterBluePlus.scanResults.listen((results) {
      if (chegou || isNavigationCanceled) return;

      for (final result in results) {
        final beacon = nav.parseBeaconData(result);
        if (beacon == null) continue;

        final local = nav.getLocalizacao(beacon);
        if (local == null) continue;

        final agora = DateTime.now();
        if (ultimaDetecao != null &&
            agora.difference(ultimaDetecao!) < cooldown &&
            local == localAtual) {
          continue;
        }

        ultimaDetecao = agora;

        if (rota.isEmpty) {
          if (local == widget.destino) {
            falar(_mensagemAlerta('already_there', local));
            finalizar();
            return;
          }

          final caminho = nav.dijkstra(local, widget.destino);
          if (caminho != null && caminho.length > 1) {
            rota = caminho;
            proximoPasso = 1;
            localAtual = local;

            atualizarPosicaoVisual(local);

            final instrucao = nav.getInstrucoes(caminho)[0];
            falar(instrucao);
            setState(() {
              status = _mensagemAlerta('at_location', local);
              mostrarSeta = true;
            });
          } else {
            falar(_mensagemAlerta('path_not_found', local));
            finalizar();
          }
          return;
        }

        if (proximoPasso < rota.length && local == rota[proximoPasso]) {
          localAtual = local;
          atualizarPosicaoVisual(local);

          setState(() {
            status = _mensagemAlerta('at_location', local);
          });

          if (proximoPasso == rota.length - 1) {
            falar(_mensagemAlerta('arrived', local));
            finalizar();
          } else {
            final instrucao = nav.getInstrucoes(rota)[proximoPasso];
            falar(instrucao);
            proximoPasso++;
          }
          return;
        }
      }
    });
  }

  String _mensagemAlerta(String chave, String local) {
    final raw = mensagens['alerts']?[chave] ?? '';
    return raw.replaceAll('{location}', local);
  }

  void atualizarPosicaoVisual(String local) {
    final newPosition = beaconPositions[local] ?? const Offset(300, 500);
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
      mostrarSeta = true;
    });
  }

  void finalizar() {
    FlutterBluePlus.stopScan();
    chegou = true;

    if (vibrationEnabled) {
      Vibration.hasVibrator().then((hasVibrator) {
        if (hasVibrator ?? false) Vibration.vibrate(duration: 600);
      });
    }
  }

  Future<void> falar(String texto) async {
    if (soundEnabled && texto.isNotEmpty) {
      await flutterTts.setLanguage(selectedLanguageCode);
      await flutterTts.setSpeechRate(0.5);
      await flutterTts.speak(texto);
    }
  }

  void cancelarNavegacao() {
    setState(() {
      isNavigationCanceled = true;
      status = mensagens['alerts']?['navigation_cancelled'] ?? '';
    });

    FlutterBluePlus.stopScan();
    flutterTts.stop();
    Vibration.vibrate(duration: 600);

    Navigator.pop(context);
  }

  @override
  void dispose() {
    flutterTts.stop();
    FlutterBluePlus.stopScan();
    _cameraController.dispose();
    super.dispose();
  }

  String obterLocalAtual() {
    return localAtual ?? (mensagens['alerts']?['searching'] ?? '');
  }

  String obterProximaParagem() {
    if (rota.isEmpty || proximoPasso >= rota.length) {
      return mensagens['alerts']?['end_of_route'] ?? '';
    }
    return rota[proximoPasso];
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
                        if (mostrarSeta)
                          AnimatedPositioned(
                            duration: const Duration(milliseconds: 1000),
                            curve: Curves.easeInOut,
                            left: currentPosition.dx,
                            top: currentPosition.dy,
                            child: Transform.rotate(
                              angle: rotationAngle,
                              child: const Icon(Icons.navigation, size: 40, color: Colors.red),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
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
                      Text(
                        '${'beacon_scan_page.destination'.tr()}: ${widget.destino}',
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 20),
                      Row(
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
                                    'beacon_scan_page.current_location'.tr(),
                                    style: const TextStyle(fontSize: 16, color: Colors.black54),
                                  ),
                                  const SizedBox(height: 5),
                                  Text(
                                    obterLocalAtual(),
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
                                    'beacon_scan_page.next'.tr(),
                                    style: const TextStyle(fontSize: 16, color: Colors.black54),
                                  ),
                                  const SizedBox(height: 5),
                                  Text(
                                    obterProximaParagem(),
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
                        onPressed: cancelarNavegacao,
                        icon: const Icon(Icons.cancel),
                        label: Text('beacon_scan_page.cancel_navigation'.tr()),
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
