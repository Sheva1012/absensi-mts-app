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

                      // --- FILTER SECTION (Limit + Date + Class) ---
                      _buildFilterSection(context, controller),

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
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Data absensi diperbarui')),
                  );
                }
              },
              child: const Icon(Icons.refresh),
            ),
          );
        },
      ),
    );
  }

  // Widget Filter yang digabung (Show Entries + Date + Class)
  Widget _buildFilterSection(
    BuildContext context,
    AbsensiController controller,
  ) {
    return Column(
      children: [
        Row(
          children: [
            // 1. Dropdown Limit (Show Entries)
            Container(
              width: 80,
              height: 50, // Samakan tinggi
              padding: const EdgeInsets.symmetric(horizontal: 10),
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
              child: DropdownButtonHideUnderline(
                child: DropdownButton<int>(
                  value: controller.itemLimit,
                  icon: const Icon(Icons.arrow_drop_down, size: 20),
                  isExpanded: true,
                  style: const TextStyle(
                    color: Colors.black87,
                    fontWeight: FontWeight.w600,
                  ),
                  items: [5, 10, 20, 50].map((val) {
                    return DropdownMenuItem<int>(
                      value: val,
                      child: Text("$val"),
                    );
                  }).toList(),
                  onChanged: (val) => controller.updateLimit(val),
                ),
              ),
            ),

            const SizedBox(width: 12),

            // 2. Date Picker
            Expanded(
              flex: 2,
              child: _AbsensiDatePicker(controller: controller),
            ),

            const SizedBox(width: 12),

            // 3. Class Dropdown
            Expanded(
              flex: 1,
              child: _KelasFilterDropdown(controller: controller),
            ),
          ],
        ),
      ],
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
      height: 50, // Tinggi disesuaikan
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: _box(),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => controller.handleDatePick(context),
        child: Row(
          children: [
            Icon(Icons.calendar_today, color: Colors.blue.shade700, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                DateFormat(
                  'dd MMM yyyy',
                  'id_ID',
                ).format(controller.selectedDate),
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
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
      height: 50, // Tinggi disesuaikan
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: _box(),
      child: controller.isKelasLoading
          ? const Center(
              child: SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          : DropdownButton<int?>(
              value: controller.selectedKelasId,
              isExpanded: true,
              underline: const SizedBox(),
              icon: const Icon(Icons.arrow_drop_down),
              hint: const Text("Kelas", style: TextStyle(fontSize: 14)),
              items: controller.daftarKelas.map((kelas) {
                return DropdownMenuItem<int?>(
                  value: kelas['id'],
                  child: Text(
                    kelas['nama_kelas'],
                    style: const TextStyle(fontSize: 14),
                  ),
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
// 5. CONTENT (TABLE + PAGINATION)
// ===========================================================
class _AbsensiContent extends StatelessWidget {
  final AbsensiController controller;
  const _AbsensiContent({required this.controller});

  @override
  Widget build(BuildContext context) {
    if (controller.absensiData.isEmpty) {
      return _EmptyStateView(controller: controller);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        _ExportPdfButton(controller: controller),
        const SizedBox(height: 16),
        _AbsensiTable(controller: controller),
        const SizedBox(height: 16),
        _buildPagination(controller), // Widget Pagination Baru
        const SizedBox(height: 50), // Padding bawah aman
      ],
    );
  }

  // Widget Pagination Control
  Widget _buildPagination(AbsensiController controller) {
    final int totalData = controller.absensiData.length;
    final int current = controller.currentPage;
    final int limit = controller.itemLimit;

    // Hitung index display "1 - 10 dari 50"
    final int startItem = ((current - 1) * limit) + 1;
    final int endItem = (current * limit) > totalData
        ? totalData
        : (current * limit);

    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text(
          "$startItem - $endItem dari $totalData",
          style: const TextStyle(
            color: Colors.grey,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(width: 16),

        // Prev Button
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          child: IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: current > 1 ? controller.prevPage : null,
            tooltip: "Sebelumnya",
          ),
        ),

        const SizedBox(width: 8),

        // Page Indicator
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.blue,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.blue.withOpacity(0.3),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Text(
            "$current",
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),

        const SizedBox(width: 8),

        // Next Button
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          child: IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: current < controller.totalPages
                ? controller.nextPage
                : null,
            tooltip: "Selanjutnya",
          ),
        ),
      ],
    );
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
              'Tidak Ada Data',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 8),
            Text(
              controller.selectedKelasId == null
                  ? 'Belum ada data absensi pada tanggal ini.'
                  : 'Tidak ditemukan data absensi untuk kelas ini.',
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
// TOMBOL EXPORT
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
        backgroundColor: const Color.fromARGB(255, 209, 33, 33),
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      ),
      onPressed: () {
        // Pastikan controller memiliki method exportPdf
        // controller.exportPdf(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Fitur Export PDF akan segera hadir")),
        );
      },
    );
  }
}

// ===========================================================
// 7. DATA TABLE (PAGINATED)
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
      child: LayoutBuilder(
        builder: (context, constraints) {
          final double availableWidth = constraints.maxWidth;

          // Gunakan getter paginatedData yang ada di controller
          final List<Map<String, dynamic>> displayData =
              controller.paginatedData;

          // Hitung offset nomor urut berdasarkan halaman
          final int startNumber =
              (controller.currentPage - 1) * controller.itemLimit;

          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: BoxConstraints(minWidth: availableWidth),
              child: DataTable(
                columnSpacing: 16,
                headingRowColor: MaterialStateProperty.all(Colors.blue.shade50),
                columns: const [
                  DataColumn(
                    label: Text(
                      'No',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ), // Tambah kolom No
                  DataColumn(
                    label: SizedBox(
                      width: 160,
                      child: Text(
                        'Nama Siswa',
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
                      width: 100,
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
                      width: 80,
                      child: Center(
                        child: Text(
                          'Masuk',
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
                          'Pulang',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ),
                  DataColumn(
                    label: SizedBox(
                      width: 150,
                      child: Center(
                        child: Text(
                          'Keterangan',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ),
                ],
                rows: List.generate(displayData.length, (index) {
                  final a = displayData[index];
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
                      DataCell(
                        Text("${startNumber + index + 1}"),
                      ), // Nomor urut
                      DataCell(SizedBox(width: 160, child: Text(nama))),
                      DataCell(
                        SizedBox(width: 100, child: Center(child: Text(tgl))),
                      ),
                      DataCell(
                        SizedBox(
                          width: 100,
                          child: Center(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: color.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                status.toUpperCase(),
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: color,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      DataCell(
                        SizedBox(width: 80, child: Center(child: Text(masuk))),
                      ),
                      DataCell(
                        SizedBox(
                          width: 80,
                          child: Center(child: Text(pulang)),
                        ),
                      ),
                      DataCell(
                        SizedBox(
                          width: 150,
                          child: Center(
                            child: Text(ket, overflow: TextOverflow.ellipsis),
                          ),
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

  static Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'hadir':
      case 'pulang':
        return Colors.green.shade700;
      case 'terlambat':
        return Colors.purple.shade700;
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
