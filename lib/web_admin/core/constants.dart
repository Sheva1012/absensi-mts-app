import 'package:flutter_dotenv/flutter_dotenv.dart';

// lib/core/constants.dart
class AppConstants {
  static const String schoolName = 'MTs Sunan Gunung Jati';
  
  // These can be set via initializeForWeb() on web platform
  static String? _webSupabaseUrl;
  static String? _webSupabaseAnonKey;
  
  /// Initialize web-specific constants (call this on web before accessing Supabase constants)
  static void initializeForWeb({
    required String supabaseUrl,
    required String supabaseAnonKey,
  }) {
    _webSupabaseUrl = supabaseUrl;
    _webSupabaseAnonKey = supabaseAnonKey;
  }
  
  /// Get Supabase URL from environment variables
  static String get supabaseUrl {
    // Check web override first
    if (_webSupabaseUrl != null && _webSupabaseUrl!.isNotEmpty) {
      return _webSupabaseUrl!;
    }
    
    final url = dotenv.env['SUPABASE_URL'];
    if (url == null || url.isEmpty) {
      throw Exception(
        'SUPABASE_URL is not configured. Please check your .env file.',
      );
    }
    return url;
  }

  /// Get Supabase Anonymous Key from environment variables
  static String get supabaseAnonKey {
    // Check web override first
    if (_webSupabaseAnonKey != null && _webSupabaseAnonKey!.isNotEmpty) {
      return _webSupabaseAnonKey!;
    }
    
    final key = dotenv.env['SUPABASE_ANON_KEY'];
    if (key == null || key.isEmpty) {
      throw Exception(
        'SUPABASE_ANON_KEY is not configured. Please check your .env file.',
      );
    }
    return key;
  }

  /// Get application environment (development, staging, production)
  static String get appEnvironment {
    return dotenv.env['APP_ENVIRONMENT'] ?? 'development';
  }

  /// Check if running in production environment
  static bool get isProduction => appEnvironment == 'production';

  /// Check if running in development environment
  static bool get isDevelopment => appEnvironment == 'development';
}

// Database Table Names
abstract class DbTables {
  static const String siswa = 'siswa';
  static const String guru = 'guru';
  static const String kelas = 'kelas';
  static const String absensi = 'absensi';
  static const String surat = 'surat';
}

// Database Column Names for Siswa
abstract class SiswaColumns {
  static const String id = 'id';
  static const String nis = 'nis';
  static const String nama = 'nama';
  static const String status = 'status';
  static const String kelasId = 'kelas_id';
  static const String email = 'email';
  static const String noHp = 'no_hp';
  static const String alamat = 'alamat';
  static const String createdAt = 'created_at';
  static const String updatedAt = 'updated_at';
}

// Database Column Names for Guru
abstract class GuruColumns {
  static const String id = 'id';
  static const String nip = 'nip';
  static const String nama = 'nama';
  static const String email = 'email';
  static const String noHp = 'no_hp';
  static const String status = 'status';
  static const String fotoUrl = 'foto_url';
  static const String createdAt = 'created_at';
  static const String updatedAt = 'updated_at';
}

// Database Column Names for Kelas
abstract class KelasColumns {
  static const String id = 'id';
  static const String namaKelas = 'nama_kelas';
  static const String tingkat = 'tingkat';
  static const String waliKelasId = 'wali_kelas_id';
  static const String jumlahSiswa = 'jumlah_siswa';
  static const String jamMasuk = 'jam_masuk';
  static const String jamPulang = 'jam_pulang';
  static const String createdAt = 'created_at';
  static const String updatedAt = 'updated_at';
}

// Database Column Names for Absensi
abstract class AbsensiColumns {
  static const String id = 'id';
  static const String siswaId = 'siswa_id';
  static const String tanggal = 'tanggal';
  static const String status = 'status';
  static const String keterangan = 'keterangan';
  static const String createdAt = 'created_at';
  static const String updatedAt = 'updated_at';
}

// Database Column Names for Surat
abstract class SuratColumns {
  static const String id = 'id';
  static const String siswaId = 'siswa_id';
  static const String tipe = 'tipe';
  static const String tanggal = 'tanggal';
  static const String alasan = 'alasan';
  static const String keterangan = 'keterangan';
  static const String createdAt = 'created_at';
  static const String updatedAt = 'updated_at';
}

// Student Status Enum
enum StudentStatus {
  aktif('aktif', 'Aktif'),
  lulus('lulus', 'Lulus'),
  tidakAktif('tidak aktif', 'Tidak Aktif');

  final String value;
  final String displayName;

  const StudentStatus(this.value, this.displayName);

  factory StudentStatus.fromValue(String value) {
    return StudentStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => StudentStatus.aktif,
    );
  }
}

// Attendance Status Enum
enum AttendanceStatus {
  hadir('hadir', 'Hadir'),
  terlambat('terlambat', 'Terlambat'),
  sakit('sakit', 'Sakit'),
  izin('izin', 'Izin'),
  alfa('alfa', 'Alfa'),
  pulang('pulang', 'Pulang');

  final String value;
  final String displayName;

  const AttendanceStatus(this.value, this.displayName);

  factory AttendanceStatus.fromValue(String value) {
    return AttendanceStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => AttendanceStatus.hadir,
    );
  }

  /// Check if status indicates student is present
  bool get isPresent => this == AttendanceStatus.hadir || this == AttendanceStatus.pulang;

  /// Check if status indicates student is absent
  bool get isAbsent =>
      this == AttendanceStatus.sakit ||
      this == AttendanceStatus.izin ||
      this == AttendanceStatus.alfa;

  /// Check if status indicates student is late
  bool get isLate => this == AttendanceStatus.terlambat;
}

// Letter Type Enum
enum LetterType {
  izin('izin', 'Izin'),
  sakit('sakit', 'Sakit');

  final String value;
  final String displayName;

  const LetterType(this.value, this.displayName);

  factory LetterType.fromValue(String value) {
    return LetterType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => LetterType.izin,
    );
  }
}

// GUI Status Color Mapping
abstract class StatusColors {
  static const Map<String, int> attendanceColors = {
    'hadir': 0xFF4CAF50,      // Green
    'terlambat': 0xFFFFC107,   // Amber
    'sakit': 0xFF2196F3,       // Blue
    'izin': 0xFF9C27B0,        // Purple
    'alfa': 0xFFF44336,        // Red
    'pulang': 0xFF00BCD4,      // Cyan
  };

  static const Map<String, int> studentStatusColors = {
    'aktif': 0xFF4CAF50,       // Green
    'lulus': 0xFF2196F3,       // Blue
    'tidak aktif': 0xFFFF5722, // Deep Orange
  };
}

// UI Constants
abstract class UiConstants {
  static const double defaultPadding = 16.0;
  static const double defaultBorderRadius = 8.0;
  static const Duration defaultAnimationDuration = Duration(milliseconds: 300);
  static const int searchDebounceMs = 500;
  static const int paginationPageSize = 20;
}