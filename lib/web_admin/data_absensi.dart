import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'absensi_controller.dart'; // Import controller

// Pengaturan Locale untuk DateFormat
// Pastikan memanggil initializeDateFormatting() di main() jika ini gagal.
// Namun, di lingkungan Flutter modern, ini seringkali tidak diperlukan.
// Locale 'id_ID' akan digunakan secara default oleh DateFormat di bawah.

// 1. MAIN PAGE WIDGET (Entry Point)
// -------------------------------------------------------------------
class PageAbsensi extends StatelessWidget {
  final String schoolName;

  const PageAbsensi({super.key, required this.schoolName});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      // PERUBAHAN: Hapus '..fetchAbsensi()' karena constructor controller
      // memanggil _initializeData() secara internal.
      create: (context) => AbsensiController(schoolName: schoolName),
      child: Consumer<AbsensiController>(
        builder: (context, controller, child) {
          return Scaffold(
            backgroundColor: const Color(0xFFF5F7FA),
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Gunakan widget yang sudah di-refactor
                  _AbsensiHeader(schoolName: controller.schoolName),
                  const SizedBox(height: 28),

                  // Baris untuk filter
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Filter Tanggal
                      Expanded(
                        flex: 2,
                        child: _AbsensiDatePicker(controller: controller),
                      ),
                      const SizedBox(width: 20),
                      // BARU: Filter Kelas
                      Expanded(
                        flex: 1,
                        child: _KelasFilterDropdown(controller: controller),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Tampilkan loading atau tabel
                  controller.isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _AbsensiContent(controller: controller),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// 2. HEADER WIDGET
// -------------------------------------------------------------------
class _AbsensiHeader extends StatelessWidget {
  final String schoolName;
  const _AbsensiHeader({required this.schoolName});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade800, Colors.blue.shade600],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.2),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Data Absensi',
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
                schoolName,
                style: const TextStyle(color: Colors.white, fontSize: 16),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// 3. DATE PICKER WIDGET (Diseragamkan)
// -------------------------------------------------------------------
class _AbsensiDatePicker extends StatelessWidget {
  final AbsensiController controller;
  const _AbsensiDatePicker({required this.controller});

  @override
  Widget build(BuildContext context) {
    // Memastikan DateFormat menggunakan 'id_ID'
    final dateFormatter = DateFormat('EEEE, dd MMMM yyyy', 'id_ID');

    return Container(
      height: 60, // ✅ Tinggi diseragamkan
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => controller.handleDatePick(context),
        borderRadius: BorderRadius.circular(12),
        child: Row(
          children: [
            Icon(Icons.calendar_today_outlined, color: Colors.blue.shade700),
            const SizedBox(width: 16),
            const Text(
              'Tanggal:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                dateFormatter.format(controller.selectedDate),
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.black87,
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Icon(Icons.arrow_drop_down, color: Colors.grey.shade700),
          ],
        ),
      ),
    );
  }
}

// 4. KELAS FILTER DROPDOWN (Diseragamkan)
// -------------------------------------------------------------------
class _KelasFilterDropdown extends StatelessWidget {
  final AbsensiController controller;
  const _KelasFilterDropdown({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60, // ✅ Sama seperti DatePicker
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(Icons.class_outlined, color: Colors.blue.shade700),
          const SizedBox(width: 16),
          const Text(
            'Kelas:',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: controller.isKelasLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : DropdownButton<int?>(
                    value: controller.selectedKelasId,
                    isExpanded: true,
                    underline: const SizedBox.shrink(),
                    icon: Icon(
                      Icons.arrow_drop_down,
                      color: Colors.grey.shade700,
                    ),
                    onChanged: (int? newValue) {
                      controller.onKelasSelected(newValue);
                    },
                    items: controller.daftarKelas.map((kelas) {
                      return DropdownMenuItem<int?>(
                        value: kelas['id'],
                        child: Text(
                          kelas['nama_kelas'],
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.black87,
                            fontWeight: FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }).toList(),
                  ),
          ),
        ],
      ),
    );
  }
}

// 5. CONTENT WIDGET (LOGIKA TAMPIL DATA/KOSONG)
// -------------------------------------------------------------------
class _AbsensiContent extends StatelessWidget {
  final AbsensiController controller;
  const _AbsensiContent({required this.controller});

  @override
  Widget build(BuildContext context) {
    if (controller.absensiData.isEmpty) {
      return _EmptyDataView(controller: controller);
    }
    return _AbsensiDataTable(controller: controller);
  }
}

// 6. EMPTY STATE WIDGET
// -------------------------------------------------------------------
class _EmptyDataView extends StatelessWidget {
  final AbsensiController controller;
  const _EmptyDataView({required this.controller});

  @override
  Widget build(BuildContext context) {
    final dateFormatter = DateFormat('dd MMMM yyyy', 'id_ID');

    return Center(
      child: Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        constraints: const BoxConstraints(minWidth: 400),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.info_outline, size: 48, color: Colors.blueGrey),
            const SizedBox(height: 16),
            const Text(
              'Belum ada data absensi',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tidak ditemukan data untuk tanggal ${dateFormatter.format(controller.selectedDate)}.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              icon: const Icon(Icons.refresh),
              label: const Text('Muat Ulang Data'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade700,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
              ),
              onPressed: controller.fetchAbsensi,
            ),
          ],
        ),
      ),
    );
  }
}

