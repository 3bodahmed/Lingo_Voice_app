import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_tts/flutter_tts.dart';

class StoriesScreen extends StatefulWidget {
  const StoriesScreen({super.key});

  @override
  State<StoriesScreen> createState() => _StoriesScreenState();
}

class _StoriesScreenState extends State<StoriesScreen> {
  final FlutterTts _flutterTts = FlutterTts();
  final ScrollController _scrollController = ScrollController();

  List<Map<String, String>> _stories = [];
  bool _isLoadingMore = false;
  bool _isInitialLoading = true;
  String _errorMessage = '';
  int _skip = 0;
  final int _limit = 5;

  @override
  void initState() {
    super.initState();
    _initTts();
    _fetchMoreStories(isRefresh: true);

    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
              _scrollController.position.maxScrollExtent - 200 &&
          !_isLoadingMore) {
        _fetchMoreStories();
      }
    });
  }

  void _initTts() {
    _flutterTts.setPitch(1.0);
    _flutterTts.setSpeechRate(0.45);
  }

  Future<void> _fetchMoreStories({bool isRefresh = false}) async {
    if (_isLoadingMore && !isRefresh) return;

    if (isRefresh) {
      _skip = 0;
      setState(() {
        _stories = [];
        _isInitialLoading = true;
        _errorMessage = '';
      });
    }

    setState(() => _isLoadingMore = true);

    try {
      // استخدام DummyJSON Quotes API (سريع ولا يحتاج مفاتيح أو VPN)
      final String url =
          'https://dummyjson.com/quotes?limit=$_limit&skip=$_skip';

      final response = await http
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 6));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> quotes = data['quotes'] ?? [];

        List<Map<String, String>> newStories = [];
        for (var item in quotes) {
          String quoteText = item['quote'] ?? '';
          String author = item['author'] ?? 'حكمة عالمية';

          newStories.add({
            'title': 'مقولة / حكمة مترجمة',
            'author': author,
            'english': quoteText,
            'arabic': 'اضغط على زر الترجمة لعرض النص العربي',
          });
        }

        setState(() {
          if (isRefresh) _stories.clear();
          _stories.addAll(newStories);
          _skip += _limit;
        });
      } else {
        throw Exception('الخادم غير المباشر لم يستجب.');
      }
    } catch (e) {
      // في حال وجود مشكلة في الاتصال، يتم الانتقال تلقائياً للقصص المحلية
      if (_stories.isEmpty) {
        _loadFallbackStories();
        setState(() {
          _errorMessage = '⚠️ تعذر الاتصال بالشبكة، تم عرض قصص محلية.';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingMore = false;
          _isInitialLoading = false;
        });
      }
    }
  }

  void _loadFallbackStories() {
    List<Map<String, String>> localStories = [
      {
        'title': 'The Honest Woodcutter (الحطاب الأمين)',
        'author': 'Aesop',
        'english':
            'A poor woodcutter dropped his axe into a river. A fairy helped him find his gold, silver, and real axe.',
        'arabic':
            'أسقط حطاب فقير فأسه في النهر. ساعدته حورية في العثور على فأسه الذهبية والفضية والحقيقية.',
      },
      {
        'title': 'The Boy Who Cried Wolf (الراعي والكذاب)',
        'author': 'Aesop',
        'english':
            'A boy lied about a wolf attacking sheep. When a real wolf came, nobody believed him.',
        'arabic':
            'كذب ولد بشأن هجوم ذئب على الخراف. وعندما جاء ذئب حقيقي، لم يصدقه أحد.',
      },
      {
        'title': 'The Lion and the Mouse (الأسد والفأر)',
        'author': 'Aesop',
        'english':
            'A lion caught a mouse. The mouse begged for mercy and promised to help him later. Later, the mouse saved the lion from a hunter\'s net.',
        'arabic':
            'أمسك أسد بفأر. توسل الفأر للرحمة ووعد بمساعدته. لاحقاً، أنقذ الفأر الأسد من شبكة صياد.',
      },
    ];

    setState(() {
      _stories.addAll(localStories);
    });
  }

  Future<void> _translateStory(int index) async {
    if (index >= _stories.length) return;

    final story = _stories[index];
    final englishText = story['english'] ?? '';

    if (englishText.isEmpty ||
        story['arabic'] != 'اضغط على زر الترجمة لعرض النص العربي') {
      return;
    }

    setState(() {
      _stories[index]['arabic'] = 'جاري الترجمة...';
    });

    try {
      final response = await http
          .get(
            Uri.parse(
              'https://api.mymemory.translated.net/get?q=${Uri.encodeComponent(englishText)}&langpair=en|ar',
            ),
          )
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final translation =
            data['responseData']['translatedText'] ?? 'فشلت الترجمة';
        setState(() {
          _stories[index]['arabic'] = translation;
        });
      } else {
        throw Exception();
      }
    } catch (e) {
      setState(() {
        _stories[index]['arabic'] = 'تعذرت الترجمة حالياً، حاول لاحقاً';
      });
    }
  }

  Future<void> _speak(String text, String lang) async {
    if (text.isEmpty) return;
    await _flutterTts.stop();
    await _flutterTts.setLanguage(lang == 'en' ? 'en-US' : 'ar-SA');
    await _flutterTts.speak(text);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _flutterTts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          if (_errorMessage.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                _errorMessage,
                style: const TextStyle(color: Colors.orange, fontSize: 13),
              ),
            ),

          Expanded(
            child: _isInitialLoading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: () => _fetchMoreStories(isRefresh: true),
                    child: ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(10),
                      itemCount: _stories.length + 1,
                      itemBuilder: (context, index) {
                        if (index == _stories.length) {
                          return _isLoadingMore
                              ? const Padding(
                                  padding: EdgeInsets.all(16.0),
                                  child: Center(
                                    child: CircularProgressIndicator(),
                                  ),
                                )
                              : const SizedBox.shrink();
                        }

                        final story = _stories[index];
                        return Card(
                          elevation: 3,
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        story['english'] ?? '',
                                        style: const TextStyle(
                                          fontSize: 15,
                                          height: 1.4,
                                        ),
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.volume_up,
                                        color: Colors.blue,
                                      ),
                                      onPressed: () =>
                                          _speak(story['english']!, 'en'),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade100,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          story['arabic'] ?? '',
                                          style: const TextStyle(
                                            fontSize: 14,
                                            color: Colors.black87,
                                          ),
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(
                                          Icons.translate,
                                          color: Colors.green,
                                        ),
                                        onPressed: () => _translateStory(index),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
