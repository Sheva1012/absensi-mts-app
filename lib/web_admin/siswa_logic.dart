// File: data_siswa_logic.dart
import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart'; // Dibutuhkan untuk BuildContext
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:file_picker/file_picker.dart';
import 'package:barcode_widget/barcode_widget.dart';
import 'package:universal_html/html.dart' as html;
import 'package:pdf/pdf.dart';
import 'package:excel/excel.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class DataSiswaLogic with ChangeNotifier {
  final SupabaseClient supabase = Supabase.instance.client;

  // --- State ---
  bool _isLoading = true;
  bool _isKelasLoading = true;
  List<Map<String, dynamic>> _siswaData = [];
  List<Map<String, dynamic>> _kelasList = [];

  int? _selectedKelasId;
  String? _selectedStatus;

  // --- PAGINATION STATE ---
  int _itemLimit = 10; // Default 10 data per halaman
  int _currentPage = 1; // Halaman aktif
  int _totalItems = 0; // Total data di database (sesuai filter)

  // --- Getters ---
  bool get isLoading => _isLoading;
  bool get isKelasLoading => _isKelasLoading;
  List<Map<String, dynamic>> get siswaData => _siswaData;
  List<Map<String, dynamic>> get kelasList => _kelasList;
  int? get selectedKelasId => _selectedKelasId;
  String? get selectedStatus => _selectedStatus;

  // Getters Pagination
  int get itemLimit => _itemLimit;
  int get currentPage => _currentPage;
  int get totalItems => _totalItems;

  // Menghitung total halaman
  int get totalPages {
    if (_itemLimit == 0) return 0;
    return (_totalItems / _itemLimit).ceil();
  }

  // Teks Info Pagination (misal: "1 - 10 dari 50")
  String get paginationInfo {
    if (_totalItems == 0) return "0 - 0 dari 0";
    int start = (_currentPage - 1) * _itemLimit + 1;
    int end = start + _siswaData.length - 1;
    return "$start - $end dari $_totalItems";
  }

  String get selectedKelasNama {
    if (_selectedKelasId == null) return "Semua Kelas";
    try {
      return _kelasList.firstWhere(
        (k) => k['id'] == _selectedKelasId,
      )['nama_kelas'];
    } catch (e) {
      return "Kelas";
    }
  }

  // --- Inisialisasi ---
  Future<void> init(String? initialKelasId) async {
    _selectedKelasId = initialKelasId != null
        ? int.tryParse(initialKelasId)
        : null;
    await fetchKelas();
  }

  // --- Logika Pagination & Filter ---

  // 1. Ganti Limit (Reset ke hal 1)
  void updateLimit(int newLimit, String searchKeyword) {
    _itemLimit = newLimit;
    _currentPage = 1;
    notifyListeners();
    fetchSiswa(searchKeyword);
  }

  // 2. Halaman Selanjutnya
  void nextPage(String searchKeyword) {
    if (_currentPage < totalPages) {
      _currentPage++;
      notifyListeners();
      fetchSiswa(searchKeyword);
    }
  }

  // 3. Halaman Sebelumnya
  void previousPage(String searchKeyword) {
    if (_currentPage > 1) {
      _currentPage--;
      notifyListeners();
      fetchSiswa(searchKeyword);
    }
  }

  // 4. Event Handler Filter
  void onKelasSelected(int? kelasId, String searchKeyword) {
    _selectedKelasId = kelasId;
    // Reset ke hal 1 setiap filter berubah
    fetchSiswa(searchKeyword, resetPage: true);
  }

  void onStatusSelected(String? status, String searchKeyword) {
    _selectedStatus = status;
    // Reset ke hal 1 setiap filter berubah
    fetchSiswa(searchKeyword, resetPage: true);
  }

  // --- Logika Fetching ---
  Future<void> fetchKelas() async {
    _isKelasLoading = true;
    notifyListeners();

    try {
      final response = await supabase
          .from('kelas')
          .select('id, nama_kelas')
          .order('nama_kelas', ascending: true);
      _kelasList = List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching kelas: $e');
    } finally {
      _isKelasLoading = false;
      notifyListeners();
      await fetchSiswa(""); // Muat siswa
    }
  }

  // --- MAIN FETCH FUNCTION (Server-side Pagination) ---
  Future<void> fetchSiswa(
    String searchKeyword, {
    bool resetPage = false,
  }) async {
    if (resetPage) _currentPage = 1;

    _isLoading = true;
    notifyListeners();
    try {
      // 1. Hitung Range Supabase (Zero-based index)
      final int from = (_currentPage - 1) * _itemLimit;
      final int to = from + _itemLimit - 1;

      // 2. Query Dasar (HAPUS FetchOptions dari sini)
      var query = supabase.from('siswa').select('*, kelas!inner(nama_kelas)');

      // 3. Terapkan Filter
      if (_selectedKelasId != null) {
        query = query.eq('kelas_id', _selectedKelasId!);
      }
      if (_selectedStatus != null && _selectedStatus!.isNotEmpty) {
        query = query.eq('status', _selectedStatus!);
      }
      if (searchKeyword.trim().isNotEmpty) {
        query = query.ilike('nama', '%$searchKeyword%');
      }

      // 4. Eksekusi dengan Sort, Range, DAN Count
      final response = await query
          .order('kelas_id', ascending: true)
          .order('nama', ascending: true)
          .range(from, to)
          .count(
            CountOption.exact,
          ); // <--- GUNAKAN INI SEBAGAI GANTI FetchOptions

      // 5. Ambil Data & Total Count
      // response.data biasanya dynamic, kita cast ke List
      final List<dynamic> data = response.data as List<dynamic>;

      // response.count berisi jumlah total data (untuk pagination)
      final int count = response.count ?? 0;

      _siswaData = List<Map<String, dynamic>>.from(data);
      _totalItems = count;
    } catch (e) {
      print('Error fetching siswa: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // --- Logika CRUD ---
  Future<String?> saveSiswa({
    required bool isEdit,
    int? siswaId,
    required String nis,
    required String nama,
    required int? kelasId,
    required String ortuNama,
    required String ortuNomor,
    required String? status,
  }) async {
    try {
      final dataMap = {
        'nis': nis,
        'nama': nama,
        'kelas_id': kelasId,
        'orang_tua_nama': ortuNama,
        'orang_tua_nomor': ortuNomor,
        'status': status,
      };

      if (isEdit) {
        await supabase.from('siswa').update(dataMap).eq('id', siswaId!);
      } else {
        await supabase.from('siswa').insert(dataMap);
      }
      // Refresh data setelah simpan
      await fetchSiswa("");
      return null; // null artinya sukses
    } catch (e) {
      return 'Gagal menyimpan data: $e'; // return String error
    }
  }

  Future<String?> deleteSiswa(int id) async {
    try {
      await supabase.from('siswa').delete().eq('id', id);
      // Refresh data setelah hapus
      await fetchSiswa("");
      return null;
    } catch (e) {
      return 'Gagal menghapus data: $e';
    }
  }

  // --- Logika Download Barcode (Image) ---
  Future<void> downloadBarcode(Uint8List bytes, String filename) async {
    final base64 = base64Encode(bytes);
    final href = 'data:application/octet-stream;base64,$base64';
    html.AnchorElement(href: href)
      ..setAttribute("download", filename)
      ..click();
  }

  // --- Logika PDF ---
  Future<void> generateBarcodePdf(BuildContext context) async {
    final String namaKelas = selectedKelasNama;
    if (_siswaData.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tidak ada data siswa (di halaman ini) untuk dicetak.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final pdf = pw.Document();
    List<pw.Widget> barcodeWidgets = [];

    for (final siswa in _siswaData) {
      final String nis = siswa['nis']?.toString() ?? '';
      final String nama = siswa['nama'] ?? 'Siswa';

      if (nis.isNotEmpty) {
        barcodeWidgets.add(
          pw.Container(
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey300),
              borderRadius: pw.BorderRadius.circular(5),
            ),
            child: pw.Column(
              mainAxisSize: pw.MainAxisSize.min,
              children: [
                pw.Text(
                  nama,
                  style: pw.TextStyle(
                    fontSize: 10,
                    fontWeight: pw.FontWeight.bold,
                  ),
                  textAlign: pw.TextAlign.center,
                ),
                pw.SizedBox(height: 2),
                pw.Text("NIS: $nis", style: const pw.TextStyle(fontSize: 8)),
                pw.SizedBox(height: 5),
                pw.BarcodeWidget(
                  barcode: pw.Barcode.qrCode(),
                  data: nis,
                  width: 80,
                  height: 80,
                  drawText: false,
                  color: PdfColors.black,
                ),
              ],
            ),
          ),
        );
      }
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        header: (context) => pw.Header(
          level: 0,
          child: pw.Text(
            "Daftar QR Code - $namaKelas",
            style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
          ),
        ),
        build: (context) => [
          pw.GridView(
            crossAxisCount: 3,
            childAspectRatio: 1.2,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            children: barcodeWidgets,
          ),
        ],
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }

  // --- Logika Import Excel ---
  // --- Logika Import Excel (DIPERBAIKI) ---
  Future<void> importExcel(BuildContext context) async {
    if (_selectedKelasId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Gagal: Silakan pilih Kelas spesifik di filter terlebih dahulu.',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final int targetKelasId = _selectedKelasId!;

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'xls'],
        withData: true, // PENTING untuk Web: pastikan bytes terambil
      );

      if (result == null || result.files.single.bytes == null) {
        return;
      }

      // Tampilkan loading
      if (context.mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) =>
              const Center(child: CircularProgressIndicator()),
        );
      }

      final bytes = result.files.single.bytes!;
      final excel = Excel.decodeBytes(bytes);

      // Cek apakah ada table
      if (excel.tables.isEmpty) {
        throw Exception("File Excel tidak memiliki sheet.");
      }

      final sheetName = excel.tables.keys.first;
      final sheet = excel.tables[sheetName];

      if (sheet == null || sheet.rows.isEmpty || sheet.rows.length < 2) {
        throw Exception("Sheet kosong atau tidak ada data.");
      }

      final rows = sheet.rows;
      final List<Map<String, dynamic>> studentsToInsert = [];

      // Fungsi Helper Lokal untuk membaca cell dengan aman di Web
      String? getCellValue(List<Data?> row, int index) {
        try {
          if (index >= row.length) return null; // Cek index out of bounds
          final cell = row[index];
          if (cell == null) return null; // Cek cell null
          final val = cell.value;
          if (val == null) return null; // Cek value null
          return val.toString().trim(); // Convert to string & trim
        } catch (e) {
          return null;
        }
      }

      // Mulai loop dari baris ke-2 (index 1)
      for (int i = 1; i < rows.length; i++) {
        final row = rows[i];

        // Lewati jika baris benar-benar kosong
        if (row.isEmpty) continue;

        // Mapping kolom (B=1, C=2, E=4/8)
        final nis = getCellValue(row, 1); // Kolom B
        final nama = getCellValue(row, 2); // Kolom C
        final ortuNama = getCellValue(
          row,
          8,
        ); // Kolom I (sesuai kode sebelumnya)
        final ortuNomor = "-";

        // Validasi minimal: NIS dan Nama wajib ada
        if (nis != null && nis.isNotEmpty && nama != null && nama.isNotEmpty) {
          studentsToInsert.add({
            'nis': nis,
            'nama': nama,
            'kelas_id': targetKelasId,
            'orang_tua_nama': ortuNama ?? "-", // Default dash jika kosong
            'orang_tua_nomor': ortuNomor,
            'status': 'aktif',
          });
        }
      }

      if (studentsToInsert.isEmpty) {
        throw Exception("Tidak ada data valid (Cek kolom NIS & Nama).");
      }

      // Insert ke Supabase
      await supabase.from('siswa').insert(studentsToInsert);

      // Tutup Loading
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Berhasil mengimpor ${studentsToInsert.length} siswa!',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }

      await fetchSiswa(""); // Refresh UI
    } catch (e) {
      print('Error importExcel: $e');
      // Pastikan loading tertutup jika error
      if (context.mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal import: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
