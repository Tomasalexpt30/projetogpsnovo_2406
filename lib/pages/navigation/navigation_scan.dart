// beacon_scan_page.dart

// Importações necessárias para funcionalidades como TTS, Bluetooth, permissões, etc.
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

// Definição da página de scan de beacons para navegação
class BeaconScanPage extends StatefulWidget {
  final String destino; // Nome do destino escolhido
  final Map<String, String> destinosMap; // Mapa com os nomes dos destinos e beacons associados

  const BeaconScanPage({super.key, required this.destino, required this.destinosMap});

  @override
  State<BeaconScanPage> createState() => _BeaconScanPageState();
}

class _BeaconScanPageState extends State<BeaconScanPage> with TickerProviderStateMixin {
  final FlutterTts flutterTts = FlutterTts(); // Inicialização do TTS (text-to-speech)
  final NavigationManager nav = NavigationManager(); // Instância do gestor de navegação
  final PreferencesHelper _preferencesHelper = PreferencesHelper(); // Helper para ler definições do utilizador (som, idioma, etc.)

  bool isFinalizing = false; // Estado que indica se a navegação está a ser finalizada

  Map<String, dynamic> mensagens = {}; // Mapa com mensagens multilíngua carregadas

  late String? beaconDoDestino; // Beacon associado ao destino final

  String ultimaInstrucaoFalada = ''; //Guarda a última instrução falada, para evitar repetições

  String? localAtual; // Guarda o nome do local atual
  List<String> rota = []; // Lista com a rota definida (lista de beacons)
  int proximoPasso = 0; // Índice do próximo passo na rota
  bool chegou = false; // Indica se o utilizador já chegou ao destino
  bool isNavigationCanceled = false; // Estado para verificar se a navegação foi cancelada

  DateTime? ultimaDetecao;  // Regista o tempo da última deteção de beacon (para aplicar cooldown)
  final Duration cooldown = const Duration(seconds: 4); // Duração de cooldown entre deteções sucessivas
  String selectedLanguageCode = 'pt-PT'; // Idioma selecionado (padrão: português de Portugal)
  // Preferências de som e vibração
  bool soundEnabled = true;
  bool vibrationEnabled = true;
  // Configurações da voz (velocidade e tom)
  double voiceSpeed = 0.6;
  double voicePitch = 1.0;

  Offset currentPosition = const Offset(300, 500); // Posição atual (em coordenadas relativas ao mapa)
  Offset previousPosition = const Offset(300, 500); // Posição anterior (para calcular deslocamento)
  Offset cameraOffset = const Offset(300, 500); // Posição da câmara (utilizada para animação de movimento no mapa)
  double rotationAngle = 0.0; // Ângulo de rotação do indicador (ex: seta de direção)

  bool mostrarSeta = false; // Controla a visibilidade da seta de direção

  late AnimationController _cameraController; // Controlador da animação da câmara
  late Animation<Offset> _cameraAnimation;  // Animação de transição da câmara entre posições

  String currentFloor = 'Piso 0';  // Piso atual em exibição

  final Map<String, String> imagensPorPiso = { // Mapeamento de cada piso para a respetiva imagem do mapa
    'Piso -1': 'assets/images/map/-01_piso.png',
    'Piso 0': 'assets/images/map/00_piso.png',
    'Piso 1': 'assets/images/map/01_piso.png',
    'Piso 2': 'assets/images/map/02_piso.png',
  };

  String status = ''; // Texto de estado (pode ser usado para feedback visual)

  // Coordenadas relativas no mapa para cada beacon
  final Map<String, Offset> beaconPositions = {
    'Beacon 1': Offset(300, 500),
    'Beacon 3': Offset(300, 250),
    'Beacon 15': Offset(380, 95),
  };

