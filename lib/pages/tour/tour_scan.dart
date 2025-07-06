import 'dart:async'; // Necessário para usar Future e Timer
import 'dart:convert'; // Para leitura e decodificação de ficheiros JSON
import 'dart:math' as math; // Biblioteca matemática (ex: cálculo de ângulos)
import 'package:flutter/material.dart'; // Widgets principais do Flutter
import 'package:flutter/services.dart'; // Permite aceder a assets
import 'package:flutter_blue_plus/flutter_blue_plus.dart'; // Biblioteca para Bluetooth LE
import 'package:flutter_tts/flutter_tts.dart'; // Text-to-Speech
import 'package:permission_handler/permission_handler.dart'; // Para pedir permissões do sistema
import 'package:vibration/vibration.dart'; // Para usar vibração no dispositivo
import 'tour_manager.dart'; // Lógica de gestão de beacons e navegação
import 'package:projetogpsnovo/helpers/preferences_helpers.dart'; // Gestão de preferências guardadas
import 'package:easy_localization/easy_localization.dart'; // Tradução de strings

// Página que realiza o scan de beacons durante a visita guiada
class TourScanPage extends StatefulWidget {
  final String destino; // Destino final da visita
  final Map<String, String> destinosMap; // Mapa com nomes dos destinos

  const TourScanPage({super.key, required this.destino, required this.destinosMap});

  @override
  State<TourScanPage> createState() => _TourScanPageState(); // Liga ao estado
}

// Estado associado à página de scan
class _TourScanPageState extends State<TourScanPage> with TickerProviderStateMixin {
  final FlutterTts flutterTts = FlutterTts(); // Instância TTS
  final TourManager nav = TourManager(); // Lógica de navegação (carrega JSON e instruções)
  final PreferencesHelper _preferencesHelper = PreferencesHelper(); // Preferências locais

  bool isFinalizing = false; // Indica se está a terminar navegação
  Map<String, dynamic> mensagens = {}; // Armazena JSON com mensagens traduzidas
  String ultimaInstrucaoFalada = ''; // Guarda a última instrução dita

  String? localAtual; // Nome do beacon atual
  List<String> rota = []; // Lista de pontos na rota
  int proximoPasso = 0; // Índice do próximo ponto na rota
  bool chegou = false; // Se chegou ao destino final
  bool isNavigationCanceled = false; // Se a navegação foi cancelada
  bool isProcessingBeacon = false; // Evita processamentos repetidos de beacons

  DateTime? ultimaDetecao; // Última vez que detetou um beacon
  final Duration cooldown = const Duration(seconds: 4); // Tempo mínimo entre detecções

  String selectedLanguageCode = 'pt-PT'; // Idioma selecionado
  bool soundEnabled = true; // Se som está ativo
  bool vibrationEnabled = true; // Se vibração está ativa
  double voiceSpeed = 0.6; // Velocidade da voz
  double voicePitch = 1.0; // Tom da voz

  Offset currentPosition = const Offset(300, 500); // Posição atual no mapa
  Offset previousPosition = const Offset(300, 500); // Posição anterior (para animação)
  Offset cameraOffset = const Offset(300, 500); // Offset da câmara (centro visualizado)
  double rotationAngle = 0.0; // Ângulo de rotação da seta
  bool mostrarSeta = false; // Se deve mostrar a seta de direção

  late AnimationController _cameraController; // Controlador da animação da câmara
  late Animation<Offset> _cameraAnimation; // Animação de movimento da câmara

  String currentFloor = 'Piso 0'; // Piso atual

  // Mapa que associa pisos às imagens dos mapas
  final Map<String, String> imagensPorPiso = {
    'Piso -1': 'assets/images/map/-01_piso.png',
    'Piso 0': 'assets/images/map/00_piso.png',
    'Piso 1': 'assets/images/map/01_piso.png',
    'Piso 2': 'assets/images/map/02_piso.png',
  };

  String status = ''; // Mensagem de status atual

  // Coordenadas no mapa associadas aos beacons
  final Map<String, Offset> beaconPositions = {
    'Beacon 1': Offset(300, 500),
    'Beacon 3': Offset(300, 250),
    'Beacon 15': Offset(380, 95),
  };

