import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';


class BeaconInfo {
  final String uuid;        // identificador único do beacon
  final int major;          // número major do beacon (grupo ou zona)
  final int minor;          // número minor do beacon (identificador específico)
  final String macAddress; // endereço MAC do dispositivo

  BeaconInfo(this.uuid, this.major, this.minor, this.macAddress);

  @override
  bool operator ==(Object other) =>
      identical(this, other) || // verifica se é exatamente o mesmo objeto
          other is BeaconInfo &&
              runtimeType == other.runtimeType &&
              uuid == other.uuid &&
              major == other.major &&
              minor == other.minor &&
              macAddress.toUpperCase() == other.macAddress.toUpperCase(); // comparação sem diferenciar maiúsculas/minúsculas no MAC

  @override
  int get hashCode =>
      uuid.hashCode ^ major.hashCode ^ minor.hashCode ^ macAddress.toUpperCase().hashCode; // gera código hash para usar em mapas e sets
}

class NavigationManager {
  final Map<BeaconInfo, String> beaconLocations = {
    // mapeia BeaconInfo para nome (ex.: "Beacon 1")

    BeaconInfo('107e0a13-90f3-42bf-b980-181d93c3ccd2', 10001, 1,
        'FF:87:6D:60:E2:CE'): 'Beacon 1',
    BeaconInfo('107e0a13-90f3-42bf-b980-181d93c3ccd2', 10001, 3,
        'F2:29:76:B1:E1:4D'): 'Beacon 3',
    BeaconInfo('107e0a13-90f3-42bf-b980-181d93c3ccd2', 10001, 4,
        'FD:F3:6B:A2:22:DD'): 'Beacon 4',
    BeaconInfo('107e0a13-90f3-42bf-b980-181d93c3ccd2', 10001, 5,
        'EC:3B:82:29:F8:2D'): 'Beacon 5',
    BeaconInfo('107e0a13-90f3-42bf-b980-181d93c3ccd2', 10001, 6,
        'FA:93:62:AF:62:66'): 'Beacon 6',
    BeaconInfo('107e0a13-90f3-42bf-b980-181d93c3ccd2', 10000, 7,
        'E8:C5:D8:A6:E9:BA'): 'Beacon 7',
    BeaconInfo('107e0a13-90f3-42bf-b980-181d93c3ccd2', 10001, 8,
        'C3:8B:3B:92:A0:09'): 'Beacon 8',
    BeaconInfo('107e0a13-90f3-42bf-b980-181d93c3ccd2', 10001, 9,
        'DD:82:40:D0:83:6F'): 'Beacon 9',
    BeaconInfo('107e0a13-90f3-42bf-b980-181d93c3ccd2', 10000, 10,
        'DD:28:73:88:D8:D2'): 'Beacon 10',
    BeaconInfo('107e0a13-90f3-42bf-b980-181d93c3ccd2', 10000, 11,
        'E5:12:43:87:BE:A5'): 'Beacon 11',
    BeaconInfo('107e0a13-90f3-42bf-b980-181d93c3ccd2', 10000, 12,
        'C4:DF:3A:76:9C:CD'): 'Beacon 12',
    BeaconInfo('107e0a13-90f3-42bf-b980-181d93c3ccd2', 10000, 13,
        'D6:71:FD:D8:53:A1'): 'Beacon 13',
    BeaconInfo('107e0a13-90f3-42bf-b980-181d93c3ccd2', 10000, 14,
        'FE:FD:80:74:9B:00'): 'Beacon 14',
    BeaconInfo('107e0a13-90f3-42bf-b980-181d93c3ccd2', 10001, 15,
        'C2:C7:83:CD:77:6E'): 'Beacon 15',
    BeaconInfo('107e0a13-90f3-42bf-b980-181d93c3ccd2', 10001, 16,
        'F8:BE:75:76:4D:29'): 'Beacon 16',
    BeaconInfo('107e0a13-90f3-42bf-b980-181d93c3ccd2', 10001, 17,
        'C6:97:47:5A:8F:6C'): 'Beacon 17',
    BeaconInfo('107e0a13-90f3-42bf-b980-181d93c3ccd2', 10000, 18,
        'E3:1D:5F:D5:56:35'): 'Beacon 18',
    BeaconInfo('107e0a13-90f3-42bf-b980-181d93c3ccd2', 10002, 19,
        'F5:4B:CF:31:D5:A3'): 'Beacon 19',
    BeaconInfo('107e0a13-90f3-42bf-b980-181d93c3ccd2', 10002, 20,
        'F5:71:BD:7A:B9:A3'): 'Beacon 20',
    BeaconInfo('107e0a13-90f3-42bf-b980-181d93c3ccd2', 10003, 21,
        'C8:77:BE:A3:90:64'): 'Beacon 21',
    BeaconInfo('107e0a13-90f3-42bf-b980-181d93c3ccd2', 10001, 22,
        'E2:56:6F:02:0A:DD'): 'Beacon 22',
    BeaconInfo('107e0a13-90f3-42bf-b980-181d93c3ccd2', 10002, 23,
        'C7:68:90:86:BE:7B'): 'Beacon 23',
    BeaconInfo('107e0a13-90f3-42bf-b980-181d93c3ccd2', 10002, 24,
        'C3:EE:4E:EC:04:FF'): 'Beacon 24',
    BeaconInfo('107e0a13-90f3-42bf-b980-181d93c3ccd2', 10002, 25,
        'DB:DB:2C:2A:42:D4'): 'Beacon 25',
    BeaconInfo('107e0a13-90f3-42bf-b980-181d93c3ccd2', 10003, 26,
        'CA:EA:BC:7D:9E:E8'): 'Beacon 26',
    BeaconInfo('107e0a13-90f3-42bf-b980-181d93c3ccd2', 10002, 27,
        'CB:DD:F2:E9:BD:53'): 'Beacon 27',
    BeaconInfo('107e0a13-90f3-42bf-b980-181d93c3ccd2', 10002, 28,
        'E0:62:65:E0:D4:FB'): 'Beacon 28',
    BeaconInfo('107e0a13-90f3-42bf-b980-181d93c3ccd2', 10002, 29,
        'FF:B2:A4:E8:07:2B'): 'Beacon 29',
    BeaconInfo('107e0a13-90f3-42bf-b980-181d93c3ccd2', 10002, 30,
        'EB:9E:2E:26:D8:54'): 'Beacon 30',
    BeaconInfo('107e0a13-90f3-42bf-b980-181d93c3ccd2', 10003, 31,
        'F6:AD:B9:EA:40:63'): 'Beacon 31',
    BeaconInfo('107e0a13-90f3-42bf-b980-181d93c3ccd2', 10003, 32,
        'FE:31:74:78:F8:C9'): 'Beacon 32',
    BeaconInfo('107e0a13-90f3-42bf-b980-181d93c3ccd2', 10003, 33,
        'EB:C0:32:AE:59:7F'): 'Beacon 33',
    BeaconInfo('107e0a13-90f3-42bf-b980-181d93c3ccd2', 10003, 36,
        'DC:ED:EA:6E:0B:2D'): 'Beacon 36',
    BeaconInfo('107e0a13-90f3-42bf-b980-181d93c3ccd2', 10003, 37,
        'C5:14:B9:27:15:D0'): 'Beacon 37',
    BeaconInfo('107e0a13-90f3-42bf-b980-181d93c3ccd2', 10004, 38,
        'E1:AD:34:83:56:08'): 'Beacon 38',
  };
  Map<String, Map<String, int>> mapaFaculdade = {
  }; // mapa de conexões entre beacons
  Map<String, String> instrucoesCarregadas = {
  }; // instruções carregadas do JSON
  Map<String, dynamic> jsonBeacons = {}; // dados completos dos beacons do JSON

