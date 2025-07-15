import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:vibration/vibration.dart';
import 'tour_manager.dart';
import 'package:projetogpsnovo/helpers/preferences_helpers.dart';
import 'package:easy_localization/easy_localization.dart';

class TourScanPage extends StatefulWidget {
  final String destino;
  final Map<String, String> destinosMap;

  const TourScanPage({super.key, required this.destino, required this.destinosMap});

  @override
  State<TourScanPage> createState() => _TourScanPageState();
}

class _TourScanPageState extends State<TourScanPage> with TickerProviderStateMixin {
  final FlutterTts flutterTts = FlutterTts();
  final TourManager nav = TourManager();
  final PreferencesHelper _preferencesHelper = PreferencesHelper();

  bool isFinalizing = false;

  Map<String, dynamic> mensagens = {};

  String ultimaInstrucaoFalada = '';

  final Set<String> _processedBeacons = {};  // Guardar já processados
  final Map<String, DateTime> ultimaDeteccaoPorBeacon = {};  // Cooldown por beacon
  static const int rssiThreshold = -60;  // Limiar mínimo de sinal (dBm)


  String? localAtual;
  List<String> rota = [];
  int proximoPasso = 0;
  bool chegou = false;
  bool isNavigationCanceled = false;
  bool isProcessingBeacon = false;

  DateTime? ultimaDetecao;
  final Duration cooldown = const Duration(seconds: 4);
  String selectedLanguageCode = 'pt-PT';
  bool soundEnabled = true;
  bool vibrationEnabled = true;
  double voiceSpeed = 0.6;
  double voicePitch = 1.0;

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

