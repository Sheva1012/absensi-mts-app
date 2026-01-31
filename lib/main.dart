import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:window_manager/window_manager.dart';
import 'web_admin/core/constants.dart';

import 'web_admin/login.dart';
import 'web_admin/dashboard.dart';
import 'web_admin/sidebar.dart';
import 'web_admin/data/data_kelas.dart';
import 'web_admin/data/data_guru.dart';
import 'web_admin/data/data_siswa.dart';
import 'web_admin/data/data_absensi.dart';
import 'web_admin/data/data_surat.dart';
import 'web_admin/placeholder.dart';

final supabase = Supabase.instance.client;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Initialize Supabase 
  await Supabase.initialize(
    url: AppConstants.supabaseUrl, 
    anonKey: AppConstants.supabaseAnonKey, 
  );

  // 2. Setup Desktop
  if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
    await _setupDesktopWindow();
  }

  runApp(const MyApp());
}

Future<void> _setupDesktopWindow() async {
  await windowManager.ensureInitialized();

  const windowOptions = WindowOptions(
    // Menggunakan variabel nama sekolah
    title: 'Absensi ${AppConstants.schoolName}',
    center: true,
    minimumSize: Size(1100, 650),
    skipTaskbar: false,
    titleBarStyle: TitleBarStyle.normal,
  );

  windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
    await windowManager.focus();
    await Future.delayed(const Duration(milliseconds: 150));
    await windowManager.maximize();

    final isMax = await windowManager.isMaximized();
    if (!isMax) {
      await windowManager.maximize();
    }
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // Menggunakan variabel nama sekolah
      title: 'Admin ${AppConstants.schoolName}',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: 'Poppins',
        useMaterial3: true,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('id', 'ID'), Locale('en', 'US')],
      home: const AuthGate(),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

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
        return session != null
            ? const AdminDashboardPage()
            : const LoginScreen();
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
  String? _selectedKelasId;

  void _onMenuSelected(int index) async {
    if (index == 6) {
      await supabase.auth.signOut();
      return;
    }
    setState(() {
      _selectedIndex = index;
      if (index != 4) {
        _selectedKelasId = null;
      }
    });
  }

  void _navigateToSiswaPerKelas(String kelasId) {
    setState(() {
      _selectedKelasId = kelasId;
      _selectedIndex = 4;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Mapping halaman menggunakan Constants untuk nama sekolah
    final List<Widget> pages = [
      const DashboardScreen(),
      const PageAbsensi(
        schoolName: AppConstants.schoolName,
      ),
      const PageGuru(
        schoolName: AppConstants.schoolName,
      ),
      PageKelas(
        schoolName: AppConstants.schoolName,
        onViewSiswa: _navigateToSiswaPerKelas,
      ),
      DataSiswaPage(
        schoolName: AppConstants.schoolName,
        initialKelasId: _selectedKelasId,
      ),
      const DataSuratPage(
        schoolName: AppConstants.schoolName,
      ),
      const SizedBox(),
    ];

    final Widget content = (_selectedIndex < pages.length)
        ? pages[_selectedIndex]
        : const PlaceholderScreen(title: 'Halaman Tidak Ditemukan');

    return Scaffold(
      body: Row(
        children: [
          Sidebar(
            selectedIndex: _selectedIndex,
            onMenuSelected: _onMenuSelected,
          ),
          Expanded(
            child: Container(
              color: const Color(0xFFf5f7fa),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: KeyedSubtree(
                  key: ValueKey<int>(_selectedIndex),
                  child: content,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
