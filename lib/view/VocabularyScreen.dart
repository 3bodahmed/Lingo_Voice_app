import 'package:flutter/material.dart';
import 'package:word_puzzle_pack/word_puzzle_pack.dart';
import 'package:translator/translator.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:hive/hive.dart';

class Vocabularyscreen extends StatefulWidget {
  const Vocabularyscreen({super.key});

  @override
  State<Vocabularyscreen> createState() => _VocabularyscreenState();
}

class _VocabularyscreenState extends State<Vocabularyscreen> {
  List<String> _words = [];
  late final Box _cacheBox;
  final FlutterTts _tts = FlutterTts();
  final GoogleTranslator _translator = GoogleTranslator();

  @override
  void initState() {
    super.initState();
    _cacheBox = Hive.box('translations_cache');
    _initTts();
    _loadWords();
  }

  void _initTts() {
    _tts.setLanguage('en-US');
    _tts.setPitch(1.0);
  }

  void _loadWords() {
    try {
      DictionaryData.loadDefaultEntries();
      final allWords = WordLists.getAllWords();

      setState(() {
        _words = allWords.take(1000).toList();
      });
    } catch (e) {
      setState(() {
        _words = ['hello', 'book', 'run', 'happy', 'big'];
      });
    }
  }

  Future<String> _getTranslation(String word) async {
    String cached = _cacheBox.get(word, defaultValue: '');
    if (cached.isNotEmpty) return cached;

    try {
      var translation = await _translator.translate(word, to: 'ar');
      await _cacheBox.put(word, translation.text);
      return translation.text;
    } catch (e) {
      return 'ترجمة غير متاحة';
    }
  }

  Future<void> _speak(String word) async {
    await _tts.stop();
    await _tts.speak(word);
  }

  @override
  void dispose() {
    _tts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _words.isEmpty
          ? const Center(child: Text('لا توجد كلمات'))
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: _words.length,
              itemBuilder: (context, index) {
                final word = _words[index];

                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.blue.shade100,
                      child: Text(
                        word.isNotEmpty ? word[0].toUpperCase() : '?',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    title: Text(
                      word,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: FutureBuilder<String>(
                      future: _getTranslation(word),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Text(
                            'جاري الترجمة...',
                            style: TextStyle(color: Colors.grey),
                          );
                        }
                        return Text(
                          snapshot.data ?? 'ترجمة غير متاحة',
                          style: TextStyle(color: Colors.grey.shade700),
                        );
                      },
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.volume_up, color: Colors.blue),
                      onPressed: () => _speak(word),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
