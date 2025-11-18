import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'absensi_controller.dart';

// ===========================================================
// 1. MAIN PAGE
// ===========================================================
class PageAbsensi extends StatelessWidget {
  final String schoolName;

  const PageAbsensi({super.key, required this.schoolName});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AbsensiController(schoolName: schoolName),
      child: Consumer<AbsensiController>(
        builder: (context, controller, _) {
          return Scaffold(
            backgroundColor: const Color(0xFFF5F7FA),
            body: SafeArea(
              child: RefreshIndicator(
                onRefresh: controller.fetchAbsensi,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _AbsensiHeader(schoolName: controller.schoolName),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: _AbsensiDatePicker(controller: controller),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            flex: 1,
                            child: _KelasFilterDropdown(controller: controller),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      controller.isLoading
                          ? const Center(
                              child: Padding(
                                padding: EdgeInsets.only(top: 60),
                                child: CircularProgressIndicator(),
                              ),
                            )
                          : _AbsensiContent(controller: controller),
                    ],
                  ),
                ),
              ),
            ),
            floatingActionButton: FloatingActionButton(
              backgroundColor: Colors.blue.shade700,
              onPressed: () async {
                await controller.fetchAbsensi();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Data absensi diperbarui')),
                );
              },
              child: const Icon(Icons.refresh),
            ),
          );
        },
      ),
    );
  }
}

// ===========================================================
// 2. HEADER
// ===========================================================
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
              fontSize: 26,
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

