import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AbsensiController extends ChangeNotifier {
  final SupabaseClient supabase = Supabase.instance.client;
  final String schoolName;

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

  // --- Fetch Data ---
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

      debugLog('Daftar kelas berhasil dimuat: ${_daftarKelas.length} kelas');
    } catch (e, st) {
      debugLog('Error saat fetchDaftarKelas: $e');
      debugLog('Stack: $st');
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
    debugLog('Mulai fetch absensi dari Supabase...');

    try {
      final String tglFilter = DateFormat('yyyy-MM-dd').format(_selectedDate);
      final int? localKelasId = _selectedKelasId;

      debugLog('Filter tanggal: $tglFilter, Filter kelas: $localKelasId');

      var query = supabase.from('absensi').select('''
        id,
        siswa_id,
        siswa!inner(nama, kelas_id),
        tanggal,
        status,
        waktu_masuk,
        waktu_pulang,
        keterangan,
        updated_by,
        guru (nama),
        created_at,
        updated_at
      ''').eq('tanggal', tglFilter);

      if (localKelasId != null) {
        query = query.eq('siswa.kelas_id', localKelasId);
      }

      final response = await query.order('created_at', ascending: false);
      _absensiData = List<Map<String, dynamic>>.from(response);

      debugLog('Data absensi berhasil dimuat: ${_absensiData.length} baris');
    } catch (e, st) {
      debugLog('Error saat fetchAbsensi: $e');
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
      await fetchAbsensi();
    }
  }

  Future<void> onKelasSelected(int? kelasId) async {
    if (kelasId == _selectedKelasId) return;

    _selectedKelasId = kelasId;
    notifyListeners();
    await fetchAbsensi();
  }

  Future<void> updateAbsensi({
    required int absensiId,
    required String status,
    required String keterangan,
    required TimeOfDay? waktuMasuk,
    required TimeOfDay? waktuPulang,
    required DateTime tanggal,
  }) async {
    final String tgl = tanggal.toIso8601String().split('T').first;
    final String? wMasuk = waktuMasuk != null
        ? '${waktuMasuk.hour.toString().padLeft(2, '0')}:${waktuMasuk.minute.toString().padLeft(2, '0')}:00'
        : null;
    final String? wPulang = waktuPulang != null
        ? '${waktuPulang.hour.toString().padLeft(2, '0')}:${waktuPulang.minute.toString().padLeft(2, '0')}:00'
        : null;

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

      final String editedDate = DateFormat('yyyy-MM-dd').format(tanggal);
      final String currentDate = DateFormat('yyyy-MM-dd').format(_selectedDate);

      if (editedDate == currentDate) {
        await fetchAbsensi();
      } else {
        _selectedDate = tanggal;
        notifyListeners();
        await fetchAbsensi();
      }
    } catch (e) {
      debugLog('Error update absensi: $e');
      rethrow;
    }
  }

  // --- UTILITAS PEMFORMATAN ---
  DateTime? parseDateTime(dynamic value) {
    if (value == null) return null;
    try {
      if (value is DateTime) return value;
      if (value is String && value.contains('T')) return DateTime.parse(value);
      if (value is String && value.length == 10) {
        return DateFormat('yyyy-MM-dd').parse(value);
      }
      return DateTime.parse(value.toString());
    } catch (e) {
      debugLog('parseDateTime error for value=$value -> $e');
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
    } catch (e) {
      debugLog('parseTimeOfDay error for value=$value -> $e');
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
