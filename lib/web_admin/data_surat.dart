import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:universal_html/html.dart' as html;

// Daftar Jenis Surat Dibatasi hanya Izin dan Sakit
const List<String> jenisSuratList = ['izin', 'sakit'];

class DataSuratPage extends StatefulWidget {
  final String schoolName;

  const DataSuratPage({super.key, required this.schoolName});

  @override
  State<DataSuratPage> createState() => _DataSuratPageState();
}

class _DataSuratPageState extends State<DataSuratPage> {
  final SupabaseClient supabase = Supabase.instance.client;
  bool isLoading = true;
  List<Map<String, dynamic>> suratData = [];

  // Filter States
  String? selectedJenisSurat;
  DateTime? selectedStartDate;
  DateTime? selectedEndDate;
  final TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    Intl.defaultLocale = 'id_ID';
    fetchSurat();
  }

  /// 📥 Fetch Data Surat dari Supabase (Kode tetap sama)
  Future<void> fetchSurat() async {
    setState(() => isLoading = true);
    try {
      var query = supabase.from('surat').select('*, siswa!inner(nama)');

      if (selectedStartDate != null) {
        query = query.gte(
          'tanggal',
          DateFormat('yyyy-MM-dd').format(selectedStartDate!),
        );
      }
      if (selectedEndDate != null) {
        query = query.lte(
          'tanggal',
          DateFormat('yyyy-MM-dd').format(selectedEndDate!),
        );
      }
      if (selectedJenisSurat != null && selectedJenisSurat!.isNotEmpty) {
        query = query.eq('jenis', selectedJenisSurat!);
      }

      final response = await query.order('tanggal', ascending: false);
      List<Map<String, dynamic>> allData = List<Map<String, dynamic>>.from(
        response,
      );

      if (searchController.text.trim().isNotEmpty) {
        String keyword = searchController.text.toLowerCase();
        allData = allData
            .where(
              (s) => (s['siswa']?['nama'] ?? '')
                  .toString()
                  .toLowerCase()
                  .contains(keyword),
            )
            .toList();
      }

      setState(() {
        suratData = allData;
        isLoading = false;
      });
    } catch (e, stacktrace) {
      print('==================================================');
      print('❌ Error fetching surat: $e');
      print('Stacktrace: $stacktrace');
      print('==================================================');

      setState(() => isLoading = false);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Gagal memuat data surat. Cek log konsol untuk detail.',
            ),
          ),
        );
      }
    }
  }

  void _showSnackbar(String message) {
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  /// 📤 Menangani Download/Konversi PDF
  /// Logika ini sekarang menangani konversi jika URL adalah gambar,
  /// dan memicu download otomatis untuk web/mobile.
  Future<void> _handleDownload(String fileUrl, String fileName) async {
    if (fileUrl.isEmpty) {
      _showSnackbar('URL file tidak tersedia.');
      return;
    }

    // Cek apakah URL adalah gambar yang mungkin perlu dikonversi
    final isImage =
        fileUrl.toLowerCase().contains('.png') ||
        fileUrl.toLowerCase().contains('.jpg') ||
        fileUrl.toLowerCase().contains('.jpeg') ||
        fileUrl.toLowerCase().contains('.webp'); // asumsi ini bisa diconvert

    if (isImage) {
      _showSnackbar('Mulai mengunduh dan mengkonversi gambar ke PDF...');
      try {
        // 1. Ambil data gambar dari URL
        final response = await http.get(Uri.parse(fileUrl));
        if (response.statusCode != 200) {
          _showSnackbar(
            'Gagal mengambil file gambar. Status: ${response.statusCode}',
          );
          return;
        }
        final imageBytes = response.bodyBytes;

        // 2. Buat objek PDF
        final pdf = pw.Document();
        final image = pw.MemoryImage(imageBytes);

        // 3. Tambahkan gambar ke PDF (disesuaikan agar pas di halaman A4)
        pdf.addPage(
          pw.Page(
            pageFormat: PdfPageFormat.a4,
            build: (pw.Context context) {
              return pw.Container(
                alignment: pw.Alignment.center,
                child: pw.Image(image),
              );
            },
          ),
        );

        // 4. Simpan PDF ke bytes
        final Uint8List pdfBytes = await pdf.save();
        final finalFileName = '$fileName.pdf';

        // 5. Memicu Download berdasarkan Platform
        if (kIsWeb) {
          // Khusus Flutter Web: Memicu download otomatis
          final blob = html.Blob([pdfBytes]);
          final url = html.Url.createObjectUrlFromBlob(blob);
          html.AnchorElement(href: url)
            ..setAttribute("download", finalFileName)
            ..click();
          html.Url.revokeObjectUrl(url);
          _showSnackbar('PDF berhasil dibuat dan diunduh.');
        } else {
          // Mobile/Desktop: Simpan ke direktori download/aplikasi dan buka
          final directory = await getApplicationDocumentsDirectory();
          final file = File('${directory.path}/$finalFileName');
          await file.writeAsBytes(pdfBytes);

          // Coba membuka file (Tergantung OS, bisa memicu viewer/download)
          final success = await launchUrl(Uri.file(file.path));
          if (success) {
            _showSnackbar('PDF berhasil dibuat. File dibuka: ${file.path}');
          } else {
            _showSnackbar('PDF berhasil dibuat, tetapi gagal dibuka.');
          }
        }
      } catch (e, stacktrace) {
        print('==================================================');
        print('❌ Error converting/downloading PDF: $e');
        print('Stacktrace: $stacktrace');
        print('==================================================');
        _showSnackbar('Gagal mengkonversi/mengunduh PDF. Cek log konsol.');
      }
    } else {
      // Jika URL bukan gambar (misalnya, sudah PDF atau jenis dokumen lain)
      // Gunakan url_launcher untuk membuka/mengunduh URL aslinya
      final Uri uri = Uri.parse(fileUrl);

      if (!await canLaunchUrl(uri)) {
        _showSnackbar('URL tidak valid atau browser tidak bisa dibuka.');
        return;
      }

      try {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        _showSnackbar('Membuka file asli...');
      } catch (e) {
        _showSnackbar('Error saat membuka file: $e');
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
            'Data Surat Izin/Sakit Siswa',
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
                "Filter Data Surat",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              SizedBox(
                width: 230,
                child: _buildDateFilter('Dari Tanggal', selectedStartDate, (
                  date,
                ) {
                  setState(() {
                    selectedStartDate = date;
                  });
                  fetchSurat();
                }),
              ),
              SizedBox(
                width: 230,
                child: _buildDateFilter('Sampai Tanggal', selectedEndDate, (
                  date,
                ) {
                  setState(() {
                    selectedEndDate = date;
                  });
                  fetchSurat();
                }),
              ),
              SizedBox(
                width: 230,
                child: DropdownButtonFormField<String>(
                  value: selectedJenisSurat,
                  hint: const Text("Pilih Jenis Surat"),
                  items: [
                    const DropdownMenuItem(
                      value: null,
                      child: Text("Semua Jenis"),
                    ),
                    ...jenisSuratList.map(
                      (jenis) =>
                          DropdownMenuItem(value: jenis, child: Text(jenis)),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() {
                      selectedJenisSurat = value;
                    });
                    fetchSurat();
                  },
                  decoration: InputDecoration(
                    labelText: 'Jenis Surat',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                  ),
                ),
              ),
              SizedBox(
                width: 230,
                child: TextField(
                  controller: searchController,
                  decoration: InputDecoration(
                    labelText: 'Cari Nama Siswa',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                  ),
                  onChanged: (val) {
                    fetchSurat();
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDateFilter(
    String label,
    DateTime? currentValue,
    Function(DateTime?) onChanged,
  ) {
    return TextFormField(
      readOnly: true,
      onTap: () async {
        final DateTime? pickedDate = await showDatePicker(
          context: context,
          initialDate: currentValue ?? DateTime.now(),
          firstDate: DateTime(2000),
          lastDate: DateTime(2050),
        );
        if (pickedDate != null) {
          onChanged(pickedDate);
        }
      },
      controller: TextEditingController(
        text: currentValue == null
            ? ''
            : DateFormat('dd MMM yyyy').format(currentValue),
      ),
      decoration: InputDecoration(
        labelText: label,
        suffixIcon: IconButton(
          icon: Icon(currentValue == null ? Icons.calendar_today : Icons.clear),
          onPressed: currentValue == null
              ? null
              : () {
                  onChanged(null);
                },
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 10,
        ),
      ),
    );
  }

  Widget _buildTable() {
    if (suratData.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Text('Tidak ada data surat ditemukan dengan filter saat ini.'),
        ),
      );
    }

    return Container(
      // Hapus width: double.infinity di sini karena akan ditangani oleh LayoutBuilder/parent
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
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Gunakan lebar maksimum yang tersedia sebagai lebar minimum untuk DataTable
          final double minTableWidth = constraints.maxWidth;

          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              // Menggunakan minWidth: minTableWidth akan membuat tabel mengisi lebar penuh,
              // tetapi jika total lebar kolom melebihi minTableWidth, ia akan melebar dan
              // SingleChildScrollView akan mengaktifkan scrolling.
              constraints: BoxConstraints(minWidth: minTableWidth),
              child: DataTable(
                columnSpacing: 24,
                headingRowHeight: 56,
                dataRowHeight: 64,
                headingRowColor: MaterialStateProperty.all(Colors.blue.shade50),
                columns: const [
                  DataColumn(
                    label: Text(
                      'ID Surat',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      'ID Siswa',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      'Nama Siswa',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      'Tanggal',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      'Jenis Surat',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      'Aksi',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
                rows: List.generate(suratData.length, (i) {
                  final s = suratData[i];
                  // Pastikan Anda telah mengimpor package intl
                  // import 'package:intl/intl.dart';
                  final tanggal = s['tanggal'] != null
                      ? DateFormat(
                          'dd MMM yyyy',
                        ).format(DateTime.parse(s['tanggal']))
                      : '-';

                  return DataRow(
                    cells: [
                      DataCell(Text('${s['id'] ?? '-'}')),
                      DataCell(Text('${s['siswa_id'] ?? '-'}')),
                      DataCell(Text('${s['siswa']?['nama'] ?? '-'}')),
                      DataCell(Text(tanggal)),
                      DataCell(Text('${s['jenis'] ?? '-'}')),
                      DataCell(
                        Row(
                          children: [
                            _buildAction(
                              Icons.visibility,
                              'Lihat',
                              Colors.green,
                              () => _showDetailDialog(s),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                }),
              ),
            ),
          );
        },
      ),
    );
  }

  /// ℹ️ Dialog Detail Surat
  void _showDetailDialog(Map<String, dynamic> surat) {
    final String tanggal = surat['tanggal'] != null
        ? DateFormat(
            'EEEE, dd MMMM yyyy',
          ).format(DateTime.parse(surat['tanggal']))
        : '-';

    final String fileUrl = surat['file_url'] ?? '';
    final bool isDownloadable = fileUrl.isNotEmpty;
    final String actionLabel = _getDownloadActionLabel(fileUrl);
    final Color actionColor = fileUrl.toLowerCase().contains('.pdf')
        ? Colors.red
        : Colors.orange;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Detail Surat'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                _buildDetailRow('ID Surat:', surat['id'].toString()),
                _buildDetailRow('ID Siswa:', surat['siswa_id'].toString()),
                _buildDetailRow('Nama Siswa:', surat['siswa']?['nama'] ?? '-'),
                _buildDetailRow('Tanggal:', tanggal),
                _buildDetailRow('Jenis Surat:', surat['jenis'] ?? '-'),
                _buildDetailRow('File URL:', fileUrl),
                const SizedBox(height: 16),
                const Text(
                  'Aksi:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  onPressed: isDownloadable
                      ? () {
                          Navigator.of(
                            context,
                          ).pop(); // Tutup dialog sebelum download
                          // Buat nama file yang unik untuk download
                          final filename =
                              'surat_${surat['id'] ?? 'unknown'}_${surat['jenis'] ?? 'file'}';
                          _handleDownload(
                            fileUrl,
                            filename,
                          ); // Panggil fungsi download/konversi
                        }
                      : null,
                  icon: const Icon(Icons.picture_as_pdf),
                  label: Text(actionLabel),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: actionColor,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Tutup'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  String _getDownloadActionLabel(String fileUrl) {
    final lowerUrl = fileUrl.toLowerCase();
    if (lowerUrl.isEmpty) {
      return 'File Tidak Tersedia';
    } else if (lowerUrl.contains('.png') ||
        lowerUrl.contains('.jpg') ||
        lowerUrl.contains('.jpeg')) {
      return 'Konversi & Download PDF (dari Gambar)';
    } else if (lowerUrl.contains('.pdf')) {
      return 'Download PDF Asli';
    } else {
      return 'Download File Asli';
    }
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Widget _buildAction(
    IconData icon,
    String label,
    Color color,
    VoidCallback onPressed,
  ) {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: color.withOpacity(0.1),
        foregroundColor: color,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      icon: Icon(icon, size: 16),
      label: Text(
        label,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
      ),
      onPressed: onPressed,
    );
  }
}
