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


  //FALTA BEACON 2, 34 E 35
  List<String> beaconsOperacionais = ['Beacon 1', 'Beacon 3', 'Beacon 4', 'Beacon 5', 'Beacon 6', 'Beacon 7', 'Beacon 8', 'Beacon 9', 'Beacon 10', 'Beacon 11', 'Beacon 12', 'Beacon 13', 'Beacon 14', 'Beacon 15', 'Beacon 16', 'Beacon 17', 'Beacon 18', 'Beacon 19', 'Beacon 20', 'Beacon 21', 'Beacon 22', 'Beacon 23', 'Beacon 24', 'Beacon 25', 'Beacon 26', 'Beacon 27', 'Beacon 28', 'Beacon 29', 'Beacon 30', 'Beacon 31', 'Beacon 32', 'Beacon 33', 'Beacon 36', 'Beacon 37', 'Beacon 38'];

  bool isFinalizing = false;

  Map<String, dynamic> mensagens = {};

  late String? beaconDoDestino;

  String ultimaInstrucaoFalada = '';

  String? localAtual;
  String? beaconAnterior; // PATCH: guarda o beacon anterior
  List<String> rota = [];
  int proximoPasso = 0;
  bool chegou = false;
  bool isNavigationCanceled = false;

  final Set<String> _processedBeacons = {};
  // Cooldown individual por beacon
  final Map<String, DateTime> ultimaDeteccaoPorBeacon = {};
  // Tempo mínimo entre processamentos do mesmo beacon
  final Duration cooldown = const Duration(seconds: 1);
  // Limiar de RSSI (em dBm) para considerar o utilizador “próximo” do beacon
  static const int rssiThreshold = -60;

  Timer? _scanRestartTimer;
  StreamSubscription<List<ScanResult>>? _scanSub;  // ← nova linha

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
    'Piso 3': 'assets/images/map/03_piso.png',
    'Piso 4': 'assets/images/map/04_piso.png',
  };

  String status = '';
