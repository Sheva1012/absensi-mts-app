import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DataSiswaPage extends StatefulWidget {
  final String schoolName;

  const DataSiswaPage({super.key, required this.schoolName});

  @override
  State<DataSiswaPage> createState() => _DataSiswaPageState();
}

class _DataSiswaPageState extends State<DataSiswaPage> {
  final SupabaseClient supabase = Supabase.instance.client;
  bool isLoading = true;
  List<Map<String, dynamic>> siswaData = [];

  @override
  void initState() {
    super.initState();
    fetchSiswa();
  }

  Future<void> fetchSiswa() async {
   setState(() => isLoading = true);
   try {
    // Corrected Supabase query using inner join syntax
    final response = await supabase.from('siswa').select('*, kelas!inner(nama_kelas)');

    setState(() {
     siswaData = List<Map<String, dynamic>>.from(response);
     siswaData.sort((a, b) {
      int kelasComparison = (a['kelas_id'] ?? 0).compareTo(b['kelas_id'] ?? 0);
      if (kelasComparison != 0) {
       return kelasComparison;
      }
      return (a['no'] ?? 0).compareTo(b['no'] ?? 0);
     });
     isLoading = false;
    });
   } catch (e) {
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
              DataColumn(label: Text('No Absen', style: TextStyle(fontWeight: FontWeight.bold))),
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
              return DataRow(cells: [
                DataCell(Text('${s['no'] ?? '-'}')),
                DataCell(Text('${s['nis'] ?? '-'}')),
                DataCell(Text('${s['nama'] ?? '-'}')),
                DataCell(Text('${s['kelas']?['nama_kelas'] ?? s['kelas']?['nama'] ?? '-'}')),
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
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: color.withOpacity(0.1),
        foregroundColor: color,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      icon: Icon(icon, size: 16),
      label: Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
      onPressed: () {},
    );
  }
}