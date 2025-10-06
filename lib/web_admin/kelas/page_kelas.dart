import 'package:flutter/material.dart';

class PageKelas extends StatefulWidget {
  final String className;
  final String adminName;
  final String schoolName;
  final List<Map<String, String>> studentData;

  const PageKelas({
    super.key,
    required this.className,
    required this.adminName,
    required this.schoolName,
    required this.studentData,
  });

  @override
  State<PageKelas> createState() => _PageKelasState();
}

class _PageKelasState extends State<PageKelas> {
  String selectedStatus = 'Semua Status';
  String searchQuery = '';
  final dateController = TextEditingController(text: '28/09/2023');
  final searchController = TextEditingController();

  List<Map<String, String>> get filteredData => widget.studentData.where((s) =>
    (selectedStatus == 'Semua Status' || s['status'] == selectedStatus) &&
    s['nama']!.toLowerCase().contains(searchQuery.toLowerCase())
  ).toList();

  int get hadirCount => filteredData.where((s) => s['status'] == 'Hadir').length;
  int get terlambatCount => filteredData.where((s) => s['status'] == 'Terlambat').length;
  int get tidakHadirCount => filteredData.where((s) => s['status'] == 'Tidak Hadir').length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            _buildHeader(),
            const SizedBox(height: 32),
            SizedBox(width: double.infinity, child: _buildFilters()),
            const SizedBox(height: 28),
            SizedBox(width: double.infinity, child: _buildStats()),
            const SizedBox(height: 28),
            SizedBox(width: double.infinity, child: _buildTable()),
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
        boxShadow: [BoxShadow(color: Colors.blue.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Data Absensi ${widget.className}', style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(20)),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today, size: 14, color: Colors.white),
                    const SizedBox(width: 8),
                    Text('Per tanggal ${dateController.text}', style: const TextStyle(fontSize: 14, color: Colors.white)),
                  ],
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(gradient: LinearGradient(colors: [Colors.blue[400]!, Colors.blue[600]!]), shape: BoxShape.circle),
                  child: Center(child: Text(widget.adminName.split(' ').map((e) => e[0]).join(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18))),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.adminName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                    Text(widget.schoolName, style: TextStyle(fontSize: 13, color: Colors.grey[600])),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Container(
      padding: const EdgeInsets.all(24),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Filter & Aksi',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              _buildDateInput(), // 🔹 ganti khusus untuk tanggal
              _buildDropdown(),
              _buildInput(searchController, 'Cari Siswa', Icons.search,
                  onChanged: (v) => setState(() => searchQuery = v)),
            ],
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _buildButton('Terapkan Filter', Icons.filter_alt, Colors.blue),
              _buildButton('Cetak Laporan', Icons.print, Colors.green),
              _buildButton('Refresh Data', Icons.refresh, Colors.orange),
            ],
          ),
        ],
      ),
    );
  }

  /// 🔹 Input khusus tanggal
  Widget _buildDateInput() {
    return SizedBox(
      width: 220,
      child: TextField(
        controller: dateController,
        readOnly: true,
        onTap: () async {
          final picked = await showDatePicker(
            context: context,
            initialDate: DateTime.now(),
            firstDate: DateTime(2020),
            lastDate: DateTime(2100),
            locale: const Locale("id", "ID"), // format Indonesia
          );
          if (picked != null) {
            setState(() {
              dateController.text =
                  "${picked.day.toString().padLeft(2, '0')}/"
                  "${picked.month.toString().padLeft(2, '0')}/"
                  "${picked.year}";
            });
          }
        },
        decoration: InputDecoration(
          labelText: 'Tanggal',
          prefixIcon: const Icon(Icons.calendar_today, color: Colors.blue),
          filled: true,
          fillColor: Colors.grey[50],
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!)),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.blue, width: 2)),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }

  Widget _buildInput(TextEditingController? ctrl, String label, IconData icon, {bool readOnly = false, Function(String)? onChanged}) {
    return SizedBox(
      width: 280,
      child: TextField(
        controller: ctrl,
        readOnly: readOnly,
        onChanged: onChanged,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: Colors.blue),
          filled: true,
          fillColor: Colors.grey[50],
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[300]!)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.blue, width: 2)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }

  Widget _buildDropdown() {
    return SizedBox(
      width: 220,
      child: DropdownButtonFormField<String>(
        value: selectedStatus,
        decoration: InputDecoration(
          labelText: 'Status Kehadiran',
          filled: true,
          fillColor: Colors.grey[50],
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[300]!)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.blue, width: 2)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
        items: ['Semua Status', 'Hadir', 'Terlambat', 'Tidak Hadir'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
        onChanged: (val) => setState(() => selectedStatus = val!),
      ),
    );
  }

  Widget _buildButton(String label, IconData icon, Color color) {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      icon: Icon(icon, size: 20),
      label: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
      onPressed: () {},
    );
  }

  Widget _buildStats() {
    final stats = [
      ('Hadir', hadirCount, Icons.check_circle, Colors.green),
      ('Terlambat', terlambatCount, Icons.access_time, Colors.orange),
      ('Tidak Hadir', tidakHadirCount, Icons.cancel, Colors.red),
      ('Total Siswa', widget.studentData.length, Icons.people, Colors.blue),
    ];
    
    return Row(
      children: [
        ...stats.take(3).map((s) => Expanded(
          child: Padding(
            padding: const EdgeInsets.only(right: 20),
            child: _buildStatCard(s.$1, s.$2.toString(), s.$3, s.$4),
          ),
        )),
        Expanded(
          child: _buildStatCard(stats[3].$1, stats[3].$2.toString(), stats[3].$3, stats[3].$4),
        ),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.08), blurRadius: 10, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 20),
          Text(value, style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(label, style: TextStyle(fontSize: 15, color: Colors.grey[600], fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildTable() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.08), blurRadius: 10, offset: const Offset(0, 2))],
      ),
      child: DataTable(
        columnSpacing: 24,
        headingRowHeight: 56,
        dataRowHeight: 64,
        headingRowColor: MaterialStateProperty.all(Colors.grey[50]),
        columns: ['No', 'Nama Siswa', 'Waktu Absensi', 'Status', 'Surat Izin', 'Aksi']
            .map((e) => DataColumn(label: Text(e, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14))))
            .toList(),
        rows: List.generate(filteredData.length, (i) {
          final s = filteredData[i];
          return DataRow(cells: [
            DataCell(Text('${i + 1}', style: const TextStyle(fontSize: 14))),
            DataCell(Text(s['nama']!, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500))),
            DataCell(Text(s['waktu']!, style: const TextStyle(fontSize: 14))),
            DataCell(_buildBadge(s['status']!)),
            DataCell(Center(child: s['suratIzin'] == 'Ada' ? const Icon(Icons.check_circle, color: Colors.green, size: 22) : const Text('-'))),
            DataCell(Row(children: [
              _buildAction(Icons.edit, 'Edit', Colors.blue),
              const SizedBox(width: 8),
              _buildAction(Icons.visibility, 'Lihat', Colors.green),
            ])),
          ]);
        }),
      ),
    );
  }

  Widget _buildBadge(String status) {
    final colors = {
      'Hadir': (Colors.green[100]!, Colors.green[800]!),
      'Terlambat': (Colors.orange[100]!, Colors.orange[800]!),
      'Tidak Hadir': (Colors.red[100]!, Colors.red[800]!),
    };
    final c = colors[status] ?? (Colors.grey[100]!, Colors.grey[800]!);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(color: c.$1, borderRadius: BorderRadius.circular(20)),
      child: Text(status, style: TextStyle(color: c.$2, fontWeight: FontWeight.w600, fontSize: 13)),
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