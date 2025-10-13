// page_absensi.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PageAbsensi extends StatefulWidget {
  final String schoolName;

  const PageAbsensi({super.key, required this.schoolName});

  @override
  State<PageAbsensi> createState() => _PageAbsensiState();
}

class _PageAbsensiState extends State<PageAbsensi> {
  final SupabaseClient supabase = Supabase.instance.client;
  bool isLoading = true;
  List<Map<String, dynamic>> absensiData = [];

  // -------- Debug helper ----------
  void debugLog(String message) {
    debugPrint('[ABSENSI DEBUG] $message');
  }

  @override
  void initState() {
    super.initState();
    fetchAbsensi();
  }

  Future<void> fetchAbsensi() async {
    setState(() => isLoading = true);
    debugLog('Mulai fetch absensi dari Supabase...');
    try {
      // Query sesuai schema: ambil relasi siswa(nama) dan guru(nama)
      final response = await supabase.from('absensi').select('''
        id,
        siswa_id,
        siswa (nama),
        tanggal,
        status,
        waktu_masuk,
        waktu_pulang,
        keterangan,
        updated_by,
        guru (nama),
        created_at,
        updated_at
      ''');

      debugLog('Raw response type: ${response.runtimeType}');
      if (response is List) {
        absensiData = List<Map<String, dynamic>>.from(response.map((e) => Map<String, dynamic>.from(e as Map)));
        debugLog('Data absensi berhasil dimuat: ${absensiData.length} baris');
      } else {
        debugLog('Response bukan list. Isi response: $response');
        absensiData = [];
      }
    } catch (e, st) {
      debugLog('Error saat fetchAbsensi: $e');
      debugLog('Stack: $st');
      absensiData = [];
    } finally {
      setState(() => isLoading = false);
    }
  }

  String fmtDate(dynamic value) {
    if (value == null) return '-';
    try {
      DateTime dt;
      if (value is DateTime) {
        dt = value;
      } else {
        dt = DateTime.parse(value.toString());
      }
      return DateFormat('dd-MM-yyyy').format(dt);
    } catch (e) {
      debugLog('fmtDate error for value=$value -> $e');
      return value.toString();
    }
  }

  String fmtDateTime(dynamic value) {
    if (value == null) return '-';
    try {
      DateTime dt;
      if (value is DateTime) {
        dt = value;
      } else {
        dt = DateTime.parse(value.toString());
      }
      return DateFormat('dd-MM-yyyy HH:mm').format(dt.toLocal());
    } catch (e) {
      debugLog('fmtDateTime error for value=$value -> $e');
      return value.toString();
    }
  }

  String fmtTime(dynamic value) {
    if (value == null) return '-';
    try {
      final s = value.toString();
      final parts = s.split(':');
      if (parts.length >= 2) {
        return '${parts[0].padLeft(2, '0')}:${parts[1].padLeft(2, '0')}';
      } else {
        return s;
      }
    } catch (e) {
      debugLog('fmtTime error for value=$value -> $e');
      return value.toString();
    }
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
        gradient: LinearGradient(colors: [Colors.blue.shade800, Colors.blue.shade600]),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.blue.withOpacity(0.2), blurRadius: 12, offset: const Offset(0, 4))
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Data Absensi',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
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

