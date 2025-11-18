// File: data_siswa_page.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
// (Import file picker & PDF/QR dihilangkan dari sini, sudah ada di logic)
import 'package:barcode_widget/barcode_widget.dart';
import 'package:screenshot/screenshot.dart';

// --- (TAMBAHAN) IMPORT LOGIKA ---
import 'siswa_logic.dart';

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
  // --- 1. Buat instance Logic dan Controller UI ---
  late final DataSiswaLogic _logic;
  final TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // --- 2. Inisialisasi logic dan listener ---
    _logic = DataSiswaLogic();
    _logic.addListener(_onLogicUpdate); // Dengarkan perubahan
    _logic.init(widget.initialKelasId); // Mulai fetch data

    // Tambahkan listener untuk search
    searchController.addListener(_onSearchChanged);
  }

  // --- 3. Metode untuk rebuild UI ---
  void _onLogicUpdate() {
    if (mounted) {
      setState(() {});
    }
  }

  void _onSearchChanged() {
    // Panggil fetchSiswa dari logic setiap kali ada ketikan
    _logic.fetchSiswa(searchController.text);
  }

  @override
  void dispose() {
    // --- 4. Hapus listener & controller ---
    _logic.removeListener(_onLogicUpdate);
    searchController.removeListener(_onSearchChanged);
    _logic.dispose();
    searchController.dispose();
    super.dispose();
  }

  // --- (MODIFIKASI) SEMUA FUNGSI UI SEKARANG MEMANGGIL _logic ---

  Future<void> _showDeleteConfirmDialog(int id, String nama) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi Hapus'),
        content: Text('Apakah Anda yakin ingin menghapus data $nama?'),
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
      final error = await _logic.deleteSiswa(id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error ?? 'Data siswa berhasil dihapus'),
            backgroundColor: error == null ? Colors.green : Colors.red,
          ),
        );
      }
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
              mainAxisSize: MainAxisSize.min,
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
                  value: kelasId,
                  hint: const Text('Pilih Kelas'),
                  items: [
                    const DropdownMenuItem<int>(
                      value: null,
                      child: Text("(Belum ada kelas)"),
                    ),
                    ..._logic
                        .kelasList // AMBIL DARI LOGIC
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
                  value: status,
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
                // PANGGIL LOGIC.SAVE
                final error = await _logic.saveSiswa(
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
                Navigator.pop(context); // Tutup dialog
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      error ??
                          (isEdit
                              ? 'Data berhasil diperbarui'
                              : 'Data siswa berhasil ditambahkan'),
                    ),
                    backgroundColor: error == null ? Colors.green : Colors.red,
                  ),
                );
              },
              child: Text(isEdit ? "Simpan Perubahan" : "Tambah"),
            ),
          ],
        );
      },
    );
    // --- WIDGET PAGINATION BARU ---
    Widget _buildPagination() {
      return Row(
        mainAxisAlignment: MainAxisAlignment.end, // Posisi di kanan
        children: [
          // 1. Info Data (Contoh: "1 - 10 dari 50")
          Text(
            _logic.paginationInfo,
            style: const TextStyle(
              color: Colors.grey,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 16),

          // 2. Tombol Previous
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: IconButton(
              icon: const Icon(Icons.chevron_left),
              tooltip: "Halaman Sebelumnya",
              // Disable jika di halaman 1
              onPressed: _logic.currentPage > 1
                  ? () => _logic.previousPage(searchController.text)
                  : null,
            ),
          ),

          const SizedBox(width: 8),

          // 3. Indikator Angka Halaman
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.blue, // Warna kotak nomor halaman
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
              "${_logic.currentPage}",
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),

          const SizedBox(width: 8),

          // 4. Tombol Next
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: IconButton(
              icon: const Icon(Icons.chevron_right),
              tooltip: "Halaman Selanjutnya",
              // Disable jika sudah di halaman terakhir
              onPressed: _logic.currentPage < _logic.totalPages
                  ? () => _logic.nextPage(searchController.text)
                  : null,
            ),
          ),
        ],
      );
    }
  }

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
                color: Colors.white,
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
                    BarcodeWidget(
                      barcode: Barcode.qrCode(),
                      data: nis,
                      width: 250,
                      height: 250,
                      drawText: false,
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
                  // PANGGIL LOGIC.DOWNLOAD
                  await _logic.downloadBarcode(
                    bytes,
                    '$safeFilename-qrcode.png',
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }

  // --- UI WIDGETS ---
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
                  onPressed: () => _showSiswaForm(), // Panggil UI
                  icon: const Icon(Icons.add),
                  label: const Text("Tambah Siswa"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: () => _logic.importExcel(context), // Panggil LOGIC
                  icon: const Icon(Icons.file_upload),
                  label: const Text("Import Excel"),
                ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  // Cek status dari LOGIC
                  onPressed: _logic.selectedKelasId == null
                      ? null
                      : () =>
                            _logic.generateBarcodePdf(context), // Panggil LOGIC
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
            _logic
                    .isLoading // Cek status dari LOGIC
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
          _logic.isKelasLoading
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text("Memuat filter..."),
                  ),
                )
              : Row(
                  children: [
                    // --- [BARU] DROPDOWN JUMLAH DATA ---
                    SizedBox(
                      width: 90,
                      child: DropdownButtonFormField<int>(
                        value: _logic.itemLimit,
                        decoration: InputDecoration(
                          labelText: 'Show',
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 10,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        items: [5, 10, 15, 20, 50]
                            .map(
                              (val) => DropdownMenuItem(
                                value: val,
                                child: Text(val.toString()),
                              ),
                            )
                            .toList(),
                        onChanged: (val) {
                          if (val != null) {
                            // Panggil fungsi updateLimit di Logic
                            _logic.updateLimit(val, searchController.text);
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 12),

                    // --- DROPDOWN KELAS ---
                    Expanded(
                      flex: 2,
                      child: DropdownButtonFormField<int>(
                        value: _logic.selectedKelasId,
                        hint: const Text("Semua Kelas"),
                        isExpanded: true,
                        items: [
                          const DropdownMenuItem<int>(
                            value: null,
                            child: Text("Semua Kelas"),
                          ),
                          ..._logic.kelasList.map(
                            (kelas) => DropdownMenuItem<int>(
                              value: kelas['id'] as int,
                              child: Text(
                                kelas['nama_kelas'],
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        ],
                        onChanged: (value) {
                          _logic.onKelasSelected(value, searchController.text);
                        },
                        decoration: InputDecoration(
                          labelText: 'Kelas',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // --- SEARCH FIELD ---
                    Expanded(
                      flex: 3,
                      child: TextField(
                        controller: searchController,
                        decoration: InputDecoration(
                          labelText: 'Cari Nama',
                          prefixIcon: const Icon(Icons.search),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // --- DROPDOWN STATUS ---
                    Expanded(
                      flex: 2,
                      child: DropdownButtonFormField<String>(
                        value: _logic.selectedStatus,
                        hint: const Text("Semua Status"),
                        items: const [
                          DropdownMenuItem(value: null, child: Text("Semua")),
                          DropdownMenuItem(
                            value: "aktif",
                            child: Text("Aktif"),
                          ),
                          DropdownMenuItem(
                            value: "tidak aktif",
                            child: Text("Tdk Aktif"),
                          ),
                          DropdownMenuItem(
                            value: "lulus",
                            child: Text("Lulus"),
                          ),
                        ],
                        onChanged: (value) {
                          _logic.onStatusSelected(value, searchController.text);
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

  // 1. METHOD UTAMA: Membangun Tabel + Pagination
  Widget _buildTable() {
    // Cek jika data kosong
    if (_logic.siswaData.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Text('Tidak ada data siswa ditemukan.'),
        ),
      );
    }

    const double colSpacing = 17.0;
    final ScrollController horizontalController = ScrollController();

    // Gunakan Column agar Tabel dan Pagination tersusun vertikal
    return Column(
      children: [
        // --- BAGIAN A: TABEL DATA ---
        Container(
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
              final double minTableWidth = constraints.maxWidth;

              return Scrollbar(
                controller: horizontalController,
                thumbVisibility: true,
                trackVisibility: true,
                scrollbarOrientation: ScrollbarOrientation.bottom,
                child: SingleChildScrollView(
                  controller: horizontalController,
                  scrollDirection: Axis.horizontal,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(minWidth: minTableWidth),
                      child: DataTable(
                        columnSpacing: colSpacing,
                        headingRowHeight: 52,
                        dataRowHeight: 60,
                        headingRowColor: MaterialStateProperty.all(
                          Colors.blue.shade50,
                        ),
                        columns: const [
                          DataColumn(
                            label: Center(
                              child: Text(
                                'No',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                          DataColumn(
                            label: Center(
                              child: Text(
                                'NIS',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                          DataColumn(
                            label: Center(
                              child: Text(
                                'Nama',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                          DataColumn(
                            label: Center(
                              child: Text(
                                'Kelas',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                          DataColumn(
                            label: Center(
                              child: Text(
                                'Nama Ortu',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                          DataColumn(
                            label: Center(
                              child: Text(
                                'No. Ortu',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                          DataColumn(
                            label: Center(
                              child: Text(
                                'Status',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                          DataColumn(
                            label: Center(
                              child: Text(
                                'Aksi',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        ],
                        rows: List.generate(_logic.siswaData.length, (i) {
                          final s = _logic.siswaData[i];

                          // --- LOGIKA NOMOR URUT ---
                          // (Halaman saat ini - 1) * Limit + Index + 1
                          // Contoh Hal 2, limit 10, data pertama: (1 * 10) + 0 + 1 = 11
                          final int rowNumber =
                              ((_logic.currentPage - 1) * _logic.itemLimit) +
                              i +
                              1;

                          return DataRow(
                            cells: [
                              DataCell(
                                Center(child: Text('$rowNumber')),
                              ), // Gunakan rowNumber
                              DataCell(
                                Center(child: Text('${s['nis'] ?? '-'}')),
                              ),
                              DataCell(
                                Center(child: Text('${s['nama'] ?? '-'}')),
                              ),
                              DataCell(
                                Center(
                                  child: Text(
                                    '${s['kelas']?['nama_kelas'] ?? '-'}',
                                  ),
                                ),
                              ),
                              DataCell(
                                Center(
                                  child: Text('${s['orang_tua_nama'] ?? '-'}'),
                                ),
                              ),
                              DataCell(
                                Center(
                                  child: Text('${s['orang_tua_nomor'] ?? '-'}'),
                                ),
                              ),
                              DataCell(
                                Center(child: Text('${s['status'] ?? '-'}')),
                              ),
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
                                        onPressed: () =>
                                            _showSiswaForm(siswa: s),
                                      ),
                                      const SizedBox(width: 4),
                                      _buildAction(
                                        Icons.delete,
                                        'Hapus',
                                        Colors.red,
                                        onPressed: () =>
                                            _showDeleteConfirmDialog(
                                              s['id'],
                                              s['nama'],
                                            ),
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
                ),
              );
            },
          ),
        ),

        const SizedBox(height: 20), // Jarak antara tabel dan pagination
        // --- BAGIAN B: PAGINATION (Next/Prev) ---
        _buildPagination(),

        const SizedBox(height: 50), // Jarak aman bawah
      ],
    );
  }

  // 2. METHOD HELPER: Membuat Tombol Navigasi
  Widget _buildPagination() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        // Info Halaman (1 - 10 dari 50)
        Text(
          _logic.paginationInfo,
          style: const TextStyle(
            color: Colors.grey,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(width: 16),

        // Tombol Previous
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          child: IconButton(
            icon: const Icon(Icons.chevron_left),
            tooltip: "Sebelumnya",
            // Disable tombol jika di halaman 1
            onPressed: _logic.currentPage > 1
                ? () => _logic.previousPage(searchController.text)
                : null,
          ),
        ),

        const SizedBox(width: 8),

        // Kotak Nomor Halaman
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
            "${_logic.currentPage}",
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),

        const SizedBox(width: 8),

        // Tombol Next
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          child: IconButton(
            icon: const Icon(Icons.chevron_right),
            tooltip: "Selanjutnya",
            // Disable tombol jika sudah di halaman terakhir
            onPressed: _logic.currentPage < _logic.totalPages
                ? () => _logic.nextPage(searchController.text)
                : null,
          ),
        ),
      ],
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
      tooltip: tooltip,
      onPressed: onPressed,
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.all(color.withOpacity(0.1)),
        shape: WidgetStateProperty.all(const CircleBorder()),
        overlayColor: WidgetStateProperty.all(color.withOpacity(0.2)),
      ),
    );
  }
}
