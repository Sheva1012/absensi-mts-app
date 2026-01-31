// lib/core/constants.dart
class AppConstants {
  static const String schoolName = 'MTs Sunan Gunung Jati';
  
  // Gunakan --dart-define saat build untuk keamanan lebih tinggi
  // Contoh command: flutter run --dart-define=SUPABASE_URL=https://xyz.supabase.co ...
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL', 
    defaultValue: 'https://eachbhkjgadrpmrpbwat.supabase.co'
  );
  
  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImVhY2hiaGtqZ2FkcnBtcnBid2F0Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTk2Njk1MDEsImV4cCI6MjA3NTI0NTUwMX0.gZPdf88neU4yuLdKkUlTKNadpsRArxUp2IlQHk-XCrI' 
  );
}