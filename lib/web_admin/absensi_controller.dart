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
  bool _isLoading = false;
  bool _isKelasLoading = false;
  
  // Data Tabel
  List<Map<String, dynamic>> _absensiData = [];
  
  // Data Kelas
  List<Map<String, dynamic>> _daftarKelas = [];
  
  // Filter Aktif
  DateTime _selectedDate = DateTime.now();
  int? _selectedKelasId;

  // Pagination State
  int _currentPage = 1;
  int _itemLimit = 10;
  int _totalRows = 0; 

  AbsensiController({required this.schoolName}) {
    _init();
  }

  // --- Getters ---
  bool get isLoading => _isLoading;
  bool get isKelasLoading => _isKelasLoading;
  List<Map<String, dynamic>> get absensiData => _absensiData;
  List<Map<String, dynamic>> get daftarKelas => _daftarKelas;
  DateTime get selectedDate => _selectedDate;
  int? get selectedKelasId => _selectedKelasId;
  
  int get currentPage => _currentPage;
  int get itemLimit => _itemLimit;
  int get totalRows => _totalRows;
  int get totalPages => _itemLimit > 0 ? (_totalRows / _itemLimit).ceil() : 0;

  void _init() {
    fetchDaftarKelas();
    fetchAbsensi();
  }

  // --- 1. FETCH DAFTAR KELAS ---
  Future<void> fetchDaftarKelas() async {
    _isKelasLoading = true;
    notifyListeners();

    try {
      final response = await supabase
          .from('kelas')
          .select('id, nama_kelas')
          .order('nama_kelas', ascending: true);

      _daftarKelas = List<Map<String, dynamic>>.from(response);
      _daftarKelas.insert(0, {'id': null, 'nama_kelas': 'Semua Kelas'});
    } catch (e) {
      debugPrint("Error fetch kelas: $e");
    } finally {
      _isKelasLoading = false;
      notifyListeners();
    }
  }

  // --- 2. FETCH ABSENSI (Server-Side Pagination) ---
  Future<void> fetchAbsensi() async {
    _isLoading = true;
    notifyListeners();

    try {
      final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
      
      final int from = (_currentPage - 1) * _itemLimit;
      final int to = from + _itemLimit - 1;

      // PERBAIKAN 1 & 2: Hapus FetchOptions, gunakan method chaining
      var query = supabase
          .from('absensi')
          .select('*, siswa!inner(id, nama, nis, kelas_id)') 
          .eq('tanggal', dateStr);

      if (_selectedKelasId != null) {
        query = query.eq('siswa.kelas_id', _selectedKelasId!);
      }

      // PERBAIKAN: Tambahkan .count(CountOption.exact) agar return type jadi PostgrestResponse
      final response = await query
          .order('siswa(nama)', ascending: true)
          .range(from, to)
          .count(CountOption.exact); 

      // Sekarang properti .data dan .count sudah valid karena pakai CountOption
      final dataList = response.data as List<dynamic>;
      _totalRows = response.count; 

      _absensiData = List<Map<String, dynamic>>.from(dataList);

    } catch (e) {
      debugPrint('Error fetch absensi: $e');
      _absensiData = [];
      _totalRows = 0;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // --- Event Handlers ---

  Future<void> handleDatePick(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (picked != null && picked != _selectedDate) {
      _selectedDate = picked;
      _currentPage = 1; 
      fetchAbsensi();
    }
  }

  void onKelasSelected(int? val) {
    _selectedKelasId = val;
    _currentPage = 1; 
    fetchAbsensi();
  }

  void updateLimit(int? val) {
    if (val != null) {
      _itemLimit = val;
      _currentPage = 1; 
      fetchAbsensi();
    }
  }

  void nextPage() {
    if (_currentPage < totalPages) {
      _currentPage++;
      fetchAbsensi();
    }
  }

  void prevPage() {
    if (_currentPage > 1) {
      _currentPage--;
      fetchAbsensi();
    }
  }

  // --- EXPORT PDF ---
  Future<void> exportPdf(BuildContext context) async {
    // 1. Loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
      var query = supabase
          .from('absensi')
          .select('*, siswa!inner(id, nama, kelas_id)')
          .eq('tanggal', dateStr);

      if (_selectedKelasId != null) {
        query = query.eq('siswa.kelas_id', _selectedKelasId!);
      }

      final response = await query.order('siswa(nama)', ascending: true);
      // Di sini kita tidak butuh count, jadi response langsung berupa List<dynamic>
      final List<Map<String, dynamic>> fullData = List<Map<String, dynamic>>.from(response);

      // PERBAIKAN 3: Cek mounted sebelum pakai Navigator/Scaffold
      if (!context.mounted) return;

      if (fullData.isEmpty) {
        Navigator.pop(context); // Tutup loading
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tidak ada data untuk diexport')),
        );
        return;
      }

      String namaKelas = 'Semua Kelas';
      if (_selectedKelasId != null) {
        final kelas = _daftarKelas.firstWhere(
          (k) => k['id'] == _selectedKelasId, 
          orElse: () => {'nama_kelas': '-'}
        );
        namaKelas = kelas['nama_kelas'];
      }

      final pdfDoc = await _generatePdfDocument(fullData, namaKelas, dateStr);
      final bytes = await pdfDoc.save();

      if (!context.mounted) return;
      Navigator.pop(context); // Tutup Loading
      
      final fileName = 'Laporan_Absensi_${namaKelas.replaceAll(' ', '_')}_$dateStr.pdf';
      await Printing.sharePdf(bytes: bytes, filename: fileName);

    } catch (e) {
      if (context.mounted) {
         Navigator.pop(context); // Tutup Loading jika error
         ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(content: Text('Gagal export PDF: $e')),
         );
      }
      debugPrint("Error export PDF: $e");
    }
  }

  Future<pw.Document> _generatePdfDocument(
    List<Map<String, dynamic>> data, 
    String namaKelas, 
    String tgl
  ) async {
    final doc = pw.Document();
    final font = await PdfGoogleFonts.robotoRegular();
    final boldFont = await PdfGoogleFonts.robotoBold();

    final headers = ['No', 'Nama Siswa', 'Status', 'Masuk', 'Pulang', 'Keterangan'];
    final rows = <List<String>>[];

    for (var i = 0; i < data.length; i++) {
      final row = data[i];
      final siswa = row['siswa'] ?? {};
      rows.add([
        (i + 1).toString(),
        siswa['nama'] ?? '-',
        (row['status'] ?? '-').toString().toUpperCase(),
        fmtTime(row['waktu_masuk']),
        fmtTime(row['waktu_pulang']),
        row['keterangan'] ?? '-',
      ]);
    }

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        theme: pw.ThemeData.withFont(base: font, bold: boldFont),
        build: (context) => [
          pw.Header(
            level: 0,
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Laporan Absensi', style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
                    pw.Text(schoolName, style: const pw.TextStyle(fontSize: 14)),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text('Kelas: $namaKelas'),
                    pw.Text('Tanggal: $tgl'),
                  ],
                )
              ]
            )
          ),
          pw.SizedBox(height: 20),
          
          // PERBAIKAN 4: Ganti pw.Table.fromTextArray jadi pw.TableHelper.fromTextArray
          pw.TableHelper.fromTextArray(
            headers: headers,
            data: rows,
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.blue700),
            rowDecoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey300))),
            cellAlignments: {
              0: pw.Alignment.center,
              1: pw.Alignment.centerLeft,
              2: pw.Alignment.center,
              3: pw.Alignment.center,
              4: pw.Alignment.center,
              5: pw.Alignment.centerLeft,
            },
            columnWidths: {
              0: const pw.FixedColumnWidth(30),
              1: const pw.FlexColumnWidth(3),
              2: const pw.FixedColumnWidth(60),
              3: const pw.FixedColumnWidth(50),
              4: const pw.FixedColumnWidth(50),
              5: const pw.FlexColumnWidth(2),
            }
          ),
        ],
        footer: (context) => pw.Container(
          alignment: pw.Alignment.centerRight,
          margin: const pw.EdgeInsets.only(top: 10),
          child: pw.Text(
            'Halaman ${context.pageNumber} dari ${context.pagesCount}',
            style: const pw.TextStyle(color: PdfColors.grey, fontSize: 10),
          ),
        ),
      ),
    );

    return doc;
  }

  // --- Helpers ---
  String fmtDate(String? isoDate) {
    if (isoDate == null) return '-';
    try {
      final dt = DateTime.parse(isoDate);
      return DateFormat('dd/MM/yyyy').format(dt);
    } catch (_) { return isoDate; }
  }

  String fmtTime(dynamic timeStr) {
    if (timeStr == null) return '-';
    String str = timeStr.toString();
    if (str.length >= 5) return str.substring(0, 5);
    return str;
  }
}