//Offset(x, y)
  // X Maior = Mais a direita
  // Y Maior = Mais abaixo
  final Map<String, Map<String, dynamic>> beaconPositions = {
    'Beacon 1': {'offset': Offset(300, 560), 'floor': 'Piso 0'},
    //'Beacon 2': {'offset': Offset(144, 599), 'floor': 'Piso -1'},
    'Beacon 3': {'offset': Offset(346, 295), 'floor': 'Piso 0'},
    'Beacon 4': {'offset': Offset(519, 378), 'floor': 'Piso 0'},
    'Beacon 5': {'offset': Offset(878, 463), 'floor': 'Piso 0'},
    'Beacon 6': {'offset': Offset(1216, 488), 'floor': 'Piso 0'},
    'Beacon 7': {'offset': Offset(1293, 549), 'floor': 'Piso -1'},
    'Beacon 8': {'offset': Offset(523, 208), 'floor': 'Piso 0'},
    'Beacon 9': {'offset': Offset(610, 291), 'floor': 'Piso 0'},
    'Beacon 10': {'offset': Offset(588, 203), 'floor': 'Piso -1'},
    'Beacon 11': {'offset': Offset(733, 178), 'floor': 'Piso -1'},
    'Beacon 12': {'offset': Offset(623, 388), 'floor': 'Piso -1'},
    'Beacon 13': {'offset': Offset(758, 311), 'floor': 'Piso -1'},
    'Beacon 14': {'offset': Offset(1003, 320), 'floor': 'Piso -1'},
    'Beacon 15': {'offset': Offset(345, 50), 'floor': 'Piso 0'},
    'Beacon 16': {'offset': Offset(138, 38), 'floor': 'Piso 0'},
    'Beacon 17': {'offset': Offset(53, 128), 'floor': 'Piso 0'},
    'Beacon 18': {'offset': Offset(71, 93), 'floor': 'Piso -1'},
    'Beacon 19': {'offset': Offset(129, 299), 'floor': 'Piso 1'},
    'Beacon 20': {'offset': Offset(153, 154), 'floor': 'Piso 1'},
    'Beacon 21': {'offset': Offset(36, 510), 'floor': 'Piso 2'},
    'Beacon 22': {'offset': Offset(528, 43), 'floor': 'Piso 0'},
    'Beacon 23': {'offset': Offset(603, 498), 'floor': 'Piso 1'},
    'Beacon 24': {'offset': Offset(687, 630), 'floor': 'Piso 1'},
    'Beacon 25': {'offset': Offset(609, 738), 'floor': 'Piso 1'},
    'Beacon 26': {'offset': Offset(612, 1084), 'floor': 'Piso 2'},
    'Beacon 27': {'offset': Offset(834, 597), 'floor': 'Piso 1'},
    'Beacon 28': {'offset': Offset(834, 725), 'floor': 'Piso 1'},
    'Beacon 29': {'offset': Offset(1056, 729), 'floor': 'Piso 1'},
    'Beacon 30': {'offset': Offset(1170, 721), 'floor': 'Piso 1'},
    'Beacon 31': {'offset': Offset(1166, 774), 'floor': 'Piso 2'},
    'Beacon 32': {'offset': Offset(1140, 904), 'floor': 'Piso 2'},
    'Beacon 33': {'offset': Offset(553, 374), 'floor': 'Piso 2'},
    //'Beacon 34': {'offset': Offset(630, 242), 'floor': 'Piso 3'},
    //'Beacon 35': {'offset': Offset(1463, 239), 'floor': 'Piso 4'},
    'Beacon 36': {'offset': Offset(406, 240), 'floor': 'Piso 2'}, //Mas tambêm aparece no piso 3
    'Beacon 37': {'offset': Offset(234, 236), 'floor': 'Piso 2'},
    'Beacon 38': {'offset': Offset(200, 200), 'floor': 'Piso 3'},
  };



  @override
  void initState() {
    super.initState();
    _cameraController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _startListening();   // ← subscrever ao scanResults UMA vez
    pedirPermissoes();
  }

  /// Subscreve UMA vez ao stream de resultados BLE
  void _startListening() {
    _scanSub = FlutterBluePlus.scanResults.listen(_processScanResults);
  }

  /// Lida com cada batch de scanResults
  Future<void> _processScanResults(List<ScanResult> results) async {
    if (chegou || isNavigationCanceled || isFinalizing) return;
    for (final result in results) {
      // … todo o teu for(result) { … lógica de RSSI, UUID, cooldown, navegação … }
    }
  }

  Future<void> finalizarNavegacao() async {
    print('[DEBUG] Scan parado - navegação concluída');
    FlutterBluePlus.stopScan();

    if (vibrationEnabled) {
      print('[DEBUG] Vibração longa - navegação concluída');
      Vibration.vibrate(duration: 800);
    }

    await falar(mensagens['alerts']?['navigation_end_alert'] ?? 'Navegação concluida.');

    setState(() {
      chegou = true;
      status = 'beacon_scan_page.navigation_end'.tr();
    });

    isFinalizing = true;
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
    beaconDoDestino = nav.getBeaconDoDestino(widget.destino);
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
      status = mensagens['alerts']?['searching_alert'] ?? '';
    });
  }

  void iniciarScan() {
    // 0) Cancela qualquer subscrição anterior
    _scanSub?.cancel();

    // 1) Inicia o scan contínuo
    FlutterBluePlus.startScan(
      continuousUpdates: true,
      androidScanMode: AndroidScanMode.lowLatency,
      androidUsesFineLocation: true,
    );

    // 2) Subscreve ao stream de resultados
    _scanSub = FlutterBluePlus.scanResults.listen((results) async {
      if (chegou || isNavigationCanceled || isFinalizing) return;

      for (final result in results) {
        // 2.1) Filtrar sinais fracos
        if (result.rssi < rssiThreshold) continue;

        final beacon = nav.parseBeaconData(result);
        if (beacon == null ||
            beacon.uuid.toLowerCase() != '107e0a13-90f3-42bf-b980-181d93c3ccd2') {
          continue;
        }

        final local = nav.getLocalizacao(beacon);
        if (local == null || !beaconsOperacionais.contains(local)) continue;

        // ── NOVO: detecta se o utilizador voltou a um beacon já ultrapassado ──
        final idx = rota.indexOf(local);
        if (rota.isNotEmpty && idx != -1 && idx < proximoPasso - 1) {
          // limpa histórico mas mantém o atual para não re‑disparar logo
          _processedBeacons
            ..clear()
            ..add(local);

          // recalcula a rota a partir deste ponto
          final novoCaminho = nav.dijkstra(local, widget.destino);
          if (novoCaminho != null && novoCaminho.length > 1) {
            rota = novoCaminho;
            proximoPasso = 1;
            localAtual = local;
            atualizarPosicaoVisual(local);

            final instr = nav.getInstrucoes(novoCaminho)[0];
            await _speakWithVibe(instr);
            setState(() => mostrarSeta = true);
          } else {
            await falar(mensagens['alerts']?['path_not_found_alert'] ?? 'Caminho não encontrado.');
            finalizar();
          }
          return;
        }



        // 2.2) “Process‑once”: ignora se já processado nesta rota
        if (_processedBeacons.contains(local)) continue;
        _processedBeacons.add(local);

        // —— Caso 1: rota ainda não iniciada ——
        if (rota.isEmpty) {
          // Se já está no destino
          if (local == nav.getBeaconDoDestino(widget.destino)) {
            await _handleArrivalDirect(local);
            return;
          }
          // Senão, planeia a rota a partir daqui
          final caminho = nav.dijkstra(local, widget.destino);
          if (caminho != null && caminho.length > 1) {
            rota = caminho;
            proximoPasso = 1;
            localAtual = local;
            atualizarPosicaoVisual(local);
            final instr = nav.getInstrucoes(caminho)[0];
            await _speakWithVibe(instr);
            setState(() => mostrarSeta = true);
          } else {
            await falar(mensagens['alerts']?['path_not_found_alert'] ?? 'Caminho não encontrado.');
            finalizar();
          }
          return;
        }

        // —— Caso 2: passo esperado na rota ——
        if (proximoPasso < rota.length && local == rota[proximoPasso]) {
          beaconAnterior = localAtual;
          localAtual = local;
          atualizarPosicaoVisual(local);

          final destinosHere = List<String>.from(
            nav.jsonBeacons[localAtual]?['beacon_destinations'] ?? [],
          );
          // Último passo?
          if (destinosHere.contains(widget.destino)) {
            await _handleFinalStep(local);
            return;
          }
          // Passo intermédio
          final instr = nav.getInstrucoes(rota)[proximoPasso];
          await _speakWithVibe(instr);
          proximoPasso++;
          return;
        }

        // —— Caso 3: beacon inesperado — recalcula a rota ——
        _processedBeacons
          ..clear()
          ..add(local);

        final novoCaminho = nav.dijkstra(local, widget.destino);
        if (novoCaminho != null && novoCaminho.length > 1) {
          rota = novoCaminho;
          proximoPasso = 1;
          localAtual = local;
          atualizarPosicaoVisual(local);
          final instr = nav.getInstrucoes(novoCaminho)[0];
          await _speakWithVibe(instr);
          setState(() => mostrarSeta = true);
        } else {
          await falar(mensagens['alerts']?['path_not_found_alert'] ?? 'Caminho não encontrado.');
          finalizar();
        }
        return;
      }
    });
  }

