import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class BeaconInfo {
  final String uuid;
  final int major;
  final int minor;
  final String macAddress;

  BeaconInfo(this.uuid, this.major, this.minor, this.macAddress);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is BeaconInfo &&
              runtimeType == other.runtimeType &&
              uuid == other.uuid &&
              major == other.major &&
              minor == other.minor &&
              macAddress.toUpperCase() == other.macAddress.toUpperCase();

  @override
  int get hashCode =>
      uuid.hashCode ^ major.hashCode ^ minor.hashCode ^ macAddress.toUpperCase().hashCode;
}

class NavigationManager {
  final Map<BeaconInfo, String> beaconLocations = {
    BeaconInfo('fda50693-a4e2-4fb1-afcf-c6eb07647825', 10001, 1, 'FF:87:6D:60:E2:CE'): 'Beacon 1',
    BeaconInfo('fda50693-a4e2-4fb1-afcf-c6eb07647825', 10001, 2, 'DC:ED:EA:6E:0B:2D'): 'Beacon 3',
    BeaconInfo('fda50693-a4e2-4fb1-afcf-c6eb07647825', 10001, 3, 'F2:29:76:B1:E1:4D'): 'Beacon 15',
  };

  Map<String, Map<String, int>> mapaFaculdade = {};
  Map<String, String> instrucoesCarregadas = {};
  Map<String, dynamic> jsonBeacons = {};

  /// Carrega as instruções e o mapa com as conexões e destinos dos beacons operacionais
  Future<void> carregarInstrucoes(String selectedLanguageCode) async {
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

    final Map<String, dynamic> jsonData = jsonString != null ? json.decode(jsonString) : {};
    instrucoesCarregadas = Map<String, String>.from(jsonData['instructions'] ?? {});
    jsonBeacons = jsonData['beacons'] ?? {};

    _construirMapa();
  }

  /// Constrói o mapa considerando apenas os beacons operacionais
  void _construirMapa() {
    mapaFaculdade.clear();

    List<String> beaconsOperacionais = ['Beacon 1', 'Beacon 3', 'Beacon 15'];

    for (var beaconKey in beaconsOperacionais) {
      if (jsonBeacons.containsKey(beaconKey)) {
        final beaconData = jsonBeacons[beaconKey];
        final destinos = List<String>.from(beaconData['beacon_destinations'] ?? []);
        final conexoes = List<String>.from(beaconData['beacon_connections'] ?? []);

        mapaFaculdade[beaconKey] = {};

        // Adiciona conexões
        for (var conexao in conexoes) {
          if (beaconsOperacionais.contains(conexao)) {
            mapaFaculdade[beaconKey]![conexao] = 1; // Distância arbitrária
          }
        }

        // Adiciona destinos como nós diretos (para que Dijkstra funcione)
        for (var destino in destinos) {
          mapaFaculdade[beaconKey]![destino] = 1; // Distância arbitrária
          mapaFaculdade[destino] = {beaconKey: 1}; // Ligação reversa
        }
      }
    }
  }

  String? getLocalizacao(BeaconInfo beacon) {
    return beaconLocations[beacon];
  }

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

    final path = <String>[];
    String? u = destino;
    while (u != null) {
      path.insert(0, u);
      u = prev[u];
    }

    return path.isNotEmpty && path.first == origem ? path : null;
  }

  List<String> getInstrucoes(List<String> caminho) {
    final instr = <String>[];

    for (var i = 0; i < caminho.length - 1; i++) {
      final chave = '${caminho[i]}-${caminho[i + 1]}';
      if (instrucoesCarregadas.containsKey(chave)) {
        instr.add(instrucoesCarregadas[chave]!);
      } else {
        // Se não houver instrução carregada, tenta buscar no beacon_instructions
        final instruction = buscarInstrucaoNoBeacon(caminho[i], caminho[i + 1]);
        if (instruction != null && instruction.isNotEmpty) {
          instr.add(instruction);
        }
      }
    }

    return instr;
  }

  /// Busca a instrução no JSON original se não tiver sido carregada para TTS
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

  /// Devolve o beacon associado a um destino
  String? getBeaconDoDestino(String destino) {
    for (var beaconKey in jsonBeacons.keys) {
      final destinos = List<String>.from(jsonBeacons[beaconKey]['beacon_destinations'] ?? []);
      if (destinos.contains(destino)) {
        return beaconKey;
      }
    }
    return null;
  }

  BeaconInfo? parseBeaconData(ScanResult result) {
    final md = result.advertisementData.manufacturerData;
    if (md.isEmpty) return null;

    if (!md.containsKey(76)) return null;
    final data = md[76]!;

    if (data.length < 23) return null;

    final uuidBytes = data.sublist(2, 18);
    final uuid = uuidBytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    final formattedUuid =
        '${uuid.substring(0, 8)}-${uuid.substring(8, 12)}-${uuid.substring(12, 16)}-${uuid.substring(16, 20)}-${uuid.substring(20)}';

    final major = (data[18] << 8) + data[19];
    final minor = (data[20] << 8) + data[21];

    final mac = result.device.id.id.toUpperCase();

    print('[DEBUG] Beacon detetado → UUID: $formattedUuid | Major: $major | Minor: $minor | MAC: $mac');

    return BeaconInfo(formattedUuid, major, minor, mac);
  }
}
