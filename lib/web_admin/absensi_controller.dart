import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Import untuk PDF
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

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

  // =======================================================
  // === BARU: FUNGSI UNTUK EXPORT PDF ===
  // =======================================================

  /// Fungsi utama yang dipanggil dari UI untuk memulai export PDF
  Future<void> exportPdf(BuildContext context) async {
    debugLog('Mulai export PDF...');

    if (_absensiData.isEmpty) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('Tidak ada data untuk diexport'),
            backgroundColor: Colors.orange,
          ),
        );
      return;
    }

    // Tampilkan dialog loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      // 1. Dapatkan Nama Kelas yang dipilih
      String namaKelas = 'Semua Kelas';
      if (_selectedKelasId != null) {
        final kelasMap = _daftarKelas.firstWhere(
          (k) => k['id'] == _selectedKelasId,
          orElse: () => {'nama_kelas': 'Semua Kelas'},
        );
        namaKelas = kelasMap['nama_kelas'];
      }

      // 2. Format Tanggal
      final String tgl = DateFormat(
        'EEEE, dd MMMM yyyy',
        'id_ID',
      ).format(_selectedDate);

      // 3. Buat dokumen PDF
      final pdf = await _generatePdfDocument(namaKelas, tgl);

      // 4. Tutup dialog loading
      if (context.mounted) Navigator.of(context).pop();

      // 5. Tampilkan dialog Print/Simpan
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save(),
      );
      debugLog('Export PDF berhasil.');
    } catch (e, st) {
      debugLog('Error exportPdf: $e\n$st');
      if (context.mounted) Navigator.of(context).pop(); // Tutup dialog loading
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text('Gagal membuat PDF: $e'),
            backgroundColor: Colors.red,
          ),
        );
    }
  }

  /// Helper untuk membangun dokumen PDF
  Future<pw.Document> _generatePdfDocument(String namaKelas, String tgl) async {
    final doc = pw.Document();

    // Muat font
    final font = await PdfGoogleFonts.robotoRegular();
    final boldFont = await PdfGoogleFonts.robotoBold();

    // Siapkan data untuk tabel
    final headers = [
      'No',
      'Nama Siswa',
      'Status',
      'Masuk',
      'Pulang',
      'Keterangan',
    ];

    final data = <List<String>>[];
    for (var i = 0; i < _absensiData.length; i++) {
      final row = _absensiData[i];
      final siswa = row['siswa'] ?? {};

      data.add([
        (i + 1).toString(), // No
        siswa['nama'] ?? '-', // Nama Siswa
        (row['status'] ?? '-').toString().toUpperCase(), // Status
        fmtTime(row['waktu_masuk']), // Masuk
        fmtTime(row['waktu_pulang']), // Pulang
        row['keterangan'] ?? '-', // Keterangan
      ]);
    }

    // Tambah halaman ke dokumen
    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        theme: pw.ThemeData.withFont(base: font, bold: boldFont),
        build: (pw.Context context) {
          return [
            // --- Header Dokumen ---
            pw.Header(
              level: 0,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'Laporan Absensi',
                    style: pw.TextStyle(
                      fontSize: 24,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.Text(
                    schoolName, // Menggunakan nama sekolah dari controller
                    style: const pw.TextStyle(fontSize: 18),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 20),

            // --- Info Filter ---
            pw.Text(
              'Kelas: $namaKelas',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            ),
            pw.Text(
              'Tanggal: $tgl',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 20),

            // --- Tabel Data ---
            pw.Table.fromTextArray(
              headers: headers,
              data: data,
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              cellAlignments: {
                0: pw.Alignment.center,
                1: pw.Alignment.centerLeft,
                2: pw.Alignment.center,
                3: pw.Alignment.center,
                4: pw.Alignment.center,
                5: pw.Alignment.centerLeft,
              },
              border: pw.TableBorder.all(color: PdfColors.grey),
              columnWidths: {
                0: const pw.FlexColumnWidth(0.5), // No
                1: const pw.FlexColumnWidth(3), // Nama
                2: const pw.FlexColumnWidth(2), // Status
                3: const pw.FlexColumnWidth(1), // Masuk
                4: const pw.FlexColumnWidth(1), // Pulang
                5: const pw.FlexColumnWidth(2), // Keterangan
              },
            ),
          ];
        },
        // --- Footer Dokumen ---
        footer: (pw.Context context) {
          return pw.Container(
            alignment: pw.Alignment.centerRight,
            margin: const pw.EdgeInsets.only(top: 10.0),
            child: pw.Text(
              'Dicetak pada: ${fmtDateTime(DateTime.now())} | Halaman ${context.pageNumber} dari ${context.pagesCount}',
              style: pw.Theme.of(
                context,
              ).defaultTextStyle.copyWith(color: PdfColors.grey, fontSize: 10),
            ),
          );
        },
      ),
    );

    return doc;
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
