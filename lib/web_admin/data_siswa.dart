import 'dart:io';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:file_picker/file_picker.dart';

// --- (TAMBAHAN) IMPORTS UNTUK QR CODE, PDF, DAN UNDUH ---
import 'package:barcode_widget/barcode_widget.dart';
import 'package:screenshot/screenshot.dart';
import 'package:universal_html/html.dart' as html;
import 'dart:typed_data';
import 'dart:convert';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
// --- AKHIR TAMBAHAN IMPORTS ---

class DataSiswaPage extends StatefulWidget {
  final String schoolName;
  final String? initialKelasId;

  const DataSiswaPage({
    super.key,
    required this.schoolName,
    this.initialKelasId,
  });

  @override
  State<DataSiswaPage> createState() => _DataSiswaPageState();
}

class _DataSiswaPageState extends State<DataSiswaPage> {
  final SupabaseClient supabase = Supabase.instance.client;

  bool isLoading = true;
  bool isKelasLoading = true;

  List<Map<String, dynamic>> siswaData = [];
  List<Map<String, dynamic>> kelasList = [];

  int? selectedKelasId;
  String? selectedStatus;
  final TextEditingController searchController = TextEditingController();

  // Helper untuk mendapatkan nama kelas yang dipilih (untuk judul PDF)
  String get _selectedKelasNama {
    if (selectedKelasId == null) return "Semua Kelas";
    try {
      return kelasList.firstWhere(
        (k) => k['id'] == selectedKelasId,
      )['nama_kelas'];
    } catch (e) {
      return "Kelas";
    }
  }

  @override
  void initState() {
    super.initState();
    selectedKelasId = widget.initialKelasId != null
        ? int.tryParse(widget.initialKelasId!)
        : null;
    fetchKelas();
  }

  Future<void> fetchKelas() async {
    if (!mounted) return;
    setState(() {
      isKelasLoading = true;
    });

    try {
      final response = await supabase
          .from('kelas')
          .select('id, nama_kelas')
          .order('nama_kelas', ascending: true);

      if (!mounted) return;
      setState(() {
        kelasList = List<Map<String, dynamic>>.from(response);
        isKelasLoading = false;
      });

      await fetchSiswa();
    } catch (e) {
      print('Error fetching kelas: $e');
      if (!mounted) return;
      setState(() {
        isKelasLoading = false;
      });
    }
  }

  Future<void> fetchSiswa() async {
    setState(() => isLoading = true);
    try {
      var query = supabase.from('siswa').select('*, kelas!inner(nama_kelas)');
      if (selectedKelasId != null) {
        query = query.eq('kelas_id', selectedKelasId!);
      }

      if (selectedStatus != null && selectedStatus!.isNotEmpty) {
        query = query.eq('status', selectedStatus!);
      }

      final response = await query.order('kelas_id', ascending: true);
      List<Map<String, dynamic>> allData = List<Map<String, dynamic>>.from(
        response,
      );

      if (searchController.text.trim().isNotEmpty) {
        String keyword = searchController.text.toLowerCase();
        allData = allData
            .where(
              (s) =>
                  (s['nama'] ?? '').toString().toLowerCase().contains(keyword),
            )
            .toList();
      }

      if (!mounted) return;
      setState(() {
        siswaData = allData;
        siswaData.sort((a, b) {
          int kelasComparison = (a['kelas_id'] ?? 0).compareTo(
            b['kelas_id'] ?? 0,
          );
          if (kelasComparison != 0) return kelasComparison;
          return (a['no'] ?? 0).compareTo(b['no'] ?? 0);
        });
        isLoading = false;
      });
    } catch (e) {
      print('Error fetching siswa: $e');
      if (!mounted) return;
      setState(() => isLoading = false);
    }
  }

