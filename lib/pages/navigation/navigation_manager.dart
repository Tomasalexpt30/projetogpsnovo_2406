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
    BeaconInfo('fda50693-a4e2-4fb1-afcf-c6eb07647825', 1, 2, '51:00:24:12:01:CA'): 'Entrada',
    BeaconInfo('fda50693-a4e2-4fb1-afcf-c6eb07647825', 1, 2, '51:00:24:12:01:E3'): 'Patio',
    BeaconInfo('fda50693-a4e2-4fb1-afcf-c6eb07647825', 1, 2, '51:00:24:12:01:B2'): 'Corredor 1',
  };

  final Map<String, Map<String, int>> mapaFaculdade = {
    'Entrada': {'Centro de Informação': 1, 'Patio': 2},
    'Centro de Informação': {'Entrada': 1, 'Sala dos Azulejos': 1},
    'Sala dos Azulejos': {'Centro de Informação': 1},
    'Patio': {'Entrada': 2, 'Corredor 1': 2, 'Corredor 2': 2},
    'Corredor 1': {'Patio': 2, 'Sala30': 2, 'Sala50': 3},
    'Corredor 2': {'Patio': 2, 'Subir Piso 1 (Centro)': 2},
    'Sala30': {'Corredor 1': 2, 'Sala50': 4},
    'Sala50': {'Corredor 1': 3, 'Sala30': 4},
    'Subir Piso 1 (Centro)': {'Corredor 2': 2, 'Entrada P1': 1},
    'Entrada P1': {'Subir Piso 1 (Centro)': 1, 'Patio de Cima': 1},
    'Patio de Cima': {'Entrada P1': 1, 'Biblioteca': 2, 'Subir Piso 2 (Camões)': 2},
    'Biblioteca': {'Patio de Cima': 2},
    'Subir Piso 2 (Camões)': {'Patio de Cima': 2, 'Camões P2': 1},
    'Camões P2': {'Subir Piso 2 (Camões)': 1, 'Sala S60': 2},
    'Sala S60': {'Camões P2': 2, 'Sala S63': 2},
    'Sala S63': {'Sala S60': 2},
    'Subir Piso 1 (Informática)': {'Sala S60': 2, 'Informática P2': 1},
    'Informática P2': {'Subir Piso 1 (Informática)': 1, 'UAL Media': 2},
    'UAL Media': {'Informática P2': 2, 'Corredor Final': 2},
    'Corredor Final': {'UAL Media': 2, 'Salas P2': 2},
    'Salas P2': {'Corredor Final': 2},
    'Descer Piso -1': {'Entrada': 2, 'Refeitório': 2},
    'Refeitório': {'Descer Piso -1': 2, 'Fotocópias': 2},
    'Fotocópias': {'Refeitório': 2, 'Esplanada -1': 2},
    'Esplanada -1': {'Fotocópias': 2},
  };

  final Map<String, String> instrucoesPersonalizadasPT = {
    'Entrada-Centro de Informação': 'Vire à esquerda para o Centro de Informação.',
    'Centro de Informação-Sala dos Azulejos': 'Siga em frente até à Sala dos Azulejos.',
    'Entrada-Patio': 'Siga em frente atravessando a entrada principal até ao Pátio.',
    'Patio-Corredor 1': 'Siga em frente e entre no Corredor 1 à sua esquerda.',
    'Patio-Corredor 2': 'Siga em frente e vire à direita para o Corredor 2.',
    'Corredor 1-Sala30': 'A Sala 30 está à direita.',
    'Corredor 1-Sala50': 'Vire à esquerda para a Sala 50.',
    'Corredor 2-Subir Piso 1 (Centro)': 'No fim do corredor, suba as escadas para o Piso 1.',
    'Subir Piso 1 (Centro)-Entrada P1': 'Chegou à entrada do Piso 1.',
    'Entrada P1-Patio de Cima': 'Siga em frente até ao Pátio do piso superior.',
    'Patio de Cima-Biblioteca': 'Siga para a esquerda até à Biblioteca.',
    'Patio de Cima-Subir Piso 2 (Camões)': 'Vire à direita e suba para o Piso 2 pela zona de Camões.',
    'Subir Piso 2 (Camões)-Camões P2': 'Chegou à zona de Camões no Piso 2.',
    'Camões P2-Sala S60': 'Continue em frente até à Sala S60.',
    'Sala S60-Sala S63': 'Siga pelo corredor até à Sala S63.',
    'Sala S60-Subir Piso 1 (Informática)': 'Volte para trás e desça as escadas para o Piso 1.',
    'Subir Piso 1 (Informática)-Informática P2': 'Suba para o Piso 2, zona do Centro de Informática.',
    'Informática P2-UAL Media': 'Vire à direita para o UAL Media.',
    'UAL Media-Corredor Final': 'Siga em frente pelo corredor.',
    'Corredor Final-Salas P2': 'Continue até ao final do corredor para aceder às salas.',
    'Entrada-Descer Piso -1': 'Desça as escadas junto à entrada para o Piso -1.',
    'Descer Piso -1-Refeitório': 'Siga em frente para o refeitório e zona de comer.',
    'Refeitório-Fotocópias': 'Continue pela esquerda até às fotocópias.',
    'Fotocópias-Esplanada -1': 'Siga pela direita até à esplanada do Piso -1.',
  };

  final Map<String, String> instrucoesPersonalizadasEN = {
    'Entrada-Centro de Informação': 'Turn left towards the Information Center.',
    'Centro de Informação-Sala dos Azulejos': 'Go straight to the Sala dos Azulejos.',
    'Entrada-Patio': 'Go straight through the main entrance to the Patio.',
    'Patio-Corredor 1': 'Go straight and enter Corridor 1 to your left.',
    'Patio-Corredor 2': 'Go straight and turn right to Corridor 2.',
    'Corredor 1-Sala30': 'Sala 30 is to the right.',
    'Corredor 1-Sala50': 'Turn left to Sala 50.',
    'Corredor 2-Subir Piso 1 (Centro)': 'At the end of the corridor, go upstairs to Floor 1.',
    'Subir Piso 1 (Centro)-Entrada P1': 'You have reached the entrance of Floor 1.',
    'Entrada P1-Patio de Cima': 'Go straight to the upper patio.',
    'Patio de Cima-Biblioteca': 'Turn left to go to the Library.',
    'Patio de Cima-Subir Piso 2 (Camões)': 'Turn right and go upstairs to Floor 2 via Camões.',
    'Subir Piso 2 (Camões)-Camões P2': 'You have reached the Camões area on Floor 2.',
    'Camões P2-Sala S60': 'Go straight to Sala S60.',
    'Sala S60-Sala S63': 'Go down the hall to Sala S63.',
    'Sala S60-Subir Piso 1 (Informática)': 'Turn back and go down the stairs to Floor 1.',
    'Subir Piso 1 (Informática)-Informática P2': 'Go upstairs to Floor 2, the Computer Science area.',
    'Informática P2-UAL Media': 'Turn right to UAL Media.',
    'UAL Media-Corredor Final': 'Go straight down the hall.',
    'Corredor Final-Salas P2': 'Continue to the end of the corridor to access the rooms.',
    'Entrada-Descer Piso -1': 'Go down the stairs near the entrance to Floor -1.',
    'Descer Piso -1-Refeitório': 'Go straight to the cafeteria and eating area.',
    'Refeitório-Fotocópias': 'Continue to the left to the photocopy area.',
    'Fotocópias-Esplanada -1': 'Go to the right to the outdoor area on Floor -1.',
  };

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

  List<String> getInstrucoes(List<String> caminho, String selectedLanguageCode) {
    final instr = <String>[];
    final instrucoes = selectedLanguageCode == 'en-US' ? instrucoesPersonalizadasEN : instrucoesPersonalizadasPT;

    for (var i = 0; i < caminho.length - 1; i++) {
      final chave = '${caminho[i]}-${caminho[i + 1]}';
      instr.add(instrucoes[chave] ??
          (selectedLanguageCode == 'en-US'
              ? 'Go from ${caminho[i]} to ${caminho[i + 1]}.'
              : 'Dirija-se de ${caminho[i]} para ${caminho[i + 1]}.')
      );
    }

    if (caminho.length > 1) {
      instr.add(selectedLanguageCode == 'en-US'
          ? 'You have reached your destination.'
          : 'Chegou ao seu destino.');
    }

    return instr;
  }

  BeaconInfo? parseBeaconData(ScanResult result) {
    final md = result.advertisementData.manufacturerData;
    if (md.isEmpty) return null;

    if (!md.containsKey(76)) return null; // Apple iBeacon ID = 0x004C = 76
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
