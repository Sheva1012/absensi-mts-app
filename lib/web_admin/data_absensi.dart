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

  @override
  void initState() {
    super.initState();
    fetchAbsensi();
  }

  Future<void> fetchAbsensi() async {
    setState(() => isLoading = true);
    try {
      final response = await supabase.from('absensi').select(
          'id, siswa_id, siswa(nama), tanggal, status, waktu_masuk, waktu_pulang, verified, keterangan, surat_url');

      setState(() {
        absensiData = List<Map<String, dynamic>>.from(response);
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
        gradient: LinearGradient(colors: [Colors.teal[700]!, Colors.teal[500]!]),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.teal.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 4))
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Data Absensi',
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
    if (absensiData.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Text('Tidak ada data absensi ditemukan.'),
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
                  label: Text('Nama Siswa',
                      style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(
                  label: Text('Tanggal',
                      style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(
                  label: Text('Status',
                      style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(
                  label: Text('Waktu Masuk',
                      style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(
                  label: Text('Waktu Pulang',
                      style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(
                  label: Text('Keterangan',
                      style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(
                  label: Text('Surat',
                      style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(
                  label: Text('Aksi',
                      style: TextStyle(fontWeight: FontWeight.bold))),
            ],
            rows: List.generate(absensiData.length, (i) {
              final a = absensiData[i];
              return DataRow(cells: [
                DataCell(Text(a['siswa']?['nama'] ?? '-')),
                DataCell(Text(
                    DateFormat('dd-MM-yyyy').format(DateTime.parse(a['tanggal'])))),
                DataCell(Text(a['status'] ?? '-')),
                DataCell(Text(a['waktu_masuk'] ?? '-')),
                DataCell(Text(a['waktu_pulang'] ?? '-')),
                DataCell(Text(a['keterangan'] ?? '-')),
                DataCell(
                  a['surat_url'] != null
                      ? ElevatedButton(
                          onPressed: () {},
                          style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.teal.withOpacity(0.1),
                              foregroundColor: Colors.teal),
                          child: const Text('Lihat Surat'),
                        )
                      : const Text('-'),
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
      label: Text(label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
      onPressed: () {},
    );
  }
}