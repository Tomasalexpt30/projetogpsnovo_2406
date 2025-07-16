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
  final String destino;  // Destino selecionado pelo utilizador
  final Map<String, String> destinosMap;  // Mapa de destinos disponíveis

  const BeaconScanPage({super.key, required this.destino, required this.destinosMap});

  @override
  State<BeaconScanPage> createState() => _BeaconScanPageState();
}

class _BeaconScanPageState extends State<BeaconScanPage> with TickerProviderStateMixin {
  final FlutterTts flutterTts = FlutterTts(); // Texto-para-fala
  final NavigationManager nav = NavigationManager(); // Gestor de navegação
  final PreferencesHelper _preferencesHelper = PreferencesHelper(); // Preferências guardadas

  List<String> beaconsOperacionais = [
    // Lista de beacons ativos no sistema
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

  bool isFinalizing = false; // Marca se está a finalizar a navegação

  Map<String, dynamic> mensagens = {}; // Mensagens carregadas do JSON

  late String? beaconDoDestino; // Beacon correspondente ao destino final

  String ultimaInstrucaoFalada = ''; // Guarda última instrução dita

  String? localAtual; // Local atual detetado
  String? beaconAnterior; // Último beacon detetado
  List<String> rota = []; // Lista de pontos na rota
  int proximoPasso = 0; // Índice do próximo ponto na rota
  bool chegou = false; // Indicador de chegada ao destino
  bool isNavigationCanceled = false; // Se foi cancelada a navegação

  final Set<String> _processedBeacons = {}; // Beacons já processados

  final Map<String, DateTime> ultimaDeteccaoPorBeacon = {
  }; // Última deteção de cada beacon

  final Duration cooldown = const Duration(
      seconds: 1); // Tempo mínimo entre deteções

  static const int rssiThreshold = -60; // RSSI mínimo para considerar próximo

  Timer? _scanRestartTimer; // Temporizador para reiniciar scan
  StreamSubscription<
      List<ScanResult>>? _scanSub; // Subscrição de resultados BLE

  String selectedLanguageCode = 'pt-PT'; // Código do idioma
  bool soundEnabled = true; // Som ativado
  bool vibrationEnabled = true; // Vibração ativada
  double voiceSpeed = 0.6; // Velocidade voz
  double voicePitch = 1.0; // Tom de voz

  Offset currentPosition = const Offset(300, 500); // Posição visual no mapa
  Offset previousPosition = const Offset(300, 500); // Posição anterior no mapa
  Offset cameraOffset = const Offset(300, 500); // Offset da câmara
  double rotationAngle = 0.0; // Ângulo de rotação da seta

  bool mostrarSeta = false; // Mostrar seta no mapa

  late AnimationController _cameraController; // Controlador de animação de câmara
  late Animation<Offset> _cameraAnimation; // Animação de movimento no mapa

  String currentFloor = 'Piso 0'; // Piso atual

  final Map<String, String> imagensPorPiso = { // Mapas por piso
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
    'Beacon 36': {'offset': Offset(406, 240), 'floor': 'Piso 2'},
    //Mas tambêm aparece no piso 3
    'Beacon 37': {'offset': Offset(234, 236), 'floor': 'Piso 2'},
    'Beacon 38': {'offset': Offset(200, 200), 'floor': 'Piso 3'},
  };


  @override
  void initState() {
    super.initState();
    _cameraController =
        AnimationController( // Controlador para animações no mapa
          vsync: this,
          duration: const Duration(milliseconds: 1000),
        );
    _startListening(); // Subscreve ao stream de scanResults
    pedirPermissoes(); // Pede permissões e inicia configuração
  }

  /// Subscreve UMA vez ao stream de resultados BLE
  void _startListening() {
    _scanSub = FlutterBluePlus.scanResults.listen(_processScanResults);
  }

  /// Processa cada batch de resultados BLE (ainda vazio neste trecho)
  Future<void> _processScanResults(List<ScanResult> results) async {
    if (chegou || isNavigationCanceled || isFinalizing)
      return; // Ignora se já terminou
    for (final result in results) {
      // (processamento ainda a ser implementado)
    }
  }

  Future<void> finalizarNavegacao() async {
    print('[DEBUG] Scan parado - navegação concluída');
    FlutterBluePlus.stopScan(); // Para o scan BLE

    if (vibrationEnabled) {
      print('[DEBUG] Vibração longa - navegação concluída');
      Vibration.vibrate(duration: 800); // Vibração final
    }

    await falar(
        mensagens['alerts']?['navigation_end_alert'] ?? 'Navegação concluida.');

    setState(() {
      chegou = true; // Marca como concluído
      status = 'beacon_scan_page.navigation_end'.tr(); // Atualiza status
    });

    isFinalizing = true; // Evita ações extra
  }

  Future<void> pedirPermissoes() async {
    await [ // Pede permissões BLE e localização
      Permission.bluetooth,
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.locationWhenInUse,
    ].request();

    await _loadSettings(); // Carrega definições
    await nav.carregarInstrucoes(selectedLanguageCode); // Carrega instruções
    beaconDoDestino =
        nav.getBeaconDoDestino(widget.destino); // Define beacon de destino
    iniciarScan(); // Começa scan
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
    await _carregarMensagens(); // Carrega mensagens TTS
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
        break; // Entra no primeiro ficheiro encontrado
      } catch (_) {}
    }
    setState(() {
      mensagens = jsonString != null ? json.decode(jsonString) : {};
      status =
          mensagens['alerts']?['searching_alert'] ?? ''; // Mensagem inicial
    });
  }

  void iniciarScan() {
    _scanSub?.cancel(); // Cancela subscrição anterior se existir

    FlutterBluePlus.startScan( // Inicia BLE scan
      continuousUpdates: true,
      androidScanMode: AndroidScanMode.lowLatency,
      androidUsesFineLocation: true,
    );

    _scanSub = FlutterBluePlus.scanResults.listen((results) async {
      if (chegou || isNavigationCanceled || isFinalizing)
        return; // Ignora se finalizado

      for (final result in results) {
        if (result.rssi < rssiThreshold) continue; // Filtra sinais fracos

        final beacon = nav.parseBeaconData(result);
        if (beacon == null ||
            beacon.uuid.toLowerCase() !=
                '107e0a13-90f3-42bf-b980-181d93c3ccd2') {
          continue; // Só aceita UUID esperado
        }


        final local = nav.getLocalizacao(beacon);
        if (local == null || !beaconsOperacionais.contains(local))
          continue; // Ignora se não for beacon conhecido

// ── NOVO: detecta se o utilizador voltou a um beacon já ultrapassado ──
        final idx = rota.indexOf(local);
        if (rota.isNotEmpty && idx != -1 &&
            idx < proximoPasso - 1) { // Se voltou atrás no caminho
          _processedBeacons
            ..clear()
            ..add(local); // Limpa histórico, mantém o atual

          final novoCaminho = nav.dijkstra(
              local, widget.destino); // Recalcula rota a partir daqui
          if (novoCaminho != null && novoCaminho.length > 1) {
            rota = novoCaminho;
            proximoPasso = 1;
            localAtual = local;
            atualizarPosicaoVisual(local);

            final instr = nav.getInstrucoes(
                novoCaminho)[0]; // Primeira instrução recalculada
            await _speakWithVibe(instr);
            setState(() => mostrarSeta = true);
          } else {
            await falar(mensagens['alerts']?['path_not_found_alert'] ??
                'Caminho não encontrado.');
            finalizar();
          }
          return;
        }

// 2.2) “Process‑once”: ignora se já processado nesta rota
        if (_processedBeacons.contains(local)) continue;
        _processedBeacons.add(local);

// —— Caso 1: rota ainda não iniciada ——
        if (rota.isEmpty) {
          if (local ==
              nav.getBeaconDoDestino(widget.destino)) { // Já está no destino
            await _handleArrivalDirect(local);
            return;
          }

          final caminho = nav.dijkstra(
              local, widget.destino); // Calcula nova rota
          if (caminho != null && caminho.length > 1) {
            beaconAnterior = localAtual;
            rota = caminho;
            proximoPasso = 1;
            localAtual = local;
            atualizarPosicaoVisual(local);
            final instr = nav.getInstrucoesComOrigem(
                caminho, beaconAnterior)[0]; // Primeira instrução
            await _speakWithVibe(instr);
            setState(() => mostrarSeta = true);
          } else {
            await falar(mensagens['alerts']?['path_not_found_alert'] ??
                'Caminho não encontrado.');
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
          if (destinosHere.contains(widget.destino)) { // Se chegou ao destino
            await _handleFinalStep(local);
            return;
          }

          final instr = nav.getInstrucoesComOrigem(
              rota, beaconAnterior)[proximoPasso]; // Instrução do próximo passo
          await _speakWithVibe(instr);
          proximoPasso++;
          return;
        }

// —— Caso 3: beacon inesperado — recalcula a rota ——
        _processedBeacons
          ..clear()
          ..add(local);

        final novoCaminho = nav.dijkstra(
            local, widget.destino); // Tenta recalcular rota
        if (novoCaminho != null && novoCaminho.length > 1) {
          beaconAnterior = localAtual;
          rota = novoCaminho;
          proximoPasso = 1;
          localAtual = local;
          atualizarPosicaoVisual(local);
          final instr = nav.getInstrucoesComOrigem(
              novoCaminho, beaconAnterior)[0];
          await _speakWithVibe(instr);
          setState(() => mostrarSeta = true);
        } else {
          await falar(mensagens['alerts']?['path_not_found_alert'] ??
              'Caminho não encontrado.');
          finalizar();
        }
        return;
      }
    });
  }

  Future<void> _speakWithVibe(String texto) async {
    if (vibrationEnabled) Vibration.vibrate(
        duration: 400); // Vibra antes de falar
    await falar(texto); // Fala o texto
  }

  Future<void> _handleArrivalDirect(String local) async {
    isFinalizing = true; // Marca navegação como finalizada
    if (vibrationEnabled) Vibration.vibrate(duration: 400); // Vibração curta
    final instr = nav.buscarInstrucaoNoBeacon(local, widget.destino) ??
        ''; // Última instrução
    atualizarPosicaoVisual(local); // Atualiza posição no mapa
    setState(() => mostrarSeta = true);
    if (instr.isNotEmpty) await falar(instr); // Fala a última instrução

    FlutterBluePlus.stopScan(); // Para scan BLE
    if (vibrationEnabled) Vibration.vibrate(
        duration: 600); // Vibração longa final
    setState(() {
      chegou = true;
      status = 'beacon_scan_page.navigation_end'.tr(); // Atualiza status UI
    });
    await falar(mensagens['alerts']?['navigation_end_alert'] ??
        'Navegação concluída.'); // Mensagem final
  }

  Future<void> _handleFinalStep(String local) async {
    isFinalizing = true;
    if (vibrationEnabled) Vibration.vibrate(duration: 400); // Vibração curta
    final instrFinal = nav.buscarInstrucaoNoBeacon(
        local, widget.destino, beaconAnterior) ?? '';
    if (instrFinal.isNotEmpty) await falar(instrFinal); // Fala instrução final

    FlutterBluePlus.stopScan();
    if (vibrationEnabled) Vibration.vibrate(
        duration: 600); // Vibração longa final
    setState(() {
      chegou = true;
      status = 'beacon_scan_page.navigation_end'.tr();
    });
    await falar(
        mensagens['alerts']?['navigation_end_alert'] ?? 'Navegação concluída.');
  }

  void atualizarPosicaoVisual(String local) {
    final beaconInfo = beaconPositions[local];
    if (beaconInfo == null) return;

    final newPosition = beaconInfo['offset'] as Offset;
    final newFloor = beaconInfo['floor'] as String;

    if (newFloor != currentFloor) {
      setState(() {
        currentFloor = newFloor; // Atualiza piso no UI
      });
    }

    final delta = newPosition - currentPosition;
    final angle = math.atan2(delta.dy, delta.dx) +
        math.pi / 2; // Calcula ângulo

    _cameraAnimation =
    Tween<Offset>(begin: cameraOffset, end: newPosition).animate(
      CurvedAnimation(parent: _cameraController, curve: Curves.easeInOut),
    )
      ..addListener(() {
        setState(() {
          cameraOffset = _cameraAnimation.value; // Anima a câmara
        });
      });

    _cameraController.forward(from: 0);

    setState(() {
      previousPosition = currentPosition;
      currentPosition = newPosition;
      rotationAngle = angle;
      mostrarSeta = true; // Mostra seta no mapa
    });
  }

  void finalizar() {
    FlutterBluePlus.stopScan(); // Para scan BLE
    chegou = true; // Marca como concluído

    if (vibrationEnabled) {
      Vibration.hasVibrator().then((hasVibrator) {
        if (hasVibrator ?? false) Vibration.vibrate(
            duration: 600); // Vibração longa final
      });
    }
  }

  Future<void> falar(String texto) async {
    if (soundEnabled && texto.isNotEmpty) {
      setState(() {
        ultimaInstrucaoFalada = texto; // Atualiza texto no UI
      });
      await flutterTts.stop();
      await flutterTts.setLanguage(selectedLanguageCode);
      await flutterTts.setSpeechRate(voiceSpeed);
      await flutterTts.setPitch(voicePitch);
      await flutterTts.speak(texto); // Fala o texto
    }
  }


  void cancelarNavegacao() {
    setState(() {
      isNavigationCanceled = true; // Marca navegação como cancelada
      status = mensagens['alerts']?['navigation_cancelled_alert'] ?? '';
    });

    FlutterBluePlus.stopScan(); // Para BLE scan
    flutterTts.stop(); // Para TTS

    Navigator.pop(context); // Volta ao ecrã anterior
  }

  void mostrarDescricao() async {
    if (localAtual != null && mensagens['beacons']?[localAtual] != null) {
      final descricao = mensagens['beacons']?[localAtual]?['beacon_description']; // Pega descrição do beacon

      if (descricao != null && descricao.isNotEmpty) {
        print('[DEBUG] A falar descrição do beacon atual: $descricao');
        await falar(descricao); // Fala descrição
      } else {
        print(
            '[DEBUG] Descrição indisponível para o beacon atual: $localAtual');
        await falar('Descrição indisponível para o beacon atual.');
      }
    } else {
      print('[DEBUG] Ainda não foi detetado nenhum beacon.');
      await falar('Ainda não foi detetado nenhum beacon.');
    }
  }

  @override
  void dispose() {
    _scanRestartTimer?.cancel(); // Cancela timer
    flutterTts.stop(); // Para TTS
    FlutterBluePlus.stopScan(); // Para BLE scan
    _cameraController.dispose(); // Libera animação
    super.dispose();
  }

  String obterLocalAtual() {
    return localAtual ?? (mensagens['alerts']?['searching_alert'] ??
        ''); // Retorna local atual ou alerta
  }

  String obterProximaParagem() {
    if (rota.isEmpty || proximoPasso >= rota.length) {
      return mensagens['alerts']?['end_of_route_alert'] ??
          ''; // Se fim, alerta de fim
    }
    return rota[proximoPasso]; // Próximo na rota
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: InteractiveViewer( // Permite zoom e deslocamento no mapa
              panEnabled: true,
              scaleEnabled: true,
              minScale: 1.0,
              maxScale: 3.5,
              constrained: false,
              boundaryMargin: const EdgeInsets.all(100),
              child: Stack(
                children: [
                  Transform.translate(
                    offset: Offset(
                        -cameraOffset.dx + 150, -cameraOffset.dy + 320),
                    child: Stack(
                      children: [
                        Image.asset( // Mostra o mapa do piso atual
                          imagensPorPiso[currentFloor]!,
                          fit: BoxFit.none,
                          alignment: Alignment.topLeft,
                        ),
                        if (mostrarSeta)
                          AnimatedPositioned( // Mostra seta no local atual
                            duration: const Duration(milliseconds: 1000),
                            curve: Curves.easeInOut,
                            left: currentPosition.dx,
                            top: currentPosition.dy,
                            child: Transform.rotate(
                              angle: rotationAngle,
                              child: const Icon(Icons.navigation, size: 40,
                                  color: Colors.red),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          DraggableScrollableSheet( // Caixa de informações inferior
            minChildSize: 0.20,
            maxChildSize: 0.32,
            initialChildSize: 0.32,
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
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text( // Título com destino atual
                        '${'beacon_scan_page.destination'.tr()}: ${widget
                            .destino}',
                        style: const TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 20),
                      if (!chegou) ...[ // Mostra instrução ou alerta
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: ultimaInstrucaoFalada.isEmpty ? Colors
                                .yellow[100] : Colors.blue[100],
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                ultimaInstrucaoFalada.isEmpty
                                    ? Icons.warning
                                    : Icons.campaign,
                                color: ultimaInstrucaoFalada.isEmpty ? Colors
                                    .orange : Colors.blue,
                                size: 30,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Center(
                                  child: Text(
                                    ultimaInstrucaoFalada.isNotEmpty
                                        ? ultimaInstrucaoFalada
                                        : '${mensagens['alerts']?['searching_alert'] ??
                                        'A procurar...'}',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: ultimaInstrucaoFalada.isEmpty
                                          ? Colors.orange[900]
                                          : Colors.blue[900],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ] else
                        ...[ // Mensagem de chegada
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.green[100],
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                    Icons.check_circle, color: Colors.green,
                                    size: 30),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Center(
                                    child: Text(
                                      status,
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(fontSize: 16,
                                          fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      const SizedBox(height: 20),
                      Row( // Botões de ações
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: mostrarDescricao,
                              // Ouve descrição local
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
                              onPressed: cancelarNavegacao, // Cancela navegação
                              icon: const Icon(Icons.cancel),
                              label: Text(
                                  'beacon_scan_page.cancel_navigation'.tr()),
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