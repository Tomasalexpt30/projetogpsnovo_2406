import 'package:flutter/material.dart';
import 'tour_scan_beacons.dart';

class TourPage extends StatefulWidget {
  const TourPage({super.key});

  static const Map<String, String> imagensPorPiso = {
    'Piso -1': 'assets/images/map/-01_piso.png',
    'Piso 0': 'assets/images/map/00_piso.png',
    'Piso 1': 'assets/images/map/01_piso.png',
    'Piso 2': 'assets/images/map/02_piso.png',
  };

  static const List<TourStop> tourStops = [
    TourStop(
      nomePT: 'Entrada',
      nomeEN: 'Entrance',
      piso: 'Piso 0',
      textoPT: 'Bem-vindo à Universidade Autónoma de Lisboa...',
      textoEN: 'Welcome to the Autonomous University of Lisbon...',
      position: Offset(300, 500),
      uuid: 'fda50693-a4e2-4fb1-afcf-c6eb07647825',
      major: 1,
      minor: 2,
      macAddress: '51:00:24:12:01:CA',
    ),
    TourStop(
      nomePT: 'Pátio',
      nomeEN: 'Courtyard',
      piso: 'Piso 0',
      textoPT: 'Este é o átrio principal da universidade...',
      textoEN: 'This is the main atrium of the university...',
      position: Offset(300, 250),
      uuid: 'fda50693-a4e2-4fb1-afcf-c6eb07647825',
      major: 1,
      minor: 2,
      macAddress: '51:00:24:12:01:E3',
    ),
    TourStop(
      nomePT: 'Camões',
      nomeEN: 'Camões',
      piso: 'Piso 0',
      textoPT: 'A estátua de Camões representa o valor da literatura...',
      textoEN: 'The Camões statue represents the value of literature...',
      position: Offset(380, 95),
      uuid: 'fda50693-a4e2-4fb1-afcf-c6eb07647825',
      major: 1,
      minor: 2,
      macAddress: '51:00:24:12:01:B2',
    ),
  ];

  @override
  State<TourPage> createState() => _TourPageState();
}

class _TourPageState extends State<TourPage> with TickerProviderStateMixin {
  String imagemPiso = TourPage.imagensPorPiso['Piso 0']!;
  Offset cameraOffset = TourPage.tourStops[0].position;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: InteractiveViewer(
              panEnabled: true,
              scaleEnabled: true,
              minScale: 1.0,
              maxScale: 3.5,
              constrained: false,
              boundaryMargin: const EdgeInsets.all(100),
              child: Stack(
                children: [
                  Transform.translate(
                    offset: Offset(-cameraOffset.dx + 150, -cameraOffset.dy + 320),
                    child: Stack(
                      children: [
                        Image.asset(
                          imagemPiso,
                          fit: BoxFit.none,
                          alignment: Alignment.topLeft,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          DraggableScrollableSheet(
            minChildSize: 0.20,
            maxChildSize: 0.28,
            initialChildSize: 0.28,
            builder: (context, controller) {
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.95),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                  boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 6)],
                ),
                child: SingleChildScrollView(
                  controller: controller,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Text(
                        'Visita Guiada',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Inicie a sua visita guiada pelos principais pontos da universidade.',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => TourScanPage(tourStops: TourPage.tourStops),
                            ),
                          );
                        },
                        icon: const Icon(Icons.navigation),
                        label: const Text('Iniciar Visita'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
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
