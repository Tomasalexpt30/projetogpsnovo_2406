/// Importações necessárias para trabalhar com JSON, assets locais e Bluetooth
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

/// Classe que representa um beacon individual com UUID, major, minor e endereço MAC
class BeaconInfo {
  final String uuid;
  final int major;
  final int minor;
  final String macAddress;

  // Construtor
  BeaconInfo(this.uuid, this.major, this.minor, this.macAddress);

  // Sobrescreve o operador de igualdade para comparar beacons corretamente
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is BeaconInfo &&
              runtimeType == other.runtimeType &&
              uuid == other.uuid &&
              major == other.major &&
              minor == other.minor &&
              macAddress.toUpperCase() == other.macAddress.toUpperCase();

  // Sobrescreve o hashCode para suportar utilização em Mapas e Sets
  @override
  int get hashCode =>
      uuid.hashCode ^ major.hashCode ^ minor.hashCode ^ macAddress.toUpperCase().hashCode;
}

/// Classe responsável por gerir a lógica de navegação com base em beacons
class NavigationManager {
  /// Mapa que associa cada beacon (por BeaconInfo) ao seu identificador lógico
  final Map<BeaconInfo, String> beaconLocations = {
    BeaconInfo('fda50693-a4e2-4fb1-afcf-c6eb07647825', 1, 2, '51:00:24:12:01:CA'): 'Beacon 1',
    BeaconInfo('fda50693-a4e2-4fb1-afcf-c6eb07647825', 1, 2, '51:00:24:12:01:E3'): 'Beacon 3',
    BeaconInfo('fda50693-a4e2-4fb1-afcf-c6eb07647825', 1, 2, '51:00:24:12:01:B2'): 'Beacon 15',
  };

  Map<String, Map<String, int>> mapaFaculdade = {}; // Grafo com as ligações entre beacons e destinos
  Map<String, String> instrucoesCarregadas = {}; // Instruções já traduzidas para o TTS
  Map<String, dynamic> jsonBeacons = {}; // Dados completos carregados do JSON

  /// Carrega o ficheiro de instruções com base no idioma selecionado
  Future<void> carregarInstrucoes(String selectedLanguageCode) async {
    String langCode = selectedLanguageCode.toLowerCase().split('-')[0];  // ex: pt
    String fullCode = selectedLanguageCode.toLowerCase().replaceAll('_', '-'); // ex: pt-pt

    // Tenta carregar primeiro o mais específico, depois mais genérico, por fim inglês
    List<String> paths = [
      'assets/tts/navigation/nav_$fullCode.json',
      'assets/tts/navigation/nav_$langCode.json',
      'assets/tts/navigation/nav_en.json',
    ];

    String? jsonString;
    for (String path in paths) {
      try {
        jsonString = await rootBundle.loadString(path); // Tenta carregar o ficheiro
        break;
      } catch (_) {}
    }

    // Decodifica o JSON carregado
    final Map<String, dynamic> jsonData = jsonString != null ? json.decode(jsonString) : {};
    instrucoesCarregadas = Map<String, String>.from(jsonData['instructions'] ?? {});
    jsonBeacons = jsonData['beacons'] ?? {};

    _construirMapa(); // Constrói o grafo com base nos dados carregados
  }

  /// Constrói o grafo de navegação com base nos beacons operacionais
  void _construirMapa() {
    mapaFaculdade.clear();

    // Lista dos beacons ativos
    List<String> beaconsOperacionais = ['Beacon 1', 'Beacon 3', 'Beacon 15'];

    for (var beaconKey in beaconsOperacionais) {
      if (jsonBeacons.containsKey(beaconKey)) {
        final beaconData = jsonBeacons[beaconKey];
        final destinos = List<String>.from(beaconData['beacon_destinations'] ?? []);
        final conexoes = List<String>.from(beaconData['beacon_connections'] ?? []);

        mapaFaculdade[beaconKey] = {};

        // Adiciona conexões diretas entre beacons
        for (var conexao in conexoes) {
          if (beaconsOperacionais.contains(conexao)) {
            mapaFaculdade[beaconKey]![conexao] = 1;
          }
        }

        // Adiciona destinos como nós do grafo com ligação ao beacon
        for (var destino in destinos) {
          mapaFaculdade[beaconKey]![destino] = 1;
          mapaFaculdade[destino] = {beaconKey: 1}; // Ligação reversa para o algoritmo funcionar
        }
      }
    }
  }

