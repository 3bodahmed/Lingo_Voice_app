import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Settingsscreen extends StatefulWidget {
  final Function(bool) onThemeChanged;
  final bool currentTheme;
  const Settingsscreen({
    super.key,
    required this.onThemeChanged,
    required this.currentTheme,
  });

  @override
  State<Settingsscreen> createState() => _SettingsscreenState();
}

class _SettingsscreenState extends State<Settingsscreen> {
  bool _isDarkMode = false;
  double _speechRate = 0.5;
  double _speechPitch = 1.0;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isDarkMode = widget.currentTheme; // نأخذ القيمة من الوالد
      _speechRate = prefs.getDouble('speechRate') ?? 0.5;
      _speechPitch = prefs.getDouble('speechPitch') ?? 1.0;
    });
    // تطبيق إعدادات TTS عند التحميل
    _applyTtsSettings();
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', _isDarkMode);
    await prefs.setDouble('speechRate', _speechRate);
    await prefs.setDouble('speechPitch', _speechPitch);
  }

  void _toggleDarkMode(bool value) {
    setState(() {
      _isDarkMode = value;
    });
    _saveSettings();
    // إعلام الوالد (MyApp) بتغيير الثيم
    widget.onThemeChanged(value);
  }

  void _updateSpeechRate(double value) {
    setState(() {
      _speechRate = value;
    });
    _saveSettings();
    _applyTtsSettings();
  }

  void _updateSpeechPitch(double value) {
    setState(() {
      _speechPitch = value;
    });
    _saveSettings();
    _applyTtsSettings();
  }

  Future<void> _applyTtsSettings() async {
    final tts = FlutterTts();
    await tts.setSpeechRate(_speechRate);
    await tts.setPitch(_speechPitch);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSectionHeader('Styles'),
          SwitchListTile(
            title: const Text('Dark mode'),
            subtitle: const Text('Active dark colors'),
            value: _isDarkMode,
            onChanged: _toggleDarkMode,
            secondary: Icon(
              _isDarkMode ? Icons.nightlight_round : Icons.wb_sunny,
            ),
          ),
          const Divider(),

          _buildSectionHeader('Voice and prounuciation'),
          ListTile(
            title: const Text('Speed pronunciation'),
            subtitle: Slider(
              value: _speechRate,
              min: 0.1,
              max: 1.0,
              divisions: 10,
              label: _speechRate.toStringAsFixed(1),
              onChanged: _updateSpeechRate,
            ),
          ),
          ListTile(
            title: const Text('Sound level'),
            subtitle: Slider(
              value: _speechPitch,
              min: 0.5,
              max: 2.0,
              divisions: 15,
              label: _speechPitch.toStringAsFixed(1),
              onChanged: _updateSpeechPitch,
            ),
          ),
          const Divider(),

          _buildSectionHeader('inforamtion App'),
          const ListTile(
            leading: Icon(Icons.info_outline),
            title: Text('Version'),
            subtitle: Text('LingoVoice v1.0.0'),
          ),
          const ListTile(
            leading: Icon(Icons.people_outline),
            title: Text('Develop'),
            subtitle: Text('Team LingoVoice by Eng: Abdulmalk Ahmed'),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      child: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 16,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}
