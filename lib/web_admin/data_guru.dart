import 'package:flutter/material.dart';
// import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PageGuru extends StatefulWidget {
  final String schoolName;

  const PageGuru({super.key, required this.schoolName});

  @override
  State<PageGuru> createState() => _PageGuruState();
}

class _PageGuruState extends State<PageGuru> {
  final SupabaseClient supabase = Supabase.instance.client;
  bool isLoading = true;
  List<Map<String, dynamic>> guruData = [];

  @override
  void initState() {
    super.initState();
    fetchGuru();
  }

  Future<void> fetchGuru() async {
    setState(() => isLoading = true);
    try {
      final response = await supabase.from('guru').select();

      // DEBUG: Cetak respons dari Supabase
      print('Response from Supabase: $response');

      setState(() {
        guruData = List<Map<String, dynamic>>.from(response);
        isLoading = false;
      });

      // DEBUG: Periksa apakah data berhasil dimasukkan
      print('Data berhasil dimuat. Jumlah item: ${guruData.length}');
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
            LinearGradient(colors: [Colors.green[700]!, Colors.green[500]!]),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.green.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 4))
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Data Guru',
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
    if (guruData.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Text('Tidak ada data guru ditemukan.'),
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
              DataColumn(label: Text('Nama', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('Email', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('Role', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('Kelas Diampu', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('Avatar', style: TextStyle(fontWeight: FontWeight.bold))), 
              DataColumn(label: Text('Aksi', style: TextStyle(fontWeight: FontWeight.bold))),
            ],
            rows: List.generate(guruData.length, (i) {
              final s = guruData[i];
              return DataRow(cells: [
                DataCell(Text(s['nama'] ?? '-')),
                DataCell(Text(s['email'] ?? '-')),
                DataCell(Text(s['role'] ?? '-')),
                DataCell(Text(s['kelas_diampu']?.toString() ?? '-')),
                DataCell(
                  s['avatar_url'] != null
                      ? CircleAvatar(
                          backgroundImage: NetworkImage(s['avatar_url']),
                        )
                      : const CircleAvatar(
                          child: Icon(Icons.person),
                        ),
                ),
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