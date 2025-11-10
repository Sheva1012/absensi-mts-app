// File: data_siswa_logic.dart
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart'; // Dibutuhkan untuk BuildContext
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:file_picker/file_picker.dart';
import 'package:barcode_widget/barcode_widget.dart';
import 'package:screenshot/screenshot.dart';
import 'package:universal_html/html.dart' as html;
import 'dart:typed_data';
import 'dart:convert';
import 'package:pdf/pdf.dart';
import 'package:excel/excel.dart';
import 'package:csv/csv.dart';
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

  // --- Getters ---
  bool get isLoading => _isLoading;
  bool get isKelasLoading => _isKelasLoading;
  List<Map<String, dynamic>> get siswaData => _siswaData;
  List<Map<String, dynamic>> get kelasList => _kelasList;
  int? get selectedKelasId => _selectedKelasId;
  String? get selectedStatus => _selectedStatus;

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
      await fetchSiswa(""); // Muat siswa setelah kelas didapat
    }
  }

  Future<void> fetchSiswa(String searchKeyword) async {
    _isLoading = true;
    notifyListeners();
    try {
      var query = supabase.from('siswa').select('*, kelas!inner(nama_kelas)');
      if (_selectedKelasId != null) {
        query = query.eq('kelas_id', _selectedKelasId!);
      }
      if (_selectedStatus != null && _selectedStatus!.isNotEmpty) {
        query = query.eq('status', _selectedStatus!);
      }

      final response = await query.order('kelas_id', ascending: true);
      List<Map<String, dynamic>> allData = List<Map<String, dynamic>>.from(
        response,
      );

      if (searchKeyword.trim().isNotEmpty) {
        String keyword = searchKeyword.toLowerCase();
        allData = allData
            .where(
              (s) =>
                  (s['nama'] ?? '').toString().toLowerCase().contains(keyword),
            )
            .toList();
      }

      _siswaData = allData;
      _siswaData.sort((a, b) {
        int kelasComparison = (a['kelas_id'] ?? 0).compareTo(
          b['kelas_id'] ?? 0,
        );
        if (kelasComparison != 0) return kelasComparison;
        return (a['no'] ?? 0).compareTo(b['no'] ?? 0);
      });
    } catch (e) {
      print('Error fetching siswa: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // --- Event Handlers ---
  void onKelasSelected(int? kelasId, String searchKeyword) {
    _selectedKelasId = kelasId;
    notifyListeners();
    fetchSiswa(searchKeyword);
  }

  void onStatusSelected(String? status, String searchKeyword) {
    _selectedStatus = status;
    notifyListeners();
    fetchSiswa(searchKeyword);
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
      if (isEdit) {
        await supabase
            .from('siswa')
            .update({
              'nis': nis,
              'nama': nama,
              'kelas_id': kelasId,
              'orang_tua_nama': ortuNama,
              'orang_tua_nomor': ortuNomor,
              'status': status,
            })
            .eq('id', siswaId!);
      } else {
        await supabase.from('siswa').insert({
          'nis': nis,
          'nama': nama,
          'kelas_id': kelasId,
          'orang_tua_nama': ortuNama,
          'orang_tua_nomor': ortuNomor,
          'status': status,
        });
      }
      await fetchSiswa(""); // Refresh data
      return null; // Sukses
    } catch (e) {
      return 'Gagal menyimpan data: $e'; // Kembalikan pesan error
    }
  }

  Future<String?> deleteSiswa(int id) async {
    try {
      await supabase.from('siswa').delete().eq('id', id);
      await fetchSiswa(""); // Refresh data
      return null; // Sukses
    } catch (e) {
      return 'Gagal menghapus data: $e'; // Kembalikan pesan error
    }
  }

  // --- Logika Ekstra (PDF, QR, CSV) ---
  Future<void> downloadBarcode(Uint8List bytes, String filename) async {
    final base64 = base64Encode(bytes);
    final href = 'data:application/octet-stream;base64,$base64';
    html.AnchorElement(href: href)
      ..setAttribute("download", filename)
      ..click();
  }

  Future<void> generateBarcodePdf(BuildContext context) async {
    final String namaKelas = selectedKelasNama;
    if (_siswaData.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tidak ada data siswa untuk dicetak di kelas ini.'),
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
            "Daftar QR Code Siswa - $namaKelas",
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

  Future<void> importExcel(BuildContext context) async {
    // Cek jika kelas sudah dipilih
    if (_selectedKelasId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Gagal: Silakan pilih satu kelas spesifik di filter (misal: "Kelas 7A") sebelum mengimpor.',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final int targetKelasId = _selectedKelasId!;

    // 1. Ambil file .xlsx
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx', 'xls'],
    );

    if (result == null || result.files.single.bytes == null) {
      return; // Pengguna membatalkan
    }

    // Tampilkan dialog loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final bytes = result.files.single.bytes!;
      final excel = Excel.decodeBytes(bytes);

      // Asumsikan sheet pertama, atau "KELAS A" jika Anda mau hardcode
      final sheet = excel.tables[excel.tables.keys.first]!;
      final rows = sheet.rows;

      if (rows.isEmpty || rows.length < 2) {
        throw Exception(
          "File Excel kosong atau tidak memiliki data (minimal 1 baris header dan 1 baris data).",
        );
      }

      final List<Map<String, dynamic>> studentsToInsert = [];

      // Mulai dari 1 (lewati header)
      for (int i = 1; i < rows.length; i++) {
        final row = rows[i];

        // Lewati baris yang benar-benar kosong
        if (row.every((cell) => cell == null || cell.value == null)) {
          continue;
        }

        // --- PERBAIKAN INDEKS KOLOM ---
        // Sesuai screenshot Anda (image_4f5b29.png):
        // Kolom A (indeks 0) = no (Diabaikan)
        // Kolom B (indeks 1) = nisn (Akan kita ambil)
        // Kolom C (indeks 2) = nama (Akan kita ambil)
        // Kolom D (indeks 3) = alamat (Diabaikan)
        // Kolom E (indeks 4) = nama ayah (Akan kita ambil sebagai ortuNama)
        // Kolom F (indeks 5) = nama ibu (Diabaikan)
        // Kolom G (indeks 6) = no hp (Diabaikan)

        final nis = row.length > 0
            ? row[0]?.value?.toString()
            : null; // Ambil dari Kolom B
        final nama = row.length > 2
            ? row[2]?.value?.toString()
            : null; // Ambil dari Kolom C
        final ortuNama = row.length > 8
            ? row[8]?.value?.toString()
            : null; // Ambil dari Kolom E
        final ortuNomor = "-"; // Sesuai permintaan Anda

        // Validasi data: Cek NIS (Kolom B) and Nama (Kolom C)
        if (nis != null && nis.isNotEmpty && nama != null && nama.isNotEmpty) {
          studentsToInsert.add({
            'nis': nis,
            'nama': nama,
            'kelas_id': targetKelasId, // ID Kelas dari filter
            'orang_tua_nama': ortuNama,
            'orang_tua_nomor': ortuNomor, // Masukkan "-"
            'status': 'aktif',
          });
        } else {
          print(
            '-> MELEWATI baris ${i + 1} karena NIS (Kolom B) atau Nama (Kolom C) kosong.',
          );
        }
        // --- AKHIR PERBAIKAN ---
      }

      if (studentsToInsert.isEmpty) {
        throw Exception(
          "Tidak ada data siswa yang valid untuk diimpor. (Pastikan Kolom B (NIS) dan C (Nama) terisi).",
        );
      }

      // Masukkan data
      await supabase.from('siswa').insert(studentsToInsert);

      if (context.mounted) Navigator.pop(context); // Tutup loading

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Berhasil mengimpor ${studentsToInsert.length} siswa ke kelas ini!',
          ),
          backgroundColor: Colors.green,
        ),
      );

      await fetchSiswa(""); // Refresh data UI
    } catch (e) {
      print('Error importExcel: $e');
      if (context.mounted) Navigator.pop(context); // Tutup loading
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal mengimpor data: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
