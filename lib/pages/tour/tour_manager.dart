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
    BeaconInfo('fda50693-a4e2-4fb1-afcf-c6eb07647825', 10001, 1, 'FF:87:6D:60:E2:CE'): 'Beacon 1',
    BeaconInfo('fda50693-a4e2-4fb1-afcf-c6eb07647825', 10001, 2, 'DC:ED:EA:6E:0B:2D'): 'Beacon 3',
    BeaconInfo('fda50693-a4e2-4fb1-afcf-c6eb07647825', 10001, 3, 'F2:29:76:B1:E1:4D'): 'Beacon 15',
  };

  Map<String, String> instrucoesCarregadas = {};
  Map<String, dynamic> jsonBeacons = {};
  List<String> rotaPreDefinida = [];

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
        jsonString = await rootBundle.loadString(path);
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
    return beaconLocations[beacon];
  }

  List<String> getInstrucoes(List<String> caminho) {
    final instr = <String>[];

    for (var i = 0; i < caminho.length - 1; i++) {
      final chave = '${caminho[i]}-${caminho[i + 1]}';
      if (instrucoesCarregadas.containsKey(chave)) {
        instr.add(instrucoesCarregadas[chave]!);
      } else {
        final instruction = buscarInstrucaoNoBeacon(caminho[i], caminho[i + 1]);
        if (instruction != null && instruction.isNotEmpty) {
          instr.add(instruction);
        }
      }
    }

    return instr;
  }

  String? buscarInstrucaoNoBeacon(String origem, String destino) {
    if (jsonBeacons.containsKey(origem)) {
      final instructions = jsonBeacons[origem]['beacon_instructions'] ?? {};
      final chave = '$origem-$destino';
      return instructions[chave] ?? '';
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