  Future<void> carregarInstrucoes(String selectedLanguageCode) async {
    String langCode = selectedLanguageCode.toLowerCase().split(
        '-')[0]; // ex.: pt
    String fullCode = selectedLanguageCode.toLowerCase().replaceAll(
        '_', '-'); // ex.: pt-PT

    List<String> paths = [
      // tenta carregar por ordem: código completo, código simples, inglês
      'assets/tts/navigation/nav_$fullCode.json',
      'assets/tts/navigation/nav_$langCode.json',
      'assets/tts/navigation/nav_en.json',
    ];

    String? jsonString;
    for (String path in paths) {
      try {
        jsonString = await rootBundle.loadString(path); // tenta ler ficheiro
        break;
      } catch (_) {}
    }

    final Map<String, dynamic> jsonData = jsonString != null ? json.decode(
        jsonString) : {};
    instrucoesCarregadas =
    Map<String, String>.from(jsonData['instructions'] ?? {});
    jsonBeacons = jsonData['beacons'] ?? {};

    _construirMapa(); // cria o grafo com conexões
  }

  void _construirMapa() {
    mapaFaculdade.clear(); // limpa mapa anterior

    List<String> beaconsOperacionais = [
      // lista de beacons ativos no sistema
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

    for (var beaconKey in beaconsOperacionais) {
      if (jsonBeacons.containsKey(beaconKey)) {
        final beaconData = jsonBeacons[beaconKey];
        final destinos = List<String>.from(
            beaconData['beacon_destinations'] ?? []); // destinos diretos
        final conexoes = List<String>.from(
            beaconData['beacon_connections'] ?? []); // beacons vizinhos

        mapaFaculdade[beaconKey] = {};

        for (var conexao in conexoes) {
          if (beaconsOperacionais.contains(conexao)) {
            mapaFaculdade[beaconKey]![conexao] = 1; // peso 1 para conexões
          }
        }

        for (var destino in destinos) {
          mapaFaculdade[beaconKey]![destino] =
          1; // peso 1 para destinos diretos
          mapaFaculdade[destino] =
          {beaconKey: 1}; // caminho inverso para o destino
        }
      }
    }
  }

  String? getLocalizacao(BeaconInfo beacon) {
    return beaconLocations[beacon]; // devolve o nome (ex.: 'Beacon 1') a partir do BeaconInfo
  }

  List<String>? dijkstra(String origem, String destino) {
    final dist = <String, int>{}; // distâncias calculadas
    final prev = <String, String?>{}; // nós anteriores no caminho
    final nodes = mapaFaculdade.keys.toSet();
    final unvisited = Set<String>.from(nodes);

    for (var node in nodes) {
      dist[node] = node == origem ? 0 : 1 <<
          30; // distância inicial (0 para origem, infinito para outros)
      prev[node] = null;
    }
    while (unvisited.isNotEmpty) {
      final current = unvisited.reduce((a, b) =>
      dist[a]! < dist[b]!
          ? a
          : b); // nó com menor distância
      if (current == destino) break;
      unvisited.remove(current);

      mapaFaculdade[current]?.forEach((neighbor, weight) {
        if (unvisited.contains(neighbor)) {
          final alt = dist[current]! + weight; // distância alternativa
          if (alt < dist[neighbor]!) {
            dist[neighbor] = alt;
            prev[neighbor] = current;
          }
        }
      });
    }

    final path = <String>[]; // reconstruir caminho final
    String? u = destino;
    while (u != null) {
      path.insert(0, u);
      u = prev[u];
    }

    return path.isNotEmpty && path.first == origem
        ? path
        : null; // devolve caminho ou null
  }

  List<String> getInstrucoes(List<String> caminho) {
    final instr = <String>[];

    for (var i = 0; i < caminho.length - 1; i++) {
      String? origem = i > 0 ? caminho[i - 1] : null;
      final atual = caminho[i];
      final destino = caminho[i + 1];

      final instruction = buscarInstrucaoNoBeacon(
          atual, destino, origem); // busca instrução no JSON
      if (instruction != null && instruction.isNotEmpty) {
        instr.add(instruction);
      }
    }

    return instr;
  }

  String? buscarInstrucaoNoBeacon(String atual, String destino,
      [String? origem]) {
    if (jsonBeacons.containsKey(atual)) {
      final instructions = jsonBeacons[atual]['beacon_instructions'] ?? {};

      if (origem != null) {
        final chaveTripla = '$origem-$atual-$destino'; // ex.: Beacon5-Beacon6-Beacon7
        if (instructions.containsKey(chaveTripla)) {
          return instructions[chaveTripla];
        }
      }

      final chaveSimples = '$atual-$destino'; // ex.: Beacon6-Beacon7
      return instructions[chaveSimples] ?? '';
    }
    return '';
  }

  bool isDestinoFinal(String localAtual, String proximoPasso) {
    if (jsonBeacons.containsKey(localAtual)) {
      final destinos = List<String>.from(
          jsonBeacons[localAtual]['beacon_destinations'] ?? []);
      return destinos.contains(
          proximoPasso); // verifica se o próximo é destino final
    }
    return false;
  }

  String? getBeaconDoDestino(String destino) {
    for (var beaconKey in jsonBeacons.keys) {
      final destinos = List<String>.from(
          jsonBeacons[beaconKey]['beacon_destinations'] ?? []);
      if (destinos.contains(destino)) {
        return beaconKey; // encontra o beacon associado ao destino
      }
    }
    return null;
  }

  BeaconInfo? parseBeaconData(ScanResult result) {
    final md = result.advertisementData.manufacturerData;
    if (md.isEmpty) return null;

    if (!md.containsKey(76)) return null; // verifica Apple iBeacon (código 76)
    final data = md[76]!;

    if (data.length < 23) return null;

    final uuidBytes = data.sublist(2, 18);
    final uuid = uuidBytes
        .map((b) => b.toRadixString(16).padLeft(2, '0'))
        .join();
    final formattedUuid =
        '${uuid.substring(0, 8)}-${uuid.substring(8, 12)}-${uuid.substring(
        12, 16)}-${uuid.substring(16, 20)}-${uuid.substring(20)}';

    final major = (data[18] << 8) + data[19];
    final minor = (data[20] << 8) + data[21];

    final mac = result.device.id.id.toUpperCase();

    print(
        '[DEBUG] Beacon detetado → UUID: $formattedUuid | Major: $major | Minor: $minor | MAC: $mac');

    return BeaconInfo(formattedUuid, major, minor, mac);
  }

  List<String> getInstrucoesComOrigem(List<String> caminho, String? origem) {
    final instr = <String>[];

    for (var i = 0; i < caminho.length - 1; i++) {
      String? origemUsada = i > 0
          ? caminho[i - 1]
          : origem; // usa origem inicial ou anterior
      final atual = caminho[i];
      final destino = caminho[i + 1];

      final instruction = buscarInstrucaoNoBeacon(atual, destino, origemUsada);
      if (instruction != null && instruction.isNotEmpty) {
        instr.add(instruction);
      }
    }

    return instr;
  }
}