  Widget _buildTable() {
    if (absensiData.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Text('Tidak ada data absensi ditemukan.'),
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.grey.withOpacity(0.08), blurRadius: 10, offset: const Offset(0, 2))
        ],
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 1000),
          child: DataTable(
            columnSpacing: 24,
            headingRowHeight: 56,
            dataRowHeight: 64,
            headingRowColor: MaterialStateProperty.all(Colors.grey[50]),
            columns: const [
              DataColumn(label: Text('Nama Siswa', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('Tanggal', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('Waktu Masuk', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('Waktu Pulang', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('Keterangan', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('Surat', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('Aksi', style: TextStyle(fontWeight: FontWeight.bold))),
            ],
            rows: List.generate(absensiData.length, (i) {
              final a = absensiData[i];
              final String namaSiswa = (a['siswa'] is Map) ? (a['siswa']['nama'] ?? '-') : '-';
              final tanggal = fmtDate(a['tanggal']);
              final status = a['status'] ?? '-';
              final masuk = fmtTime(a['waktu_masuk']);
              final pulang = fmtTime(a['waktu_pulang']);
              final keterangan = a['keterangan'] ?? '-';

              return DataRow(cells: [
                DataCell(Text(namaSiswa)),
                DataCell(Text(tanggal)),
                DataCell(Text(status)),
                DataCell(Text(masuk)),
                DataCell(Text(pulang)),
                DataCell(Text(keterangan)),
                // Kolom Surat: schema tidak punya surat_url -> tampil '-'
                const DataCell(Text('-')),
                DataCell(Row(children: [
                  _buildAction(Icons.edit, 'Edit', Colors.blue, onPressed: () {
                    debugLog('Edit pressed for id=${a['id']}');
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Edit: fitur belum diimplementasikan')));
                  }),
                  const SizedBox(width: 8),
                  _buildAction(Icons.visibility, 'Detail', Colors.blue.shade700, onPressed: () {
                    debugLog('Detail pressed for id=${a['id']}');
                    _showDetailBottomSheet(context, a);
                  }),
                ])),
              ]);
            }),
          ),
        ),
      ),
    );
  }

  Widget _buildAction(IconData icon, String label, Color color, {required VoidCallback onPressed}) {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: color.withOpacity(0.12),
        foregroundColor: color,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      icon: Icon(icon, size: 16),
      label: Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
      onPressed: onPressed,
    );
  }

  void _showDetailBottomSheet(BuildContext context, Map<String, dynamic> a) {
    final String namaSiswa = (a['siswa'] is Map) ? (a['siswa']['nama'] ?? '-') : '-';
    // Hanya ambil nama guru (jika ada). Jika null -> '-'
    final String guruNama = (a['guru'] is Map) ? (a['guru']['nama'] ?? '-') : '-';
    final String tanggal = fmtDate(a['tanggal']);
    final String status = a['status'] ?? '-';
    final String waktuMasuk = fmtTime(a['waktu_masuk']);
    final String waktuPulang = fmtTime(a['waktu_pulang']);
    final String keterangan = a['keterangan'] ?? '-';
    final String createdAt = fmtDateTime(a['created_at']);
    final String updatedAt = fmtDateTime(a['updated_at']);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.85,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                children: [
                  // Header blue clean
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade700,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.assignment_ind, color: Colors.white),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'Detail Absensi',
                            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ),
                        IconButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                          icon: const Icon(Icons.close, color: Colors.white),
                        )
                      ],
                    ),
                  ),

                  // Body
                  Expanded(
                    child: SingleChildScrollView(
                      controller: scrollController,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Summary card
                          Card(
                            elevation: 2,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.blue.shade50,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Icon(Icons.people, size: 28, color: Colors.blue),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(namaSiswa, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                        const SizedBox(height: 6),
                                        Text('Tanggal: $tanggal • Status: $status', style: const TextStyle(fontSize: 13)),
                                      ],
                                    ),
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text('Masuk: $waktuMasuk', style: const TextStyle(fontWeight: FontWeight.w600)),
                                      const SizedBox(height: 6),
                                      Text('Pulang: $waktuPulang', style: const TextStyle(fontWeight: FontWeight.w600)),
                                    ],
                                  )
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: 18),

                          // Details list
                          _buildDetailRow(Icons.note, 'Keterangan', keterangan),
                          const SizedBox(height: 8),
                          // Hanya tampilkan nama guru (label: Diupdate oleh)
                          _buildDetailRow(Icons.edit, 'Diupdate oleh', guruNama),
                          const SizedBox(height: 8),
                          _buildDetailRow(Icons.calendar_today, 'Dibuat pada', createdAt),
                          const SizedBox(height: 8),
                          _buildDetailRow(Icons.update, 'Diupdate pada', updatedAt),

                          const SizedBox(height: 20),
                          const SizedBox(height: 30),
                        ],
                      ),
                    ),
                  )
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDetailRow(IconData icon, String title, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: Colors.blue.shade700),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              Text(value, style: const TextStyle(fontSize: 13, color: Colors.black87)),
            ],
          ),
        )
      ],
    );
  }
}
