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

class TourManager {
  final Map<BeaconInfo, String> beaconLocations = {
    BeaconInfo('107e0a13-90f3-42bf-b980-181d93c3ccd2', 10001, 1, 'FF:87:6D:60:E2:CE'): 'Beacon 1',
    BeaconInfo('107e0a13-90f3-42bf-b980-181d93c3ccd2', 10001, 3, 'F2:29:76:B1:E1:4D'): 'Beacon 3',
    BeaconInfo('107e0a13-90f3-42bf-b980-181d93c3ccd2', 10001, 4, 'FD:F3:6B:A2:22:DD'): 'Beacon 4',
    BeaconInfo('107e0a13-90f3-42bf-b980-181d93c3ccd2', 10001, 5, 'EC:3B:82:29:F8:2D'): 'Beacon 5',
    BeaconInfo('107e0a13-90f3-42bf-b980-181d93c3ccd2', 10001, 6, 'FA:93:62:AF:62:66'): 'Beacon 6',
    BeaconInfo('107e0a13-90f3-42bf-b980-181d93c3ccd2', 10000, 7, 'E8:C5:D8:A6:E9:BA'): 'Beacon 7',
    BeaconInfo('107e0a13-90f3-42bf-b980-181d93c3ccd2', 10001, 8, 'C3:8B:3B:92:A0:09'): 'Beacon 8',
    BeaconInfo('107e0a13-90f3-42bf-b980-181d93c3ccd2', 10001, 9, 'DD:82:40:D0:83:6F'): 'Beacon 9',
    BeaconInfo('107e0a13-90f3-42bf-b980-181d93c3ccd2', 10000, 10, 'DD:28:73:88:D8:D2'): 'Beacon 10',
    BeaconInfo('107e0a13-90f3-42bf-b980-181d93c3ccd2', 10000, 11, 'E5:12:43:87:BE:A5'): 'Beacon 11',
    BeaconInfo('107e0a13-90f3-42bf-b980-181d93c3ccd2', 10000, 12, 'C4:DF:3A:76:9C:CD'): 'Beacon 12',
    BeaconInfo('107e0a13-90f3-42bf-b980-181d93c3ccd2', 10000, 13, 'D6:71:FD:D8:53:A1'): 'Beacon 13',
    BeaconInfo('107e0a13-90f3-42bf-b980-181d93c3ccd2', 10000, 14, 'FE:FD:80:74:9B:00'): 'Beacon 14',
    BeaconInfo('107e0a13-90f3-42bf-b980-181d93c3ccd2', 10001, 15, 'C2:C7:83:CD:77:6E'): 'Beacon 15',
    BeaconInfo('107e0a13-90f3-42bf-b980-181d93c3ccd2', 10001, 16, 'F8:BE:75:76:4D:29'): 'Beacon 16',
    BeaconInfo('107e0a13-90f3-42bf-b980-181d93c3ccd2', 10001, 17, 'C6:97:47:5A:8F:6C'): 'Beacon 17',
    BeaconInfo('107e0a13-90f3-42bf-b980-181d93c3ccd2', 10000, 18, 'E3:1D:5F:D5:56:35'): 'Beacon 18',
    BeaconInfo('107e0a13-90f3-42bf-b980-181d93c3ccd2', 10002, 19, 'F5:4B:CF:31:D5:A3'): 'Beacon 19',
    BeaconInfo('107e0a13-90f3-42bf-b980-181d93c3ccd2', 10002, 20, 'F5:71:BD:7A:B9:A3'): 'Beacon 20',
    BeaconInfo('107e0a13-90f3-42bf-b980-181d93c3ccd2', 10003, 21, 'C8:77:BE:A3:90:64'): 'Beacon 21',
    BeaconInfo('107e0a13-90f3-42bf-b980-181d93c3ccd2', 10001, 22, 'E2:56:6F:02:0A:DD'): 'Beacon 22',
    BeaconInfo('107e0a13-90f3-42bf-b980-181d93c3ccd2', 10002, 23, 'C7:68:90:86:BE:7B'): 'Beacon 23',
    BeaconInfo('107e0a13-90f3-42bf-b980-181d93c3ccd2', 10002, 24, 'C3:EE:4E:EC:04:FF'): 'Beacon 24',
    BeaconInfo('107e0a13-90f3-42bf-b980-181d93c3ccd2', 10002, 25, 'DB:DB:2C:2A:42:D4'): 'Beacon 25',
    BeaconInfo('107e0a13-90f3-42bf-b980-181d93c3ccd2', 10003, 26, 'CA:EA:BC:7D:9E:E8'): 'Beacon 26',
    BeaconInfo('107e0a13-90f3-42bf-b980-181d93c3ccd2', 10002, 27, 'CB:DD:F2:E9:BD:53'): 'Beacon 27',
    BeaconInfo('107e0a13-90f3-42bf-b980-181d93c3ccd2', 10002, 28, 'E0:62:65:E0:D4:FB'): 'Beacon 28',
    BeaconInfo('107e0a13-90f3-42bf-b980-181d93c3ccd2', 10002, 29, 'FF:B2:A4:E8:07:2B'): 'Beacon 29',
    BeaconInfo('107e0a13-90f3-42bf-b980-181d93c3ccd2', 10002, 30, 'EB:9E:2E:26:D8:54'): 'Beacon 30',
    BeaconInfo('107e0a13-90f3-42bf-b980-181d93c3ccd2', 10003, 31, 'F6:AD:B9:EA:40:63'): 'Beacon 31',
    BeaconInfo('107e0a13-90f3-42bf-b980-181d93c3ccd2', 10003, 32, 'FE:31:74:78:F8:C9'): 'Beacon 32',
    BeaconInfo('107e0a13-90f3-42bf-b980-181d93c3ccd2', 10003, 33, 'EB:C0:32:AE:59:7F'): 'Beacon 33',
    BeaconInfo('107e0a13-90f3-42bf-b980-181d93c3ccd2', 10003, 36, 'DC:ED:EA:6E:0B:2D'): 'Beacon 36',
    BeaconInfo('107e0a13-90f3-42bf-b980-181d93c3ccd2', 10003, 37, 'C5:14:B9:27:15:D0'): 'Beacon 37',
    BeaconInfo('107e0a13-90f3-42bf-b980-181d93c3ccd2', 10004, 38, 'E1:AD:34:83:56:08'): 'Beacon 38',
  };