// ===========================================================
// 3. FILTER TANGGAL
// ===========================================================
class _AbsensiDatePicker extends StatelessWidget {
  final AbsensiController controller;
  const _AbsensiDatePicker({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: _box(),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => controller.handleDatePick(context),
        child: Row(
          children: [
            Icon(Icons.calendar_today, color: Colors.blue.shade700),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                DateFormat(
                  'EEEE, dd MMM yyyy',
                  'id_ID',
                ).format(controller.selectedDate),
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
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

  BoxDecoration _box() => BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(12),
    boxShadow: [
      BoxShadow(
        color: Colors.grey.withOpacity(0.08),
        blurRadius: 10,
        offset: const Offset(0, 2),
      ),
    ],
  );
}

// ===========================================================
// 4. FILTER KELAS
// ===========================================================
class _KelasFilterDropdown extends StatelessWidget {
  final AbsensiController controller;
  const _KelasFilterDropdown({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: _box(),
      child: controller.isKelasLoading
          ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
          : DropdownButton<int?>(
              value: controller.selectedKelasId,
              isExpanded: true,
              underline: const SizedBox(),
              icon: const Icon(Icons.arrow_drop_down),
              items: controller.daftarKelas.map((kelas) {
                return DropdownMenuItem<int?>(
                  value: kelas['id'],
                  child: Text(kelas['nama_kelas']),
                );
              }).toList(),
              onChanged: (val) => controller.onKelasSelected(val),
            ),
    );
  }

  BoxDecoration _box() => BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(12),
    boxShadow: [
      BoxShadow(
        color: Colors.grey.withOpacity(0.08),
        blurRadius: 10,
        offset: const Offset(0, 2),
      ),
    ],
  );
}

// ===========================================================
// 5. CONTENT
// ===========================================================
class _AbsensiContent extends StatelessWidget {
  final AbsensiController controller;
  const _AbsensiContent({required this.controller});

  @override
  Widget build(BuildContext context) {
    if (controller.absensiData.isEmpty) {
      return _EmptyStateView(controller: controller);
    }

    // --- DIUBAH: Tambahkan Column dan Tombol Export ---
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end, // Tombol ke kanan
      children: [
        _ExportPdfButton(controller: controller),
        const SizedBox(height: 16),
        _AbsensiTable(controller: controller),
      ],
    );
    // --- AKHIR PERUBAHAN ---
  }
}

// ===========================================================
// 6. EMPTY STATE
// ===========================================================
class _EmptyStateView extends StatelessWidget {
  final AbsensiController controller;
  const _EmptyStateView({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.only(top: 80),
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.info_outline, size: 48, color: Colors.blueGrey),
            const SizedBox(height: 16),
            const Text(
              'Tidak Ada Siswa',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 8),
            Text(
              controller.selectedKelasId == null
                  ? 'Belum ada data siswa di sekolah ini.'
                  : 'Tidak ditemukan data siswa untuk kelas ini.',
              style: const TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ===========================================================
// BARU: WIDGET TOMBOL EXPORT
// ===========================================================
class _ExportPdfButton extends StatelessWidget {
  final AbsensiController controller;
  const _ExportPdfButton({required this.controller});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      icon: const Icon(Icons.picture_as_pdf, size: 18),
      label: const Text('Export PDF'),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color.fromARGB(255, 209, 33, 33), // Warna tombol
        foregroundColor: Colors.white, // Warna teks
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      ),
      onPressed: () {
        // Ambil controller dari provider
        final controller = Provider.of<AbsensiController>(
          context,
          listen: false,
        );

        // Panggil fungsi export PDF
        controller.exportPdf(context);
      },
    );
  }
}

// ===========================================================
// 7. DATA TABLE
// ===========================================================
class _AbsensiTable extends StatelessWidget {
  final AbsensiController controller;
  const _AbsensiTable({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade300, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      // Perubahan di sini: Menggunakan LayoutBuilder
      child: LayoutBuilder(
        builder: (context, constraints) {
          final double availableWidth = constraints.maxWidth;

          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: BoxConstraints(minWidth: availableWidth),
              child: DataTable(
                columnSpacing: 16, // lebih kecil biar tidak renggang
                headingRowColor: MaterialStateProperty.all(Colors.blue.shade50),
                columns: const [
                  DataColumn(
                    label: SizedBox(
                      width: 150, // Nama siswa lebih panjang
                      child: Text(
                        'Nama Siswa',
                        textAlign: TextAlign.left,
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  DataColumn(
                    label: SizedBox(
                      width: 100,
                      child: Center(
                        child: Text(
                          'Tanggal',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ),
                  DataColumn(
                    label: SizedBox(
                      width: 90,
                      child: Center(
                        child: Text(
                          'Status',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ),
                  DataColumn(
                    label: SizedBox(
                      width: 110,
                      child: Center(
                        child: Text(
                          'Waktu Masuk',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ),
                  DataColumn(
                    label: SizedBox(
                      width: 110,
                      child: Center(
                        child: Text(
                          'Waktu Pulang',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ),
                  DataColumn(
                    label: SizedBox(
                      width: 180,
                      child: Center(
                        child: Text(
                          'Keterangan',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ),
                ],
                rows: controller.absensiData.map((a) {
                  final siswa = a['siswa'] ?? {};
                  final nama = siswa['nama'] ?? '-';
                  final tgl = controller.fmtDate(a['tanggal']);
                  final status = a['status'] ?? '-';
                  final masuk = controller.fmtTime(a['waktu_masuk']);
                  final pulang = controller.fmtTime(a['waktu_pulang']);
                  final ket = a['keterangan'] ?? '-';
                  final color = _statusColor(status);

                  return DataRow(
                    cells: [
                      DataCell(SizedBox(width: 150, child: Text(nama))),
                      DataCell(
                        SizedBox(width: 100, child: Center(child: Text(tgl))),
                      ),
                      DataCell(
                        SizedBox(
                          width: 90,
                          child: Center(
                            child: Text(
                              status.toUpperCase(),
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: color,
                              ),
                            ),
                          ),
                        ),
                      ),
                      DataCell(
                        SizedBox(width: 110, child: Center(child: Text(masuk))),
                      ),
                      DataCell(
                        SizedBox(
                          width: 110,
                          child: Center(child: Text(pulang)),
                        ),
                      ),
                      DataCell(
                        SizedBox(
                          width: 180,
                          child: Center(
                            child: Text(ket, overflow: TextOverflow.ellipsis),
                          ),
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          );
        },
      ),
    );
  }

  static Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'hadir':
      case 'pulang': // Status 'pulang' dianggap sukses
        return Colors.green.shade700;
      case 'terlambat': // Tambahkan status 'terlambat'
        return Colors.purple.shade700; // Warna ungu agar beda
      case 'sakit':
      case 'izin':
        return Colors.orange.shade700;
      case 'alfa':
        return Colors.red.shade700;
      default:
        return Colors.black87;
    }
  }
}
