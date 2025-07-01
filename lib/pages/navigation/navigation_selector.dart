import 'package:flutter/material.dart';
import 'navigation_scan.dart';

class NavigationSelectorPage extends StatefulWidget {
  const NavigationSelectorPage({super.key});

  @override
  State<NavigationSelectorPage> createState() => _NavigationSelectorPageState();
}

class _NavigationSelectorPageState extends State<NavigationSelectorPage> {
  final List<String> destinos = ['Entrada', 'Patio', 'Corredor 1', 'Corredor 1', 'Corredor 1', 'Corredor 1', 'Corredor 1', 'Corredor 1'];
  String? destinoSelecionado;

  final Map<String, String> destinosMap = {
    'entrada': 'Entrada',
    'pátio': 'Pátio',
    'corredor 1': 'Corredor 1',
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Selecionar Destino')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Escolhe o destino para iniciar a navegação:',
              style: TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 20),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(border: OutlineInputBorder()),
              value: destinoSelecionado,
              hint: const Text('Selecionar destino'),
              items: destinos
                  .map((destino) => DropdownMenuItem(
                value: destino,
                child: Text(destino),
              ))
                  .toList(),
              onChanged: (value) {
                setState(() {
                  destinoSelecionado = value;
                });
              },
            ),
            const SizedBox(height: 30),
            Center(
              child: ElevatedButton.icon(
                onPressed: destinoSelecionado == null
                    ? null
                    : () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => BeaconScanPage(
                        destino: destinoSelecionado!,
                        destinosMap: destinosMap,
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.navigation),
                label: const Text('Iniciar Navegação'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
