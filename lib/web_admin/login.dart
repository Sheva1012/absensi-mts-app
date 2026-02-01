import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/constants.dart';
import 'core/theme.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controller
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  // Focus Nodes
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();

  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _handleLogin() async {
    if (_isLoading) return;

    // Validasi Form
    if (!_formKey.currentState!.validate()) return;

    // Tutup Keyboard
    FocusScope.of(context).unfocus();

    setState(() => _isLoading = true);

    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text.trim();

      // Eksekusi Login ke Supabase
      final response = await Supabase.instance.client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user == null) {
        throw const AuthException('Login gagal, user tidak ditemukan.');
      }

      // Catatan: Jika sukses, AuthGate di main.dart akan otomatis mengarahkan ke Dashboard
    } on AuthException catch (e) {
      // Handle error spesifik Supabase
      String msg = 'Terjadi kesalahan saat login.';
      if (e.message.contains('Invalid login credentials')) {
        msg = 'Email atau password salah.';
      } else if (e.message.contains('Email not confirmed')) {
        msg = 'Email belum dikonfirmasi.';
      }
      _showErrorSnackBar(msg);
    } catch (e) {
      _showErrorSnackBar('Gagal terhubung ke server.');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        alignment:
            Alignment.topCenter, // Pastikan alignment stack ke tengah atas
        children: [
          // 1. Background Header Biru (Layer Paling Bawah)
          _buildTopBackground(),

          // 2. Logo & Teks (Layer Tengah - Ditaruh DI ATAS Background)
          _buildHeaderBranding(),

          // 3. Form Card (Layer Paling Atas - Scrollable)
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // PENTING: Spacer ini menggantikan tempat Logo yang dipindah ke atas
                  // Agar Card Login tidak menutupi Logo/Header
                  const SizedBox(height: 220),

                  ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: size.width < 600 ? 400 : 450,
                    ),
                    child: Card(
                      elevation: 8,
                      shadowColor: Colors.black26,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(32.0),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                'Selamat Datang',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primaryDark,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Silahkan login untuk mengakses panel admin',
                                style: TextStyle(color: AppColors.textGrey),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 30),

                              // Input Email
                              TextFormField(
                                controller: _emailController,
                                focusNode: _emailFocus,
                                decoration: AppStyles.inputDecoration(
                                  'Email',
                                  Icons.email_outlined,
                                ),
                                keyboardType: TextInputType.emailAddress,
                                textInputAction: TextInputAction.next,
                                autofillHints: const [AutofillHints.email],
                                onFieldSubmitted: (_) => FocusScope.of(
                                  context,
                                ).requestFocus(_passwordFocus),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Email wajib diisi';
                                  }
                                  if (!value.contains('@')) {
                                    return 'Format email tidak valid';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 20),

                              // Input Password
                              TextFormField(
                                controller: _passwordController,
                                focusNode: _passwordFocus,
                                obscureText: _obscurePassword,
                                decoration:
                                    AppStyles.inputDecoration(
                                      'Password',
                                      Icons.lock_outline,
                                    ).copyWith(
                                      suffixIcon: IconButton(
                                        icon: Icon(
                                          _obscurePassword
                                              ? Icons.visibility_off
                                              : Icons.visibility,
                                          color: Colors.grey,
                                        ),
                                        onPressed: () => setState(
                                          () => _obscurePassword =
                                              !_obscurePassword,
                                        ),
                                      ),
                                    ),
                                textInputAction: TextInputAction.done,
                                onFieldSubmitted: (_) => _handleLogin(),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Password wajib diisi';
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
                                height: 50,
                                child: ElevatedButton(
                                  style: AppStyles.buttonStyle,
                                  onPressed: _isLoading ? null : _handleLogin,
                                  child: _isLoading
                                      ? const SizedBox(
                                          height: 20,
                                          width: 20,
                                          child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 3,
                                          ),
                                        )
                                      : const Text('MASUK'),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 50),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBackground() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      height: 200, // Sedikit dipertinggi agar muat logo + teks
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(40),
            bottomRight: Radius.circular(100),
          ),
        ),
      ),
    );
  }

  // UBAH INI JADI POSITIONED
  Widget _buildHeaderBranding() {
    return Positioned(
      top: 30, // Jarak dari atas layar
      left: 0,
      right: 0,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8), // Padding diperkecil sedikit
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            // Pastikan aset logo ada
            child: Image.asset('assets/Logo MTS.png', height: 80, width: 80),
          ),
          const SizedBox(height: 12),
          Text(
            AppConstants.schoolName,
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w800,
              color: Colors
                  .white, // Warna Putih agar kontras dengan Background Biru
              shadows: [
                Shadow(
                  offset: Offset(0, 2),
                  blurRadius: 4,
                  color: Colors.black26,
                ),
              ],
              letterSpacing: 0.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
