import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'beacon_scan_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
    'sala 10': 'Sala 10',
    'cafeteria': 'Cafeteria',
  };

  final Set<String> destinosComBeacon = {'Entrada', 'Pátio', 'Corredor 1'};

  String? destinoSelecionado;
  late stt.SpeechToText _speech;
  final FlutterTts _tts = FlutterTts();
  bool _speechAvailable = false;
  bool _isListening = false;

  // Lista para armazenar os favoritos
  List<String> favoritos = [];
  List<String> destinosDisponiveis = [
    'Entrada',
    'Corredor 1',
    'Pátio',
    'Cafeteria',
    'Sala 10'
  ]; // Todos os destinos são disponíveis inicialmente

  @override
  void initState() {
    super.initState();
    _initSpeech();
    _initTTS();
    _loadFavorites(); // Carregar os favoritos armazenados ao iniciar
  }

  // Inicializar o reconhecimento de voz
  Future<void> _initSpeech() async {
    _speech = stt.SpeechToText();
    _speechAvailable = await _speech.initialize(
      onStatus: (status) => print('[STATUS] $status'),
      onError: (error) => print('[ERRO] $error'),
    );
  }

  // Inicializar o TTS (Texto para fala)
  Future<void> _initTTS() async {
    await _tts.setLanguage('pt-BR'); // Alterado para pt-BR (português do Brasil)
    await _tts.setSpeechRate(0.4);
    await _tts.setPitch(1.0);
  }

  // Função para adicionar favoritos
  void _adicionarFavorito(String destino) {
    setState(() {
      if (!favoritos.contains(destino)) {
        favoritos.add(destino);
        destinosDisponiveis.remove(destino); // Remove o destino dos disponíveis
        _saveFavorites(); // Salvar os favoritos sempre que houver uma alteração
      }
    });
  }

  // Função para remover favoritos
  void _removerFavorito(String destino) {
    setState(() {
      favoritos.remove(destino);
      destinosDisponiveis.add(destino); // Adiciona de volta aos disponíveis
      _saveFavorites(); // Salvar os favoritos sempre que houver uma alteração
    });
  }

  // Função para salvar os favoritos usando SharedPreferences
  Future<void> _saveFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('favoritos', favoritos); // Armazenar a lista de favoritos
  }

  // Função para carregar os favoritos do SharedPreferences
  Future<void> _loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      favoritos = prefs.getStringList('favoritos') ?? []; // Carregar favoritos, se existirem
      destinosDisponiveis.removeWhere((destino) => favoritos.contains(destino)); // Remover os favoritos dos destinos disponíveis
    });
  }

  // Função para exibir o pop-up com os destinos disponíveis
  void _mostrarAdicionarFavorito() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Adicionar aos Favoritos'),
          content: SingleChildScrollView(
            child: ListBody(
              children: destinosDisponiveis.map((destino) {
                return ListTile(
                  title: Text(destino),
                  onTap: () {
                    _adicionarFavorito(destino);
                    Navigator.of(context).pop(); // Fecha o pop-up após adicionar
                  },
                );
              }).toList(),
            ),
          ),
        );
      },
    );
  }

  // Função para capturar o comando de voz
  Future<void> _ouvirComando() async {
    if (!_speechAvailable) return;

    setState(() => _isListening = true);

    // Iniciar escuta com o idioma pt-BR
    await _speech.listen(
      localeId: 'pt-BR', // Alterado para o português do Brasil
      listenMode: stt.ListenMode.dictation,
      onResult: (result) async {
        final textoReconhecido = result.recognizedWords.toLowerCase().trim();
        print('Reconhecido: $textoReconhecido');

        // Verificar se o texto reconhecido contém algum destino
        for (final entrada in destinosMap.entries) {
          if (textoReconhecido.contains(entrada.key)) {
            final destino = entrada.value;

            if (destinosComBeacon.contains(destino)) {
              setState(() {
                destinoSelecionado = destino;
                _isListening = false;
              });
              await _speech.stop();
              await _tts.speak("Ok, vamos começar.");
              await Future.delayed(const Duration(seconds: 2));
              if (!mounted) return;
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => BeaconScanPage(
                    destino: destino,
                    destinosMap: destinosMap, // Passando destinosMap para BeaconScanPage
                  ),
                ),
              );
              return;
            }
          }
        }

        await _speech.stop();
        setState(() => _isListening = false);
        await _tts.speak("Destino não se encontra disponível. Repita, por favor.");
      },
    );
  }

  String get imagemPiso {
    return 'assets/images/map/00_piso.png'; // Piso fixo no 0
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Mapa
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
          // Bloco deslizante de pesquisa e navegação
          DraggableScrollableSheet(
            minChildSize: 0.20,
            maxChildSize: 0.40,
            initialChildSize: 0.40,
            builder: (context, controller) {
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.95),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                  boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 6)],
                ),
                child: SingleChildScrollView(
                  controller: controller,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Para onde deseja ir?',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 10),
                      // Dropdown para selecionar o destino
                      DropdownButtonFormField<String>(
                        decoration: const InputDecoration(border: OutlineInputBorder()),
                        value: destinoSelecionado,
                        hint: const Text('Selecionar destino'),
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
                      // Botões alinhados na mesma linha
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          ElevatedButton.icon(
                            onPressed: destinoSelecionado == null
                                ? null
                                : () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => BeaconScanPage(
                                    destino: destinoSelecionado!,
                                    destinosMap: destinosMap, // Passando destinosMap
                                  ),
                                ),
                              );
                            },
                            icon: const Icon(Icons.navigation),
                            label: const Text('Iniciar Navegação'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                            ),
                          ),
                          ElevatedButton.icon(
                            onPressed: _ouvirComando,
                            icon: const Icon(Icons.mic),
                            label: const Text('Por Voz'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      const Text('Favoritos',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      // Exibir favoritos em linha horizontal com possibilidade de deslizar
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
                                        _tts.speak("Destino selecionado: $favorito");
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
                                            child: Container(
                                              width: 22,
                                              height: 22,
                                              child: const Center(
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
                            // Botão para adicionar mais favoritos
                            Padding(
                              padding: const EdgeInsets.only(right: 10, top:5),
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

          // Botão de retroceder
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
