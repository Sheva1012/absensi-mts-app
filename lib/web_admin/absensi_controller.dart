import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AbsensiController extends ChangeNotifier {
  final SupabaseClient supabase = Supabase.instance.client;
  final String schoolName; // hanya label tampilan, bukan filter query

  // --- State ---
  bool _isLoading = true;
  bool _isKelasLoading = true;
  List<Map<String, dynamic>> _absensiData = [];
  List<Map<String, dynamic>> _daftarKelas = [];
  DateTime _selectedDate = DateTime.now();
  int? _selectedKelasId;

  AbsensiController({required this.schoolName}) {
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

  void debugLog(String message) => debugPrint('[ABSENSI DEBUG] $message');

  // --- Inisialisasi ---
  Future<void> _initializeData() async {
    await fetchDaftarKelas();
    await fetchAbsensi();
  }

  // --- Ambil daftar kelas ---
  Future<void> fetchDaftarKelas() async {
    debugLog('Mulai fetch daftar kelas...');
    _isKelasLoading = true;
    notifyListeners();

    try {
      final response = await supabase
          .from('kelas')
          .select('id, nama_kelas')
          .order('nama_kelas', ascending: true);

      _daftarKelas = List<Map<String, dynamic>>.from(response);
      _daftarKelas.insert(0, {'id': null, 'nama_kelas': 'Semua Kelas'});
      _selectedKelasId = null;
    } catch (e, st) {
      debugLog('Error fetchDaftarKelas: $e\n$st');
      _daftarKelas = [
        {'id': null, 'nama_kelas': 'Semua Kelas'},
      ];
    } finally {
      _isKelasLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchAbsensi() async {
    isLoading = true;
    debugLog('Mulai fetch absensi...');

    try {
      final tglFilter = DateFormat('yyyy-MM-dd').format(_selectedDate);
      final localKelasId = _selectedKelasId;

      // ✅ 1️⃣ Ambil semua siswa aktif
      final siswaResult = localKelasId == null
          ? await supabase
                .from('siswa')
                .select('id, nama, kelas_id, status')
                .order('nama')
          : await supabase
                .from('siswa')
                .select('id, nama, kelas_id, status')
                .eq('kelas_id', localKelasId)
                .order('nama');

      final siswaList = List<Map<String, dynamic>>.from(siswaResult);
      debugLog('Jumlah siswa: ${siswaList.length}');

      // ✅ 2️⃣ Ambil absensi hari itu
      final absensiResult = await supabase
          .from('absensi')
          .select(
            'id, siswa_id, tanggal, status, waktu_masuk, waktu_pulang, '
            'keterangan, updated_by, guru (nama)',
          )
          .eq('tanggal', tglFilter);

      final absensiList = List<Map<String, dynamic>>.from(absensiResult);
      debugLog('Jumlah absensi tanggal $tglFilter: ${absensiList.length}');

      // ✅ 3️⃣ Gabungkan data
      final merged = <Map<String, dynamic>>[];
      for (final siswa in siswaList) {
        final abs = absensiList.firstWhere(
          (a) => a['siswa_id'] == siswa['id'],
          orElse: () => {},
        );

        merged.add(
          abs.isEmpty
              ? {
                  'id': null,
                  'siswa_id': siswa['id'],
                  'tanggal': tglFilter,
                  'status': 'alfa',
                  'waktu_masuk': null,
                  'waktu_pulang': null,
                  'keterangan': 'Belum diabsen.',
                  'updated_by': null,
                  'guru': null,
                  'siswa': siswa,
                }
              : {...abs, 'siswa': siswa},
        );
      }

      _absensiData = merged;
      debugLog('Data gabungan: ${merged.length} siswa ditampilkan.');
    } catch (e, st) {
      debugLog('Error fetchAbsensi: $e\n$st');
      _absensiData = [];
    } finally {
      isLoading = false;
    }
  }

  // --- Event: pilih tanggal ---
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
      await fetchAbsensi();
    }
  }

  // --- Event: pilih kelas ---
  Future<void> onKelasSelected(int? kelasId) async {
    if (kelasId == _selectedKelasId) return;
    _selectedKelasId = kelasId;
    notifyListeners();
    await fetchAbsensi();
  }

  // --- CREATE Absensi ---
  Future<void> createAbsensi({
    required int siswaId,
    required String status,
    required String keterangan,
    required TimeOfDay? waktuMasuk,
    required TimeOfDay? waktuPulang,
    required DateTime tanggal,
  }) async {
    debugLog('Membuat absensi baru untuk siswa $siswaId...');
    final tgl = DateFormat('yyyy-MM-dd').format(tanggal);
    final String? wMasuk = waktuMasuk != null
        ? '${waktuMasuk.hour.toString().padLeft(2, '0')}:${waktuMasuk.minute.toString().padLeft(2, '0')}:00'
        : null;
    final String? wPulang = waktuPulang != null
        ? '${waktuPulang.hour.toString().padLeft(2, '0')}:${waktuPulang.minute.toString().padLeft(2, '0')}:00'
        : null;
    final String? guruId = supabase.auth.currentUser?.id;

    final insertData = {
      'siswa_id': siswaId,
      'tanggal': tgl,
      'status': status,
      'waktu_masuk': wMasuk,
      'waktu_pulang': wPulang,
      'keterangan': keterangan,
      'updated_by': guruId,
    };

    try {
      await supabase.from('absensi').insert(insertData);
      await fetchAbsensi();
      debugLog('Absensi baru berhasil dibuat.');
    } catch (e) {
      debugLog('Error createAbsensi: $e');
      rethrow;
    }
  }

  // --- UPDATE Absensi ---
  Future<void> updateAbsensi({
    required int absensiId,
    required String status,
    required String keterangan,
    required TimeOfDay? waktuMasuk,
    required TimeOfDay? waktuPulang,
    required DateTime tanggal,
  }) async {
    debugLog('Update absensi ID $absensiId...');
    final tgl = DateFormat('yyyy-MM-dd').format(tanggal);
    final String? wMasuk = waktuMasuk != null
        ? '${waktuMasuk.hour.toString().padLeft(2, '0')}:${waktuMasuk.minute.toString().padLeft(2, '0')}:00'
        : null;
    final String? wPulang = waktuPulang != null
        ? '${waktuPulang.hour.toString().padLeft(2, '0')}:${waktuPulang.minute.toString().padLeft(2, '0')}:00'
        : null;
    final String? guruId = supabase.auth.currentUser?.id;

    final updateData = {
      'tanggal': tgl,
      'status': status,
      'waktu_masuk': wMasuk,
      'waktu_pulang': wPulang,
      'keterangan': keterangan,
      'updated_at': DateTime.now().toIso8601String(),
    };

    try {
      await supabase.from('absensi').update(updateData).eq('id', absensiId);
      await fetchAbsensi();
      debugLog('Absensi berhasil diperbarui.');
    } catch (e) {
      debugLog('Error updateAbsensi: $e');
      rethrow;
    }
  }

  // --- Utility Format & Parse ---
  DateTime? parseDateTime(dynamic value) {
    if (value == null) return null;
    try {
      if (value is DateTime) return value;
      if (value is String && value.contains('T')) return DateTime.parse(value);
      if (value is String && value.length == 10) {
        return DateFormat('yyyy-MM-dd').parse(value);
      }
      return DateTime.parse(value.toString());
    } catch (_) {
      return null;
    }
  }

  TimeOfDay? parseTimeOfDay(dynamic value) {
    if (value == null) return null;
    try {
      final parts = value.toString().split(':');
      if (parts.length >= 2) {
        return TimeOfDay(
          hour: int.parse(parts[0]),
          minute: int.parse(parts[1]),
        );
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  String fmtDate(dynamic value) {
    final dt = parseDateTime(value);
    if (dt == null) return '-';
    return DateFormat('dd-MM-yyyy', 'id_ID').format(dt);
  }

  String fmtDateTime(dynamic value) {
    final dt = parseDateTime(value);
    if (dt == null) return '-';
    return DateFormat('dd-MM-yyyy HH:mm', 'id_ID').format(dt.toLocal());
  }

  String fmtTime(dynamic value) {
    final tod = parseTimeOfDay(value);
    if (tod == null) return '-';
    return '${tod.hour.toString().padLeft(2, '0')}:${tod.minute.toString().padLeft(2, '0')}';
  }
}
