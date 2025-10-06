import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'web_admin/login.dart';
import 'web_admin/dashboard.dart';
import 'web_admin/data_orangtua.dart';
import 'web_admin/kelas/kelas7A.dart';
import 'web_admin/kelas/kelas7B.dart';
import 'web_admin/kelas/kelas7C.dart';
import 'web_admin/kelas/kelas8A.dart';
import 'web_admin/kelas/kelas8B.dart';
import 'web_admin/kelas/kelas8C.dart';
import 'web_admin/kelas/kelas9A.dart';
import 'web_admin/kelas/kelas9B.dart';
import 'web_admin/kelas/kelas9C.dart';
import 'web_admin/placeholder.dart';
import 'web_admin/sidebar.dart';

// --- Halaman Utama Aplikasi Dashboard (Setelah Login) ---
class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  int _selectedIndex = 0; // Default ke Dashboard (Index 0)

  void _onItemTapped(int index) {
    if (index == 11) {
      // Index Log Out
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

  static const List<Widget> _widgetOptions = <Widget>[
    // Index 0: Dashboard
    DashboardScreen(),

    // Kelas 7
    Kelas7A(), // Index 1
    Kelas7B(), // Index 2
    Kelas7C(), // Index 3

    // Kelas 8
    Kelas8A(), // Index 4
    Kelas8B(), // Index 5
    Kelas8C(), // Index 6

    // Kelas 9
    Kelas9A(), // Index 7
    Kelas9B(), // Index 8
    Kelas9C(), // Index 9

    // Index 10: Data Orang Tua
    DataOrangTuaScreen(),

    // Index 11: Log Out (Ditangani di _onItemTapped)
    PlaceholderScreen(title: 'Log Out'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: <Widget>[
          SizedBox(
            width: 250,
            child: Sidebar(
              selectedIndex: _selectedIndex,
              onMenuSelected: _onItemTapped,
            ),
          ),
          Expanded(
            child: Container(
              color: const Color(0xFFf5f7fa),
              child: _widgetOptions.elementAt(_selectedIndex),
            ),
          ),
        ],
      ),
    );
  }
}

// --- Main App Entry Point ---
void main() {
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
      
      // 🔹 Tambahkan Localizations biar DatePicker tidak error
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],

      supportedLocales: const [
        Locale('id', 'ID'), // Bahasa Indonesia
        Locale('en', 'US'), // fallback Inggris
      ],

      // home: const LoginScreen(), // <-- ini sebelumnya
      home: const AdminDashboardPage(), // langsung ke dashboard
    );
  }
}
