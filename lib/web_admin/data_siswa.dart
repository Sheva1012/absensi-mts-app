import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DataSiswaPage extends StatefulWidget {
  final String schoolName;
  final String? initialKelasId;

  const DataSiswaPage({super.key, required this.schoolName,this.initialKelasId,});

  @override
  State<DataSiswaPage> createState() => _DataSiswaPageState();
}

class _DataSiswaPageState extends State<DataSiswaPage> {
  final SupabaseClient supabase = Supabase.instance.client;

  // State loading untuk tabel utama (sudah ada)
  bool isLoading = true;
  // --- 1. TAMBAHKAN STATE LOADING BARU ---
  // State loading khusus untuk dropdown filter kelas
  bool isKelasLoading = true;

  List<Map<String, dynamic>> siswaData = [];
  List<Map<String, dynamic>> kelasList = [];

  String? selectedKelasId;
  String? selectedStatus;
  final TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Ambil ID kelas dari widget (jika ada)
    selectedKelasId = widget.initialKelasId;
    // Mulai proses loading
    fetchKelas();
  }

  Future<void> fetchKelas() async {
    // --- 2. PASTIKAN isKelasLoading = true DI AWAL ---
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
        // --- 3. SET isKelasLoading = false SETELAH DATA DAPAT ---
        isKelasLoading = false;
      });

      // Panggil fetchSiswa setelah data kelas siap
      await fetchSiswa();
    } catch (e) {
      print('Error fetching kelas: $e');
      if (!mounted) return;
      setState(() {
        // --- 4. SET isKelasLoading = false JIKA GAGAL JUGA ---
        isKelasLoading = false;
      });
    }
  }

  Future<void> fetchSiswa() async {
    // ... (Fungsi fetchSiswa Anda tidak perlu diubah)
    setState(() => isLoading = true);
    try {
      var query = supabase.from('siswa').select('*, kelas!inner(nama_kelas)');

      if (selectedKelasId != null && selectedKelasId!.isNotEmpty) {
        query = query.eq('kelas_id', selectedKelasId!);
      }

      if (selectedStatus != null && selectedStatus!.isNotEmpty) {
        query = query.eq('status', selectedStatus!);
      }

      final response = await query.order('kelas_id', ascending: true);
      List<Map<String, dynamic>> allData =
          List<Map<String, dynamic>>.from(response);

      if (searchController.text.trim().isNotEmpty) {
        String keyword = searchController.text.toLowerCase();
        allData = allData
            .where((s) => (s['nama'] ?? '')
                .toString()
                .toLowerCase()
                .contains(keyword))
            .toList();
      }

      if (!mounted) return;
      setState(() {
        siswaData = allData;
        siswaData.sort((a, b) {
          int kelasComparison =
              (a['kelas_id'] ?? 0).compareTo(b['kelas_id'] ?? 0);
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
            _buildFilter(), // Filter tetap dibangun
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
    // ... (Fungsi _buildHeader Anda tidak perlu diubah)
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [Colors.blue[700]!, Colors.blue[500]!]),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.blue.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 4))
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Data Siswa',
            style: TextStyle(
                fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
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

  /// 🔹 FILTER SECTION: kelas, nama, dan status
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
              offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ... (Header Filter)
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
          // --- 5. GUNAKAN isKelasLoading DI SINI ---
          // Jika data kelas sedang loading, tampilkan placeholder
          isKelasLoading
              ? const Center(
                  child: Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text("Memuat filter kelas..."),
                ))
              // Jika sudah selesai, baru tampilkan filter yang sebenarnya
              : Row(
                  children: [
                    // 🔸 Filter Kelas
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: selectedKelasId,
                        hint: const Text("Pilih Kelas"),
                        items: [
                          const DropdownMenuItem(
                              value: null, child: Text("Semua Kelas")),
                          ...kelasList.map((kelas) => DropdownMenuItem(
                                value: kelas['id'].toString(),
                                child: Text(kelas['nama_kelas']),
                              )),
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
                              borderRadius: BorderRadius.circular(8)),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 10),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),

                    // 🔸 Pencarian Nama
                    Expanded(
                      child: TextField(
                        // ... (Tidak ada perubahan di sini)
                        controller: searchController,
                        decoration: InputDecoration(
                          labelText: 'Cari Nama',
                          prefixIcon: const Icon(Icons.search),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8)),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 10),
                        ),
                        onChanged: (val) {
                          fetchSiswa();
                        },
                      ),
                    ),
                    const SizedBox(width: 16),

                    // 🔸 Filter Status
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        // ... (Tidak ada perubahan di sini)
                        value: selectedStatus,
                        hint: const Text("Semua Status"),
                        items: const [
                          DropdownMenuItem(
                              value: null, child: Text("Semua Status")),
                          DropdownMenuItem(value: "Aktif", child: Text("Aktif")),
                          DropdownMenuItem(
                              value: "Tidak Aktif",
                              child: Text("Tidak Aktif")),
                          DropdownMenuItem(
                              value: "Lulus", child: Text("Lulus")),
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
                              borderRadius: BorderRadius.circular(8)),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 10),
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
    // ... (Fungsi _buildTable Anda tidak perlu diubah)
    if (siswaData.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Text('Tidak ada data siswa ditemukan.'),
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
              offset: const Offset(0, 2))
        ],
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 1200),
          child: DataTable(
            columnSpacing: 24,
            headingRowHeight: 56,
            dataRowHeight: 64,
            headingRowColor: MaterialStateProperty.all(Colors.grey[50]),
            columns: const [
              DataColumn(
                  label: Text('No',
                      style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(
                  label: Text('NIS',
                      style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(
                  label: Text('Nama',
                      style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(
                  label: Text('Kelas',
                      style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(
                  label: Text('Nama Ortu',
                      style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(
                  label: Text('No. Ortu',
                      style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(
                  label: Text('Status',
                      style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(
                  label: Text('Aksi',
                      style: TextStyle(fontWeight: FontWeight.bold))),
            ],
            rows: List.generate(siswaData.length, (i) {
              final s = siswaData[i];
              return DataRow(cells: [
                DataCell(Text('${s['no'] ?? '-'}')),
                DataCell(Text('${s['nis'] ?? '-'}')),
                DataCell(Text('${s['nama'] ?? '-'}')),
                DataCell(Text('${s['kelas']?['nama_kelas'] ?? '-'}')),
                DataCell(Text('${s['orang_tua_nama'] ?? '-'}')),
                DataCell(Text('${s['orang_tua_nomor'] ?? '-'}')),
                DataCell(Text('${s['status'] ?? '-'}')),
                DataCell(Row(children: [
                  _buildAction(Icons.edit, 'Edit', Colors.blue),
                  const SizedBox(width: 8),
                  _buildAction(Icons.visibility, 'Lihat', Colors.green),
                ])),
              ]);
            }),
          ),
        ),
      ),
    );
  }

  Widget _buildAction(IconData icon, String label, Color color) {
    // ... (Fungsi _buildAction Anda tidak perlu diubah)
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: color.withOpacity(0.1),
        foregroundColor: color,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      icon: Icon(icon, size: 16),
      label: Text(label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
      onPressed: () {},
    );
  }
}