  final Map<String, Map<String, dynamic>> beaconPositions = {
    'Beacon 1': {'offset': Offset(300, 560), 'floor': 'Piso 0'},
    'Beacon 3': {'offset': Offset(346, 295), 'floor': 'Piso 0'},
    'Beacon 15': {'offset': Offset(380, 95), 'floor': 'Piso 0'},
    // Adiciona mais beacons conforme a tua necessidade
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

  Future<void> finalizarNavegacao() async {
    print('[DEBUG] Scan parado - navegação concluída');
    FlutterBluePlus.stopScan();

    if (vibrationEnabled) {
      print('[DEBUG] Vibração longa - navegação concluída');
      Vibration.vibrate(duration: 800);
    }

    // Garantir que a mensagem de fim da visita só seja chamada uma vez
    if (!chegou) {
      print('[DEBUG] Chegou ao último ponto da rota, exibindo mensagem final');
      await falar(mensagens['alerts']?['tour_end_alert'] ?? "A Visita Guiada chegou ao fim. Obrigado por usar a nossa aplicação!");

      setState(() {
        chegou = true;
        status = 'tour_scan_page.tour_end'.tr(); // Mensagem final de conclusão
      });

      isFinalizing = true;  // Marca que a navegação foi finalizada
    }
  }

  Future<void> pedirPermissoes() async {
    await [
      Permission.bluetooth,
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.locationWhenInUse,
    ].request();

    await _loadSettings();
    await nav.carregarInstrucoes(selectedLanguageCode);
    iniciarScan();
  }

  Future<void> falarHistoricoEInstrucao(String local) async {
    FlutterBluePlus.stopScan();
    isProcessingBeacon = true;

    final beaconData = mensagens['beacons']?[local];

    if (beaconData != null &&
        beaconData['historical_point_name'] != null &&
        beaconData['historical_point_message'] != null) {
      String nomePonto = beaconData['historical_point_name'];
      String mensagemPonto = beaconData['historical_point_message'];

      print('[DEBUG] Ponto histórico detectado: $nomePonto');
      await falar(nomePonto);
      await flutterTts.awaitSpeakCompletion(true);

      print('[DEBUG] A falar mensagem histórica: $mensagemPonto');
      await falar(mensagemPonto);
      await flutterTts.awaitSpeakCompletion(true);
    }

    String? instrucao = '';
    if (proximoPasso < rota.length - 1) {
      String beaconAnterior = proximoPasso > 0 ? rota[proximoPasso - 1] : '';
      String localAtual = rota[proximoPasso];
      String destino = rota[proximoPasso + 1];
      instrucao = nav.buscarInstrucaoNoBeacon(beaconAnterior, localAtual, destino);
    }

    if (instrucao != null && instrucao.isNotEmpty) {
      print('[DEBUG] A falar instrução: $instrucao');
      await falar(instrucao);
      await flutterTts.awaitSpeakCompletion(true);
    }

    isProcessingBeacon = false;
    iniciarScan();
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
    await _carregarMensagens();
  }

  Future<void> _carregarMensagens() async {
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
        jsonString = await rootBundle.loadString(path);
        break;
      } catch (_) {}
    }
    setState(() {
      mensagens = jsonString != null ? json.decode(jsonString) : {};
      status = mensagens['alerts']?['searching_alert'] ?? '';
    });
  }

  void iniciarScan() {
    if (isFinalizing) {
      print('[DEBUG] Navegação já finalizada, não iniciando novo scan.');
      return;
    }

    FlutterBluePlus.startScan(
      continuousUpdates: true,
      androidScanMode: AndroidScanMode.lowLatency,
      androidUsesFineLocation: true,
    );
    print('[DEBUG] Iniciando scan para detectar beacons...');

    FlutterBluePlus.scanResults.listen((results) async {
      if (chegou || isNavigationCanceled || isFinalizing) return;

      for (final result in results) {
        if (result.rssi < rssiThreshold) continue; // Filtrar sinais fracos

        final beacon = nav.parseBeaconData(result);
        if (beacon == null ||
            beacon.uuid.toLowerCase() != '107e0a13-90f3-42bf-b980-181d93c3ccd2') {
          continue; // Ignorar se não for o UUID esperado
        }

        final local = nav.getLocalizacao(beacon);
        if (local == null) continue;

        final agora = DateTime.now();

        // Cooldown individual por beacon
        if (ultimaDeteccaoPorBeacon.containsKey(local)) {
          final ultima = ultimaDeteccaoPorBeacon[local]!;
          if (agora.difference(ultima) < cooldown) continue;
        }
        ultimaDeteccaoPorBeacon[local] = agora;

        // Ignorar se já processado nesta rota
        if (_processedBeacons.contains(local)) continue;
        _processedBeacons.add(local);

        if (rota.isEmpty) {
          rota = nav.rotaPreDefinida;
          proximoPasso = 0;
          print('[DEBUG] Rota carregada: $rota');
        }

        if (proximoPasso >= rota.length) return;

        final beaconEsperado = rota[proximoPasso];

        if (local == beaconEsperado) {
          print('[DEBUG] Ponto esperado alcançado: $local');
          localAtual = local;
          atualizarPosicaoVisual(local);

          if (vibrationEnabled) {
            print('[DEBUG] Vibração curta - passo correto');
            Vibration.vibrate(duration: 400);
          }

          await falarHistoricoEInstrucao(local);

          proximoPasso++;

          if (proximoPasso >= rota.length) {
            print('[DEBUG] Fim da rota atingido.');
            await finalizarNavegacao();
          }

          setState(() => mostrarSeta = true);
        } else {
          print('[DEBUG] Beacon inesperado: $local (esperado: $beaconEsperado)');
        }
      }
    });
  }


  void atualizarPosicaoVisual(String local) {
    final beaconInfo = beaconPositions[local];
    if (beaconInfo == null) return;

    final newPosition = beaconInfo['offset'] as Offset;
    final newFloor = beaconInfo['floor'] as String;

    if (newFloor != currentFloor) {
      setState(() {
        currentFloor = newFloor;
      });
    }

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

    print('[DEBUG] Atualizando a posição visual no mapa para: $newPosition');
  }


  Future<void> falar(String texto, {bool isFinalMessage = false}) async {
    if (soundEnabled && texto.isNotEmpty) {
      setState(() {
        ultimaInstrucaoFalada = texto;
      });
      await flutterTts.stop();
      await flutterTts.setLanguage(selectedLanguageCode);
      await flutterTts.setSpeechRate(voiceSpeed);
      await flutterTts.setPitch(voicePitch);
      await flutterTts.speak(texto);

      // Adicionando vibração com base no tipo de mensagem
      if (isFinalMessage) {
        // Vibração longa para mensagens finais
        if (vibrationEnabled) {
          print('[DEBUG] Vibração longa - mensagem final');
          Vibration.vibrate(duration: 800); // Long vibration
        }
      } else {
        // Vibração curta para instruções
        if (vibrationEnabled) {
          print('[DEBUG] Vibração curta - mensagem de instrução');
          Vibration.vibrate(duration: 400); // Short vibration
        }
      }
    }
  }

  void cancelarNavegacao() {
    setState(() {
      isNavigationCanceled = true;
      status = mensagens['alerts']?['navigation_cancelled_alert'] ?? '';
    });

    FlutterBluePlus.stopScan();
    flutterTts.stop();

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
    return localAtual ?? (mensagens['alerts']?['searching_alert'] ?? '');
  }

  String obterProximaParagem() {
    if (rota.isEmpty || proximoPasso >= rota.length) {
      return mensagens['alerts']?['end_of_route_alert'] ?? '';
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
            minChildSize: 0.45,
            maxChildSize: 0.45,
            initialChildSize: 0.45, // Dynamic size based on content
            builder: (context, controller) {
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.95),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                  boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 6)],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      '${'tour_scan_page.tour_title'.tr()}',
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 20),
                    Expanded(
                      child: SingleChildScrollView(
                        controller: controller,
                        child: Column(
                          children: [
                            if (!chegou) ...[
                              _buildMessageContainer(), // Message container with dynamic positioning
                            ] else ...[
                              _buildFinalMessageContainer(),
                            ],
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Align(
                      alignment: Alignment.bottomCenter,
                      child: ElevatedButton.icon(
                        onPressed: cancelarNavegacao,
                        icon: const Icon(Icons.cancel),
                        label: Text('tour_scan_page.cancel_tour'.tr()),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.redAccent,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }


// Widget para exibir o contêiner de mensagens
  Widget _buildMessageContainer() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: ultimaInstrucaoFalada.isEmpty ? Colors.yellow[100] : Colors.blue[100],
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(
            ultimaInstrucaoFalada.isEmpty ? Icons.warning : Icons.campaign,
            color: ultimaInstrucaoFalada.isEmpty ? Colors.orange : Colors.blue,
            size: 30,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Center(
              child: Text(
                ultimaInstrucaoFalada.isNotEmpty
                    ? ultimaInstrucaoFalada
                    : '${mensagens['alerts']?['searching_alert'] ?? 'A procurar...'}',
                textAlign: TextAlign.left,  // Alterado de center para left
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: ultimaInstrucaoFalada.isEmpty ? Colors.orange[900] : Colors.blue[900],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

// Widget para exibir o contêiner de mensagem final
  Widget _buildFinalMessageContainer() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.green[100],  // Cor de fundo verde
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: Colors.green, size: 30),
          const SizedBox(width: 10),
          Expanded(
            child: Center(
              child: Text(
                status,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}