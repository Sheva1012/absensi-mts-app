import 'package:flutter/material.dart';
import 'kelas_logic.dart'; // <- Import file logika yang baru
// import 'data_siswa.dart'; // Anda mungkin masih memerlukan ini jika onViewSiswa menggunakannya

class PageKelas extends StatefulWidget {
  final String schoolName;
  final Function(String kelasId) onViewSiswa;

  const PageKelas({
    super.key,
    required this.schoolName,
    required this.onViewSiswa,
  });

  @override
  State<PageKelas> createState() => _PageKelasState();
}

class _PageKelasState extends State<PageKelas> {
  late final PageKelasLogic _logic;

  @override
  void initState() {
    super.initState();
    _logic = PageKelasLogic();
    _logic.addListener(_onLogicUpdate);
    _logic.fetchData();
  }

  void _onLogicUpdate() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _logic.removeListener(_onLogicUpdate);
    _logic.dispose();
    super.dispose();
  }

  // --- LOGIKA UI (Event Handling) ---

  void _showAddDialog() {
    _showUpsertDialog(null); // Panggil dialog dengan data 'kelas' null
  }

  void _showUpsertDialog(Map<String, dynamic>? kelas) {
    showDialog(
      context: context,
      builder: (context) {
        return _UpsertKelasDialog(
          kelas: kelas, // Kirim null jika 'Tambah', kirim data jika 'Edit'
          guruData: _logic.guruData,
          onSave: (nama, jamMasuk, jamPulang, waliId) async {
            final String? error;
            if (kelas == null) {
              // Mode TAMBAH
              error = await _logic.createKelas(
                nama,
                jamMasuk,
                jamPulang,
                waliId,
              );
            } else {
              // Mode EDIT
              error = await _logic.updateKelas(
                kelas,
                nama,
                jamMasuk,
                jamPulang,
                waliId,
              );
            }

            if (!mounted) return; // Pastikan widget masih ada
            Navigator.pop(context); // Tutup dialog

            // Tampilkan Snackbar berdasarkan hasil
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  error ??
                      (kelas == null
                          ? 'Kelas berhasil ditambahkan'
                          : 'Data kelas berhasil diperbarui'),
                ),
                backgroundColor: error == null ? Colors.green : Colors.red,
              ),
            );
          },
        );
      },
    );
  }

  // --- BUILD METHOD UTAMA ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Header (Tombol 'Tambah' dihapus dari sini)
            _KelasHeader(schoolName: widget.schoolName),
            const SizedBox(height: 28), // Spasi setelah header
            // 2. Tombol 'Tambah Kelas' DITEMPATKAN DI SINI
            Container(
              alignment: Alignment.centerRight, // Posisikan tombol di kanan
              margin: const EdgeInsets.only(bottom: 20), // Beri spasi bawah
              child: ElevatedButton.icon(
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Tambah Kelas'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[700], // Samakan dengan header
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                ),
                onPressed: _showAddDialog, // Panggil fungsi tambah
              ),
            ),

            // 3. Konten Tabel
            _logic.isLoading
                ? const Center(child: CircularProgressIndicator())
                : _KelasDataTable(
                    kelasData: _logic.kelasData,
                    guruData: _logic.guruData,
                    onEdit: (kelas) {
                      _showUpsertDialog(kelas); // Panggil dialog edit
                    },
                    onView: (kelasId) {
                      widget.onViewSiswa(kelasId);
                    },
                  ),
          ],
        ),
      ),
    );
  }
}

// =========================================================================
// WIDGET-WIDGET YANG DIEKSTRAK
// =========================================================================

// 1. WIDGET HEADER (DIUBAH)
class _KelasHeader extends StatelessWidget {
  final String schoolName;
  // final VoidCallback onAddKelas; // <-- DIHAPUS

  const _KelasHeader({
    required this.schoolName,
    // required this.onAddKelas, // <-- DIHAPUS
  });

