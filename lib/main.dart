// main.dart
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'View/event_recommender_screen.dart';
import 'View/favorite_event_screen.dart';
import 'View/recommender_screen.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  await Firebase.initializeApp(
   options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Get saved user ID or generate a temporary one
  final prefs = await SharedPreferences.getInstance();
  String userId = prefs.getString('userId') ?? 'user123';
  
  runApp(MyApp(userId: userId));
}

class MyApp extends StatelessWidget {
  final String userId;
  
  const MyApp({Key? key, required this.userId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Seekhere',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF8E97FD)),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF8E97FD),
          foregroundColor: Colors.white,
          elevation: 2,
        ),
        cardTheme: CardTheme(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        useMaterial3: true,
      ),
      home: const MainScreen(),
      routes: {
        '/event-recommender': (context) => EventRecommenderScreen(userId: userId),
        '/favorite-events': (context) => FavoriteEventsScreen(userId: userId),
        '/recommender': (context) => RecommenderScreen(userId: userId),
      },
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({Key? key}) : super(key: key);

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 2; // Default to the recommender tab
  late String userId;
  
  @override
  void initState() {
    super.initState();
    _getUserId();
  }
  
  Future<void> _getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    userId = prefs.getString('userId') ?? 'user123';
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    // Get userId from parent widget
    userId = 'user123';
    
    final List<Widget> pages = [
      const Placeholder(child: Center(child: Text('Book of Answer'))),
      const Placeholder(child: Center(child: Text('Mood Recorder'))),
      RecommenderScreen(userId: userId),
      const Placeholder(child: Center(child: Text('Diary'))),
      const Placeholder(child: Center(child: Text('Account'))),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        selectedItemColor: const Color(0xFF8E97FD),
        unselectedItemColor: Colors.grey,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.menu_book),
            label: 'BoA',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.mood),
            label: 'Mood',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.location_on, color: Color(0xFF8E97FD)),
            activeIcon: CircleAvatar(
              backgroundColor: Color(0xFF8E97FD),
              radius: 24,
              child: Icon(Icons.location_on, color: Colors.white),
            ),
            label: 'Recommender',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.book),
            label: 'Diary',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Account',
          ),
        ],
      ),
    );
  }
}