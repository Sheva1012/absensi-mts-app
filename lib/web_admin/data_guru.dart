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
    if (mounted) {
      setState(() => isLoading = true);
    }
    try {
      final response = await supabase.from('guru').select();

      if (mounted) {
        setState(() {
          guruData = List<Map<String, dynamic>>.from(response);
          isLoading = false;
        });
      }
    } catch (e) {
      print('Error fetching data: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("Terjadi error: $e"),
          backgroundColor: Colors.red,
        ));
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  void _showAddForm() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.person_add, color: Colors.blue),
            SizedBox(width: 8),
            Text('Tambah Data Guru'),
          ],
        ),
        content: SingleChildScrollView(
          child: FormTambahGuru(
            onSave: (data) async {
              try {
                print('Data yang akan disimpan: $data');
                
                await Future.delayed(const Duration(seconds: 1));
                
                Navigator.of(context).pop();
                
                fetchGuru();
                
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Data guru ${data['nama']} berhasil ditambahkan'),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
          ),
        ),
      ),
    );
  }

  void _showEditForm(Map<String, dynamic> guru) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.edit, color: Colors.blue),
            SizedBox(width: 8),
            Text('Edit Data Guru'),
          ],
        ),
        content: SingleChildScrollView(
          child: FormEditGuru(
            data: guru,
            onSave: (data) async {
              try {
                print('Data yang akan diupdate: $data');
                
                await Future.delayed(const Duration(seconds: 1));
                
                Navigator.of(context).pop();
                
                fetchGuru();
                
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Data guru ${data['nama']} berhasil diupdate'),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
          ),
        ),
      ),
    );
  }

  void _showDeleteDialog(Map<String, dynamic> guru) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Data Guru'),
        content: Text('Yakin ingin menghapus data guru ${guru['nama']}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              try {
                print('Menghapus guru: ${guru['nama']}');
                await Future.delayed(const Duration(seconds: 1));
                
                Navigator.of(context).pop();
                fetchGuru();
                
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Data guru ${guru['nama']} berhasil dihapus'),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('Hapus', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
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
                  s['avatar_url'] != null && s['avatar_url'].isNotEmpty
                      ? CircleAvatar(
                          backgroundImage: NetworkImage(s['avatar_url']),
                        )
                      : const CircleAvatar(
                          child: Icon(Icons.person),
                        ),
                ),
                DataCell(Row(children: [
                  _buildAction(
                    Icons.edit, 
                    'Edit', 
                    Colors.blue,
                    onPressed: () => _showEditForm(s),
                  ),
                  const SizedBox(width: 8),
                  _buildAction(
                    Icons.person_add, 
                    'Tambah', 
                    Colors.green,
                    onPressed: _showAddForm,
                  ),
                  const SizedBox(width: 8),
                  _buildAction(
                    Icons.delete, 
                    'Hapus', 
                    Colors.red,
                    onPressed: () => _showDeleteDialog(s),
                  ),
                ])),
              ]);
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
      label: Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
      onPressed: onPressed,
    );
  }
}

class FormTambahGuru extends StatefulWidget {
  final Function(Map<String, dynamic>) onSave;

  const FormTambahGuru({super.key, required this.onSave});

  @override
  State<FormTambahGuru> createState() => _FormTambahGuruState();
}

class _FormTambahGuruState extends State<FormTambahGuru> {
  final _formKey = GlobalKey<FormState>();
  final _namaController = TextEditingController();
  final _emailController = TextEditingController();
  final _roleController = TextEditingController();
  final _kelasController = TextEditingController();
  final _avatarController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextFormField(
            controller: _namaController,
            decoration: const InputDecoration(
              labelText: 'Nama Guru',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.person),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Nama guru harus diisi';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _emailController,
            decoration: const InputDecoration(
              labelText: 'Email',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.email),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Email harus diisi';
              }
              if (!value.contains('@')) {
                return 'Email tidak valid';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _roleController,
            decoration: const InputDecoration(
              labelText: 'Role',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.work),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Role harus diisi';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _kelasController,
            decoration: const InputDecoration(
              labelText: 'Kelas Diampu',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.class_),
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _avatarController,
            decoration: const InputDecoration(
              labelText: 'URL Avatar (opsional)',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.image),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Batal'),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _submitForm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Simpan'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      final data = {
        'nama': _namaController.text,
        'email': _emailController.text,
        'role': _roleController.text,
        'kelas_diampu': _kelasController.text,
        'avatar_url': _avatarController.text.isEmpty ? null : _avatarController.text,
        'created_at': DateTime.now().toIso8601String(),
      };
      
      widget.onSave(data);
    }
  }

  @override
  void dispose() {
    _namaController.dispose();
    _emailController.dispose();
    _roleController.dispose();
    _kelasController.dispose();
    _avatarController.dispose();
    super.dispose();
  }
}

class FormEditGuru extends StatefulWidget {
  final Map<String, dynamic> data;
  final Function(Map<String, dynamic>) onSave;

  const FormEditGuru({super.key, required this.data, required this.onSave});

  @override
  State<FormEditGuru> createState() => _FormEditGuruState();
}

class _FormEditGuruState extends State<FormEditGuru> {
  final _formKey = GlobalKey<FormState>();
  late final _namaController = TextEditingController(text: widget.data['nama'] ?? '');
  late final _emailController = TextEditingController(text: widget.data['email'] ?? '');
  late final _roleController = TextEditingController(text: widget.data['role'] ?? '');
  late final _kelasController = TextEditingController(
      text: widget.data['kelas_diampu']?.toString() ?? '');
  late final _avatarController = TextEditingController(
      text: widget.data['avatar_url']?.toString() ?? '');

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextFormField(
            controller: _namaController,
            decoration: const InputDecoration(
              labelText: 'Nama Guru',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.person),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Nama guru harus diisi';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _emailController,
            decoration: const InputDecoration(
              labelText: 'Email',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.email),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Email harus diisi';
              }
              if (!value.contains('@')) {
                return 'Email tidak valid';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _roleController,
            decoration: const InputDecoration(
              labelText: 'Role',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.work),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Role harus diisi';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _kelasController,
            decoration: const InputDecoration(
              labelText: 'Kelas Diampu',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.class_),
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _avatarController,
            decoration: const InputDecoration(
              labelText: 'URL Avatar',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.image),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Batal'),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _submitForm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Update'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      final data = {
        ...widget.data,
        'nama': _namaController.text,
        'email': _emailController.text,
        'role': _roleController.text,
        'kelas_diampu': _kelasController.text,
        'avatar_url': _avatarController.text.isEmpty ? null : _avatarController.text,
        'updated_at': DateTime.now().toIso8601String(),
      };
      
      widget.onSave(data);
    }
  }

  @override
  void dispose() {
    _namaController.dispose();
    _emailController.dispose();
    _roleController.dispose();
    _kelasController.dispose();
    _avatarController.dispose();
    super.dispose();
  }
}