// Auxiliares a incluir na classe:

  Future<void> _speakWithVibe(String texto) async {
    if (vibrationEnabled) Vibration.vibrate(duration: 400);
    await falar(texto);
  }

  Future<void> _handleArrivalDirect(String local) async {
    isFinalizing = true;
    if (vibrationEnabled) Vibration.vibrate(duration: 400);
    final instr = nav.buscarInstrucaoNoBeacon(local, widget.destino) ?? '';
    atualizarPosicaoVisual(local);
    setState(() => mostrarSeta = true);
    if (instr.isNotEmpty) await falar(instr);

    FlutterBluePlus.stopScan();
    if (vibrationEnabled) Vibration.vibrate(duration: 600);
    setState(() {
      chegou = true;
      status = 'beacon_scan_page.navigation_end'.tr();
    });
    await falar(mensagens['alerts']?['navigation_end_alert'] ?? 'Navegação concluída.');
  }

  Future<void> _handleFinalStep(String local) async {
    isFinalizing = true;
    if (vibrationEnabled) Vibration.vibrate(duration: 400);
    final instrFinal = nav.buscarInstrucaoNoBeacon(local, widget.destino, beaconAnterior) ?? '';
    if (instrFinal.isNotEmpty) await falar(instrFinal);

    FlutterBluePlus.stopScan();
    if (vibrationEnabled) Vibration.vibrate(duration: 600);
    setState(() {
      chegou = true;
      status = 'beacon_scan_page.navigation_end'.tr();
    });
    await falar(mensagens['alerts']?['navigation_end_alert'] ?? 'Navegação concluída.');
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
      setState(() {
        ultimaInstrucaoFalada = texto;
      });
      await flutterTts.stop();
      await flutterTts.setLanguage(selectedLanguageCode);
      await flutterTts.setSpeechRate(voiceSpeed);
      await flutterTts.setPitch(voicePitch);
      await flutterTts.speak(texto);
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

  void mostrarDescricao() async {
    if (localAtual != null && mensagens['beacons']?[localAtual] != null) {
      final descricao = mensagens['beacons']?[localAtual]?['beacon_description'];

      if (descricao != null && descricao.isNotEmpty) {
        print('[DEBUG] A falar descrição do beacon atual: $descricao');
        await falar(descricao);
      } else {
        print('[DEBUG] Descrição indisponível para o beacon atual: $localAtual');
        await falar('Descrição indisponível para o beacon atual.');
      }
    } else {
      print('[DEBUG] Ainda não foi detetado nenhum beacon.');
      await falar('Ainda não foi detetado nenhum beacon.');
    }
  }

  @override
  void dispose() {
    _scanRestartTimer?.cancel();
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
                      if (!chegou) ...[
                        Container(
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
                                    textAlign: TextAlign.center,
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
                        ),
                      ]
                      else ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.green[100],
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
                        ),
                      ],
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: mostrarDescricao,
                              icon: const Icon(Icons.info),
                              label: Text('beacon_scan_page.description'.tr()),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blueAccent,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: cancelarNavegacao,
                              icon: const Icon(Icons.cancel),
                              label: Text('beacon_scan_page.cancel_navigation'.tr()),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.redAccent,
                                foregroundColor: Colors.white,
                              ),
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
        ],
      ),
    );
  }
}