  @override
  Widget build(BuildContext context) {
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
            'Data Kelas',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          // DIUBAH: Kembalikan seperti semula (hanya nama sekolah)
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

// 2. WIDGET TABEL DATA (Tidak Berubah)
class _KelasDataTable extends StatelessWidget {
  final List<Map<String, dynamic>> kelasData;
  final List<Map<String, dynamic>> guruData;
  final ValueChanged<Map<String, dynamic>> onEdit;
  final ValueChanged<String> onView;

  const _KelasDataTable({
    required this.kelasData,
    required this.guruData,
    required this.onEdit,
    required this.onView,
  });

  @override
  Widget build(BuildContext context) {
    if (kelasData.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Text('Tidak ada data kelas ditemukan.'),
        ),
      );
    }

    final ScrollController _horizontalController = ScrollController();

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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Scrollbar(
            controller: _horizontalController,
            thumbVisibility: true,
            trackVisibility: true,
            scrollbarOrientation: ScrollbarOrientation.bottom,
            child: SingleChildScrollView(
              controller: _horizontalController,
              scrollDirection: Axis.horizontal,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 16), // jarak scrollbar
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minWidth: 1210),
                  child: DataTable(
                    columnSpacing: 24,
                    headingRowHeight: 50,
                    dataRowHeight: 60,
                    headingRowColor: MaterialStateProperty.all(
                      Colors.blue.shade50,
                    ),
                    columns: const [
                      DataColumn(
                        label: SizedBox(
                          width: 50,
                          child: Center(
                            child: Text(
                              'ID',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ),
                      DataColumn(
                        label: SizedBox(
                          width: 160,
                          child: Center(
                            child: Text(
                              'Nama Kelas',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ),
                      DataColumn(
                        label: SizedBox(
                          width: 160,
                          child: Center(
                            child: Text(
                              'Wali Kelas',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ),
                      DataColumn(
                        label: SizedBox(
                          width: 120,
                          child: Center(
                            child: Text(
                              'Jam Masuk',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ),
                      DataColumn(
                        label: SizedBox(
                          width: 120,
                          child: Center(
                            child: Text(
                              'Jam Pulang',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ),
                      DataColumn(
                        label: SizedBox(
                          width: 200,
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
                    rows: List.generate(kelasData.length, (i) {
                      final s = kelasData[i];
                      final waliNama = s['wali_nama'] ?? '-';
                      return DataRow(
                        cells: [
                          DataCell(Center(child: Text(s['id'].toString()))),
                          DataCell(Center(child: Text(s['nama_kelas'] ?? '-'))),
                          DataCell(Center(child: Text(waliNama))),
                          DataCell(Center(child: Text(s['jam_masuk'] ?? '-'))),
                          DataCell(Center(child: Text(s['jam_pulang'] ?? '-'))),
                          DataCell(
                            Center(
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  _buildAction(
                                    Icons.edit,
                                    'Edit',
                                    Colors.blue,
                                    () => onEdit(s),
                                  ),
                                  const SizedBox(width: 8),
                                  _buildAction(
                                    Icons.visibility,
                                    'Lihat',
                                    Colors.green,
                                    () => onView(s['id'].toString()),
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
          ),
        ],
      ),
    );
  }

  Widget _buildAction(
    IconData icon,
    String label,
    Color color,
    VoidCallback onTap,
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
      onPressed: onTap,
    );
  }
}

// 3. WIDGET DIALOG (Tidak Berubah)
class _UpsertKelasDialog extends StatefulWidget {
  final Map<String, dynamic>?
  kelas; // BARU: 'kelas' bisa null (untuk mode Tambah)
  final List<Map<String, dynamic>> guruData;
  final Future<void> Function(
    String nama,
    String jamMasuk,
    String jamPulang,
    String? waliId,
  )
  onSave;

  const _UpsertKelasDialog({
    this.kelas,
    required this.guruData,
    required this.onSave,
  });

  @override
  State<_UpsertKelasDialog> createState() => _UpsertKelasDialogState();
}

class _UpsertKelasDialogState extends State<_UpsertKelasDialog> {
  late final TextEditingController namaController;
  late final TextEditingController jamMasukController;
  late final TextEditingController jamPulangController;
  String? selectedGuruId;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    namaController = TextEditingController(
      text: widget.kelas?['nama_kelas'] ?? '',
    );
    jamMasukController = TextEditingController(
      text: widget.kelas?['jam_masuk'] ?? '07:00',
    );
    jamPulangController = TextEditingController(
      text: widget.kelas?['jam_pulang'] ?? '14:00',
    );
    selectedGuruId = widget.kelas?['wali_kelas'];
  }

  @override
  void dispose() {
    namaController.dispose();
    jamMasukController.dispose();
    jamPulangController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    final nama = namaController.text.trim();
    final jamMasuk = jamMasukController.text.trim();
    final jamPulang = jamPulangController.text.trim();

    if (nama.isEmpty || jamMasuk.isEmpty || jamPulang.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nama, jam masuk, dan jam pulang tidak boleh kosong'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);
    await widget.onSave(nama, jamMasuk, jamPulang, selectedGuruId);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.kelas == null ? 'Tambah Kelas Baru' : 'Edit Data Kelas',
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: namaController,
              decoration: const InputDecoration(
                labelText: 'Nama Kelas',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: jamMasukController,
              readOnly: true,
              decoration: InputDecoration(
                labelText: 'Jam Masuk',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.access_time),
                  onPressed: () async {
                    final time = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay.now(),
                    );
                    if (time != null) {
                      jamMasukController.text =
                          '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
                    }
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: jamPulangController,
              readOnly: true,
              decoration: InputDecoration(
                labelText: 'Jam Pulang',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.access_time),
                  onPressed: () async {
                    final time = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay.now(),
                    );
                    if (time != null) {
                      jamPulangController.text =
                          '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
                    }
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: selectedGuruId,
              decoration: const InputDecoration(
                labelText: 'Pilih Wali Kelas',
                border: OutlineInputBorder(),
              ),
              items: widget.guruData.map((g) {
                return DropdownMenuItem<String>(
                  value: g['id'],
                  child: Text(g['nama']),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  selectedGuruId = value;
                });
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
        ElevatedButton(
          onPressed: _isSaving ? null : _handleSave,
          child: _isSaving
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text('Simpan'),
        ),
      ],
    );
  }
}
