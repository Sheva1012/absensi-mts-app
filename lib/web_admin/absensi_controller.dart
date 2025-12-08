import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class AbsensiController extends ChangeNotifier {
  final SupabaseClient supabase = Supabase.instance.client;
  final String schoolName;

  // --- STATE UTAMA ---
  bool isRekapMode = false; // FALSE = Harian, TRUE = Rekap Bulanan

  // State Filter
  DateTime selectedDate = DateTime.now();
  int? selectedKelasId;
  int itemLimit = 10;
  int currentPage = 1;

  // State Data & UI
  bool isLoading = false;
  bool isKelasLoading = false;

  // Container Data Harian
  List<Map<String, dynamic>> absensiData = [];
  int totalRows = 0;

  // Container Data Rekap Bulanan
  List<Map<String, dynamic>> rekapData = [];

  // Data Kelas
  List<Map<String, dynamic>> daftarKelas = [];

  AbsensiController({required this.schoolName}) {
    fetchKelas();
    fetchData();
  }

  void toggleMode(bool isRekap) {
    if (isRekapMode == isRekap) return;
    isRekapMode = isRekap;
    currentPage = 1;
    notifyListeners();
    fetchData();
  }

  Future<void> fetchData() async {
    if (isRekapMode) {
      await _fetchRekapBulanan();
    } else {
      await _fetchAbsensiHarian();
    }
  }

  // =========================================================
  // PERBAIKAN UTAMA ADA DI FUNGSI INI
  // =========================================================
  Future<void> _fetchAbsensiHarian() async {
    isLoading = true;
    notifyListeners();

    try {
      final dateStr = DateFormat('yyyy-MM-dd').format(selectedDate);
      final startRow = (currentPage - 1) * itemLimit;
      final endRow = startRow + itemLimit - 1;

      // 1. Definisikan Base Query (Filter dulu, jangan range/order dulu)
      var query = supabase
          .from('absensi')
          .select(
            '*, siswa!inner(nama, kelas_id, nis)',
          ) // Hapus FetchOptions di sini
          .eq('tanggal', dateStr);

      // 2. Tambahkan Filter Kelas (Jika ada)
      // Kita lakukan ini SEBELUM memanggil .range() atau .order()
      if (selectedKelasId != null) {
        query = query.eq('siswa.kelas_id', selectedKelasId!);
      }

      // 3. Tambahkan Order, Range, dan Count
      // .count(CountOption.exact) akan membuat return value menjadi PostgrestResponse
      // yang berisi properti 'data' dan 'count'.
      final response = await query
          .order('waktu_masuk', ascending: true)
          .range(startRow, endRow)
          .count(CountOption.exact); // Syntax Baru Supabase v2

      // 4. Ambil Data
      // response.data bertipe dynamic, kita cast ke List
      final dataList = List<Map<String, dynamic>>.from(response.data);
      final count = response.count; // Total data keseluruhan

      absensiData = dataList;
      totalRows = count;
    } catch (e) {
      debugPrint("Error Harian: $e");
      absensiData = [];
      totalRows = 0;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _fetchRekapBulanan() async {
    isLoading = true;
    notifyListeners();

    try {
      final startDate = DateTime(selectedDate.year, selectedDate.month, 1);
      final endDate = DateTime(selectedDate.year, selectedDate.month + 1, 0);

      final startStr = DateFormat('yyyy-MM-dd').format(startDate);
      final endStr = DateFormat('yyyy-MM-dd').format(endDate);

      // Query Rekap (Tanpa Count/Pagination karena butuh semua data untuk dihitung)
      var query = supabase
          .from('absensi')
          .select('status, tanggal, siswa!inner(nama, kelas_id)')
          .gte('tanggal', startStr)
          .lte('tanggal', endStr);

      if (selectedKelasId != null) {
        query = query.eq('siswa.kelas_id', selectedKelasId!);
      }

      // Di v2, jika tanpa .count(), await query langsung mengembalikan List data
      final List<dynamic> rawData = await query;

      // ... Logic Grouping Statistik (Sama seperti sebelumnya) ...
      Map<String, Map<String, int>> stats = {};

      for (var row in rawData) {
        String nama = 'Tanpa Nama';
        if (row['siswa'] != null) {
          nama = row['siswa']['nama'] ?? 'Tanpa Nama';
        }

        final String statusRaw = row['status'] ?? 'Alpha';

        if (!stats.containsKey(nama)) {
          stats[nama] = {
            'Hadir': 0,
            'Sakit': 0,
            'Izin': 0,
            'Alpha': 0,
            'Terlambat': 0,
          };
        }

        String key = 'Alpha';
        final sLower = statusRaw.toLowerCase();

        if (sLower == 'hadir')
          key = 'Hadir';
        else if (sLower == 'sakit')
          key = 'Sakit';
        else if (sLower == 'izin')
          key = 'Izin';
        else if (sLower == 'terlambat')
          key = 'Terlambat';
        else if (sLower == 'alfa' || sLower == 'alpha')
          key = 'Alpha';

        if (stats[nama]!.containsKey(key)) {
          stats[nama]![key] = stats[nama]![key]! + 1;
        }
      }

      List<Map<String, dynamic>> tempList = [];
      stats.forEach((key, value) {
        int totalHadirFisik = value['Hadir']! + value['Terlambat']!;
        int totalHari =
            totalHadirFisik +
            value['Sakit']! +
            value['Izin']! +
            value['Alpha']!;

        String persentaseStr = "0.0";
        if (totalHari > 0) {
          double p = (totalHadirFisik / totalHari) * 100;
          persentaseStr = p.toStringAsFixed(1);
        }

        tempList.add({
          'nama': key,
          'hadir': value['Hadir'],
          'terlambat': value['Terlambat'],
          'sakit': value['Sakit'],
          'izin': value['Izin'],
          'alpha': value['Alpha'],
          'total_kehadiran': totalHadirFisik,
          'persentase': persentaseStr,
        });
      });

      tempList.sort((a, b) => a['nama'].compareTo(b['nama']));

      rekapData = tempList;
      totalRows = rekapData.length;
    } catch (e) {
      debugPrint("Error Rekap: $e");
      rekapData = [];
      totalRows = 0;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // --- EXPORT PDF ---
  Future<void> exportPdf(BuildContext context) async {
    try {
      if (isRekapMode) {
        await _generatePdfRekap(context);
      } else {
        await _generatePdfHarian(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Gagal export PDF: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _generatePdfRekap(BuildContext context) async {
    final pdf = pw.Document();
    final font = await PdfGoogleFonts.nunitoExtraLight();

    final bulanStr = DateFormat('MMMM yyyy', 'id_ID').format(selectedDate);
    final title = "Laporan Rekap Absensi - $bulanStr";
    final subTitle = selectedKelasId == null
        ? "Semua Kelas"
        : "Filter Kelas Aktif";

    final headers = [
      'No',
      'Nama Siswa',
      'H',
      'T',
      'S',
      'I',
      'A',
      '% Kehadiran',
    ];

    final data = rekapData.asMap().entries.map((entry) {
      final index = entry.key + 1;
      final item = entry.value;
      return [
        index.toString(),
        item['nama'],
        item['hadir'].toString(),
        item['terlambat'].toString(),
        item['sakit'].toString(),
        item['izin'].toString(),
        item['alpha'].toString(),
        "${item['persentase']}%",
      ];
    }).toList();

    pdf.addPage(
      pw.MultiPage(
        theme: pw.ThemeData.withFont(base: font),
        pageFormat: PdfPageFormat.a4,
        build: (context) => [
          pw.Header(
            level: 0,
            child: pw.Text(
              schoolName,
              style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
            ),
          ),
          pw.Paragraph(
            text: "$title\n$subTitle",
            style: const pw.TextStyle(fontSize: 12),
          ),
          pw.SizedBox(height: 10),
          pw.Table.fromTextArray(
            headers: headers,
            data: data,
            border: pw.TableBorder.all(width: 0.5),
            headerStyle: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              fontSize: 10,
            ),
            cellStyle: const pw.TextStyle(fontSize: 10),
            cellAlignment: pw.Alignment.center,
            cellAlignments: {1: pw.Alignment.centerLeft},
            columnWidths: {
              0: const pw.FixedColumnWidth(30),
              1: const pw.FlexColumnWidth(3),
            },
          ),
          pw.SizedBox(height: 20),
          pw.Text(
            "Keterangan: H=Hadir, T=Terlambat, S=Sakit, I=Izin, A=Alpha",
            style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
          ),
        ],
      ),
    );

    await Printing.layoutPdf(onLayout: (format) => pdf.save());
  }

  Future<void> _generatePdfHarian(BuildContext context) async {
    final pdf = pw.Document();
    final font = await PdfGoogleFonts.nunitoExtraLight();

    final tglStr = DateFormat('dd MMMM yyyy', 'id_ID').format(selectedDate);
    final title = "Laporan Absensi Harian - $tglStr";

    final headers = [
      'No',
      'Nama Siswa',
      'Waktu Masuk',
      'Waktu Pulang',
      'Status',
      'Keterangan',
    ];

    final data = absensiData.asMap().entries.map((entry) {
      final index = entry.key + 1;
      final row = entry.value;

      String nama = 'Unknown';
      if (row['siswa'] != null) nama = row['siswa']['nama'] ?? '-';

      return [
        index.toString(),
        nama,
        fmtTime(row['waktu_masuk']),
        fmtTime(row['waktu_pulang']),
        (row['status'] ?? '-').toString().toUpperCase(),
        row['keterangan'] ?? '-',
      ];
    }).toList();

    pdf.addPage(
      pw.MultiPage(
        theme: pw.ThemeData.withFont(base: font),
        pageFormat: PdfPageFormat.a4,
        build: (context) => [
          pw.Header(
            level: 0,
            child: pw.Text(
              schoolName,
              style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
            ),
          ),
          pw.Paragraph(text: title, style: const pw.TextStyle(fontSize: 12)),
          pw.SizedBox(height: 10),
          pw.Table.fromTextArray(
            headers: headers,
            data: data,
            border: pw.TableBorder.all(width: 0.5),
            headerStyle: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              fontSize: 10,
            ),
            cellStyle: const pw.TextStyle(fontSize: 10),
            cellAlignment: pw.Alignment.centerLeft,
            columnWidths: {
              0: const pw.FixedColumnWidth(30),
              1: const pw.FlexColumnWidth(2),
            },
          ),
        ],
      ),
    );

    await Printing.layoutPdf(onLayout: (format) => pdf.save());
  }

  Future<void> fetchKelas() async {
    isKelasLoading = true;
    notifyListeners();
    try {
      final response = await supabase
          .from('kelas')
          .select('id, nama_kelas')
          .order('nama_kelas');
      // Di Supabase v2, response select biasa langsung List<dynamic>
      daftarKelas = List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint("Error Fetch Kelas: $e");
    } finally {
      isKelasLoading = false;
      notifyListeners();
    }
  }

  void updateLimit(int? val) {
    if (val != null) {
      itemLimit = val;
      currentPage = 1;
      fetchData();
    }
  }

  void onKelasSelected(int? val) {
    selectedKelasId = val;
    currentPage = 1;
    fetchData();
  }

  Future<void> handleDatePick(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      helpText: isRekapMode
          ? "PILIH BULAN (Tanggal Bebas)"
          : "PILIH TANGGAL ABSENSI",
    );
    if (picked != null && picked != selectedDate) {
      selectedDate = picked;
      currentPage = 1;
      fetchData();
    }
  }

  void nextPage() {
    if (isRekapMode) return;

    if (currentPage * itemLimit < totalRows) {
      currentPage++;
      fetchData();
    }
  }

  void prevPage() {
    if (isRekapMode) return;

    if (currentPage > 1) {
      currentPage--;
      fetchData();
    }
  }

  int get totalPages {
    if (totalRows == 0) return 1;
    return (totalRows / itemLimit).ceil();
  }

  String fmtDate(String date) {
    try {
      return DateFormat('dd MMM yyyy', 'id_ID').format(DateTime.parse(date));
    } catch (e) {
      return date;
    }
  }

  String fmtTime(String? time) {
    if (time == null) return '-';
    try {
      final parts = time.split(':');
      return "${parts[0]}:${parts[1]}";
    } catch (e) {
      return time;
    }
  }
}
