import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:vibration/vibration.dart';
import 'package:projetogpsnovo/helpers/preferences_helpers.dart';

class SoundSettingsPage extends StatefulWidget {
  const SoundSettingsPage({super.key});

  @override
  State<SoundSettingsPage> createState() => _SoundSettingsPageState();
}

class _SoundSettingsPageState extends State<SoundSettingsPage> {
  final FlutterTts flutterTts = FlutterTts();
  final PreferencesHelper _preferencesHelper = PreferencesHelper();

  bool soundEnabled = true;
  bool vibrationEnabled = true;
  String selectedLanguageCode = 'pt-PT';
  double voiceSpeed = 0.6;
  double voicePitch = 1.0;

  final Map<String, String> voiceTests = {
    'pt-PT': 'Isto é um teste de voz.',
    'en-US': 'This is a voice test.',
  };

  final Map<String, String> voiceOptions = {
    'pt-PT': 'Português',
    'en-US': 'English',
  };

  @override
  void initState() {
    super.initState();
    _loadSoundSettings();
    _configurarTTS();
  }

  Future<void> _configurarTTS() async {
    if (soundEnabled) {
      await flutterTts.setLanguage(selectedLanguageCode);
      await flutterTts.setSpeechRate(voiceSpeed);
      await flutterTts.setPitch(voicePitch);
    }
  }

  Future<void> _saveSoundSettings() async {
    await _preferencesHelper.saveSoundSettings(
      soundEnabled: soundEnabled,
      vibrationEnabled: vibrationEnabled,
      voiceSpeed: voiceSpeed,
      voicePitch: voicePitch,
      selectedLanguageCode: selectedLanguageCode,
    );
  }

  Future<void> _loadSoundSettings() async {
    final settings = await _preferencesHelper.loadSoundSettings();
    setState(() {
      soundEnabled = settings['soundEnabled'];
      vibrationEnabled = settings['vibrationEnabled'];
      voiceSpeed = settings['voiceSpeed'];
      voicePitch = settings['voicePitch'];
      selectedLanguageCode = settings['selectedLanguageCode'];
    });
  }

  Future<void> _testarVoz() async {
    if (soundEnabled) {
      await _configurarTTS();
      await flutterTts.speak(voiceTests[selectedLanguageCode] ?? 'Voice test.');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Voz reproduzida')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final TextStyle titleStyle = GoogleFonts.poppins(
      fontSize: 18,
      fontWeight: FontWeight.bold,
      color: Theme.of(context).brightness == Brightness.dark ? Colors.white : const Color(0xFF00B4D8),
    );

    final TextStyle subtitleStyle = GoogleFonts.poppins(
      fontSize: 14,
      color: Theme.of(context).brightness == Brightness.dark ? Colors.white70 : Colors.black87,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text('sound_settings_page.sound'.tr(), style: titleStyle),
        backgroundColor: Theme.of(context).brightness == Brightness.dark ? Colors.black : Colors.white,
        foregroundColor: const Color(0xFF00B4D8),
        elevation: 1,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('sound_settings_page.general_preferences'.tr(), style: titleStyle),
          const SizedBox(height: 8),
          SwitchListTile(
            title: Text('sound_settings_page.sound'.tr()),
            subtitle: Text('sound_settings_page.sound_description'.tr(), style: subtitleStyle),
            value: soundEnabled,
            activeColor: const Color(0xFF00B4D8),
            onChanged: (val) {
              setState(() {
                soundEnabled = val;
              });
              _saveSoundSettings();
            },
          ),
          SwitchListTile(
            title: Text('sound_settings_page.vibration'.tr()),
            subtitle: Text('sound_settings_page.vibration_description'.tr(), style: subtitleStyle),
            value: vibrationEnabled,
            activeColor: const Color(0xFF00B4D8),
            onChanged: (val) async {
              setState(() {
                vibrationEnabled = val;
              });
              if (vibrationEnabled) {
                if (await Vibration.hasVibrator()) {
                  Vibration.vibrate();
                }
              }
              _saveSoundSettings();
            },
          ),
          const Divider(height: 32),
          Text('sound_settings_page.voice'.tr(), style: titleStyle),
          const SizedBox(height: 8),
          ListTile(
            title: Text('sound_settings_page.language'.tr()),
            subtitle: Text('sound_settings_page.current_language'.tr(namedArgs: {'language': voiceOptions[selectedLanguageCode] ?? selectedLanguageCode})),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () async {
              final selected = await showDialog<String>(
                context: context,
                builder: (_) => SimpleDialog(
                  title: Text('sound_settings_page.select_language'.tr()),
                  children: voiceOptions.entries
                      .map((entry) => SimpleDialogOption(
                    child: Text(entry.value),
                    onPressed: () => Navigator.pop(context, entry.key),
                  ))
                      .toList(),
                ),
              );
              if (selected != null) {
                setState(() {
                  selectedLanguageCode = selected;
                });
                await _configurarTTS();
                _saveSoundSettings();
              }
            },
          ),
          const SizedBox(height: 16),
          Text('sound_settings_page.voice_speed'.tr(namedArgs: {'speed': voiceSpeed.toStringAsFixed(1)}), style: subtitleStyle),
          Slider(
            value: voiceSpeed,
            min: 0.5,
            max: 2.0,
            divisions: 6,
            label: '${voiceSpeed.toStringAsFixed(1)}x',
            activeColor: const Color(0xFF00B4D8),
            onChanged: (value) {
              setState(() {
                voiceSpeed = value;
              });
              _configurarTTS();
              _saveSoundSettings();
            },
          ),
          const SizedBox(height: 8),
          Text('sound_settings_page.voice_pitch'.tr(namedArgs: {'pitch': voicePitch.toStringAsFixed(1)}), style: subtitleStyle),
          Slider(
            value: voicePitch,
            min: 0.5,
            max: 2.0,
            divisions: 6,
            label: voicePitch.toStringAsFixed(1),
            activeColor: const Color(0xFF00B4D8),
            onChanged: (value) {
              setState(() {
                voicePitch = value;
              });
              _configurarTTS();
              _saveSoundSettings();
            },
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _testarVoz,
            icon: const Icon(Icons.volume_up),
            label: Text('sound_settings_page.test_voice'.tr()),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00B4D8),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
