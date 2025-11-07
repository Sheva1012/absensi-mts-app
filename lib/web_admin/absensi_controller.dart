import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AbsensiController extends ChangeNotifier {
  final SupabaseClient supabase = Supabase.instance.client;
  final String schoolName;

  bool _isLoading = true;
  bool _isKelasLoading = true; // State loading untuk kelas
  List<Map<String, dynamic>> _absensiData = [];
  List<Map<String, dynamic>> _daftarKelas = []; // State untuk daftar kelas
  DateTime _selectedDate = DateTime.now();
  int? _selectedKelasId; // State untuk ID kelas yang dipilih (nullable)

  AbsensiController({required this.schoolName}) {
    // Panggil inisialisasi data saat controller dibuat
    _initializeData();
  }

  // --- Getters ---
  bool get isLoading => _isLoading;
  bool get isKelasLoading => _isKelasLoading;
  List<Map<String, dynamic>> get absensiData => _absensiData;
  List<Map<String, dynamic>> get daftarKelas => _daftarKelas;
  DateTime get selectedDate => _selectedDate;
  int? get selectedKelasId => _selectedKelasId;

  set isLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void debugLog(String message) {
    debugPrint('[ABSENSI DEBUG] $message');
  }

  // --- Inisialisasi Data ---
  Future<void> _initializeData() async {
    // Ambil daftar kelas dulu, baru ambil data absensi
    await fetchDaftarKelas();
    await fetchAbsensi();
  }

  // --- Logika Fetching ---

  Future<void> fetchDaftarKelas() async {
    debugLog('Mulai fetch daftar kelas...');
    _isKelasLoading = true;
    notifyListeners();
    try {
      // Asumsi: Anda punya tabel 'kelas' dengan kolom 'nama_sekolah'

      // --- PERBAIKAN DI SINI ---
      // Tambahkan filter .eq('nama_sekolah', schoolName)
      final response = await supabase
          .from('kelas')
          .select('id, nama_kelas')
          .eq('nama_sekolah', schoolName) // Filter berdasarkan nama sekolah
          .order('nama_kelas', ascending: true);

      _daftarKelas = List<Map<String, dynamic>>.from(response);

      // Tambahkan opsi "Semua Kelas" di awal daftar
      _daftarKelas.insert(0, {'id': null, 'nama_kelas': 'Semua Kelas'});
      _selectedKelasId = null; // Default ke "Semua Kelas"

      debugLog('Daftar kelas berhasil dimuat: ${_daftarKelas.length} kelas');
    } catch (e, st) {
      debugLog('Error saat fetchDaftarKelas: $e');
      debugLog('Stack: $st');
      // Fallback jika gagal
      _daftarKelas = [
        {'id': null, 'nama_kelas': 'Semua Kelas'},
      ];
    } finally {
      _isKelasLoading = false;
      notifyListeners();
    }
  }

  // --- PERUBAHAN BESAR DI SINI ---
  // Logika diubah: Ambil siswa, lalu left-join absensi DENGAN FILTER
  Future<void> fetchAbsensi() async {
    isLoading = true;
    debugLog(
      'Mulai fetch absensi (perbaikan final tanpa PostgrestTransformBuilder error)...',
    );

    try {
      final String tglFilter = DateFormat('yyyy-MM-dd').format(_selectedDate);
      final int? localKelasId = _selectedKelasId;

      debugLog(
        'Filter tanggal: $tglFilter | Filter kelas: $localKelasId | Sekolah: $schoolName',
      );

      // 1️⃣ Ambil semua siswa (filter berdasarkan sekolah dan kelas)
      var siswaQuery = supabase
          .from('siswa')
          .select('id, nama, kelas_id, kelas!left(nama_kelas, nama_sekolah)')
          .eq('kelas.nama_sekolah', schoolName);

      if (localKelasId != null) {
        siswaQuery = siswaQuery.eq('kelas_id', localKelasId);
      }

      final List<Map<String, dynamic>> siswaList =
          List<Map<String, dynamic>>.from(
            await siswaQuery.order('nama', ascending: true),
          );

      // 2️⃣ Ambil absensi hanya untuk tanggal yang sedang dipilih
      final List<Map<String, dynamic>>
      absensiList = List<Map<String, dynamic>>.from(
        await supabase
            .from('absensi')
            .select(
              'id, siswa_id, tanggal, status, waktu_masuk, waktu_pulang, keterangan, updated_by, guru (nama)',
            )
            .eq('tanggal', tglFilter),
      );

      // 3️⃣ Gabungkan siswa dan absensi
      final List<Map<String, dynamic>> merged = [];

      for (final siswa in siswaList) {
        final abs = absensiList.firstWhere(
          (a) => a['siswa_id'] == siswa['id'],
          orElse: () => {},
        );

        if (abs.isEmpty) {
          merged.add({
            'id': null,
            'siswa_id': siswa['id'],
            'tanggal': tglFilter,
            'status': 'alfa',
            'waktu_masuk': null,
            'waktu_pulang': null,
            'keterangan': '',
            'updated_by': null,
            'guru': null,
            'siswa': {
              'id': siswa['id'],
              'nama': siswa['nama'],
              'kelas_id': siswa['kelas_id'],
            },
          });
        } else {
          merged.add({
            ...abs,
            'siswa': {
              'id': siswa['id'],
              'nama': siswa['nama'],
              'kelas_id': siswa['kelas_id'],
            },
          });
        }
      }

      _absensiData = merged;
      debugLog(
        'Berhasil gabungkan ${merged.length} siswa untuk tanggal $tglFilter',
      );
    } catch (e, st) {
      debugLog('Error fetchAbsensi: $e');
      debugLog('Stack: $st');
      _absensiData = [];
    } finally {
      isLoading = false;
    }
  }

  // --- Event Handlers ---

  Future<void> handleDatePick(BuildContext context) async {
    final newDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (newDate != null && newDate != _selectedDate) {
      _selectedDate = newDate;
      notifyListeners();
      await fetchAbsensi(); // Panggil fetchAbsensi
    }
  }

  // BARU: Handler untuk mengganti kelas
  Future<void> onKelasSelected(int? kelasId) async {
    if (kelasId == _selectedKelasId) return; // Tidak ada perubahan

    _selectedKelasId = kelasId;
    notifyListeners();
    await fetchAbsensi(); // Muat ulang data absensi dengan filter kelas baru
  }

  // --- FUNGSI BARU UNTUK MEMBUAT ABSENSI ---
  Future<void> createAbsensi({
    required int siswaId,
    required String status,
    required String keterangan,
    required TimeOfDay? waktuMasuk,
    required TimeOfDay? waktuPulang,
    required DateTime tanggal,
  }) async {
    debugLog('Membuat absensi baru untuk siswa $siswaId...');
    final String tgl = tanggal.toIso8601String().split('T').first;
    final String? wMasuk = waktuMasuk != null
        ? '${waktuMasuk.hour.toString().padLeft(2, '0')}:${waktuMasuk.minute.toString().padLeft(2, '0')}:00'
        : null;
    final String? wPulang = waktuPulang != null
        ? '${waktuPulang.hour.toString().padLeft(2, '0')}:${waktuPulang.minute.toString().padLeft(2, '0')}:00'
        : null;

    // Ambil ID guru yang sedang login
    final String? guruId = supabase.auth.currentUser?.id;

    final insertData = {
      'siswa_id': siswaId,
      'tanggal': tgl,
      'status': status,
      'waktu_masuk': wMasuk,
      'waktu_pulang': wPulang,
      'keterangan': keterangan,
      'updated_by': guruId, // Set guru_id sebagai updated_by
      // 'created_at' dan 'updated_at' akan di-handle Supabase
    };

    try {
      await supabase.from('absensi').insert(insertData);
      debugLog('Absensi baru berhasil dibuat.');

      // Logika refresh data setelah create (sama seperti update)
      if (DateFormat('yyyy-MM-dd').format(tanggal) ==
          DateFormat('yyyy-MM-dd').format(_selectedDate)) {
        await fetchAbsensi();
      } else {
        // Jika tanggal diubah ke hari lain, set _selectedDate
        // dan muat ulang.
        _selectedDate = tanggal;
        notifyListeners(); // Update date picker
        await fetchAbsensi(); // Muat data untuk tanggal baru
      }
    } catch (e) {
      debugLog('Error create absensi: $e');
      rethrow;
    }
  }

  Future<void> updateAbsensi({
    required int absensiId,
    required String status,
    required String keterangan,
    required TimeOfDay? waktuMasuk,
    required TimeOfDay? waktuPulang,
    required DateTime tanggal,
  }) async {
    debugLog('Memperbarui absensi $absensiId...');
    final String tgl = tanggal.toIso8601String().split('T').first;
    final String? wMasuk = waktuMasuk != null
        ? '${waktuMasuk.hour.toString().padLeft(2, '0')}:${waktuMasuk.minute.toString().padLeft(2, '0')}:00'
        : null;
    final String? wPulang = waktuPulang != null
        ? '${waktuPulang.hour.toString().padLeft(2, '0')}:${waktuPulang.minute.toString().padLeft(2, '0')}:00'
        : null;

    // Ambil ID guru yang sedang login
    final String? guruId = supabase.auth.currentUser?.id;

    final updateData = {
      'tanggal': tgl,
      'status': status,
      'waktu_masuk': wMasuk,
      'waktu_pulang': wPulang,
      'keterangan': keterangan,
      'updated_at': DateTime.now().toIso8601String(),
      'updated_by': guruId,
    };

    try {
      await supabase.from('absensi').update(updateData).eq('id', absensiId);
      debugLog('Absensi $absensiId berhasil diperbarui.');

      // Jika tanggal yang diedit SAMA dengan tanggal yang difilter,
      // muat ulang data.
      if (DateFormat('yyyy-MM-dd').format(tanggal) ==
          DateFormat('yyyy-MM-dd').format(_selectedDate)) {
        await fetchAbsensi();
      } else {
        // Jika tanggal diubah ke hari lain, cukup set _selectedDate
        // dan muat ulang.
        _selectedDate = tanggal;
        notifyListeners(); // Update date picker
        await fetchAbsensi(); // Muat data untuk tanggal baru
      }
    } catch (e) {
      debugLog('Error update absensi: $e');
      rethrow;
    }
  }

  // --- UTILITAS PEMFORMATAN DATA (PUBLIC) ---
  // (Tidak ada perubahan di bawah ini)

  // DIPERBARUI: Dibuat public (menghapus _)
  DateTime? parseDateTime(dynamic value) {
    if (value == null) return null;
    try {
      if (value is DateTime) {
        return value;
      }
      if (value is String && value.contains('T')) {
        return DateTime.parse(value);
      }
      if (value is String && value.length == 10) {
        return DateFormat('yyyy-MM-dd').parse(value);
      }
      return DateTime.parse(value.toString());
    } catch (e) {
      debugLog('_parseDateTime error for value=$value -> $e');
      return null;
    }
  }

  // DIPERBARUI: Dibuat public (menghapus _)
  TimeOfDay? parseTimeOfDay(dynamic value) {
    if (value == null) return null;
    try {
      final s = value.toString();
      final parts = s.split(':');
      if (parts.length >= 2) {
        return TimeOfDay(
          hour: int.parse(parts[0]),
          minute: int.parse(parts[1]),
        );
      }
      return null;
    } catch (e) {
      debugLog('_parseTimeOfDay error for value=$value -> $e');
      return null;
    }
  }

  String fmtDate(dynamic value) {
    final dt = parseDateTime(value); // Menggunakan metode public
    if (dt == null) return '-';
    return DateFormat('dd-MM-yyyy', 'id_ID').format(dt);
  }

  String fmtDateTime(dynamic value) {
    final dt = parseDateTime(value); // Menggunakan metode public
    if (dt == null) return '-';
    return DateFormat('dd-MM-yyyy HH:mm', 'id_ID').format(dt.toLocal());
  }

  String fmtTime(dynamic value) {
    final tod = parseTimeOfDay(value); // Menggunakan metode public
    if (tod == null) return '-';
    return '${tod.hour.toString().padLeft(2, '0')}:${tod.minute.toString().padLeft(2, '0')}';
  }
}
