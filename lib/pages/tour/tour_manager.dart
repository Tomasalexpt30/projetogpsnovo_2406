import 'dart:convert'; // Necessário para trabalhar com JSON (decodificar os ficheiros de instruções)
import 'package:flutter/services.dart'; // Permite aceder a assets (como ficheiros dentro de assets/)
import 'package:flutter_blue_plus/flutter_blue_plus.dart'; // Biblioteca para comunicação Bluetooth LE


class BeaconInfo {
  final String uuid;       // UUID do beacon (identificador único universal)
  final int major;         // Identificador major (agrupamento)
  final int minor;         // Identificador minor (subagrupamento)
  final String macAddress; // Endereço MAC do beacon (identifica fisicamente o dispositivo)

  BeaconInfo(this.uuid, this.major, this.minor, this.macAddress);

  @override
  bool operator ==(Object other) =>
      identical(this, other) || // Verifica se são a mesma instância
          other is BeaconInfo &&
              runtimeType == other.runtimeType &&
              uuid == other.uuid &&
              major == other.major &&
              minor == other.minor &&
              macAddress.toUpperCase() == other.macAddress.toUpperCase(); // Ignora maiúsculas no MAC

  @override
  int get hashCode =>
      uuid.hashCode ^ major.hashCode ^ minor.hashCode ^ macAddress.toUpperCase().hashCode;
}

class TourManager {
  final Map<BeaconInfo, String> beaconLocations = {
    BeaconInfo('fda50693-a4e2-4fb1-afcf-c6eb07647825', 1, 2, '51:00:24:12:01:CA'): 'Beacon 1',
    BeaconInfo('fda50693-a4e2-4fb1-afcf-c6eb07647825', 1, 2, '51:00:24:12:01:E3'): 'Beacon 3',
    BeaconInfo('fda50693-a4e2-4fb1-afcf-c6eb07647825', 1, 2, '51:00:24:12:01:B2'): 'Beacon 15',
  };

  Map<String, String> instrucoesCarregadas = {}; // Ligações diretas entre pontos (ex: A-B)
  Map<String, dynamic> jsonBeacons = {};         // Estrutura detalhada de cada beacon no JSON
  List<String> rotaPreDefinida = [];             // Ordem da rota da visita guiada

  Future<void> carregarInstrucoes(String selectedLanguageCode) async {
    // Extrai apenas o código de idioma (ex: "pt" de "pt-PT")
    String langCode = selectedLanguageCode.toLowerCase().split('-')[0];
    String fullCode = selectedLanguageCode.toLowerCase().replaceAll('_', '-');

    // Tenta várias localizações por ordem de prioridade
    List<String> paths = [
      'assets/tts/tour/tour_$fullCode.json', // Exato (ex: pt-pt)
      'assets/tts/tour/tour_$langCode.json', // Apenas idioma base (pt)
      'assets/tts/tour/tour_en.json',        // Fallback para inglês
    ];

    String? jsonString;
    for (String path in paths) {
      try {
        jsonString = await rootBundle.loadString(path); // Tenta carregar o ficheiro
        break; // Se conseguir, sai do ciclo
      } catch (_) {}
    }

    // Decodifica o conteúdo do JSON, se existir
    final Map<String, dynamic> jsonData = jsonString != null ? json.decode(jsonString) : {};

    // Extrai secções importantes
    instrucoesCarregadas = Map<String, String>.from(jsonData['instructions'] ?? {});
    jsonBeacons = jsonData['beacons'] ?? {};
    rotaPreDefinida = List<String>.from(jsonData['tour_route'] ?? []);

    print('[DEBUG] Rota carregada: $rotaPreDefinida');
  }

  String? getLocalizacao(BeaconInfo beacon) {
    return beaconLocations[beacon]; // Retorna "Beacon 1", "Beacon 3", etc.
  }


  List<String> getInstrucoes(List<String> caminho) {
    final instr = <String>[]; // Lista a devolver

    for (var i = 0; i < caminho.length - 1; i++) {
      final chave = '${caminho[i]}-${caminho[i + 1]}'; // Ex: "Entrada-Camões"

      if (instrucoesCarregadas.containsKey(chave)) {
        instr.add(instrucoesCarregadas[chave]!); // Usa instrução direta
      } else {
        final instruction = buscarInstrucaoNoBeacon(caminho[i], caminho[i + 1]);
        if (instruction != null && instruction.isNotEmpty) {
          instr.add(instruction); // Caso não exista direta, procura no beacon
        }
      }
    }

    return instr;
  }

  String? buscarInstrucaoNoBeacon(String origem, String destino) {
    if (jsonBeacons.containsKey(origem)) { // Verifica se o beacon de origem existe no JSON carregado
      final instructions = jsonBeacons[origem]['beacon_instructions'] ?? {}; // Acede ao campo "beacon_instructions" do beacon de origem
      final chave = '$origem-$destino'; // Define a chave composta "origem-destino", ex: "Entrada-Camões"
      return instructions[chave] ?? ''; // Retorna a instrução, se existir, ou string vazia
    }
    return ''; // Se a origem não estiver no JSON, retorna string vazia
  }

  bool isDestinoFinal(String localAtual, String proximoPasso) {
    if (jsonBeacons.containsKey(localAtual)) { // Verifica se existe definição do beacon correspondente ao localAtual no JSON
      final destinos = List<String>.from( // Extrai a lista de destinos possíveis (ex: ["Camões", "Sala 10", ...])
          jsonBeacons[localAtual]['beacon_destinations'] ?? []
      );
      return destinos.contains(proximoPasso); // Verifica se o destino atual está na lista de destinos do beacon
    }
    return false; // Se não houver informação sobre o localAtual, assume que não é destino final
  }

  BeaconInfo? parseBeaconData(ScanResult result) {
    final md = result.advertisementData.manufacturerData;
    if (md.isEmpty) return null; // Sem dados de fabricante? Ignorar.

    if (!md.containsKey(76)) return null; // iBeacon Apple usa 0x004C (76)

    final data = md[76]!; // Extrai os bytes da entrada
    if (data.length < 23) return null; // Verifica se é válido

    final uuidBytes = data.sublist(2, 18); // UUID começa na posição 2
    final uuid = uuidBytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();

    final formattedUuid =
        '${uuid.substring(0, 8)}-${uuid.substring(8, 12)}-${uuid.substring(12, 16)}-${uuid.substring(16, 20)}-${uuid.substring(20)}';

    final major = (data[18] << 8) + data[19]; // Junta os bytes major
    final minor = (data[20] << 8) + data[21]; // Junta os bytes minor

    final mac = result.device.id.id.toUpperCase(); // Obtém o MAC formatado

    print('[DEBUG] Beacon detetado → UUID: $formattedUuid | Major: $major | Minor: $minor | MAC: $mac');

    return BeaconInfo(formattedUuid, major, minor, mac); // Cria e retorna objeto
  }
}