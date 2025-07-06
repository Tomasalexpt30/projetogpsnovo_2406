// Importações necessárias
import 'package:flutter/material.dart';                         // Widgets nativos do Flutter
import 'package:google_fonts/google_fonts.dart';               // Fonte personalizada (Poppins)
import 'package:easy_localization/easy_localization.dart';     // Suporte a traduções via .tr()

class MapSettingsPage extends StatefulWidget {
  const MapSettingsPage({super.key}); // Construtor com chave opcional

  @override
  State<MapSettingsPage> createState() => _MapSettingsPageState(); // Cria estado associado
}

class _MapSettingsPageState extends State<MapSettingsPage> {
  bool darkMap = false;          // Indica se o mapa escuro está ativado
  String iconStyle = 'Padrão';   // Estilo de ícones selecionado: "Padrão" ou "Acessível"

  @override
  Widget build(BuildContext context) {
    final TextStyle titleStyle = GoogleFonts.poppins(
      fontSize: 18,                          // Tamanho da fonte
      fontWeight: FontWeight.bold,          // Negrito
      color: Theme.of(context).brightness == Brightness.dark
          ? Colors.white                    // Cor branca em modo escuro
          : const Color(0xFF00B4D8),        // Azul em modo claro
    );

    final TextStyle subtitleStyle = GoogleFonts.poppins(
      fontSize: 14,                          // Tamanho menor que o título
      color: Theme.of(context).brightness == Brightness.dark
          ? Colors.white70                  // Branco com transparência no escuro
          : Colors.black87,                 // Quase preto no claro
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'map_settings_page.map_appearance'.tr(), // Título da AppBar traduzido
          style: titleStyle,
        ),
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? Colors.black                          // Fundo escuro no modo escuro
            : Colors.white,                         // Fundo claro no modo claro
        foregroundColor: const Color(0xFF00B4D8),    // Cor dos ícones/título
        elevation: 1,                                // Sombra leve sob a AppBar
      ),
      body: ListView(
        padding: const EdgeInsets.all(16), // Espaço ao redor do conteudo
        children: [
          Text(
            'map_settings_page.map_appearance'.tr(), // Título traduzido da secção
            style: titleStyle,
          ),
          const SizedBox(height: 8), // Espaço abaixo do título
          SwitchListTile(
          title: Text(
          'map_settings_page.dark_map'.tr(), // Texto do switch (ex: "Mapa Escuro")
          style: subtitleStyle,
          ),
          subtitle: Text(
          'map_settings_page.dark_map_description'.tr(), // Descrição do switch
          style: subtitleStyle,
          ),
          value: darkMap, // Valor atual (true/false)
          activeColor: const Color(0xFF00B4D8), // Cor quando ativado
          onChanged: (val) => setState(() => darkMap = val), // Atualiza estado ao mudar o switch
          ),
          const Divider(height: 32), // Linha horizontal com espaço acima e abaixo
          Text(
            'map_settings_page.icon_style'.tr(), // Título da secção traduzido
            style: titleStyle,
          ),
          const SizedBox(height: 8),
          RadioListTile<String>(
            value: 'Padrão',                  // Valor da opção
            groupValue: iconStyle,            // Valor selecionado no momento
            activeColor: const Color(0xFF00B4D8), // Cor quando selecionado
            title: Row(
              children: [
                Icon(
                  Icons.location_on_outlined, // Ícone do marcador tradicional
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white
                      : Colors.grey,
                ),
                SizedBox(width: 10),
                Text(
                  'map_settings_page.default_style'.tr(), // Texto traduzido: "Padrão"
                  style: subtitleStyle,
                ),
              ],
            ),
            onChanged: (value) {
              setState(() {
                iconStyle = value!; // Atualiza o estilo de ícone selecionado
              });
            },
          ),
          RadioListTile<String>(
            value: 'Acessível',
            groupValue: iconStyle,
            activeColor: const Color(0xFF00B4D8),
            title: Row(
              children: [
                Icon(
                  Icons.accessibility_new, // Ícone de acessibilidade
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white
                      : Colors.grey,
                ),
                SizedBox(width: 10),
                Text(
                  'map_settings_page.accessible_style'.tr(), // Texto traduzido: "Acessível"
                  style: subtitleStyle,
                ),
              ],
            ),
            onChanged: (value) {
              setState(() {
                iconStyle = value!; // Atualiza o estilo de ícone selecionado
              });
            },
          ),
        ],
      ),
    );
  }
}
