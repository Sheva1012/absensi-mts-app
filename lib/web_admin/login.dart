import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
// Ganti 'main.dart' dengan path yang benar ke halaman dashboard Anda jika berbeda
// import 'main.dart'; // Removed or update with the correct relative path if needed, e.g.:
// import '../main.dart';

// --- Konstanta untuk Warna dan Gaya ---
// Memusatkan semua konstanta di satu tempat agar mudah diubah.
class AppColors {
  static const Color primary = Color(0xFF1E88E5);
  static const Color background = Color(0xFFB3E5FC);
  static const Color cardBackground = Colors.white;
  static const Color error = Colors.red;
  static const Color textLight = Colors.white;
  static const Color textDark = Colors.black54;
}

class AppStyles {
  static final buttonStyle = ElevatedButton.styleFrom(
    backgroundColor: AppColors.primary,
    foregroundColor: AppColors.textLight,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    elevation: 5,
  );

  static final inputDecoration = InputDecoration(
    filled: true,
    fillColor: Colors.grey.shade100,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide.none,
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
  );
}

// --- Widget Login Screen ---
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // GlobalKey untuk mengelola state dari Form.
  final _formKey = GlobalKey<FormState>();

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _isLoading = false;

  // Best practice: Selalu dispose controller untuk mencegah memory leaks.
  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  /// Menampilkan SnackBar dengan pesan error.
  /// Memisahkan logika UI seperti ini membuat kode lebih bersih.
  void _showErrorSnackBar(String message) {
    // Pastikan widget masih ada sebelum menampilkan SnackBar.
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.error),
    );
  }

  /// Fungsi untuk menangani proses login.
  Future<void> _handleLogin() async {
    // 1. Validasi semua TextFormField di dalam Form.
    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) {
      return; // Jika tidak valid, proses berhenti di sini.
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text.trim();

      // 2. Panggil Supabase Auth.
      // Cukup panggil method signIn. Navigasi akan ditangani secara otomatis
      // oleh listener yang akan kita pasang di main.dart.
      await Supabase.instance.client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      // 3. Navigasi tidak lagi diperlukan di sini.
      // Listener onAuthStateChange akan menangani perpindahan halaman.
    } on AuthException catch (e) {
      // 4. Tangani error otentikasi secara spesifik.
      // Ini memberikan pesan yang lebih relevan kepada pengguna.
      if (e.statusCode == '400') {
        _showErrorSnackBar('Email atau password salah. Silakan coba lagi.');
      } else {
        _showErrorSnackBar('Terjadi kesalahan jaringan: ${e.message}');
      }
    } catch (e) {
      // 5. Tangani error umum lainnya.
      _showErrorSnackBar('Terjadi kesalahan yang tidak terduga.');
    } finally {
      // 6. Pastikan loading state selalu kembali ke false.
      // Cek `context.mounted` sebelum setState.
      if (context.mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Latar belakang atas
          _buildTopBackground(),

          // Kartu form login
          Align(
            alignment: Alignment.center,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: screenWidth < 600 ? 400 : 500,
                ),
                child: Card(
                  color: AppColors.cardBackground,
                  elevation: 10,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    // Menggunakan Form widget
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          // Email Input
                          TextFormField(
                            controller: _emailController,
                            decoration: AppStyles.inputDecoration.copyWith(
                              labelText: 'Email',
                              hintText: 'contoh: guru@sekolah.id',
                              prefixIcon: const Icon(Icons.email_outlined),
                            ),
                            keyboardType: TextInputType.emailAddress,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Email tidak boleh kosong';
                              }
                              if (!value.contains('@') ||
                                  !value.contains('.')) {
                                return 'Format email tidak valid';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 20),

                          // Password Input
                          TextFormField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            decoration: AppStyles.inputDecoration.copyWith(
                              labelText: 'Password',
                              prefixIcon: const Icon(Icons.lock_outline),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscurePassword = !_obscurePassword;
                                  });
                                },
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Password tidak boleh kosong';
                              }
                              if (value.length < 5) {
                                return 'Password minimal 5 karakter';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 30),

                          // Tombol Login
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              style: AppStyles.buttonStyle,
                              onPressed: _isLoading ? null : _handleLogin,
                              child: _isLoading
                                  ? const CircularProgressIndicator(
                                      color: AppColors.textLight,
                                      strokeWidth: 3,
                                    )
                                  : const Text(
                                      'Login',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Logo dan nama sekolah di bawah
          _buildSchoolBranding(),
        ],
      ),
    );
  }

  // Widget-widget pembantu agar `build` method lebih rapi
  Widget _buildTopBackground() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        height: 200,
        decoration: const BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.only(bottomRight: Radius.circular(80)),
        ),
        child: const Padding(
          padding: EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Login',
                style: TextStyle(
                  color: AppColors.textLight,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Silahkan Login Untuk Melanjutkan',
                style: TextStyle(color: Colors.white70, fontSize: 16),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSchoolBranding() {
    return Positioned(
      bottom: 40,
      left: 0,
      right: 0,
      child: Column(
        children: [
          Image.asset('assets/Logo MTS.png', height: 60),
          const SizedBox(height: 8),
          const Text(
            'MTS Sunan Gunung Jati',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
          ),
        ],
      ),
    );
  }
}