  Map<String, String> instrucoesCarregadas = {}; // instruções carregadas
  Map<String, dynamic> jsonBeacons = {}; // dados dos beacons
  List<String> rotaPreDefinida = []; // rota da visita guiada

  Future<void> carregarInstrucoes(String selectedLanguageCode) async {
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

    final Map<String, dynamic> jsonData = jsonString != null ? json.decode(jsonString) : {};
    instrucoesCarregadas = Map<String, String>.from(jsonData['instructions'] ?? {});
    jsonBeacons = jsonData['beacons'] ?? {};
    rotaPreDefinida = List<String>.from(jsonData['tour_route'] ?? []);

    print('[DEBUG] Rota carregada: $rotaPreDefinida');
  }

  String? getLocalizacao(BeaconInfo beacon) {
    return beaconLocations[beacon]; // devolve nome do beacon
  }

  List<String> getInstrucoes(List<String> caminho) {
    final instr = <String>[];

    for (var i = 0; i < caminho.length - 1; i++) {
      final origem = i > 0 ? caminho[i - 1] : '';
      final atual = caminho[i];
      final destino = caminho[i + 1];

      final chave = '$origem-$atual-$destino';
      if (instrucoesCarregadas.containsKey(chave)) {
        instr.add(instrucoesCarregadas[chave]!);
      } else {
        final instruction = buscarInstrucaoNoBeacon(origem, atual, destino);
        if (instruction != null && instruction.isNotEmpty) {
          instr.add(instruction);
        }
      }
    }

    return instr;
  }

  String? buscarInstrucaoNoBeacon(String beaconAnterior, String localAtual, String destino) {
    if (jsonBeacons.containsKey(localAtual)) {
      final instructions = jsonBeacons[localAtual]['beacon_instructions'] ?? {};
      final chaveCompleta = '$beaconAnterior-$localAtual-$destino';
      final chaveSimples = '$localAtual-$destino';
      return instructions[chaveCompleta] ?? instructions[chaveSimples] ?? '';
    }
    return '';
  }

  bool isDestinoFinal(String localAtual, String proximoPasso) {
    if (jsonBeacons.containsKey(localAtual)) {
      final destinos = List<String>.from(jsonBeacons[localAtual]['beacon_destinations'] ?? []);
      return destinos.contains(proximoPasso);
    }
    return false;
  }

  BeaconInfo? parseBeaconData(ScanResult result) {
    final md = result.advertisementData.manufacturerData;
    if (md.isEmpty) return null;

    if (!md.containsKey(76)) return null; // verifica tipo iBeacon
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

    return BeaconInfo(formattedUuid, major, minor, mac); // devolve beacon parseado
  }
}