  @override
  void initState() {
    super.initState();
    _cameraController = AnimationController( // Inicializa o controlador de animação para a câmara
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    pedirPermissoes();  // Solicita permissões necessárias ao utilizador (Bluetooth, localização, etc.)
  }

  /// Função para finalizar a navegação
  Future<void> finalizarNavegacao() async {
    print('[DEBUG] Scan parado - navegação concluída');
    FlutterBluePlus.stopScan();  // Para o scan de Bluetooth

    // Caso a vibração esteja ativa, vibra o dispositivo para notificar fim da navegação
    if (vibrationEnabled) {
      print('[DEBUG] Vibração longa - navegação concluída');
      Vibration.vibrate(duration: 800);
    }

    await falar(mensagens['alerts']?['navigation_end_alert'] ?? 'Navegação concluida.'); // Fala a mensagem final de navegação (localizada por idioma)

    // Atualiza o estado para indicar que o utilizador chegou ao destino
    setState(() {
      chegou = true; // Estado que bloqueia novas interações e exibe mensagem final
      status = 'beacon_scan_page.navigation_end'.tr(); // Mensagem localizada de fim de navegação
    }); // Flag que impede novas leituras de beacons enquanto finaliza
    isFinalizing = true; // 🔒 Bloquear novas leituras
  }

  Future<void> pedirPermissoes() async { // Solicita permissões necessárias para funcionamento da navegação via Bluetooth
    await [
      Permission.bluetooth,
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.locationWhenInUse,
    ].request();

    await _loadSettings(); // Carrega definições de som, voz, idioma, etc.
    await nav.carregarInstrucoes(selectedLanguageCode); // Carrega instruções de navegação no idioma selecionado
    beaconDoDestino = nav.getBeaconDoDestino(widget.destino); // Obtém o beacon associado ao destino
    iniciarScan(); // Inicia o processo de scan de beacons
  }

  // Carrega as definições do utilizador guardadas em preferências
  Future<void> _loadSettings() async {
    final settings = await _preferencesHelper.loadSoundSettings();
    setState(() {
      selectedLanguageCode = settings['selectedLanguageCode'] ?? 'pt-PT';
      soundEnabled = settings['soundEnabled'];
      vibrationEnabled = settings['vibrationEnabled'];
      voiceSpeed = settings['voiceSpeed'] ?? 0.6;
      voicePitch = settings['voicePitch'] ?? 1.0;
    });
    await _carregarMensagens();  // Carrega mensagens de voz localizadas conforme o idioma
  }

  // Carrega o ficheiro JSON com as mensagens de voz correspondentes ao idioma
  Future<void> _carregarMensagens() async {
    String langCode = selectedLanguageCode.toLowerCase().split('-')[0];
    String fullCode = selectedLanguageCode.toLowerCase().replaceAll('_', '-');
    List<String> paths = [
      'assets/tts/navigation/nav_$fullCode.json',
      'assets/tts/navigation/nav_$langCode.json',
      'assets/tts/navigation/nav_en.json', // fallback para inglês
    ];

    String? jsonString;
    for (String path in paths) {
      try {
        jsonString = await rootBundle.loadString(path);
        break; // Sai assim que encontrar o primeiro válido
      } catch (_) {}
    }
    setState(() {
      mensagens = jsonString != null ? json.decode(jsonString) : {};
      status = mensagens['alerts']?['searching_alert'] ?? ''; // Mensagem "A procurar..."
    });
  }

  // Inicia o scan por beacons Bluetooth
  void iniciarScan() {
    FlutterBluePlus.startScan(); // Inicia o scan

    // Escuta os resultados do scan em tempo real
    FlutterBluePlus.scanResults.listen((results) async {
      if (chegou || isNavigationCanceled || isFinalizing) return; // Ignora se a navegação já terminou

      for (final result in results) {
        final beacon = nav.parseBeaconData(result); // Tenta interpretar os dados do beacon
        if (beacon == null) continue;

        final local = nav.getLocalizacao(beacon); // Converte para localização conhecida
        if (local == null) continue;

        final agora = DateTime.now();
        if (ultimaDetecao != null && agora.difference(ultimaDetecao!) < cooldown && local == localAtual) {
          continue; // Aplica cooldown para evitar spam de leituras repetidas
        }

        ultimaDetecao = agora;

        // 🔹 Caso 1: o utilizador já está no beacon do destino e não há rota definida
        if (rota.isEmpty) {
          if (local == nav.getBeaconDoDestino(widget.destino)) {
            isFinalizing = true;

            print('[DEBUG] Já está no beacon do destino: $local');

            if (vibrationEnabled) {
              print('[DEBUG] Vibração curta - já está no beacon do destino');
              Vibration.vibrate(duration: 400);
            }

            // Busca a instrução associada diretamente ao beacon final
            final instrucaoDireta = nav.buscarInstrucaoNoBeacon(local, widget.destino);
            if (instrucaoDireta != null && instrucaoDireta.isNotEmpty) {
              print('[DEBUG] A falar instrução direta: $instrucaoDireta');
              // Atualiza a visualização com a seta no local
              atualizarPosicaoVisual(local); // 👉 Mostra seta
              setState(() {
                mostrarSeta = true;
              });
              await falar(instrucaoDireta);  // Fala a instrução de chegada
            }

            // Encerra o scan de Bluetooth
            FlutterBluePlus.stopScan();
            print('[DEBUG] Scan parado - navegação concluída');
            if (vibrationEnabled) {
              print('[DEBUG] Vibração longa - navegação concluída');
              Vibration.vibrate(duration: 600);
            }

            setState(() {
              chegou = true; // Atualiza o estado indicando que o utilizador chegou ao destino
              status = 'beacon_scan_page.navigation_end'.tr(); // Mostra mensagem traduzida de fim de navegação
            });

            // Fala a mensagem final de navegação (ex: "Navegação concluída.")
            await falar(mensagens['alerts']?['navigation_end_alert'] ?? 'Navegação concluída.');
            return;
          } else {
            // 🔹 Caso o utilizador esteja num beacon inicial mas ainda não está no destino
            // Gerar a rota do beacon atual até ao destino usando o algoritmo de Dijkstra
            final caminho = nav.dijkstra(local, widget.destino);

            // Se o caminho for válido e tiver mais de um passo
            if (caminho != null && caminho.length > 1) {
              rota = caminho; // Define a rota
              proximoPasso = 1; // Define o próximo passo (posição 1 da rota)
              localAtual = local; // Guarda a localização atual

              atualizarPosicaoVisual(local); // Atualiza a seta no mapa

              final instrucao = nav.getInstrucoes(caminho)[0]; // Pega a primeira instrução
              print('[DEBUG] Instrução inicial: $instrucao');
              await falar(instrucao); // Fala a primeira instrução

              if (vibrationEnabled) {
                print('[DEBUG] Vibração curta - início de navegação');
                Vibration.vibrate(duration: 400); // Vibração para indicar início da rota
              }

              setState(() {
                mostrarSeta = true; // Ativa visualização da seta
              });
            } else {
              // Se não for possível calcular o caminho até o destino
              print('[DEBUG] Caminho não encontrado.');
              await falar(mensagens['alerts']?['path_not_found_alert'] ?? 'Caminho não encontrado.');
              finalizar(); // Encerra o processo de navegação
            }
            return;
          }
        }

        // 🔹 Caso 2: O utilizador está a meio do percurso (não é início nem destino)
        if (proximoPasso < rota.length && local == rota[proximoPasso]) {
          localAtual = local; // Atualiza a localização atual
          atualizarPosicaoVisual(local); // Atualiza visual no mapa (ex. seta)

          // Verifica se este beacon leva diretamente ao destino
          final destinosDoBeaconAtual = List<String>.from(
            nav.jsonBeacons[localAtual]?['beacon_destinations'] ?? [],
          );

          // 🔸 Se for o último passo antes do destino
          if (!isFinalizing && destinosDoBeaconAtual.contains(widget.destino)) {
            isFinalizing = true; // Impede novas instruções ou atualizações

            if (vibrationEnabled) {
              print('[DEBUG] Vibração curta - último passo');
              Vibration.vibrate(duration: 400); // Vibração curta para indicar chegada iminente
            }

            // Busca a instrução específica do beacon para o destino (ex: "Chegou ao Auditório")
            final instrucaoFinal = nav.buscarInstrucaoNoBeacon(localAtual!, widget.destino);
            if (instrucaoFinal != null && instrucaoFinal.isNotEmpty) {
              print('[DEBUG] Instrução direta de beacon para destino: $instrucaoFinal');
              await falar(instrucaoFinal); // Fala a instrução final
            }

            // Finaliza o scan
            FlutterBluePlus.stopScan();
            print('[DEBUG] Scan parado - navegação concluída');

            if (vibrationEnabled) {
              print('[DEBUG] Vibração longa - navegação concluída');
              Vibration.vibrate(duration: 600); // Vibração longa para indicar fim de navegação
            }

            // Atualiza estado para refletir que a navegação terminou
            setState(() {
              chegou = true;
              status = 'beacon_scan_page.navigation_end'.tr();
            });

            // Fala a mensagem de fim de navegação
            await falar(mensagens['alerts']?['navigation_end_alert'] ?? 'Navegação concluída.');
            return;
          }

          // 🔸 Caso intermédio: ainda está a seguir o percurso, mas não é o último beacon
          if (!isFinalizing) {
            final instrucao = nav.getInstrucoes(rota)[proximoPasso]; // Busca instrução da etapa atual
            print('[DEBUG] Instrução intermédia: $instrucao');

            if (vibrationEnabled) {
              print('[DEBUG] Vibração curta - passo intermédio');
              Vibration.vibrate(duration: 400); // Vibração curta como feedback
            }

            await falar(instrucao); // Fala a instrução da etapa atual
            proximoPasso++; // Avança para o próximo passo da rota
          }

          return; // Termina processamento deste ciclo
        }
      }
    });
  }



  void atualizarPosicaoVisual(String local) {
    final newPosition = beaconPositions[local] ?? const Offset(300, 500); // Obtém a nova posição do beacon (ou posição padrão se não estiver no mapa)
    final delta = newPosition - currentPosition; // Calcula o vetor entre a posição atual e a nova
    final angle = math.atan2(delta.dy, delta.dx) + math.pi / 2; // Calcula o ângulo de rotação com base no vetor de movimento (em radianos)

    // Define a animação de movimento da câmara (suaviza o movimento no mapa)
    _cameraAnimation = Tween<Offset>(begin: cameraOffset, end: newPosition).animate(
      CurvedAnimation(parent: _cameraController, curve: Curves.easeInOut),
    )..addListener(() {
      setState(() { // Atualiza a posição da câmara animada
        cameraOffset = _cameraAnimation.value;
      });
    });

    _cameraController.forward(from: 0); // Inicia a animação da câmara

    setState(() { // Atualiza os estados visuais da posição e seta
      previousPosition = currentPosition;
      currentPosition = newPosition;
      rotationAngle = angle;      // Atualiza rotação da seta
      mostrarSeta = true;         // Mostra a seta no ecrã
    });
  }

  void finalizar() {
    FlutterBluePlus.stopScan(); // Encerra o scan de beacons
    chegou = true;              // Marca que o destino foi alcançado

    if (vibrationEnabled) { // Se o dispositivo suportar vibração, ativa vibração longa
      Vibration.hasVibrator().then((hasVibrator) {
        if (hasVibrator ?? false) Vibration.vibrate(duration: 600);
      });
    }
  }

  Future<void> falar(String texto) async {
    if (soundEnabled && texto.isNotEmpty) { // Se o som estiver ativado e houver texto válido
      setState(() {
        ultimaInstrucaoFalada = texto; // Guarda o último texto falado
      });

      await flutterTts.stop();                        // Garante que não sobrepõe falas
      await flutterTts.setLanguage(selectedLanguageCode); // Define idioma
      await flutterTts.setSpeechRate(voiceSpeed);     // Define velocidade da fala
      await flutterTts.setPitch(voicePitch);          // Define tom da fala
      await flutterTts.speak(texto);                  // Fala o texto
    }
  }

  void cancelarNavegacao() {
    setState(() {
      isNavigationCanceled = true; // Marca navegação como cancelada
      status = mensagens['alerts']?['navigation_cancelled_alert'] ?? ''; // Mensagem de cancelamento
    });

    FlutterBluePlus.stopScan(); // Para o scan de beacons
    flutterTts.stop();          // Para qualquer fala em andamento

    Navigator.pop(context);     // Volta à página anterior
  }

  void mostrarDescricao() async {
    if (localAtual != null && mensagens['beacons']?[localAtual] != null) { // Verifica se há um beacon atual detetado e se tem descrição
      final descricao = mensagens['beacons']?[localAtual]?['beacon_description'];

      if (descricao != null && descricao.isNotEmpty) {
        print('[DEBUG] A falar descrição do beacon atual: $descricao');
        await falar(descricao); // Fala a descrição associada ao beacon
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
    flutterTts.stop();                // Para qualquer fala pendente
    FlutterBluePlus.stopScan();      // Para o scan de beacons
    _cameraController.dispose();     // Liberta recursos da animação
    super.dispose();                 // Chama o metodo base
  }

  String obterLocalAtual() {
    // Retorna o nome do local atual, ou a mensagem "A procurar..." se ainda não houver localização
    return localAtual ?? (mensagens['alerts']?['searching_alert'] ?? '');
  }

  String obterProximaParagem() {
    if (rota.isEmpty || proximoPasso >= rota.length) { // Se a rota estiver vazia ou o índice estiver fora dos limites, retorna mensagem de fim
      return mensagens['alerts']?['end_of_route_alert'] ?? '';
    }
    return rota[proximoPasso]; // Caso contrário, retorna o próximo beacon da rota
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: InteractiveViewer(
              panEnabled: true, // Permite arrastar
              scaleEnabled: true, // Permite zoom
              minScale: 1.0,
              maxScale: 3.5,
              constrained: false,
              boundaryMargin: const EdgeInsets.all(100), // Margem ao arrastar
              child: Stack(
                children: [
                  // Aplica offset da câmara ao mapa
                  Transform.translate(
                    offset: Offset(-cameraOffset.dx + 150, -cameraOffset.dy + 320),
                    child: Stack(
                      children: [
                        // Imagem do piso atual
                        Image.asset(
                          imagensPorPiso[currentFloor]!,
                          fit: BoxFit.none,
                          alignment: Alignment.topLeft,
                        ),
                        // Seta animada para mostrar a posição atual
                        if (mostrarSeta)
                          AnimatedPositioned(
                            duration: const Duration(milliseconds: 1000),
                            curve: Curves.easeInOut,
                            left: currentPosition.dx,
                            top: currentPosition.dy,
                            child: Transform.rotate(
                              angle: rotationAngle, // Aponta na direção do movimento
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

          // Widget deslizante na parte inferior da tela (como uma folha que pode ser expandida)
          DraggableScrollableSheet(
            minChildSize: 0.20,  // Altura mínima (20% da tela)
            maxChildSize: 0.32,  // Altura máxima (32% da tela)
            initialChildSize: 0.32,  // Altura inicial ao abrir a página
            builder: (context, controller) {
              return Container(
                padding: const EdgeInsets.all(16),  // Espaçamento interno do painel
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.95),  // Fundo branco com ligeira transparência
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),  // Cantos arredondados no topo
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black26,  // Sombra leve
                      blurRadius: 6,          // Suaviza a sombra
                    ),
                  ],
                ),
                child: SingleChildScrollView(
                  controller: controller,  // Controlador que sincroniza com o deslize da folha
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,  // Centraliza conteúdo horizontalmente
                    children: [
                      // Título com o destino selecionado, traduzido
                      Text(
                        '${'beacon_scan_page.destination'.tr()}: ${widget.destino}',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 20),  // Espaço entre o título e os próximos widgets
                      if (!chegou) ...[ // Se ainda não chegou ao destino, mostra informação do estado atual
                        Container(
                          padding: const EdgeInsets.all(12), // Espaçamento interno
                          decoration: BoxDecoration(
                            // Cor de fundo muda conforme se há ou não instrução falada
                            color: ultimaInstrucaoFalada.isEmpty ? Colors.yellow[100] : Colors.blue[100],
                            borderRadius: BorderRadius.circular(10), // Cantos arredondados
                          ),
                          child: Row(
                            children: [
                              // Ícone que representa o estado atual: alerta ou voz
                              Icon(
                                ultimaInstrucaoFalada.isEmpty ? Icons.warning : Icons.campaign, // Se não há fala → alerta, senão → megafone
                                color: ultimaInstrucaoFalada.isEmpty ? Colors.orange : Colors.blue, // Cor de acordo com o ícone
                                size: 30,
                              ),
                              const SizedBox(width: 10), // Espaço entre ícone e texto
                              Expanded(
                                child: Center(
                                  child: Text(
                                    // Mostra a última instrução falada ou a mensagem "A procurar..."
                                    ultimaInstrucaoFalada.isNotEmpty
                                        ? ultimaInstrucaoFalada
                                        : '${mensagens['alerts']?['searching_alert'] ?? 'A procurar...'}',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      // Cor muda conforme há ou não instrução falada
                                      color: ultimaInstrucaoFalada.isEmpty ? Colors.orange[900] : Colors.blue[900],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ]
                      else ...[ // Caso o utilizador já tenha chegado ao destino
                        // Mostra mensagem de navegação concluída
                        Container(
                          padding: const EdgeInsets.all(12), // Espaçamento interno
                          decoration: BoxDecoration(
                            color: Colors.green[100], // Fundo verde claro para indicar sucesso
                            borderRadius: BorderRadius.circular(10), // Cantos arredondados
                          ),
                          child: Row(
                              children: [
                              // Ícone de sucesso (check verde)
                              const Icon(Icons.check_circle, color: Colors.green, size: 30),
                          const SizedBox(width: 10), // Espaço entre ícone e texto
                          Expanded(
                            child: Center(
                              child: Text(
                                status, // Mensagem de estado (ex: "Navegação concluída.")
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,)
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 20), // Espaçamento vertical antes da linha de botões

                      Row(
                        children: [
                          // 📘 Botão para ouvir a descrição do local atual
                          Expanded( // Ocupa metade da largura disponível
                            child: ElevatedButton.icon(
                              onPressed: mostrarDescricao, // Chama a função que lê a descrição do beacon atual
                              icon: const Icon(Icons.info), // Ícone de informação
                              label: Text('beacon_scan_page.description'.tr()), // Texto traduzido do botão
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blueAccent, // Fundo azul
                                foregroundColor: Colors.white, // Texto e ícone brancos
                              ),
                            ),
                          ),

                          const SizedBox(width: 10), // Espaço entre os dois botões

                          // ❌ Botão para cancelar a navegação
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: cancelarNavegacao, // Chama a função para cancelar e sair da navegação
                              icon: const Icon(Icons.cancel), // Ícone de cancelamento
                              label: Text('beacon_scan_page.cancel_navigation'.tr()), // Texto traduzido do botão
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.redAccent, // Fundo vermelho
                                foregroundColor: Colors.white, // Texto e ícone brancos
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
