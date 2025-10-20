import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'data_siswa.dart'; 

class PageKelas extends StatefulWidget {
  final String schoolName;
  final Function(String kelasId) onViewSiswa;

  const PageKelas({super.key, required this.schoolName, required this.onViewSiswa});

  @override
  State<PageKelas> createState() => _PageKelasState();
}

class _PageKelasState extends State<PageKelas> {
  final SupabaseClient supabase = Supabase.instance.client;
  bool isLoading = true;
  List<Map<String, dynamic>> kelasData = [];
  List<Map<String, dynamic>> guruData = [];

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  Future<void> fetchData() async {
    setState(() => isLoading = true);
    try {

      final kelasResponse = await supabase
          .from('kelas')
          .select()
          .order('id', ascending: true);
      // ---------------------------------

      // Ambil data guru (bisa juga difilter per sekolah jika perlu)
      final guruResponse = await supabase.from('guru').select('id, nama');

      setState(() {
        kelasData = List<Map<String, dynamic>>.from(kelasResponse);
        guruData = List<Map<String, dynamic>>.from(guruResponse);
        isLoading = false;
      });

      print('Kelas: ${kelasData.length}, Guru: ${guruData.length}');
    } catch (e) {
      print('Error fetching data: $e');
      setState(() => isLoading = false);
    }
  }

  Future<void> updateKelas(Map<String, dynamic> kelas, String namaKelas,
      String jamMasuk, String? waliGuruId) async {
    try {
      await supabase.from('kelas').update({
        'nama_kelas': namaKelas,
        'jam_masuk': jamMasuk,
        'wali_kelas': waliGuruId,
      }).eq('id', kelas['id']);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Data kelas berhasil diperbarui')),
      );
      fetchData();
    } catch (e) {
      print('Error updating data: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal memperbarui data kelas')),
      );
    }
  }

  void _showEditDialog(Map<String, dynamic> kelas) {
    final TextEditingController namaController =
        TextEditingController(text: kelas['nama_kelas'] ?? '');
    final TextEditingController jamMasukController =
        TextEditingController(text: kelas['jam_masuk'] ?? '');
    String? selectedGuruId = kelas['wali_kelas'];

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Data Kelas'),
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
                DropdownButtonFormField<String>(
                  value: selectedGuruId,
                  decoration: const InputDecoration(
                    labelText: 'Pilih Wali Kelas',
                    border: OutlineInputBorder(),
                  ),
                  items: guruData.map((g) {
                    return DropdownMenuItem<String>(
                      value: g['id'],
                      child: Text(g['nama']),
                    );
                  }).toList(),
                  onChanged: (value) {
                    selectedGuruId = value;
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
              onPressed: () {
                final nama = namaController.text.trim();
                final jam = jamMasukController.text.trim();
                if (nama.isNotEmpty && jam.isNotEmpty) {
                  updateKelas(kelas, nama, jam, selectedGuruId);
                  Navigator.pop(context);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content:
                            Text('Nama kelas dan jam masuk tidak boleh kosong')),
                  );
                }
              },
              child: const Text('Simpan'),
            ),
          ],
        );
      },
    );
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
            'Data Kelas',
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

  Widget _buildTable() {
    if (kelasData.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Text('Tidak ada data kelas ditemukan.'),
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
          constraints: const BoxConstraints(minWidth: 1000),
          child: DataTable(
            columnSpacing: 24,
            headingRowHeight: 56,
            dataRowHeight: 64,
            headingRowColor: MaterialStateProperty.all(Colors.grey[50]),
            columns: const [
              DataColumn(
                  label:
                      Text('ID', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(
                  label: Text('Nama Kelas',
                      style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(
                  label: Text('Wali Kelas',
                      style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(
                  label: Text('Jam Masuk',
                      style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(
                  label: Text('Aksi',
                      style: TextStyle(fontWeight: FontWeight.bold))),
            ],
            rows: List.generate(kelasData.length, (i) {
              final s = kelasData[i];
              final wali = guruData.firstWhere(
                (g) => g['id'] == s['wali_kelas'],
                orElse: () => {'nama': '-'},
              );
              return DataRow(cells: [
                DataCell(Text(s['id'].toString())),
                DataCell(Text(s['nama_kelas'] ?? '-')),
                DataCell(Text(wali['nama'] ?? '-')),
                DataCell(Text(s['jam_masuk'] ?? '-')),
                DataCell(Row(children: [
                  _buildAction(Icons.edit, 'Edit', Colors.blue, () {
                    _showEditDialog(s);
                  }),
                  const SizedBox(width: 8),
                  
                  // --- PERBAIKAN NAVIGASI ---
                  _buildAction(Icons.visibility, 'Lihat', Colors.green, () {
                widget.onViewSiswa(s['id'].toString());
                  }),
                ])),
              ]);
            }),
          ),
        ),
      ),
    );
  }

  Widget _buildAction(
      IconData icon, String label, Color color, VoidCallback onTap) {
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
      onPressed: onTap,
    );
  }
}