  Future<void> _saveSiswa({
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

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isEdit
                ? 'Data berhasil diperbarui'
                : 'Data siswa berhasil ditambahkan',
          ),
        ),
      );

      fetchSiswa();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal menyimpan data: $e')));
    }
  }

  Future<void> _deleteSiswa(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi'),
        content: const Text(
          'Apakah Anda yakin ingin menghapus data siswa ini?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await supabase.from('siswa').delete().eq('id', id);
      fetchSiswa();
    }
  }

  void _showSiswaForm({Map<String, dynamic>? siswa}) {
    final isEdit = siswa != null;
    final TextEditingController nisController = TextEditingController(
      text: siswa?['nis'] ?? '',
    );
    final TextEditingController namaController = TextEditingController(
      text: siswa?['nama'] ?? '',
    );
    final TextEditingController ortuNamaController = TextEditingController(
      text: siswa?['orang_tua_nama'] ?? '',
    );
    final TextEditingController ortuNomorController = TextEditingController(
      text: siswa?['orang_tua_nomor'] ?? '',
    );

    int? kelasId = siswa?['kelas_id'];
    String? status = siswa?['status'];

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(isEdit ? "Edit Siswa" : "Tambah Siswa"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min, // Agar pas
              children: [
                TextField(
                  controller: nisController,
                  decoration: const InputDecoration(labelText: 'NIS'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: namaController,
                  decoration: const InputDecoration(labelText: 'Nama'),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<int>(
                  value: kelasId, // value adalah int?
                  hint: const Text('Pilih Kelas'),
                  items: [
                    const DropdownMenuItem<int>(
                      value: null,
                      child: Text("(Belum ada kelas)"),
                    ),
                    ...kelasList
                        .map(
                          (k) => DropdownMenuItem(
                            value: k['id'] as int,
                            child: Text(k['nama_kelas']),
                          ),
                        )
                        .toList(),
                  ],
                  onChanged: (val) => kelasId = val,
                  decoration: const InputDecoration(labelText: 'Kelas'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: ortuNamaController,
                  decoration: const InputDecoration(
                    labelText: 'Nama Orang Tua',
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: ortuNomorController,
                  decoration: const InputDecoration(
                    labelText: 'Nomor WA Orang Tua',
                  ),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: status, // value adalah String?
                  hint: const Text('Pilih Status'),
                  items: const [
                    DropdownMenuItem<String>(
                      value: null,
                      child: Text("(Belum ada status)"),
                    ),
                    DropdownMenuItem(value: 'aktif', child: Text('Aktif')),
                    DropdownMenuItem(
                      value: 'tidak aktif',
                      child: Text('Tidak Aktif'),
                    ),
                    DropdownMenuItem(value: 'lulus', child: Text('Lulus')),
                  ],
                  onChanged: (val) => status = val,
                  decoration: const InputDecoration(labelText: 'Status'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Batal"),
            ),
            ElevatedButton(
              onPressed: () async {
                await _saveSiswa(
                  isEdit: isEdit,
                  siswaId: siswa?['id'],
                  nis: nisController.text,
                  nama: namaController.text,
                  kelasId: kelasId,
                  ortuNama: ortuNamaController.text,
                  ortuNomor: ortuNomorController.text,
                  status: status,
                );
                if (!mounted) return;
                Navigator.pop(context);
              },
              child: Text(isEdit ? "Simpan Perubahan" : "Tambah"),
            ),
          ],
        );
      },
    );
  }

  // FUNGSI UNTUK MENGUNDUH GAMBAR BARCODE (WEB)
  Future<void> _downloadBarcode(Uint8List bytes, String filename) async {
    final base64 = base64Encode(bytes);
    final href = 'data:application/octet-stream;base64,$base64';
    final anchor = html.AnchorElement(href: href)
      ..setAttribute("download", filename)
      ..click();
  }

  // FUNGSI UNTUK MENAMPILKAN DIALOG QR CODE (PER SISWA)
  void _showBarcodeDialog(Map<String, dynamic> siswa) {
    final String nis = siswa['nis']?.toString() ?? '';
    final String nama = siswa['nama'] ?? 'Nama Tidak Ditemukan';

    if (nis.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Siswa ini tidak memiliki NIS untuk dibuatkan barcode.',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final ScreenshotController screenshotController = ScreenshotController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("QR Code Siswa"),
          content: SizedBox(
            width: 350,
            child: Screenshot(
              controller: screenshotController,
              child: Container(
                color: Colors.white, // Background putih untuk diunduh
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      nama,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "NIS: $nis",
                      style: const TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                    const SizedBox(height: 24),
                    // UBAH KE QR CODE
                    BarcodeWidget(
                      barcode: Barcode.qrCode(), // Tipe QR Code
                      data: nis,
                      width: 250, // Ukuran persegi
                      height: 250, // Ukuran persegi
                      drawText: false, // Teks sudah ada di atas
                      color: Colors.black,
                    ),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Tutup"),
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.download),
              label: const Text("Unduh"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                final bytes = await screenshotController.capture(
                  delay: const Duration(milliseconds: 10),
                );
                if (bytes != null) {
                  final safeFilename = nama
                      .replaceAll(' ', '_')
                      .replaceAll(RegExp(r'[^\w.-]'), '');
                  await _downloadBarcode(bytes, '$safeFilename-qrcode.png');
                }
              },
            ),
          ],
        );
      },
    );
  }

  // FUNGSI UNTUK MEMBUAT PDF (PER KELAS)
  Future<void> _generateBarcodePdf() async {
    final List<Map<String, dynamic>> siswaDiKelas = siswaData;
    final String namaKelas = _selectedKelasNama;

    if (siswaDiKelas.isEmpty) {
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
    for (final siswa in siswaDiKelas) {
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
                // UBAH KE QR CODE
                pw.BarcodeWidget(
                  barcode: pw.Barcode.qrCode(), // Tipe QR Code
                  data: nis,
                  width: 80, // Ukuran persegi
                  height: 80, // Ukuran persegi
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
            crossAxisCount: 3, // 3 barcode per baris
            childAspectRatio: 1.2, // UBAH: Rasio lebih persegi
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            children: barcodeWidgets,
          ),
        ],
      ),
    );

    // Tampilkan layar Print/Save PDF
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }

  Future<void> _importCSV() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv'],
    );
    if (result != null && result.files.single.path != null) {
      final file = File(result.files.single.path!);
      final bytes = await file.readAsBytes();

      try {
        await supabase.storage
            .from('uploads')
            .uploadBinary('import_siswa.csv', bytes);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('CSV berhasil diunggah ke storage')),
        );
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal upload CSV: $e')));
      }
    }
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 16),
            // BARIS TOMBOL AKSI UTAMA
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ElevatedButton.icon(
                  onPressed: () => _showSiswaForm(),
                  icon: const Icon(Icons.add),
                  label: const Text("Tambah Siswa"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: _importCSV,
                  icon: const Icon(Icons.file_upload),
                  label: const Text("Import CSV"),
                ),
                const SizedBox(width: 16),
                // TOMBOL CETAK QR CODE KELAS
                ElevatedButton.icon(
                  onPressed: selectedKelasId == null
                      ? null // Nonaktif jika "Semua Kelas" dipilih
                      : _generateBarcodePdf,
                  icon: const Icon(Icons.print),
                  label: const Text("Cetak QR Code Kelas"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey.shade300,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),
            _buildFilter(),
            const SizedBox(height: 20),
            isLoading
                ? const Center(child: CircularProgressIndicator())
                : _buildTable(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue[700]!, Colors.blue[500]!],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Data Siswa',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          Row(
            children: [
              const Icon(Icons.school, color: Colors.white),
              const SizedBox(width: 8),
              Text(
                widget.schoolName,
                style: const TextStyle(color: Colors.white, fontSize: 16),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilter() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.filter_alt, color: Colors.blueAccent),
              SizedBox(width: 8),
              Text(
                "Filter Data Siswa",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 16),
          isKelasLoading
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text("Memuat filter kelas..."),
                  ),
                )
              : Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<int>(
                        value: selectedKelasId,
                        hint: const Text("Pilih Kelas"),
                        items: [
                          const DropdownMenuItem<int>(
                            value: null,
                            child: Text("Semua Kelas"),
                          ),
                          ...kelasList.map(
                            (kelas) => DropdownMenuItem<int>(
                              value: kelas['id'] as int,
                              child: Text(kelas['nama_kelas']),
                            ),
                          ),
                        ],
                        onChanged: (value) {
                          setState(() {
                            selectedKelasId = value;
                          });
                          fetchSiswa();
                        },
                        decoration: InputDecoration(
                          labelText: 'Kelas',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextField(
                        controller: searchController,
                        decoration: InputDecoration(
                          labelText: 'Cari Nama',
                          prefixIcon: const Icon(Icons.search),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onChanged: (val) => fetchSiswa(),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: selectedStatus,
                        hint: const Text("Semua Status"),
                        items: const [
                          DropdownMenuItem(
                            value: null,
                            child: Text("Semua Status"),
                          ),
                          DropdownMenuItem(
                            value: "Aktif",
                            child: Text("Aktif"),
                          ),
                          DropdownMenuItem(
                            value: "Tidak Aktif",
                            child: Text("Tidak Aktif"),
                          ),
                          DropdownMenuItem(
                            value: "Lulus",
                            child: Text("Lulus"),
                          ),
                        ],
                        onChanged: (value) {
                          setState(() {
                            selectedStatus = value;
                          });
                          fetchSiswa();
                        },
                        decoration: InputDecoration(
                          labelText: 'Status',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
        ],
      ),
    );
  }

  Widget _buildTable() {
    if (siswaData.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Text('Tidak ada data siswa ditemukan.'),
        ),
      );
    }
    const double tableMinWidth = 790;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: tableMinWidth),
          child: DataTable(
            columnSpacing:
                0.0, 
            headingRowHeight: 52,
            dataRowHeight: 60,
            headingRowColor: MaterialStateProperty.all(Colors.blue.shade50),

            // --- Kolom (Columns) ---
            columns: const [
              DataColumn(
                label: SizedBox(
                  width: 60,
                  child: Align(
                    child: Text(
                      'No',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),
              DataColumn(
                label: SizedBox(
                  width: 70, // Dikecilkan lagi
                  child: Center(
                    child: Text(
                      'NIS',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),
              DataColumn(
                label: SizedBox(
                  width: 190, // Dikecilkan
                  child: Center(
                    child: Text(
                      'Nama',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),
              DataColumn(
                label: SizedBox(
                  width: 100, // Dikecilkan
                  child: Center(
                    child: Text(
                      'Kelas',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),
              DataColumn(
                label: SizedBox(
                  width: 160, // Dikecilkan
                  child: Center(
                    child: Text(
                      'Nama Ortu',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),
              DataColumn(
                label: SizedBox(
                  width: 100, // Dikecilkan
                  child: Center(
                    child: Text(
                      'No. Ortu',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),
              DataColumn(
                label: SizedBox(
                  width: 80,
                  child: Center(
                    child: Text(
                      'Status',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),
              DataColumn(
                label: SizedBox(
                  width: 140,
                  child: Center(
                    child: Text(
                      'Aksi',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),
            ],

            // --- Baris (Rows) ---
            rows: List.generate(siswaData.length, (i) {
              final s = siswaData[i];
              return DataRow(
                cells: [
                  DataCell(Center(child: Text('${i + 1}'))),
                  DataCell(Center(child: Text('${s['nis'] ?? '-'}'))),
                  DataCell(Center(child: Text('${s['nama'] ?? '-'}'))),
                  DataCell(
                    Center(child: Text('${s['kelas']?['nama_kelas'] ?? '-'}')),
                  ),
                  DataCell(
                    Center(child: Text('${s['orang_tua_nama'] ?? '-'}')),
                  ),
                  DataCell(
                    Center(child: Text('${s['orang_tua_nomor'] ?? '-'}')),
                  ),
                  DataCell(Center(child: Text('${s['status'] ?? '-'}'))),
                  DataCell(
                    Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildAction(
                            Icons.qr_code_2,
                            'QR',
                            Colors.teal,
                            onPressed: () => _showBarcodeDialog(s),
                          ),
                          const SizedBox(width: 4),
                          _buildAction(
                            Icons.edit,
                            'Edit',
                            Colors.blue,
                            onPressed: () => _showSiswaForm(siswa: s),
                          ),
                          const SizedBox(width: 4),
                          _buildAction(
                            Icons.delete,
                            'Hapus',
                            Colors.red,
                            onPressed: () => _deleteSiswa(s['id']),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            }),
          ),
        ),
      ),
    );
  }

  Widget _buildAction(
    IconData icon,
    String tooltip,
    Color color, {
    VoidCallback? onPressed,
  }) {
    return IconButton(
      icon: Icon(icon, size: 20, color: color),
      tooltip: tooltip, // muncul saat hover di web
      onPressed: onPressed,
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.all(color.withOpacity(0.1)),
        shape: WidgetStateProperty.all(const CircleBorder()),
        overlayColor: WidgetStateProperty.all(color.withOpacity(0.2)),
      ),
    );
  }
}
