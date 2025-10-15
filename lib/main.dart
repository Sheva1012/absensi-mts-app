import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'web_admin/login.dart';
import 'web_admin/dashboard.dart';
import 'web_admin/placeholder.dart';
import 'web_admin/sidebar.dart';
import 'web_admin/data_kelas.dart';
import 'web_admin/data_guru.dart';
import 'web_admin/data_siswa.dart';
import 'web_admin/data_absensi.dart';
// import 'web_admin/data_surat.dart'; // Uncomment jika file ini ada

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

// BARU: Tambahkan Supabase client instance agar bisa diakses di seluruh file
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
      // DIUBAH: Menggunakan AuthStateListener untuk navigasi otomatis
      home: const AuthStateListener(),
    );
  }
}

// BARU: Widget yang mendengarkan status otentikasi
class AuthStateListener extends StatelessWidget {
  const AuthStateListener({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: supabase.auth.onAuthStateChange,
      builder: (context, snapshot) {
        // Tampilkan loading indicator selagi menunggu status pertama
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final session = snapshot.data?.session;
        if (session != null) {
          // Jika user sudah login, tampilkan halaman dashboard
          return const AdminDashboardPage();
        } else {
          // Jika user belum login, tampilkan halaman login
          return const LoginScreen();
        }
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

  void _onItemTapped(int index) async { // Jadikan async
    // DIUBAH: Logika logout sekarang memanggil Supabase signOut()
    if (index == 6) { 
      await supabase.auth.signOut();
      // Navigator tidak diperlukan lagi, AuthStateListener akan menangani
      return;
    }
    setState(() {
      _selectedIndex = index;
    });
  }

  // Daftar halaman yang harus sesuai dengan indeks di sidebar
  // Pindahkan inisialisasi ke dalam initState untuk memastikan context tersedia jika diperlukan
  late final List<Widget> _widgetOptions;

  @override
  void initState() {
    super.initState();
    _widgetOptions = <Widget>[
      const DashboardScreen(), // Index 0: Dashboard
      const PageAbsensi(schoolName: 'MTs Sunan Gunung Jati'), // Index 1: Absensi
      const PageGuru(schoolName: 'MTs Sunan Gunung Jati'), // Index 2: Guru
      const PageKelas(schoolName: 'MTs Sunan Gunung Jati'), // Index 3: Kelas
      const DataSiswaPage(schoolName: 'MTs Sunan Gunung Jati'), // Index 4: Siswa
      const DataSuratPage(schoolName: 'MTs Sunan Gunung Jati'), // Index 5: Surat
      Container(), // Index 6: Log Out, tidak perlu widget karena sudah ditangani
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

// Tambahkan placeholder pages jika belum ada, atau impor dari file terpisah
class DataAbsensiPage extends StatelessWidget {
  final String schoolName;
  const DataAbsensiPage({super.key, required this.schoolName});
  @override
  Widget build(BuildContext context) {
    return const PlaceholderScreen(title: 'Halaman Absensi');
  }
}

class DataSuratPage extends StatelessWidget {
  final String schoolName;
  const DataSuratPage({super.key, required this.schoolName});
  @override
  Widget build(BuildContext context) {
    return const PlaceholderScreen(title: 'Halaman Surat');
  }
}
