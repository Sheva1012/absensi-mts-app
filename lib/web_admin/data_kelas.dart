import 'package:flutter/material.dart';
// import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PageKelas extends StatefulWidget {
  final String schoolName;

  const PageKelas({super.key, required this.schoolName});

  @override
  State<PageKelas> createState() => _PageKelasState();
}

class _PageKelasState extends State<PageKelas> {
  final SupabaseClient supabase = Supabase.instance.client;
  bool isLoading = true;
  List<Map<String, dynamic>> kelasData = [];

  @override
  void initState() {
    super.initState();
    fetchKelas();
  }

  Future<void> fetchKelas() async {
    setState(() => isLoading = true);
    try {
      final response = await supabase.from('kelas').select();

      // DEBUG: Cetak respons dari Supabase
      print('Response from Supabase: $response');

      setState(() {
        kelasData = List<Map<String, dynamic>>.from(response);
        isLoading = false;
      });
      
      // DEBUG: Periksa apakah data berhasil dimasukkan
      print('Data berhasil dimuat. Jumlah item: ${kelasData.length}');
    } catch (e) {
      // DEBUG: Tangani error jika terjadi
      print('Error fetching data: $e');
      setState(() {
        isLoading = false;
      });
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
        gradient:
            LinearGradient(colors: [Colors.blue[700]!, Colors.blue[500]!]),
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
              DataColumn(label: Text('ID', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('Nama Kelas', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('Wali Kelas', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('Jam Masuk', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('Aksi', style: TextStyle(fontWeight: FontWeight.bold))),
            ],
            rows: List.generate(kelasData.length, (i) {
              final s = kelasData[i];
              return DataRow(cells: [
                DataCell(Text(s['id'].toString())),
                DataCell(Text(s['nama_kelas'] ?? '-')),
                DataCell(Text(s['wali_guru']?.toString() ?? '-')),
                DataCell(Text(s['jam_masuk'] ?? '-')),
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
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: color.withOpacity(0.1),
        foregroundColor: color,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      icon: Icon(icon, size: 16),
      label:
          Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
      onPressed: () {},
    );
  }
}