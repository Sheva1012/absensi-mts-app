import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'web_admin/login.dart';
import 'web_admin/dashboard.dart';
import 'web_admin/placeholder.dart';
import 'web_admin/sidebar.dart';
import 'web_admin/data_kelas.dart'; 
import 'web_admin/data_guru.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inisialisasi Supabase
  await Supabase.initialize(
    url: 'https://eachbhkjgadrpmrpbwat.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImVhY2hiaGtqZ2FkcnBtcnBid2F0Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTk2Njk1MDEsImV4cCI6MjA3NTI0NTUwMX0.gZPdf88neU4yuLdKkUlTKNadpsRArxUp2IlQHk-XCrI',
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Aplikasi Admin Sekolah',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        fontFamily: 'Segoe UI',
      ),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('id', 'ID'),
        Locale('en', 'US'),
      ],
      home: const AdminDashboardPage(),
    );
  }
}

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    if (index == 6) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
      return;
    }
    setState(() {
      _selectedIndex = index;
    });
  }

  // Halaman-halaman yang ditampilkan di sidebar
  late final List<Widget> _widgetOptions = <Widget>[
    const DashboardScreen(), // index 0
    const PlaceholderScreen(title: 'Halaman Absensi'), // index 1 (Absensi)
    const PageGuru(schoolName: 'MTs Sunan Gunung Jati'),
    const PageKelas(schoolName: 'MTs Sunan Gunung Jati'),
    const PlaceholderScreen(title: 'Halaman Siswa'), // index 4 (Siswa)
    const PlaceholderScreen(title: 'Halaman Surat'), // index 5 (Surat)
    const PlaceholderScreen(title: 'Log Out'), // index 6 (Log Out)
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          Sidebar(
            selectedIndex: _selectedIndex,
            onMenuSelected: _onItemTapped,
          ),
          Expanded(
            child: Container(
              color: const Color(0xFFf5f7fa),
              child: _selectedIndex < _widgetOptions.length
                  ? _widgetOptions[_selectedIndex]
                  : const PlaceholderScreen(title: 'Halaman Tidak Ditemukan'),
            ),
          ),
        ],
      ),
    );
  }
}
