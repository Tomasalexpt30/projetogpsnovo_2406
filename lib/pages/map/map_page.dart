import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  late final WebViewController _controller;
  final TextEditingController _searchController = TextEditingController();
  bool showRouteButton = false;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..loadRequest(Uri.parse('https://mapa.autonoma.pt'))
      ..setJavaScriptMode(JavaScriptMode.unrestricted);
  }

  void _checkSearch(String value) {
    if (value.toLowerCase().contains('sala 10')) {
      setState(() => showRouteButton = true);
    } else {
      setState(() => showRouteButton = false);
    }
  }

  void _simulateRouteStart() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Aproximar para a Sala 10...')),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Ajuste das cores de acordo com o tema
    final TextStyle hintTextStyle = TextStyle(
      color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mapa'),
        backgroundColor: Theme.of(context).brightness == Brightness.dark ? Colors.black : Colors.white,
        foregroundColor: const Color(0xFF00B4D8),
        elevation: 1,
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),

          // Campo de pesquisa
          Positioned(
            left: 16,
            right: 16,
            bottom: 100,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[800] : Colors.white,
                borderRadius: BorderRadius.circular(30),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: _checkSearch,
                decoration: InputDecoration(
                  hintText: 'Destino?',
                  hintStyle: hintTextStyle,
                  border: InputBorder.none,
                  icon: Icon(Icons.search, color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black),
                ),
              ),
            ),
          ),

          // Botão de "Efetuar Rota"
          if (showRouteButton)
            Positioned(
              left: 16,
              right: 16,
              bottom: 30,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).brightness == Brightness.dark ? Colors.blueGrey : Colors.blue,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                onPressed: _simulateRouteStart,
                child: const Text(
                  'Efetuar Rota',
                  style: TextStyle(fontSize: 18, color: Colors.white),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
