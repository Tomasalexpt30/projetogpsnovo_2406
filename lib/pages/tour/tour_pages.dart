import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'tour_scan_beacons.dart';

class TourPage extends StatefulWidget {
  const TourPage({super.key});

  // Dados técnicos (ids dos pontos + dados dos beacons)
  static const List<TourStop> tourStops = [
    TourStop(
      id: 'entrada',
      piso: 'Piso 0',
      position: Offset(300, 500),
      uuid: 'fda50693-a4e2-4fb1-afcf-c6eb07647825',
      major: 1,
      minor: 2,
      macAddress: '51:00:24:12:01:CA',
    ),
    TourStop(
      id: 'patio',
      piso: 'Piso 0',
      position: Offset(300, 250),
      uuid: 'fda50693-a4e2-4fb1-afcf-c6eb07647825',
      major: 1,
      minor: 2,
      macAddress: '51:00:24:12:01:E3',
    ),
    TourStop(
      id: 'camoes',
      piso: 'Piso 0',
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

class _TourPageState extends State<TourPage> {
  String imagemPiso = TourPage.tourStops[0].piso == 'Piso 0'
      ? 'assets/images/map/00_piso.png'
      : 'assets/images/map/01_piso.png';
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
                      Text(
                        'tour_page.title'.tr(),
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'tour_page.description'.tr(),
                        style: const TextStyle(fontSize: 16, color: Colors.grey),
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
                        label: Text('tour_page.start_btn'.tr()),
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
