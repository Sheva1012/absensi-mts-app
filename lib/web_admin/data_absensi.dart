// data_absensi.dart
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

  // --- BARU: State untuk menyimpan tanggal yang dipilih ---
  // Defaultnya adalah hari ini
  DateTime _selectedDate = DateTime.now();

  // -------- Debug helper ----------
  void debugLog(String message) {
    debugPrint('[ABSENSI DEBUG] $message');
  }

  @override
  void initState() {
    super.initState();
    // Inisialisasi locale 'id_ID' untuk DateFormat
    // Anda mungkin perlu menambahkan `await initializeDateFormatting('id_ID', null);`
    // di main.dart Anda jika belum.
    // Untuk kesederhanaan, kita asumsikan 'id_ID' sudah ter-load.
    fetchAbsensi();
  }

  Future<void> fetchAbsensi() async {
    if (mounted) {
      setState(() => isLoading = true);
    }

    debugLog('Mulai fetch absensi dari Supabase...');
    try {
      // BARU: Format tanggal untuk filter Supabase (YYYY-MM-DD)
      final String tglFilter = DateFormat('yyyy-MM-dd').format(_selectedDate);
      debugLog('Filter tanggal yang digunakan: $tglFilter');

      final response = await supabase
          .from('absensi')
          .select('''
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
      ''')
          .eq('tanggal', tglFilter)
          .order(
            'created_at',
            ascending: false,
          ); 

      absensiData = response;
      debugLog('Data absensi berhasil dimuat: ${absensiData.length} baris');
    } catch (e, st) {
      debugLog('Error saat fetchAbsensi: $e');
      debugLog('Stack: $st');
      absensiData = [];
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memuat data: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  Future<void> _pickDate() async {
    final newDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (newDate != null && newDate != _selectedDate) {
      setState(() {
        _selectedDate = newDate;
      });
      fetchAbsensi();
    }
  }

  DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    try {
      if (value is DateTime) {
        return value;
      }
      return DateTime.parse(value.toString());
    } catch (e) {
      debugLog('_parseDateTime error for value=$value -> $e');
      return null;
    }
  }

  TimeOfDay? _parseTimeOfDay(dynamic value) {
    if (value == null) return null;
    try {
      final s = value.toString();
      final parts = s.split(':');
      if (parts.length >= 2) {
        return TimeOfDay(
          hour: int.parse(parts[0]),
          minute: int.parse(parts[1]),
        );
      }
      return null;
    } catch (e) {
      debugLog('_parseTimeOfDay error for value=$value -> $e');
      return null;
    }
  }

  String fmtDate(dynamic value) {
    final dt = _parseDateTime(value);
    if (dt == null) return '-';
    return DateFormat('dd-MM-yyyy').format(dt);
  }

  String fmtDateTime(dynamic value) {
    final dt = _parseDateTime(value);
    if (dt == null) return '-';
    return DateFormat('dd-MM-yyyy HH:mm').format(dt.toLocal());
  }

  String fmtTime(dynamic value) {
    final tod = _parseTimeOfDay(value);
    if (tod == null) return '-';
    return '${tod.hour.toString().padLeft(2, '0')}:${tod.minute.toString().padLeft(2, '0')}';
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
            _buildDatePicker(),
            const SizedBox(height: 20), // Beri jarak ke tabel
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
                widget.schoolName,
                style: const TextStyle(color: Colors.white, fontSize: 16),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDatePicker() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
        onTap: _pickDate, // Panggil fungsi _pickDate saat diklik
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Row(
            children: [
              Icon(Icons.calendar_today_outlined, color: Colors.blue.shade700),
              const SizedBox(width: 16),
              const Text(
                'Tampilkan Tanggal:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const Spacer(),
              Text(
                DateFormat('EEEE, dd MMMM yyyy', 'id_ID').format(_selectedDate),
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.black87,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.arrow_drop_down, color: Colors.grey.shade700),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTable() {
    // Tampilan ketika data kosong
    if (absensiData.isEmpty) {
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
              Text(
                // --- UPDATE: Pesan lebih spesifik ---
                'Belum ada data absensi',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                // --- UPDATE: Pesan lebih spesifik ---
                'Tidak ditemukan data untuk tanggal ${DateFormat('dd MMMM yyyy', 'id_ID').format(_selectedDate)}.',
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
                onPressed: fetchAbsensi,
              ),
            ],
          ),
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
          // Set lebar minimum agar tabel tidak terlalu padat
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
            columns: const [
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
            ],
            rows: List.generate(absensiData.length, (i) {
              final a = absensiData[i];
              final String namaSiswa = (a['siswa'] is Map)
                  ? (a['siswa']['nama'] ?? '-')
                  : '-';
              final tanggal = fmtDate(a['tanggal']);
              final status = a['status'] ?? '-';
              final masuk = fmtTime(a['waktu_masuk']);
              final pulang = fmtTime(a['waktu_pulang']);
              final keterangan = a['keterangan'] ?? '-';
              final hasSurat =
                  a['surat'] != null &&
                  a['surat'].toString().isNotEmpty &&
                  a['surat'].toString() != '-';

              // Helper untuk warna teks Status
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
                  // Nama Siswa
                  DataCell(
                    Text(namaSiswa, style: const TextStyle(fontSize: 13)),
                  ),
                  // Tanggal (Bisa dihapus jika mau)
                  DataCell(
                    SizedBox(
                      width: 80,
                      child: Text(
                        tanggal,
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                  ),
                  // Status (Kembali ke teks biasa)
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
                  // Waktu Masuk
                  DataCell(
                    SizedBox(
                      width: 70,
                      child: Center(
                        child: Text(
                          masuk,
                          style: TextStyle(
                            fontSize: 13,
                            color: masuk == '-'
                                ? Colors.grey
                                : Colors.green.shade700,
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Waktu Pulang
                  DataCell(
                    SizedBox(
                      width: 70,
                      child: Center(
                        child: Text(
                          pulang,
                          style: TextStyle(
                            fontSize: 13,
                            color: pulang == '-'
                                ? Colors.grey
                                : Colors.red.shade700,
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Keterangan
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
                  // Surat
                  DataCell(
                    SizedBox(
                      width: 60,
                      child: Center(
                        child: Text(
                          hasSurat ? 'Ada' : '-',
                          style: TextStyle(
                            fontSize: 13,
                            color: hasSurat
                                ? Colors.orange.shade700
                                : Colors.grey,
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Kolom Aksi
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
                              debugLog('Edit pressed for id=${a['id']}');
                              _showEditBottomSheet(context, a);
                            },
                          ),
                          const SizedBox(width: 8),
                          _buildAction(
                            Icons.visibility,
                            'Detail',
                            Colors.blue.shade700,
                            onPressed: () {
                              debugLog('Detail pressed for id=${a['id']}');
                              _showDetailBottomSheet(context, a);
                            },
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

  // Widget helper untuk Tombol Aksi
  Widget _buildAction(
    IconData icon,
    String label,
    Color color, {
    required VoidCallback onPressed,
  }) {
    // ... (kode _buildAction Anda tidak berubah) ...
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

  void _showEditBottomSheet(BuildContext context, Map<String, dynamic> a) {
    final String namaSiswa = (a['siswa'] is Map)
        ? (a['siswa']['nama'] ?? '-')
        : '-';
    final TextEditingController keteranganController = TextEditingController(
      text: a['keterangan'] ?? '',
    );

    // Variabel state untuk form
    String selectedStatus = a['status'] ?? 'hadir';
    DateTime selectedTanggal = _parseDateTime(a['tanggal']) ?? DateTime.now();
    TimeOfDay? waktuMasuk = _parseTimeOfDay(a['waktu_masuk']);
    TimeOfDay? waktuPulang = _parseTimeOfDay(a['waktu_pulang']);
    bool isSaving = false;

    // Helper untuk showDatePicker
    Future<void> pickDate(
      BuildContext context,
      StateSetter formSetState,
    ) async {
      final newDate = await showDatePicker(
        context: context,
        initialDate: selectedTanggal,
        firstDate: DateTime(2020),
        lastDate: DateTime(2100),
      );
      if (newDate != null) {
        formSetState(() {
          selectedTanggal = newDate;
        });
      }
    }

    Future<void> pickTime(
      BuildContext context,
      StateSetter formSetState,
      bool isMasuk,
    ) async {
      final initialTime =
          (isMasuk ? waktuMasuk : waktuPulang) ?? TimeOfDay.now();
      final newTime = await showTimePicker(
        context: context,
        initialTime: initialTime,
      );
      if (newTime != null) {
        formSetState(() {
          if (isMasuk) {
            waktuMasuk = newTime;
          } else {
            waktuPulang = newTime;
          }
        });
      }
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter formSetState) {
            return DraggableScrollableSheet(
              initialChildSize: 0.9,
              minChildSize: 0.5,
              maxChildSize: 0.95,
              expand: false,
              builder: (context, scrollController) {
                return Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
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
                              icon: const Icon(
                                Icons.close,
                                color: Colors.white,
                              ),
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
                                items:
                                    [
                                          'hadir',
                                          'terlambat',
                                          'sakit',
                                          'izin',
                                          'alfa',
                                        ]
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
                                    formSetState(() {
                                      selectedStatus = value;
                                    });
                                  }
                                },
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
                                leading: const Icon(
                                  Icons.login,
                                  color: Colors.green,
                                ),
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
                                        onPressed: () => formSetState(
                                          () => waktuMasuk = null,
                                        ),
                                      ),
                                    const Icon(Icons.arrow_drop_down),
                                  ],
                                ),
                                onTap: () =>
                                    pickTime(context, formSetState, true),
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
                                leading: const Icon(
                                  Icons.logout,
                                  color: Colors.red,
                                ),
                                title: const Text('Waktu Pulang'),
                                subtitle: Text(
                                  waktuPulang?.format(context) ??
                                      'Belum diatur',
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
                                        onPressed: () => formSetState(
                                          () => waktuPulang = null,
                                        ),
                                      ),
                                    const Icon(Icons.arrow_drop_down),
                                  ],
                                ),
                                onTap: () =>
                                    pickTime(context, formSetState, false),
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
                                          margin: const EdgeInsets.only(
                                            right: 8,
                                          ),
                                          child:
                                              const CircularProgressIndicator(
                                                color: Colors.white,
                                                strokeWidth: 2,
                                              ),
                                        )
                                      : const Icon(Icons.save),
                                  label: Text(
                                    isSaving
                                        ? 'Menyimpan...'
                                        : 'Simpan Perubahan',
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blue.shade800,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 16,
                                    ),
                                    textStyle: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  onPressed: isSaving
                                      ? null
                                      : () async {
                                          // 1. Set loading
                                          formSetState(() => isSaving = true);

                                          // 2. Format data untuk Supabase
                                          // Format tanggal: 'YYYY-MM-DD'
                                          final String tgl = selectedTanggal
                                              .toIso8601String()
                                              .split('T')
                                              .first;
                                          // Format waktu: 'HH:MM:SS'
                                          final String? wMasuk =
                                              waktuMasuk != null
                                              ? '${waktuMasuk!.hour.toString().padLeft(2, '0')}:${waktuMasuk!.minute.toString().padLeft(2, '0')}:00'
                                              : null;
                                          final String? wPulang =
                                              waktuPulang != null
                                              ? '${waktuPulang!.hour.toString().padLeft(2, '0')}:${waktuPulang!.minute.toString().padLeft(2, '0')}:00'
                                              : null;

                                          try {
                                            // 3. Kirim ke Supabase
                                            await supabase
                                                .from('absensi')
                                                .update({
                                                  'tanggal': tgl,
                                                  'status': selectedStatus,
                                                  'waktu_masuk': wMasuk,
                                                  'waktu_pulang': wPulang,
                                                  'keterangan':
                                                      keteranganController.text,
                                                  'updated_at': DateTime.now()
                                                      .toIso8601String(),
                                                  // 'updated_by' bisa diisi dengan ID user yg login jika ada
                                                })
                                                .eq('id', a['id']);

                                            // 4. Tutup bottom sheet
                                            if (context.mounted)
                                              Navigator.of(context).pop();

                                            // 5. Tampilkan snackbar sukses
                                            if (context.mounted) {
                                              ScaffoldMessenger.of(
                                                context,
                                              ).showSnackBar(
                                                const SnackBar(
                                                  content: Text(
                                                    'Data absensi berhasil diperbarui',
                                                  ),
                                                  backgroundColor: Colors.green,
                                                ),
                                              );
                                            }

                                            // 6. Muat ulang data di tabel
                                            // Penting: pastikan _selectedDate di state utama
                                            // sama dengan tanggal yg baru di-edit
                                            // agar data tetap muncul setelah refresh.
                                            setState(() {
                                              _selectedDate = selectedTanggal;
                                            });
                                            fetchAbsensi();
                                          } catch (e) {
                                            debugLog(
                                              'Error update absensi: $e',
                                            );
                                            // Tampilkan snackbar error
                                            if (context.mounted) {
                                              ScaffoldMessenger.of(
                                                context,
                                              ).showSnackBar(
                                                SnackBar(
                                                  content: Text(
                                                    'Gagal memperbarui data: $e',
                                                  ),
                                                  backgroundColor: Colors.red,
                                                ),
                                              );
                                            }
                                          } finally {
                                            // 7. Hentikan loading
                                            formSetState(
                                              () => isSaving = false,
                                            );
                                          }
                                        },
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
          },
        );
      },
    );
  }

  void _showDetailBottomSheet(BuildContext context, Map<String, dynamic> a) {
    final String namaSiswa = (a['siswa'] is Map)
        ? (a['siswa']['nama'] ?? '-')
        : '-';
    final String guruNama = (a['guru'] is Map)
        ? (a['guru']['nama'] ?? '-')
        : '-';
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
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
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
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
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
                          _buildDetailRow(
                            Icons.edit,
                            'Diupdate oleh',
                            guruNama,
                          ),
                          const SizedBox(height: 8),
                          _buildDetailRow(
                            Icons.calendar_today,
                            'Dibuat pada',
                            createdAt,
                          ),
                          const SizedBox(height: 8),
                          _buildDetailRow(
                            Icons.update,
                            'Diupdate pada',
                            updatedAt,
                          ),

                          const SizedBox(height: 20),
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
