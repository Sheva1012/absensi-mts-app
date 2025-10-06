import 'package:flutter/material.dart';

class DataOrangTuaScreen extends StatefulWidget {
  const DataOrangTuaScreen({super.key});

  @override
  State<DataOrangTuaScreen> createState() => _DataOrangTuaScreenState();
}

class _DataOrangTuaScreenState extends State<DataOrangTuaScreen> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _dateController =
      TextEditingController(text: '05/10/2025');
  String _selectedKelas = 'Semua Kelas';
  String _searchQuery = '';

  // Dummy data (status dihapus)
  List<Map<String, String>> get _data => [
        {
          'nama': 'John Doe',
          'namaSiswa': 'Andi Doe',
          'kelas': '7A',
          'alamat': 'Kediri',
          'hp': '082345457599',
        },
        {
          'nama': 'Jane Smith',
          'namaSiswa': 'Budi Smith',
          'kelas': '8B',
          'alamat': 'Ngarijak',
          'hp': '082345457599',
        },
        {
          'nama': 'Alice Johnson',
          'namaSiswa': 'Citra Johnson',
          'kelas': '9C',
          'alamat': 'Blitar',
          'hp': '082345457599',
        },
        {
          'nama': 'Bob Brown',
          'namaSiswa': 'Doni Brown',
          'kelas': '7A',
          'alamat': 'Malang',
          'hp': '082345457599',
        },
        {
          'nama': 'Charlie Black',
          'namaSiswa': 'Eka Black',
          'kelas': '8B',
          'alamat': 'Surabaya',
          'hp': '082345457599',
        },
      ];

  List<Map<String, String>> get _filteredData => _data.where((d) {
        final namaLower = d['nama']!.toLowerCase();
        final siswaLower = d['namaSiswa']!.toLowerCase();
        final query = _searchQuery.toLowerCase();

        final matchSearch =
            namaLower.contains(query) || siswaLower.contains(query);
        final matchKelas =
            _selectedKelas == 'Semua Kelas' || d['kelas'] == _selectedKelas;

        return matchSearch && matchKelas;
      }).toList();

  int get total => _data.length;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() => _searchQuery = _searchController.text);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _dateController.dispose();
    super.dispose();
  }

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
            _buildFilters(),
            const SizedBox(height: 28),
            _buildStats(),
            const SizedBox(height: 28),
            _buildTable(),
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
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Title kiri
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Data Orang Tua Siswa',
                style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                    color: Colors.white),
              ),
              const SizedBox(height: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today,
                        size: 14, color: Colors.white),
                    const SizedBox(width: 8),
                    Text(
                      'Per tanggal ${_dateController.text.isNotEmpty ? _dateController.text : "-"}',
                      style: const TextStyle(fontSize: 14, color: Colors.white),
                    ),
                  ],
                ),
              ),
            ],
          ),
          // Admin info kanan
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                        colors: [Colors.blue[400]!, Colors.blue[600]!]),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Text(
                      "AU",
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Admin User',
                        style: TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 16)),
                    Text('MTs Sunan Gunung Jati',
                        style: TextStyle(
                            fontSize: 13, color: Colors.grey[600])),
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
    const double fieldWidth = 200;
    const double buttonWidth = 160;

    return Align(
      alignment: Alignment.center,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1100),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.08),
                blurRadius: 10,
                offset: const Offset(0, 2),
              )
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Filter & Aksi',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),

              // 🔹 Baris filter (4 kolom sejajar)
              Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                  SizedBox(width: fieldWidth, child: _buildDateInput()),
                  SizedBox(
                    width: fieldWidth,
                    child: _buildDropdown(
                      'Kelas Siswa',
                      _selectedKelas,
                      ['Semua Kelas', '7A', '8B', '9C'],
                      (v) => setState(() => _selectedKelas = v!),
                    ),
                  ),
                  SizedBox(
                    width: fieldWidth,
                    child: _buildInput(
                      _searchController,
                      'Cari Orang Tua / Siswa',
                      Icons.search,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // 🔹 Tombol aksi
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  SizedBox(
                    width: buttonWidth,
                    child: _buildButton(
                        'Terapkan Filter', Icons.filter_alt, Colors.blue),
                  ),
                  SizedBox(
                    width: buttonWidth,
                    child: _buildButton('Cetak Data', Icons.print, Colors.green),
                  ),
                  SizedBox(
                    width: buttonWidth,
                    child: _buildButton(
                        'Refresh Data', Icons.refresh, Colors.orange),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDateInput() {
    return TextField(
      controller: _dateController,
      readOnly: true,
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: DateTime.now(),
          firstDate: DateTime(2020),
          lastDate: DateTime(2100),
          locale: const Locale("id", "ID"),
        );
        if (picked != null) {
          setState(() {
            _dateController.text =
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
      ),
    );
  }

  Widget _buildInput(TextEditingController ctrl, String label, IconData icon) {
    return TextField(
      controller: ctrl,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.blue),
        filled: true,
        fillColor: Colors.grey[50],
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildDropdown(String label, String value, List<String> items,
      void Function(String?) onChanged) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Colors.grey[50],
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      items:
          items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
      onChanged: onChanged,
    );
  }

  Widget _buildButton(String label, IconData icon, Color color) {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      icon: Icon(icon, size: 18),
      label: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
      onPressed: () {},
    );
  }

  Widget _buildStats() {
    final stats = [
      ('Total Orang Tua', total, Icons.people, Colors.blue),
      ('Total Siswa', 150, Icons.school, Colors.purple),
    ];

    return Row(
      children: stats
          .map(
            (s) => Expanded(
              child: Padding(
                padding: const EdgeInsets.only(right: 16),
                child: _buildStatCard(s.$1, s.$2.toString(), s.$3, s.$4),
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
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
          Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(14)),
              child: Icon(icon, color: color, size: 28)),
          const SizedBox(height: 20),
          Text(value,
              style:
                  const TextStyle(fontSize: 36, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(label,
              style: TextStyle(
                  fontSize: 15,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500)),
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
        boxShadow: [
          BoxShadow(
              color: Colors.grey.withOpacity(0.08),
              blurRadius: 10,
              offset: const Offset(0, 2))
        ],
      ),
      child: DataTable(
        columnSpacing: 52,
        headingRowHeight: 60,
        dataRowHeight: 64,
        headingRowColor: MaterialStateProperty.all(Colors.grey[50]),
        columns: const [
          DataColumn(label: Text('No')),
          DataColumn(label: Text('Nama Orang Tua')),
          DataColumn(label: Text('Nama Siswa')),
          DataColumn(label: Text('Kelas')),
          DataColumn(label: Text('Alamat')),
          DataColumn(label: Text('No. HP')),
          DataColumn(label: Text('Aksi')),
        ],
        rows: List.generate(_filteredData.length, (i) {
          final d = _filteredData[i];
          return DataRow(cells: [
            DataCell(Text('${i + 1}')),
            DataCell(Text(d['nama']!)),
            DataCell(Text(d['namaSiswa']!)),
            DataCell(Text(d['kelas']!)),
            DataCell(Text(d['alamat']!)),
            DataCell(Text(d['hp']!)),
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
