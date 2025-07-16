import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart'; // BLE scan
import 'package:flutter_tts/flutter_tts.dart'; // texto para voz
import 'package:permission_handler/permission_handler.dart'; // permissões
import 'package:vibration/vibration.dart'; // vibração
import 'tour_manager.dart'; // lógica de tour
import 'package:projetogpsnovo/helpers/preferences_helpers.dart'; // preferências
import 'package:easy_localization/easy_localization.dart'; // traduções

class TourScanPage extends StatefulWidget {
  final String destino; // destino da visita guiada
  final Map<String, String> destinosMap; // mapa de destinos

  const TourScanPage({super.key, required this.destino, required this.destinosMap});

  @override
  State<TourScanPage> createState() => _TourScanPageState();
}

class _TourScanPageState extends State<TourScanPage> with TickerProviderStateMixin {
  final FlutterTts flutterTts = FlutterTts(); // controlador de voz
  final TourManager nav = TourManager(); // gestor do tour
  final PreferencesHelper _preferencesHelper = PreferencesHelper(); // helper preferências

  bool isFinalizing = false; // estado de finalização

  Map<String, dynamic> mensagens = {}; // mensagens carregadas

  String ultimaInstrucaoFalada = ''; // guarda última instrução falada

  final Set<String> _processedBeacons = {}; // beacons já processados
  final Set<String> _beaconsComHistoricoFalado = {}; // históricos já falados

  final Map<String, DateTime> ultimaDeteccaoPorBeacon = {}; // registo último detetado
  static const int rssiThreshold = -60; // limiar mínimo RSSI (dBm)

  String? localAtual; // localização atual
  List<String> rota = []; // rota calculada
  int proximoPasso = 0; // índice do próximo passo
  bool chegou = false; // se chegou ao destino
  bool isNavigationCanceled = false; // se navegação foi cancelada
  bool isProcessingBeacon = false; // flag de processamento ativo

  DateTime? ultimaDetecao; // última deteção global
  final Duration cooldown = const Duration(seconds: 4); // tempo mínimo entre deteções
  String selectedLanguageCode = 'pt-PT'; // idioma selecionado
  bool soundEnabled = true; // som ativado
  bool vibrationEnabled = true; // vibração ativada
  double voiceSpeed = 0.6; // velocidade da voz
  double voicePitch = 1.0; // tom da voz

  Offset currentPosition = const Offset(300, 500); // posição no mapa
  Offset previousPosition = const Offset(300, 500); // posição anterior
  Offset cameraOffset = const Offset(300, 500); // posição da câmara
  double rotationAngle = 0.0; // ângulo de rotação (seta)

  bool mostrarSeta = false; // mostrar ou não seta de orientação

  late AnimationController _cameraController; // controlo de animação de câmara
  late Animation<Offset> _cameraAnimation; // animação de movimento

  String currentFloor = 'Piso 0'; // piso atual