// 7. DATA TABLE WIDGET
// -------------------------------------------------------------------
class _AbsensiDataTable extends StatelessWidget {
  final AbsensiController controller;
  const _AbsensiDataTable({required this.controller});

  @override
  Widget build(BuildContext context) {
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
          constraints: BoxConstraints(
            minWidth: MediaQuery.of(context).size.width * 0.75 > 850
                ? MediaQuery.of(context).size.width * 0.75
                : 850,
          ),
          child: DataTable(
            columnSpacing: 16,
            horizontalMargin: 16,
            headingRowHeight: 48,
            dataRowHeight: 52,
            headingRowColor: MaterialStateProperty.all(Colors.blue.shade50),
            columns: _buildTableColumns(),
            rows: List.generate(
              controller.absensiData.length,
              (i) => _buildDataRow(context, controller.absensiData[i]),
            ),
          ),
        ),
      ),
    );
  }

  // Helper untuk membuat kolom
  List<DataColumn> _buildTableColumns() {
    return const [
      DataColumn(
        label: Text(
          'Nama Siswa',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
        ),
      ),
      DataColumn(
        label: SizedBox(
          width: 80,
          child: Text(
            'Tanggal',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          ),
        ),
      ),
      DataColumn(
        label: SizedBox(
          width: 100,
          child: Text(
            'Status',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          ),
        ),
      ),
      DataColumn(
        label: SizedBox(
          width: 90,
          child: Text(
            'Waktu Masuk',
            textAlign: TextAlign.center,
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          ),
        ),
      ),
      DataColumn(
        label: SizedBox(
          width: 90,
          child: Text(
            'Waktu Pulang',
            textAlign: TextAlign.center,
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          ),
        ),
      ),
      DataColumn(
        label: SizedBox(
          width: 100,
          child: Text(
            'Keterangan',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          ),
        ),
      ),
      DataColumn(
        label: SizedBox(
          width: 120,
          child: Text(
            'Surat',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          ),
        ),
      ),
      DataColumn(
        label: SizedBox(
          width: 150,
          child: Text(
            'Aksi',
            textAlign: TextAlign.center,
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          ),
        ),
      ),
    ];
  }

  // Helper untuk membuat baris
  DataRow _buildDataRow(BuildContext context, Map<String, dynamic> a) {
    // Parsing 'siswa' tetap aman karena 'siswa' bisa null
    final String namaSiswa =
        (a['siswa'] is Map) ? (a['siswa']['nama'] ?? '-') : '-';
    final String tanggal = controller.fmtDate(a['tanggal']);
    final String status = a['status'] ?? '-';
    final String masuk = controller.fmtTime(a['waktu_masuk']);
    final String pulang = controller.fmtTime(a['waktu_pulang']);
    final String keterangan = a['keterangan'] ?? '-';
    final hasSurat = a['surat'] != null &&
        a['surat'].toString().isNotEmpty &&
        a['surat'].toString() != '-';

    Color getStatusColor(String status) {
      switch (status.toLowerCase()) {
        case 'hadir':
        case 'izin':
          return Colors.green.shade700;
        case 'terlambat':
        case 'sakit':
          return Colors.orange.shade700;
        case 'alfa':
          return Colors.red.shade700;
        default:
          return Colors.black87;
      }
    }

    return DataRow(
      cells: [
        DataCell(Text(namaSiswa, style: const TextStyle(fontSize: 13))),
        DataCell(
          SizedBox(
            width: 80,
            child: Text(tanggal, style: const TextStyle(fontSize: 13)),
          ),
        ),
        DataCell(
          SizedBox(
            width: 70,
            child: Text(
              status.toUpperCase(),
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: getStatusColor(status),
              ),
            ),
          ),
        ),
        DataCell(
          SizedBox(
            width: 70,
            child: Center(
              child: Text(
                masuk,
                style: TextStyle(
                  fontSize: 13,
                  color: masuk == '-' ? Colors.grey : Colors.green.shade700,
                ),
              ),
            ),
          ),
        ),
        DataCell(
          SizedBox(
            width: 70,
            child: Center(
              child: Text(
                pulang,
                style: TextStyle(
                  fontSize: 13,
                  color: pulang == '-' ? Colors.grey : Colors.red.shade700,
                ),
              ),
            ),
          ),
        ),
        DataCell(
          SizedBox(
            width: 150,
            child: Text(
              keterangan,
              style: const TextStyle(fontSize: 13),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
        ),
        DataCell(
          SizedBox(
            width: 60,
            child: Center(
              child: Text(
                hasSurat ? 'Ada' : '-',
                style: TextStyle(
                  fontSize: 13,
                  color: hasSurat ? Colors.orange.shade700 : Colors.grey,
                ),
              ),
            ),
          ),
        ),
        DataCell(
          SizedBox(
            width: 145,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildAction(
                  Icons.edit,
                  'Edit',
                  Colors.blue,
                  onPressed: () {
                    controller.debugLog('Edit pressed for id=${a['id']}');
                    _showEditBottomSheet(context, a, controller);
                  },
                ),
                const SizedBox(width: 8),
                _buildAction(
                  Icons.visibility,
                  'Detail',
                  Colors.blue.shade700,
                  onPressed: () {
                    controller.debugLog('Detail pressed for id=${a['id']}');
                    _showDetailBottomSheet(context, a, controller);
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // Helper untuk tombol aksi
  Widget _buildAction(
    IconData icon,
    String label,
    Color color, {
    required VoidCallback onPressed,
  }) {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: color.withOpacity(0.12),
        foregroundColor: color,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        minimumSize: const Size(0, 30),
      ),
      icon: Icon(icon, size: 12),
      label: Text(
        label,
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
      ),
      onPressed: onPressed,
    );
  }

  // --- LOGIKA MENAMPILKAN BOTTOM SHEET ---

  void _showEditBottomSheet(
    BuildContext context,
    Map<String, dynamic> a,
    AbsensiController controller,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        // Konten sheet sekarang dipisah ke widgetnya sendiri
        return _EditAbsensiSheet(controller: controller, absensiData: a);
      },
    );
  }

  void _showDetailBottomSheet(
    BuildContext context,
    Map<String, dynamic> a,
    AbsensiController controller,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        // Konten sheet sekarang dipisah ke widgetnya sendiri
        return _DetailAbsensiSheet(controller: controller, absensiData: a);
      },
    );
  }
}

// 8. WIDGET KONTEN DETAIL BOTTOM SHEET
// -------------------------------------------------------------------
class _DetailAbsensiSheet extends StatelessWidget {
  final AbsensiController controller;
  final Map<String, dynamic> absensiData;

  const _DetailAbsensiSheet({
    required this.controller,
    required this.absensiData,
  });

  @override
  Widget build(BuildContext context) {
    // Ambil data dan format dari controller
    final a = absensiData;
    final String namaSiswa =
        (a['siswa'] is Map) ? (a['siswa']['nama'] ?? '-') : '-';
    final String guruNama =
        (a['guru'] is Map) ? (a['guru']['nama'] ?? '-') : '-';
    final String tanggal = controller.fmtDate(a['tanggal']);
    final String status = a['status'] ?? '-';
    final String waktuMasuk = controller.fmtTime(a['waktu_masuk']);
    final String waktuPulang = controller.fmtTime(a['waktu_pulang']);
    final String keterangan = a['keterangan'] ?? '-';
    final String createdAt = controller.fmtDateTime(a['created_at']);
    final String updatedAt = controller.fmtDateTime(a['updated_at']);

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
              // Header
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 18,
                ),
                decoration: BoxDecoration(
                  color: Colors.blue.shade700,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(20),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.assignment_ind, color: Colors.white),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Detail Absensi',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close, color: Colors.white),
                    ),
                  ],
                ),
              ),
              // Body
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 18,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
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
                                child: const Icon(
                                  Icons.people,
                                  size: 28,
                                  color: Colors.blue,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      namaSiswa,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      'Tanggal: $tanggal • Status: $status',
                                      style: const TextStyle(fontSize: 13),
                                    ),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    'Masuk: $waktuMasuk',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Pulang: $waktuPulang',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      // Details list
                      _buildDetailRow(Icons.note, 'Keterangan', keterangan),
                      const SizedBox(height: 8),
                      _buildDetailRow(Icons.edit, 'Diupdate oleh', guruNama),
                      const SizedBox(height: 8),
                      _buildDetailRow(
                        Icons.calendar_today,
                        'Dibuat pada',
                        createdAt,
                      ),
                      const SizedBox(height: 8),
                      _buildDetailRow(Icons.update, 'Diupdate pada', updatedAt),
                      const SizedBox(height: 30),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // Helper untuk baris detail
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
              Text(
                value,
                style: const TextStyle(fontSize: 13, color: Colors.black87),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// 9. WIDGET KONTEN EDIT BOTTOM SHEET (STATEFUL)
// -------------------------------------------------------------------
class _EditAbsensiSheet extends StatefulWidget {
  final AbsensiController controller;
  final Map<String, dynamic> absensiData;

  const _EditAbsensiSheet({
    required this.controller,
    required this.absensiData,
  });

  @override
  State<_EditAbsensiSheet> createState() => _EditAbsensiSheetState();
}

class _EditAbsensiSheetState extends State<_EditAbsensiSheet> {
  // State LOKAL untuk form
  late String selectedStatus;
  late DateTime selectedTanggal;
  late TextEditingController keteranganController;
  TimeOfDay? waktuMasuk;
  TimeOfDay? waktuPulang;
  bool isSaving = false;

  // Ambil data awal saat widget dibuat
  @override
  void initState() {
    super.initState();
    final a = widget.absensiData;
    final controller = widget.controller;

    selectedStatus = a['status'] ?? 'hadir';
    selectedTanggal =
        controller.parseDateTime(a['tanggal']) ?? controller.selectedDate;
    waktuMasuk = controller.parseTimeOfDay(a['waktu_masuk']);
    waktuPulang = controller.parseTimeOfDay(a['waktu_pulang']);
    keteranganController = TextEditingController(text: a['keterangan'] ?? '');
  }

  // Helper untuk date picker
  Future<void> _pickDate() async {
    final newDate = await showDatePicker(
      context: context,
      initialDate: selectedTanggal,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (newDate != null) {
      setState(() {
        selectedTanggal = newDate;
      });
    }
  }

  // Helper untuk time picker
  Future<void> _pickTime(bool isMasuk) async {
    final initialTime = (isMasuk ? waktuMasuk : waktuPulang) ?? TimeOfDay.now();
    final newTime = await showTimePicker(
      context: context,
      initialTime: initialTime,
    );
    if (newTime != null) {
      setState(() {
        if (isMasuk) {
          waktuMasuk = newTime;
        } else {
          waktuPulang = newTime;
        }
      });
    }
  }

  // Logika simpan data
  Future<void> _saveChanges() async {
    setState(() => isSaving = true);
    try {
      await widget.controller.updateAbsensi(
        absensiId: widget.absensiData['id'],
        status: selectedStatus,
        keterangan: keteranganController.text,
        waktuMasuk: waktuMasuk,
        waktuPulang: waktuPulang,
        tanggal: selectedTanggal,
      );

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Data absensi berhasil diperbarui'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memperbarui data: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => isSaving = false);
      }
    }
  }

  @override
  void dispose() {
    keteranganController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final namaSiswa =
        (widget.absensiData['siswa'] is Map) ? (widget.absensiData['siswa']['nama'] ?? '-') : '-';
    final dateFormatter = DateFormat('EEEE, dd MMMM yyyy', 'id_ID');

    return DraggableScrollableSheet(
      initialChildSize: 0.9,
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
              // Header
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 18,
                ),
                decoration: BoxDecoration(
                  color: Colors.blue.shade700,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(20),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.edit_note, color: Colors.white),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Edit Absensi: $namaSiswa',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close, color: Colors.white),
                    ),
                  ],
                ),
              ),

              // Body Form
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Form Status
                      DropdownButtonFormField<String>(
                        value: selectedStatus,
                        decoration: const InputDecoration(
                          labelText: 'Status Kehadiran',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.check_circle_outline),
                        ),
                        items: ['hadir', 'terlambat', 'sakit', 'izin', 'alfa']
                            .map(
                              (status) => DropdownMenuItem(
                                value: status,
                                child: Text(
                                  status.replaceFirst(
                                    status[0],
                                    status[0].toUpperCase(),
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => selectedStatus = value);
                          }
                        },
                      ),
                      const SizedBox(height: 16),

                      // Form Tanggal
                      ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: BorderSide(color: Colors.grey.shade400),
                        ),
                        leading: const Icon(
                          Icons.calendar_today_outlined,
                          color: Colors.blue,
                        ),
                        title: const Text('Tanggal'),
                        subtitle: Text(
                          dateFormatter.format(selectedTanggal),
                        ),
                        trailing: const Icon(Icons.arrow_drop_down),
                        onTap: _pickDate,
                      ),
                      const SizedBox(height: 16),

                      // Form Waktu Masuk
                      ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: BorderSide(color: Colors.grey.shade400),
                        ),
                        leading: const Icon(Icons.login, color: Colors.green),
                        title: const Text('Waktu Masuk'),
                        subtitle: Text(
                          waktuMasuk?.format(context) ?? 'Belum diatur',
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (waktuMasuk != null)
                              IconButton(
                                icon: const Icon(
                                  Icons.clear,
                                  size: 20,
                                  color: Colors.red,
                                ),
                                onPressed: () =>
                                    setState(() => waktuMasuk = null),
                              ),
                            const Icon(Icons.arrow_drop_down),
                          ],
                        ),
                        onTap: () => _pickTime(true),
                      ),
                      const SizedBox(height: 16),

                      // Form Waktu Pulang
                      ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: BorderSide(color: Colors.grey.shade400),
                        ),
                        leading: const Icon(Icons.logout, color: Colors.red),
                        title: const Text('Waktu Pulang'),
                        subtitle: Text(
                          waktuPulang?.format(context) ?? 'Belum diatur',
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (waktuPulang != null)
                              IconButton(
                                icon: const Icon(
                                  Icons.clear,
                                  size: 20,
                                  color: Colors.red,
                                ),
                                onPressed: () =>
                                    setState(() => waktuPulang = null),
                              ),
                            const Icon(Icons.arrow_drop_down),
                          ],
                        ),
                        onTap: () => _pickTime(false),
                      ),
                      const SizedBox(height: 16),

                      // Form Keterangan
                      TextFormField(
                        controller: keteranganController,
                        decoration: const InputDecoration(
                          labelText: 'Keterangan',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.note_alt_outlined),
                        ),
                        maxLines: 3,
                      ),
                      const SizedBox(height: 24),

                      // Tombol Simpan
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          icon: isSaving
                              ? Container(
                                  width: 20,
                                  height: 20,
                                  margin: const EdgeInsets.only(right: 8),
                                  child: const CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.save),
                          label: Text(
                            isSaving ? 'Menyimpan...' : 'Simpan Perubahan',
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue.shade800,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            textStyle: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          onPressed: isSaving ? null : _saveChanges,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}