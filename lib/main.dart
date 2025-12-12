import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:window_manager/window_manager.dart';

import 'web_admin/login.dart';
import 'web_admin/dashboard.dart';
import 'web_admin/placeholder.dart';
import 'web_admin/sidebar.dart';
import 'web_admin/data_kelas.dart';
import 'web_admin/data_guru.dart';
import 'web_admin/data_siswa.dart';
import 'web_admin/data_absensi.dart';
import 'web_admin/data_surat.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://eachbhkjgadrpmrpbwat.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImVhY2hiaGtqZ2FkcnBtcnBid2F0Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTk2Njk1MDEsImV4cCI6MjA3NTI0NTUwMX0.gZPdf88neU4yuLdKkUlTKNadpsRArxUp2IlQHk-XCrI',
  );

  // Window Manager hanya untuk Desktop (bukan Web)
  if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
    await windowManager.ensureInitialized();

    const windowOptions = WindowOptions(
      title: 'Absensi',
      center: true,


      minimumSize: Size(1100, 650),
    );

    windowManager.waitUntilReadyToShow(windowOptions, () async {
      // show + focus dulu
      await windowManager.show();
      await windowManager.focus();

      // Delay sedikit supaya engine stabil (menghindari blank)
      await Future.delayed(const Duration(milliseconds: 150));

      // FULLSCREEN DENGAN BORDER = MAXIMIZE
      await windowManager.maximize();

      // kalau Windows kadang belum apply, paksa sekali lagi
      await Future.delayed(const Duration(milliseconds: 150));
      final isMax = await windowManager.isMaximized();
      if (!isMax) {
        await windowManager.maximize();
      }
    });
  }

  runApp(const MyApp());
}

// Supabase client global
final supabase = Supabase.instance.client;

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
      supportedLocales: const [Locale('id', 'ID'), Locale('en', 'US')],
      home: const AuthStateListener(),
    );
  }
}

class AuthStateListener extends StatelessWidget {
  const AuthStateListener({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: supabase.auth.onAuthStateChange,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final session = snapshot.data?.session;
        return session != null ? const AdminDashboardPage() : const LoginScreen();
      },
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
  late List<Widget> _widgetOptions;

  void _navigateToSiswa(String kelasId) {
    setState(() {
      _widgetOptions[4] = DataSiswaPage(
        schoolName: 'MTs Sunan Gunung Jati',
        initialKelasId: kelasId,
      );
      _selectedIndex = 4;
    });
  }

  void _onItemTapped(int index) async {
    if (index == 6) {
      await supabase.auth.signOut();
      return;
    }

    if (index == 4) {
      setState(() {
        _widgetOptions[4] = const DataSiswaPage(
          schoolName: 'MTs Sunan Gunung Jati',
          initialKelasId: null,
        );
        _selectedIndex = index;
      });
      return;
    }

    setState(() => _selectedIndex = index);
  }

  @override
  void initState() {
    super.initState();
    _widgetOptions = <Widget>[
      const DashboardScreen(),
      const PageAbsensi(schoolName: 'MTs Sunan Gunung Jati'),
      const PageGuru(schoolName: 'MTs Sunan Gunung Jati'),
      PageKelas(
        schoolName: 'MTs Sunan Gunung Jati',
        onViewSiswa: _navigateToSiswa,
      ),
      const DataSiswaPage(
        schoolName: 'MTs Sunan Gunung Jati',
        initialKelasId: null,
      ),
      const DataSuratPage(schoolName: 'MTs Sunan Gunung Jati'),
      Container(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          Sidebar(selectedIndex: _selectedIndex, onMenuSelected: _onItemTapped),
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
