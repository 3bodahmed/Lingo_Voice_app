import 'package:english_app/view/SettingsScreen.dart';
import 'package:english_app/view/SpeechScreen.dart';
import 'package:english_app/view/TranslateScreen.dart';
import 'package:english_app/view/VocabularyScreen.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart' as path_provider;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter(); // ⬅️ هذه تعمل على كل المنصات
  await Hive.openBox('translations_cache');
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: .fromSeed(
          seedColor: const Color.fromARGB(255, 53, 121, 222),
        ),
        
        
      ),
      
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  List<Widget> pages = [
    Translatescreen(),
    Vocabularyscreen(),
    Speechscreen(),
    Settingsscreen(),
  ];
  int _selectedIndex = 0;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("LingoVoice"),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        items:[
          BottomNavigationBarItem(
            icon: Icon(Icons.translate_outlined),
            activeIcon: Icon(Icons.translate),
            label: 'Translate',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.menu_book_outlined),
            activeIcon: Icon(Icons.menu_book),
            label: 'My Vocabrlire',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.mic_outlined),
            activeIcon: Icon(Icons.mic),
            label: 'Speech',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