  final Map<String, String> imagensPorPiso = { // imagens por piso
    'Piso -1': 'assets/images/map/-01_piso.png',
    'Piso 0': 'assets/images/map/00_piso.png',
    'Piso 1': 'assets/images/map/01_piso.png',
    'Piso 2': 'assets/images/map/02_piso.png',
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
      duration: const Duration(milliseconds: 1000), // animação de 1s
    );
    pedirPermissoes(); // pede permissões e inicia configuração
  }

  Future<void> finalizarNavegacao() async {
    print('[DEBUG] Scan parado - navegação concluída');
    FlutterBluePlus.stopScan(); // para o scan BLE

    if (vibrationEnabled) {
      print('[DEBUG] Vibração longa - navegação concluída');
      Vibration.vibrate(duration: 800); // vibração longa final
    }

    if (!chegou) { // garante que só executa uma vez
      print('[DEBUG] Chegou ao último ponto da rota, exibindo mensagem final');
      await falar(mensagens['alerts']?['tour_end_alert'] ??
          "A Visita Guiada chegou ao fim. Obrigado por usar a nossa aplicação!"); // fala mensagem final

      setState(() {
        chegou = true; // marca como concluído
        status = 'tour_scan_page.tour_end'.tr(); // texto traduzido
      });

      isFinalizing = true; // marca estado finalizado
    }
  }

  Future<void> pedirPermissoes() async {
    await [
      Permission.bluetooth,
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.locationWhenInUse,
    ].request(); // pede permissões necessárias

    await _loadSettings(); // carrega preferências
    await nav.carregarInstrucoes(selectedLanguageCode); // carrega instruções do tour
    iniciarScan(); // começa a fazer scan BLE
  }

  Future<void> falarHistoricoEInstrucao(String local) async {
    FlutterBluePlus.stopScan(); // para scan temporariamente
    isProcessingBeacon = true; // marca que está a processar

    final beaconData = mensagens['beacons']?[local]; // dados do beacon atual

    if (beaconData != null &&
        beaconData['historical_points'] != null &&
        !_beaconsComHistoricoFalado.contains(local)) {

      List<dynamic> historicalPoints = beaconData['historical_points']; // lista de pontos históricos

      for (var point in historicalPoints) {
        String nomePonto = point['name']; // nome do ponto
        String mensagemPonto = point['message']; // descrição histórica

        print('[DEBUG] Ponto histórico detectado: $nomePonto');
        await falar(nomePonto); // fala o nome
        await flutterTts.awaitSpeakCompletion(true);

        print('[DEBUG] A falar mensagem histórica: $mensagemPonto');
        await falar(mensagemPonto); // fala a descrição
        await flutterTts.awaitSpeakCompletion(true);
      }

      _beaconsComHistoricoFalado.add(local); // marca como já falado
    }

    String? instrucao = '';
    if (proximoPasso < rota.length - 1) { // verifica próximo passo
      String beaconAnterior = proximoPasso > 0 ? rota[proximoPasso - 1] : '';
      String localAtual = rota[proximoPasso];
      String destino = rota[proximoPasso + 1];
      instrucao = nav.buscarInstrucaoNoBeacon(beaconAnterior, localAtual, destino); // obtém instrução
    }

    if (instrucao != null && instrucao.isNotEmpty) {
      print('[DEBUG] A falar instrução: $instrucao');
      await falar(instrucao); // fala a instrução
      await flutterTts.awaitSpeakCompletion(true);
    }

    isProcessingBeacon = false; // terminou processamento
    iniciarScan(); // retoma o scan BLE
  }

  Future<void> _loadSettings() async {
    final settings = await _preferencesHelper.loadSoundSettings(); // carrega preferências guardadas
    setState(() {
      selectedLanguageCode = settings['selectedLanguageCode'] ?? 'pt-PT';
      soundEnabled = settings['soundEnabled'];
      vibrationEnabled = settings['vibrationEnabled'];
      voiceSpeed = settings['voiceSpeed'] ?? 0.6;
      voicePitch = settings['voicePitch'] ?? 1.0;
    });
    await _carregarMensagens(); // carrega mensagens no idioma certo
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
        jsonString = await rootBundle.loadString(path); // tenta carregar ficheiro
        break;
      } catch (_) {}
    }
    setState(() {
      mensagens = jsonString != null ? json.decode(jsonString) : {}; // guarda mensagens carregadas
      status = mensagens['alerts']?['searching_alert'] ?? ''; // define status inicial
    });
  }

  void iniciarScan() {
    if (isFinalizing) {
      print('[DEBUG] Navegação já finalizada, não iniciando novo scan.');
      return; // evita iniciar se já finalizado
    }

    FlutterBluePlus.startScan(
      continuousUpdates: true,
      androidScanMode: AndroidScanMode.lowLatency,
      androidUsesFineLocation: true,
    );
    print('[DEBUG] Iniciando scan para detectar beacons...');

    FlutterBluePlus.scanResults.listen((results) async {
      if (chegou || isNavigationCanceled || isFinalizing) return; // ignora se parada

      for (final result in results) {
        if (result.rssi < rssiThreshold) continue; // ignora sinais fracos

        final beacon = nav.parseBeaconData(result); // converte para BeaconInfo
        if (beacon == null ||
            beacon.uuid.toLowerCase() != '107e0a13-90f3-42bf-b980-181d93c3ccd2') {
          continue; // ignora UUIDs diferentes
        }

        final local = nav.getLocalizacao(beacon); // obtém nome do local
        if (local == null) continue;

        final agora = DateTime.now();

        // aplica cooldown por beacon
        if (ultimaDeteccaoPorBeacon.containsKey(local)) {
          final ultima = ultimaDeteccaoPorBeacon[local]!;
          if (agora.difference(ultima) < cooldown) continue; // ainda em cooldown
        }
        ultimaDeteccaoPorBeacon[local] = agora; // atualiza último detetado

        if (rota.isEmpty) {
          rota = nav.rotaPreDefinida; // inicializa rota se estiver vazia
          proximoPasso = 0;
          print('[DEBUG] Rota carregada: $rota');
        }

        if (proximoPasso >= rota.length) return; // já no fim

        final beaconEsperado = rota[proximoPasso];

        if (local == beaconEsperado) {
          print('[DEBUG] Ponto esperado alcançado: $local');
          localAtual = local;
          atualizarPosicaoVisual(local); // atualiza UI

          if (vibrationEnabled) {
            print('[DEBUG] Vibração curta - passo correto');
            Vibration.vibrate(duration: 400); // vibração curta ao acertar
          }

          await falarHistoricoEInstrucao(local); // fala histórico + instrução

          proximoPasso++; // avança na rota

          if (proximoPasso >= rota.length) {
            print('[DEBUG] Fim da rota atingido.');
            await finalizarNavegacao(); // termina se for último
          }

          setState(() => mostrarSeta = true); // mostra seta no mapa
        } else {
          print('[DEBUG] Beacon inesperado: $local (esperado: $beaconEsperado)');
        }
      }
    });
  }
  void atualizarPosicaoVisual(String local) {
    final beaconInfo = beaconPositions[local]; // obtém info do beacon no mapa
    if (beaconInfo == null) return;

    final newPosition = beaconInfo['offset'] as Offset; // posição no mapa
    final newFloor = beaconInfo['floor'] as String; // piso correspondente

    if (newFloor != currentFloor) {
      setState(() {
        currentFloor = newFloor; // atualiza piso se mudou
      });
    }

    final delta = newPosition - currentPosition; // diferença entre posições
    final angle = math.atan2(delta.dy, delta.dx) + math.pi / 2; // calcula ângulo de rotação

    _cameraAnimation = Tween<Offset>(begin: cameraOffset, end: newPosition).animate(
      CurvedAnimation(parent: _cameraController, curve: Curves.easeInOut),
    )..addListener(() {
      setState(() {
        cameraOffset = _cameraAnimation.value; // atualiza animação da câmara
      });
    });

    _cameraController.forward(from: 0); // inicia animação

    setState(() {
      previousPosition = currentPosition; // guarda posição anterior
      currentPosition = newPosition; // atualiza posição atual
      rotationAngle = angle; // atualiza ângulo
      mostrarSeta = true; // mostra seta no mapa
    });

    print('[DEBUG] Atualizando a posição visual no mapa para: $newPosition');
  }

  Future<void> falar(String texto, {bool isFinalMessage = false}) async {
    if (soundEnabled && texto.isNotEmpty) {
      setState(() {
        ultimaInstrucaoFalada = texto; // guarda última instrução falada
      });
      await flutterTts.stop();
      await flutterTts.setLanguage(selectedLanguageCode);
      await flutterTts.setSpeechRate(voiceSpeed);
      await flutterTts.setPitch(voicePitch);
      await flutterTts.speak(texto); // fala texto

      if (vibrationEnabled) {
        if (isFinalMessage) {
          print('[DEBUG] Vibração longa - mensagem final');
          Vibration.vibrate(duration: 800); // vibração longa no final
        } else {
          print('[DEBUG] Vibração curta - mensagem de instrução');
          Vibration.vibrate(duration: 400); // vibração curta para instruções
        }
      }
    }
  }

  void cancelarNavegacao() {
    setState(() {
      isNavigationCanceled = true; // marca como cancelado
      status = mensagens['alerts']?['navigation_cancelled_alert'] ?? '';
    });

    FlutterBluePlus.stopScan(); // para scan BLE
    flutterTts.stop(); // para fala

    Navigator.pop(context); // volta para a página anterior
  }

  @override
  void dispose() {
    flutterTts.stop(); // limpa TTS
    FlutterBluePlus.stopScan(); // limpa BLE
    _cameraController.dispose(); // limpa animação
    super.dispose(); // chama dispose padrão
  }

  String obterLocalAtual() {
    return localAtual ?? (mensagens['alerts']?['searching_alert'] ?? ''); // devolve localização atual ou status
  }

  String obterProximaParagem() {
    if (rota.isEmpty || proximoPasso >= rota.length) {
      return mensagens['alerts']?['end_of_route_alert'] ?? ''; // retorna aviso fim de rota
    }
    return rota[proximoPasso]; // próxima paragem na rota
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: InteractiveViewer( // permite zoom e arrastar no mapa
              panEnabled: true,
              scaleEnabled: true,
              minScale: 1.0,
              maxScale: 3.5,
              constrained: false,
              boundaryMargin: const EdgeInsets.all(100),
              child: Stack(
                children: [
                  Transform.translate( // move o mapa para focar no beacon atual
                    offset: Offset(-cameraOffset.dx + 150, -cameraOffset.dy + 320),
                    child: Stack(
                      children: [
                        Image.asset(
                          imagensPorPiso[currentFloor]!, // imagem do piso atual
                          fit: BoxFit.none,
                          alignment: Alignment.topLeft,
                        ),
                        if (mostrarSeta)
                          AnimatedPositioned( // seta que indica posição no mapa
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
          DraggableScrollableSheet( // painel inferior arrastável
            minChildSize: 0.45,
            maxChildSize: 0.45,
            initialChildSize: 0.45,
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
                      '${'tour_scan_page.tour_title'.tr()}', // título do painel
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 20),
                    Expanded(
                      child: SingleChildScrollView( // conteúdo scrollável
                        controller: controller,
                        child: Column(
                          children: [
                            if (!chegou) ...[
                              _buildMessageContainer(), // mostra instrução atual
                            ] else ...[
                              _buildFinalMessageContainer(), // mostra mensagem final
                            ],
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Align(
                      alignment: Alignment.bottomCenter,
                      child: ElevatedButton.icon( // botão cancelar
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

// Widget: contêiner com mensagem durante a navegação
  Widget _buildMessageContainer() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: ultimaInstrucaoFalada.isEmpty ? Colors.yellow[100] : Colors.blue[100], // muda cor se sem instrução
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(
            ultimaInstrucaoFalada.isEmpty ? Icons.warning : Icons.campaign, // ícone de aviso ou instrução
            color: ultimaInstrucaoFalada.isEmpty ? Colors.orange : Colors.blue,
            size: 30,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Center(
              child: Text(
                ultimaInstrucaoFalada.isNotEmpty
                    ? ultimaInstrucaoFalada // mostra instrução atual
                    : '${mensagens['alerts']?['searching_alert'] ?? 'A procurar...'}',
                textAlign: TextAlign.left,
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

// Widget: contêiner com mensagem final de conclusão
  Widget _buildFinalMessageContainer() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.green[100], // fundo verde de sucesso
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: Colors.green, size: 30), // ícone check
          const SizedBox(width: 10),
          Expanded(
            child: Center(
              child: Text(
                status, // mensagem final traduzida
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