  /// Devolve o nome lógico de um beacon detetado, se existir
  String? getLocalizacao(BeaconInfo beacon) {
    return beaconLocations[beacon];
  }

  /// Algoritmo de Dijkstra para calcular o caminho mais curto entre dois pontos
  List<String>? dijkstra(String origem, String destino) {
    final dist = <String, int>{};
    final prev = <String, String?>{};
    final nodes = mapaFaculdade.keys.toSet();
    final unvisited = Set<String>.from(nodes);

    for (var node in nodes) {
      dist[node] = node == origem ? 0 : 1 << 30;
      prev[node] = null;
    }

    while (unvisited.isNotEmpty) {
      // Seleciona o nó com menor distância atual
      final current = unvisited.reduce((a, b) => dist[a]! < dist[b]! ? a : b);
      if (current == destino) break;
      unvisited.remove(current);

      mapaFaculdade[current]?.forEach((neighbor, weight) {
        if (unvisited.contains(neighbor)) {
          final alt = dist[current]! + weight;
          if (alt < dist[neighbor]!) {
            dist[neighbor] = alt;
            prev[neighbor] = current;
          }
        }
      });
    }

    // Reconstrói o caminho
    final path = <String>[];
    String? u = destino;
    while (u != null) {
      path.insert(0, u);
      u = prev[u];
    }

    return path.isNotEmpty && path.first == origem ? path : null;
  }

  /// Obtém as instruções de navegação para um determinado caminho
  List<String> getInstrucoes(List<String> caminho) {
    final instr = <String>[];

    for (var i = 0; i < caminho.length - 1; i++) {
      final chave = '${caminho[i]}-${caminho[i + 1]}';

      if (instrucoesCarregadas.containsKey(chave)) {
        instr.add(instrucoesCarregadas[chave]!);
      } else {
        // Se não houver instrução no ficheiro traduzido, tenta buscar no JSON original
        final instruction = buscarInstrucaoNoBeacon(caminho[i], caminho[i + 1]);
        if (instruction != null && instruction.isNotEmpty) {
          instr.add(instruction);
        }
      }
    }

    return instr;
  }

  /// Procura a instrução diretamente no JSON original se não estiver pré-carregada
  String? buscarInstrucaoNoBeacon(String origem, String destino) {
    if (jsonBeacons.containsKey(origem)) {
      final instructions = jsonBeacons[origem]['beacon_instructions'] ?? {};
      final chave = '$origem-$destino';
      return instructions[chave] ?? '';
    }
    return '';
  }

  /// Verifica se o próximo passo é um destino final (não é outro beacon)
  bool isDestinoFinal(String localAtual, String proximoPasso) {
    if (jsonBeacons.containsKey(localAtual)) {
      final destinos = List<String>.from(jsonBeacons[localAtual]['beacon_destinations'] ?? []);
      return destinos.contains(proximoPasso);
    }
    return false;
  }

  /// Encontra o beacon responsável por um destino final
  String? getBeaconDoDestino(String destino) {
    for (var beaconKey in jsonBeacons.keys) {
      final destinos = List<String>.from(jsonBeacons[beaconKey]['beacon_destinations'] ?? []);
      if (destinos.contains(destino)) {
        return beaconKey;
      }
    }
    return null;
  }

  /// Extrai a informação de um beacon a partir de um resultado Bluetooth
  BeaconInfo? parseBeaconData(ScanResult result) {
    final md = result.advertisementData.manufacturerData;
    if (md.isEmpty) return null;

    // Verifica se o pacote iBeacon está presente (Apple: 0x004C = 76)
    if (!md.containsKey(76)) return null;

    final data = md[76]!;
    if (data.length < 23) return null;

    // Extrai e formata UUID
    final uuidBytes = data.sublist(2, 18);
    final uuid = uuidBytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    final formattedUuid =
        '${uuid.substring(0, 8)}-${uuid.substring(8, 12)}-${uuid.substring(12, 16)}-${uuid.substring(16, 20)}-${uuid.substring(20)}';

    // Extrai major e minor
    final major = (data[18] << 8) + data[19];
    final minor = (data[20] << 8) + data[21];

    // Extrai MAC address
    final mac = result.device.id.id.toUpperCase();

    print('[DEBUG] Beacon detetado → UUID: $formattedUuid | Major: $major | Minor: $minor | MAC: $mac');

    return BeaconInfo(formattedUuid, major, minor, mac);
  }
}
