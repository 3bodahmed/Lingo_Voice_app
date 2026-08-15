import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:translator/translator.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:http/http.dart' as http;

class Translatescreen extends StatefulWidget {
  const Translatescreen({super.key});

  @override
  State<Translatescreen> createState() => _TranslatescreenState();
}

class _TranslatescreenState extends State<Translatescreen> {
  final TextEditingController _controller = TextEditingController();
  final GoogleTranslator _translator = GoogleTranslator();
  final FlutterTts _flutterTts = FlutterTts();

  String _translatedText = 'The translation will appear here  ...';
  List<String> _exampleSentences = [];
  String _selectedLanguage = 'en';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initTts();
  }

  void _initTts() {
    _flutterTts.setPitch(1.0);
    _flutterTts.setSpeechRate(0.5);
  }

  Future<List<String>> _fetchExamplesFromApi(String word) async {
    List<String> examples = [];
    final url = Uri.parse(
      'https://api.dictionaryapi.dev/api/v2/entries/en/$word',
    );

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);

        for (var entry in data) {
          if (entry['meanings'] != null) {
            for (var meaning in entry['meanings']) {
              if (meaning['definitions'] != null) {
                for (var def in meaning['definitions']) {
                  if (def['example'] != null &&
                      def['example'].toString().isNotEmpty) {
                    examples.add(def['example']);
                    if (examples.length >= 2) return examples;
                  }
                }
              }
            }
          }
        }
      }
    } catch (_) {
    }
    return examples;
  }

  Future<List<String>> _generateFallbackExamples(String word, int count) async {
    try {
      String prompt =
          "Generate $count simple short example sentences using the word '$word'.";
      var res = await _translator.translate(prompt, to: 'en');
      List<String> lines = res.text
          .split(RegExp(r'\n|\d+\.'))
          .where((e) => e.trim().isNotEmpty && !e.contains("Generate"))
          .map((e) => e.trim())
          .toList();
      return lines.take(count).toList();
    } catch (_) {
      return List.generate(count, (i) => "This is a sentence with $word.");
    }
  }

  Future<void> _translateText() async {
    final text = _controller.text.trim();
    if (text.isEmpty) {
      setState(() {
        _translatedText = 'الرجاء إدخال كلمة أو جملة...';
        _exampleSentences = [];
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final targetLang = _selectedLanguage == 'en' ? 'ar' : 'en';

      var translation = await _translator.translate(text, to: targetLang);
      String englishWord = _selectedLanguage == 'en' ? text : translation.text;

      List<String> rawExamples = await _fetchExamplesFromApi(
        englishWord.toLowerCase(),
      );

      if (rawExamples.length < 1) {
        List<String> fallback = await _generateFallbackExamples(
          englishWord,
          5 - rawExamples.length,
        );
        rawExamples.addAll(fallback);
      }

      List<String> finalExamples = await Future.wait(
        rawExamples.take(5).map((ex) async {
          if (targetLang == 'ar') {
            try {
              var tr = await _translator.translate(ex, to: 'ar');
              return "${tr.text}\n($ex)";
            } catch (_) {
              return ex;
            }
          }
          return ex;
        }),
      );

      setState(() {
        _translatedText = translation.text;
        _exampleSentences = finalExamples;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _translatedText = 'حدث خطأ أثناء الترجمة';
        _exampleSentences = [];
        _isLoading = false;
      });
    }
  }

  Future<void> _speak(String text, String langCode) async {
    if (text.isNotEmpty) {
      await _flutterTts.stop();
      String cleanText = text.contains('(')
          ? text.split('(').last.replaceAll(')', '')
          : text;
      await _flutterTts.setLanguage(langCode == 'en' ? 'en-US' : 'ar-SA');
      await _flutterTts.speak(cleanText);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _flutterTts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final targetLang = _selectedLanguage == 'en' ? 'ar' : 'en';

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.2),
                    spreadRadius: 2,
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: TextField(
                controller: _controller,
                decoration: InputDecoration(
                  hintText: "Enter Word ...",
                  prefixIcon: const Icon(Icons.translate),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.search, color: Colors.blue),
                    onPressed: _translateText,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 16,
                    horizontal: 16,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 15),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text("Endlish "),
                Radio<String>(
                  value: "en",
                  groupValue: _selectedLanguage,
                  onChanged: (value) {
                    setState(() => _selectedLanguage = value!);
                  },
                ),
                const SizedBox(width: 20),
                const Text(" العربية"),
                Radio<String>(
                  value: "ar",
                  groupValue: _selectedLanguage,
                  onChanged: (value) {
                    setState(() => _selectedLanguage = value!);
                  },
                ),
              ],
            ),
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: _isLoading
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(20.0),
                        child: CircularProgressIndicator(),
                      ),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                _translatedText,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Color.fromARGB(255, 44, 88, 165),
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.volume_up,
                                color: Colors.blue,
                                size: 28,
                              ),
                              onPressed: () =>
                                  _speak(_translatedText, targetLang),
                            ),
                          ],
                        ),
                        if (_exampleSentences.isNotEmpty) ...[
                          const Divider(height: 30),
                          const Text(
                            " Examples :",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 10),
                          ..._exampleSentences.asMap().entries.map((entry) {
                            int index = entry.key + 1;
                            String example = entry.value;

                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.grey.shade200),
                              ),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 12,
                                    backgroundColor: Colors.blue.shade100,
                                    child: Text(
                                      "$index",
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.blue,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      example,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        height: 1.4,
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.volume_up_outlined,
                                      size: 20,
                                      color: Colors.grey,
                                    ),
                                    onPressed: () => _speak(example, 'en'),
                                  ),
                                ],
                              ),
                            );
                          }),
                        ],
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
