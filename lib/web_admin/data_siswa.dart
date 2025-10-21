import 'dart:io';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:file_picker/file_picker.dart';

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
        await supabase.from('siswa').update({
          'nis': nis,
          'nama': nama,
          'kelas_id': kelasId, 
          'orang_tua_nama': ortuNama,
          'orang_tua_nomor': ortuNomor,
          'status': status,
        }).eq('id', siswaId!);
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
        SnackBar(content: Text(isEdit ? 'Data berhasil diperbarui' : 'Data siswa berhasil ditambahkan')),
      );

      fetchSiswa();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menyimpan data: $e')),
      );
    }
  }

  Future<void> _deleteSiswa(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi'),
        content: const Text('Apakah Anda yakin ingin menghapus data siswa ini?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Hapus')),
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
    final TextEditingController nisController = TextEditingController(text: siswa?['nis'] ?? '');
    final TextEditingController namaController = TextEditingController(text: siswa?['nama'] ?? '');
    final TextEditingController ortuNamaController = TextEditingController(text: siswa?['orang_tua_nama'] ?? '');
    final TextEditingController ortuNomorController = TextEditingController(text: siswa?['orang_tua_nomor'] ?? '');
    
    int? kelasId = siswa?['kelas_id']; 
    String? status = siswa?['status'];

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(isEdit ? "Edit Siswa" : "Tambah Siswa"),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextField(controller: nisController, decoration: const InputDecoration(labelText: 'NIS')),
                const SizedBox(height: 8),
                TextField(controller: namaController, decoration: const InputDecoration(labelText: 'Nama')),
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
                        .map((k) => DropdownMenuItem(
                              value: k['id'] as int, 
                              child: Text(k['nama_kelas']),
                            ))
                        .toList(),
                  ],
                  onChanged: (val) => kelasId = val,
                  decoration: const InputDecoration(labelText: 'Kelas'),
                ),
                const SizedBox(height: 8),
                TextField(controller: ortuNamaController, decoration: const InputDecoration(labelText: 'Nama Orang Tua')),
                const SizedBox(height: 8),
                TextField(controller: ortuNomorController, decoration: const InputDecoration(labelText: 'Nomor WA Orang Tua')),
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
                    DropdownMenuItem(value: 'tidak aktif', child: Text('Tidak Aktif')),
                    DropdownMenuItem(value: 'lulus', child: Text('Lulus')),
                  ],
                  onChanged: (val) => status = val,
                  decoration: const InputDecoration(labelText: 'Status'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Batal")),
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
  Future<void> _importCSV() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['csv']);
    if (result != null && result.files.single.path != null) {
      final file = File(result.files.single.path!);
      final bytes = await file.readAsBytes();

      try {
        await supabase.storage.from('uploads').uploadBinary('import_siswa.csv', bytes);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('CSV berhasil diunggah ke storage')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal upload CSV: $e')),
        );
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
          constraints: const BoxConstraints(minWidth: 1200),
          child: DataTable(
            columnSpacing: 24,
            headingRowHeight: 56,
            dataRowHeight: 64,
            headingRowColor: MaterialStateProperty.all(Colors.grey[50]),
            columns: const [
              DataColumn(label: Text('No', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('NIS', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('Nama', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('Kelas', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('Nama Ortu', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('No. Ortu', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('Aksi', style: TextStyle(fontWeight: FontWeight.bold))),
            ],
            rows: List.generate(siswaData.length, (i) {
              final s = siswaData[i];
              return DataRow(
                cells: [
                  DataCell(Text('${s['no'] ?? '-'}')),
                  DataCell(Text('${s['nis'] ?? '-'}')),
                  DataCell(Text('${s['nama'] ?? '-'}')),
                  DataCell(Text('${s['kelas']?['nama_kelas'] ?? '-'}')),
                  DataCell(Text('${s['orang_tua_nama'] ?? '-'}')),
                  DataCell(Text('${s['orang_tua_nomor'] ?? '-'}')),
                  DataCell(Text('${s['status'] ?? '-'}')),
                  DataCell(
                    Row(
                      children: [
                        _buildAction(Icons.edit, 'Edit', Colors.blue, onPressed: () => _showSiswaForm(siswa: s)),
                        const SizedBox(width: 8),
                        _buildAction(Icons.delete, 'Hapus', Colors.red, onPressed: () => _deleteSiswa(s['id'])),
                      ],
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

  Widget _buildAction(IconData icon, String label, Color color, {VoidCallback? onPressed}) {
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