  @override
  void initState() {
    super.initState();
    _cameraController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000), // Tempo da animação da câmara
    );
    pedirPermissoes(); // Pede permissões necessárias (Bluetooth, localização)
  }

  // Finaliza o processo de navegação: para o scan, vibra e mostra debug
  Future<void> finalizarNavegacao() async {
    print('[DEBUG] Scan parado - navegação concluída');
    FlutterBluePlus.stopScan(); // Para o scan de beacons

    if (vibrationEnabled) {
      print('[DEBUG] Vibração longa - navegação concluída');
      Vibration.vibrate(duration: 800); // Vibração final longa
    }

    // Garantir que a mensagem de fim da visita só seja chamada uma vez
    if (!chegou) {
      print('[DEBUG] Chegou ao último ponto da rota, exibindo mensagem final');
      await falar(mensagens['alerts']?['tour_end_alert'] ?? "A Visita Guiada chegou ao fim. Obrigado por usar a nossa aplicação!");

      setState(() {
        chegou = true; // Marca que chegou ao destino final
        status = 'tour_scan_page.tour_end'.tr(); // Atualiza mensagem no UI
      });

      isFinalizing = true; // Marca que a navegação foi finalizada
    }
  }

  // Pede permissões necessárias (Bluetooth, localização) e inicia configurações
  Future<void> pedirPermissoes() async {
    await [
      Permission.bluetooth,
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.locationWhenInUse,
    ].request(); // Solicita permissões em tempo de execução

    await _loadSettings(); // Carrega configurações guardadas
    await nav.carregarInstrucoes(selectedLanguageCode); // Carrega instruções da visita
    iniciarScan(); // Inicia scan de beacons
  }

  // Fala nome e descrição de um ponto histórico, e dá instrução seguinte
  Future<void> falarHistoricoEInstrucao(String local) async {
    final beaconData = mensagens['beacons']?[local]; // Busca os dados do beacon no JSON

    if (beaconData != null && beaconData['historical_point_name'] != null && beaconData['historical_point_message'] != null) {
      String nomePonto = beaconData['historical_point_name'];
      String mensagemPonto = beaconData['historical_point_message'];

      print('[DEBUG] Ponto histórico detectado: $nomePonto');
      print('[DEBUG] A falar: Chegou a $nomePonto.');
      await falar(nomePonto); // Fala o nome do ponto
      await flutterTts.awaitSpeakCompletion(true); // Espera terminar

      print('[DEBUG] A falar mensagem histórica: $mensagemPonto');
      await falar(mensagemPonto); // Fala a mensagem associada ao ponto
      await flutterTts.awaitSpeakCompletion(true);
    }

    // Recupera a próxima instrução de navegação, se houver
    String? instrucao = '';
    if (proximoPasso < rota.length - 1) {
      instrucao = nav.buscarInstrucaoNoBeacon(local, rota[proximoPasso + 1]);
    }

    if (instrucao != null && instrucao.isNotEmpty) {
      print('[DEBUG] A falar instrução: $instrucao');
      await falar(instrucao); // Fala a instrução de navegação
    }
  }

  // Carrega configurações de som e voz guardadas em SharedPreferences
  Future<void> _loadSettings() async {
    final settings = await _preferencesHelper.loadSoundSettings();
    setState(() {
      selectedLanguageCode = settings['selectedLanguageCode'] ?? 'pt-PT'; // Código de idioma
      soundEnabled = settings['soundEnabled']; // Flag som
      vibrationEnabled = settings['vibrationEnabled']; // Flag vibração
      voiceSpeed = settings['voiceSpeed'] ?? 0.6; // Velocidade da voz
      voicePitch = settings['voicePitch'] ?? 1.0; // Tom da voz
    });
    await _carregarMensagens(); // Carrega ficheiro com mensagens no idioma atual
  }

  // Carrega mensagens da visita com base no idioma
  Future<void> _carregarMensagens() async {
    String langCode = selectedLanguageCode.toLowerCase().split('-')[0]; // Ex: "pt"
    String fullCode = selectedLanguageCode.toLowerCase().replaceAll('_', '-'); // Ex: "pt-pt"
    List<String> paths = [
      'assets/tts/tour/tour_$fullCode.json',
      'assets/tts/tour/tour_$langCode.json',
      'assets/tts/tour/tour_en.json',
    ];

    // Tenta carregar o ficheiro JSON com base nos caminhos fornecidos
    String? jsonString;
    for (String path in paths) {
      try {
        jsonString = await rootBundle.loadString(path); // Tenta ler ficheiro
        break; // Se conseguir, para o ciclo
      } catch (_) {} // Se falhar, tenta o próximo caminho
    }
    // Atualiza o estado com as mensagens carregadas
    setState(() {
      mensagens = jsonString != null ? json.decode(jsonString) : {}; // Decodifica JSON
      status = mensagens['alerts']?['searching_alert'] ?? ''; // Mensagem de estado "A procurar..."
    });
  }

  void iniciarScan() {
    if (isFinalizing) {
      print('[DEBUG] Navegação já finalizada, não iniciando novo scan.');
      return; // Impede iniciar o scan novamente após a navegação ter sido finalizada
    }

    FlutterBluePlus.startScan(); // Começa o scan Bluetooth LE
    print('[DEBUG] Iniciando scan para detectar beacons...');

    FlutterBluePlus.scanResults.listen((results) async {
      // Ignora eventos se já tiver chegado ao destino, cancelado ou estiver ocupado
      if (chegou || isNavigationCanceled || isFinalizing || isProcessingBeacon) return;

      for (final result in results) {
        final beacon = nav.parseBeaconData(result); // Converte dados do beacon para BeaconInfo
        if (beacon == null) continue;

        final local = nav.getLocalizacao(beacon); // Obtém o nome lógico do beacon
        if (local == null) continue;

        final agora = DateTime.now();
        // Se ainda estiver em cooldown e for o mesmo local, ignora
        if (ultimaDetecao != null && agora.difference(ultimaDetecao!) < cooldown && local == localAtual) {
          continue;
        }

        ultimaDetecao = agora; // Atualiza última detecção

        // Se rota ainda não foi inicializada, usa a pré-definida
        if (rota.isEmpty) {
          rota = nav.rotaPreDefinida;
          proximoPasso = 0;
          print('[DEBUG] Rota carregada: $rota');
        }

        // Verifica se o índice do próximo passo já ultrapassou o tamanho da rota
        // Se sim, significa que o utilizador já terminou a rota e não há mais beacons a processar
        if (proximoPasso >= rota.length) return;

        final beaconEsperado = rota[proximoPasso]; // Obtém o nome do beacon que se espera encontrar nesta etapa do percurso

        if (local == beaconEsperado) { // Verifica se o beacon detetado corresponde exatamente ao que se espera neste passo
          print('[DEBUG] Ponto esperado alcançado: $local'); // Imprime no terminal que o ponto correto foi detetado

          isProcessingBeacon = true; // Marca que o sistema está a processar este beacon (para evitar processamento repetido)

          localAtual = local; // Atualiza a variável localAtual com o nome do beacon recém-detectado

          atualizarPosicaoVisual(local); // Atualiza visualmente a posição do utilizador no mapa com base no beacon

          // Se a vibração estiver ativada nas preferências, executa uma vibração curta
          if (vibrationEnabled) {
            print('[DEBUG] Vibração curta - passo correto');
            Vibration.vibrate(duration: 400); // Vibra durante 400ms
          }

          // Executa a fala do nome do ponto histórico, mensagem descritiva e a instrução de navegação
          await falarHistoricoEInstrucao(local);

          proximoPasso++;// Avança para o próximo passo da rota (incrementa o índice)

          if (proximoPasso >= rota.length) { // Se o novo passo já estiver fora da rota, significa que a visita terminou
            print('[DEBUG] Fim da rota atingido.');
            await finalizarNavegacao();  // Fala a mensagem final e termina a navegação
          }

          setState(() {// Atualiza o estado do widget para mostrar a seta direcional no ecrã
            mostrarSeta = true;
          });

          isProcessingBeacon = false; // Libera a flag de processamento para permitir novas detecções

        } else {
          // Caso o beacon detetado não seja o esperado, imprime essa discrepância no terminal
          print('[DEBUG] Beacon detetado fora de sequência: $local (esperado: $beaconEsperado)');
        }

      }
    });
  }

  void atualizarPosicaoVisual(String local) {
    // Obtém a nova posição no mapa associada ao beacon.
    // Se não existir, usa uma posição padrão (300, 500)
    final newPosition = beaconPositions[local] ?? const Offset(300, 500);

    // Calcula o vetor de deslocamento entre a posição atual e a nova
    final delta = newPosition - currentPosition;

    // Calcula o ângulo de rotação da seta (em radianos) com base no vetor
    // Acrescenta pi/2 para alinhar corretamente a seta visual
    final angle = math.atan2(delta.dy, delta.dx) + math.pi / 2;

    // Cria uma animação suave entre a posição atual da câmara e a nova
    _cameraAnimation = Tween<Offset>(
      begin: cameraOffset,
      end: newPosition,
    ).animate(
      CurvedAnimation(
        parent: _cameraController,
        curve: Curves.easeInOut, // Animação suave
      ),
    )
    // Sempre que a animação avança, atualiza o estado da câmara visual
      ..addListener(() {
        setState(() {
          cameraOffset = _cameraAnimation.value;
        });
      });

    // Inicia a animação a partir do início (0%)
    _cameraController.forward(from: 0);

    // Atualiza o estado visual com a nova posição e rotação calculadas
    setState(() {
      previousPosition = currentPosition; // Guarda posição anterior
      currentPosition = newPosition;      // Atualiza para a nova posição
      rotationAngle = angle;              // Atualiza a orientação da seta
      mostrarSeta = true;                 // Mostra a seta no mapa
    });

    // Imprime no terminal a nova posição visual no mapa
    print('[DEBUG] Atualizando a posição visual no mapa para: $newPosition');
  }


  Future<void> falar(String texto, {bool isFinalMessage = false}) async {
    // Só executa se o som estiver ativado e houver texto para falar
    if (soundEnabled && texto.isNotEmpty) {
      // Atualiza a última instrução falada (útil para acessibilidade ou debugging)
      setState(() {
        ultimaInstrucaoFalada = texto;
      });
      await flutterTts.stop();// Para qualquer fala anterior que esteja a decorrer
      await flutterTts.setLanguage(selectedLanguageCode);// Configura o TTS com o idioma selecionado
      await flutterTts.setSpeechRate(voiceSpeed);// Define a velocidade da voz (controlada pelo utilizador)
      await flutterTts.setPitch(voicePitch);// Define o tom da voz
      await flutterTts.speak(texto); // Inicia a fala do texto recebido

      // ---------- Vibração associada à fala ----------

      if (isFinalMessage) {
        // Se for uma mensagem final (ex: fim da visita), vibração longa
        if (vibrationEnabled) {
          print('[DEBUG] Vibração longa - mensagem final');
          Vibration.vibrate(duration: 800); // Vibração de 800ms
        }
      } else {
        // Caso contrário, vibração curta para instruções normais
        if (vibrationEnabled) {
          print('[DEBUG] Vibração curta - mensagem de instrução');
          Vibration.vibrate(duration: 400); // Vibração de 400ms
        }
      }
    }
  }

  void cancelarNavegacao() {

    setState(() { // Marca a navegação como cancelada e atualiza o estado com a mensagem
      isNavigationCanceled = true;
      status = mensagens['alerts']?['navigation_cancelled_alert'] ?? '';
    });
    FlutterBluePlus.stopScan(); // Para o scan de beacons
    flutterTts.stop(); // Para qualquer instrução de voz que esteja a decorrer
    Navigator.pop(context);// Fecha a página e volta para o ecrã anterior
  }

  @override
  void dispose() {
    flutterTts.stop();// Garante que nenhuma fala continua a correr ao sair da página
    FlutterBluePlus.stopScan(); // Termina o scan Bluetooth para poupar recursos e evitar conflitos
    _cameraController.dispose(); // Liberta o controlador da animação da câmara no mapa
    super.dispose(); // Chama o dispose da classe mãe para limpeza completa
  }

  String obterLocalAtual() { // Se houver um local detetado, devolve esse nome
    return localAtual ?? (mensagens['alerts']?['searching_alert'] ?? ''); // Caso contrário, devolve a mensagem "A procurar..."
  }

  String obterProximaParagem() {                            // Se a rota estiver vazia ou o índice do próximo passo for inválido,
    if (rota.isEmpty || proximoPasso >= rota.length) {      // devolve a mensagem de "fim da rota"
      return mensagens['alerts']?['end_of_route_alert'] ?? '';
    }
    return rota[proximoPasso]; // Caso contrário, devolve o nome do próximo ponto na rota
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack( // Empilha elementos visuais uns sobre os outros
        children: [
          Positioned.fill(
            child: InteractiveViewer(
              panEnabled: true, // Permite arrastar o mapa
              scaleEnabled: true, // Permite dar zoom
              minScale: 1.0,
              maxScale: 3.5, // Limite máximo de zoom
              constrained: false, // Permite conteúdo fora da área visível
              boundaryMargin: const EdgeInsets.all(100), // Margem para movimento livre do mapa
              child: Stack(
                children: [
                  // Move a “câmara” para centrar o utilizador
                  Transform.translate(
                    offset: Offset(-cameraOffset.dx + 150, -cameraOffset.dy + 320),
                    child: Stack(
                      children: [
                        // Imagem do piso atual carregada com base em currentFloor
                        Image.asset(
                          imagensPorPiso[currentFloor]!, // Ex: "Piso 0"
                          fit: BoxFit.none, // Não redimensiona a imagem
                          alignment: Alignment.topLeft,
                        ),
                        if (mostrarSeta)
                          AnimatedPositioned(
                            duration: const Duration(milliseconds: 1000), // Animação suave
                            curve: Curves.easeInOut,
                            left: currentPosition.dx, // Posição no mapa
                            top: currentPosition.dy,
                            child: Transform.rotate(
                              angle: rotationAngle, // Rotação para indicar direção
                              child: const Icon(
                                  Icons.navigation, // Ícone de seta
                                  size: 40,
                                  color: Colors.red, // Cor visível no mapa
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
          DraggableScrollableSheet(
            minChildSize: 0.45,
            maxChildSize: 0.45,
            initialChildSize: 0.45, // Painel ocupa 45% da altura
            builder: (context, controller) {
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.95), // Fundo semi-transparente
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(12)), // Bordas arredondadas
                  boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 6)],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      '${'tour_scan_page.tour_title'.tr()}', // Tradução da chave para o idioma atual
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    Expanded(
                      child: SingleChildScrollView(
                        controller: controller, // Permite scroll interno
                        child: Column(
                          children: [
                            if (!chegou) ...[
                              _buildMessageContainer(), // Mostra instruções de navegação
                            ] else ...[
                              _buildFinalMessageContainer(), // Mostra mensagem de fim da visita
                            ],
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Align(
                      alignment: Alignment.bottomCenter,
                      child: ElevatedButton.icon(
                        onPressed: cancelarNavegacao, // Ação de cancelar a navegação
                        icon: const Icon(Icons.cancel),
                        label: Text('tour_scan_page.cancel_tour'.tr()), // Tradução da etiqueta
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


  // Widget para exibir o contêiner de mensagens dinâmicas (ex: instruções de navegação)
  Widget _buildMessageContainer() {
    return Container(
      padding: const EdgeInsets.all(12), // Espaçamento interno do container
      decoration: BoxDecoration(
        // Cor de fundo depende se já há uma instrução falada
        color: ultimaInstrucaoFalada.isEmpty
            ? Colors.yellow[100] // Se ainda não falou nada, fundo amarelo claro
            : Colors.blue[100],  // Se já falou, fundo azul claro
        borderRadius: BorderRadius.circular(10), // Cantos arredondados
      ),
      child: Row(
        children: [
          // Ícone à esquerda, depende do estado
          Icon(
            ultimaInstrucaoFalada.isEmpty
                ? Icons.warning // Ícone de alerta se ainda não foi detetado o beacon
                : Icons.campaign, // Ícone de megafone se já deu instrução
            color: ultimaInstrucaoFalada.isEmpty
                ? Colors.orange // Cor de alerta
                : Colors.blue,  // Cor de informação
            size: 30, // Tamanho do ícone
          ),
          const SizedBox(width: 10), // Espaço entre ícone e texto

          Expanded( // O texto ocupa o espaço restante da linha
            child: Center(
              child: Text(
                // Mostra a última instrução falada ou a mensagem "A procurar..."
                ultimaInstrucaoFalada.isNotEmpty
                    ? ultimaInstrucaoFalada
                    : '${mensagens['alerts']?['searching_alert'] ?? 'A procurar...'}',
                textAlign: TextAlign.left, // Alinhamento do texto à esquerda
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: ultimaInstrucaoFalada.isEmpty
                      ? Colors.orange[900] // Cor do texto para alerta
                      : Colors.blue[900],  // Cor do texto para instrução
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Widget para exibir o contêiner de mensagem final (ex: "Visita Concluída")
  Widget _buildFinalMessageContainer() {
    return Container(
      padding: const EdgeInsets.all(12), // Espaçamento interno
      decoration: BoxDecoration(
        color: Colors.green[100], // Cor de fundo verde claro, indicando sucesso
        borderRadius: BorderRadius.circular(10), // Cantos arredondados
      ),
      child: Row(
        children: [
          // Ícone de check verde
          const Icon(Icons.check_circle, color: Colors.green, size: 30),
          const SizedBox(width: 10), // Espaço entre ícone e texto

          Expanded(
            child: Center(
              child: Text(
                status, // Texto do estado atual (ex: mensagem de fim da visita)
                textAlign: TextAlign.center, // Texto centralizado
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}