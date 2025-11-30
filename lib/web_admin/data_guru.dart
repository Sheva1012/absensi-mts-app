import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:multi_select_flutter/multi_select_flutter.dart';
import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';

class Kelas {
  final String id;
  final String nama;

  Kelas({required this.id, required this.nama});

  Map<String, dynamic> toJson() => {'id': id, 'nama': nama};

  factory Kelas.fromJson(Map<String, dynamic> json) => Kelas(
    id: json['id'] as String? ?? '',
    nama: json['nama'] as String? ?? '',
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Kelas && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

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
    if (mounted) setState(() => isLoading = true);
    try {
      final response = await supabase
          .from('guru')
          .select()
          .order('nama', ascending: true);
      if (mounted) {
        setState(() {
          guruData = List<Map<String, dynamic>>.from(response);
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackbar("Gagal memuat data guru: $e");
        setState(() => isLoading = false);
      }
    }
  }

  void _showErrorSnackbar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
      ),
    );
  }

  void _showSuccessSnackbar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  void _showFormDialog({Map<String, dynamic>? guru}) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              guru == null ? Icons.person_add : Icons.edit,
              color: Colors.blue,
            ),
            const SizedBox(width: 8),
            Text(guru == null ? 'Tambah Data Guru' : 'Edit Data Guru'),
          ],
        ),
        content: SizedBox(
          width: MediaQuery.of(context).size.width * 0.4,
          child: SingleChildScrollView(
            child: FormGuru(
              initialData: guru,
              onSave: (data) async {
                try {
                  if (guru == null) {
                    await supabase.from('guru').insert(data);
                    _showSuccessSnackbar(
                      'Data guru ${data['nama']} berhasil ditambahkan',
                    );
                  } else {
                    final id = guru['id'];
                    await supabase.from('guru').update(data).eq('id', id);
                    _showSuccessSnackbar(
                      'Data guru ${data['nama']} berhasil diupdate',
                    );
                  }
                  if (mounted) Navigator.of(context).pop();
                  fetchGuru();
                } catch (e) {
                  // Tidak perlu pop di sini karena error akan ditangani di dalam form
                  _showErrorSnackbar("Terjadi kesalahan: $e");
                }
              },
            ),
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
                final id = guru['id'];
                await supabase.from('guru').delete().eq('id', id);

                final avatarUrl = guru['avatar_url'] as String?;
                if (avatarUrl != null && avatarUrl.isNotEmpty) {
                  final fileName = avatarUrl.split('/').last;
                  await supabase.storage.from('avatars').remove([
                    'public/$fileName',
                  ]);
                }

                if (mounted) Navigator.of(context).pop();
                _showSuccessSnackbar(
                  'Data guru ${guru['nama']} berhasil dihapus',
                );
                fetchGuru();
              } catch (e) {
                if (mounted) Navigator.of(context).pop();
                _showErrorSnackbar("Gagal menghapus data: $e");
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
            _buildAddButton(),
            const SizedBox(height: 16),
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
            'Data Guru',
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

  Widget _buildAddButton() {
    return Align(
      alignment: Alignment.centerRight,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color.fromARGB(255, 11, 226, 43),
          foregroundColor: Colors.white,
          elevation: 2,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        icon: const Icon(Icons.person_add),
        label: const Text(
          'Tambah Data Guru',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        onPressed: () => _showFormDialog(),
      ),
    );
  }

  Widget _buildTable() {
    // Cek jika data kosong
    if (guruData.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Text('Tidak ada data guru ditemukan.'),
        ),
      );
    }

    // Controller untuk scroll horizontal
    final ScrollController _horizontalController = ScrollController();

    return Container(
      // Hapus width: double.infinity agar menyesuaikan parent (LayoutBuilder)
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
      // Gunakan LayoutBuilder agar responsif terhadap perubahan lebar (sidebar)
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Lebar minimum tabel mengikuti lebar container yang tersedia
          final double minTableWidth = constraints.maxWidth;

          return Scrollbar(
            controller: _horizontalController,
            thumbVisibility: true,
            trackVisibility: true,
            scrollbarOrientation: ScrollbarOrientation.bottom,
            child: SingleChildScrollView(
              controller: _horizontalController,
              scrollDirection: Axis.horizontal,
              child: ConstrainedBox(
                // KUNCI: minWidth diset ke constraints.maxWidth
                // Ini membuat tabel "full width" jika konten sedikit,
                // tapi tetap bisa di-scroll jika konten melebar.
                constraints: BoxConstraints(minWidth: minTableWidth),
                child: DataTable(
                  columnSpacing: 24,
                  headingRowHeight: 56,
                  dataRowHeight: 64,
                  headingRowColor: MaterialStateProperty.all(
                    Colors.blue.shade50,
                  ),
                  columns: const [
                    DataColumn(
                      label: Text(
                        'Nama',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        'Email',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    DataColumn(
                      label: SizedBox(
                        width: 80,
                        child: Text(
                          'Role',
                          style: TextStyle(fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        'Kelas Diampu',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    DataColumn(
                      label: SizedBox(
                        width: 80,
                        child: Text(
                          'Avatar',
                          style: TextStyle(fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                    DataColumn(
                      label: SizedBox(
                        width: 180,
                        child: Text(
                          'Aksi',
                          style: TextStyle(fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ],
                  rows: List.generate(guruData.length, (i) {
                    final guru = guruData[i];

                    // Logika memproses kelas diampu
                    final dynamic data = guru['kelas_diampu'];
                    List<String> semuaKelas = [];
                    if (data is Map<String, dynamic>) {
                      data.forEach((key, value) {
                        if (value is List) {
                          semuaKelas.addAll(value.cast<String>());
                        }
                      });
                    }
                    final kelasDiampuText = semuaKelas.isNotEmpty
                        ? semuaKelas.join(', ')
                        : '-';

                    return DataRow(
                      cells: [
                        DataCell(Text(guru['nama'] ?? '-')),
                        DataCell(Text(guru['email'] ?? '-')),
                        DataCell(
                          SizedBox(
                            width: 80,
                            child: Center(child: Text(guru['role'] ?? '-')),
                          ),
                        ),
                        DataCell(Text(kelasDiampuText)),
                        DataCell(
                          SizedBox(
                            width: 80,
                            child: Center(
                              child:
                                  (guru['avatar_url'] != null &&
                                      guru['avatar_url'].isNotEmpty)
                                  ? CircleAvatar(
                                      backgroundImage: NetworkImage(
                                        guru['avatar_url'],
                                      ),
                                    )
                                  : const CircleAvatar(
                                      child: Icon(Icons.person),
                                    ),
                            ),
                          ),
                        ),
                        DataCell(
                          SizedBox(
                            width: 180,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _buildActionButton(
                                  Icons.edit,
                                  'Edit',
                                  Colors.blue,
                                  onPressed: () => _showFormDialog(guru: guru),
                                ),
                                const SizedBox(width: 8),
                                _buildActionButton(
                                  Icons.delete,
                                  'Hapus',
                                  Colors.red,
                                  onPressed: () => _showDeleteDialog(guru),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    );
                  }),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

Widget _buildActionButton(
  IconData icon,
  String label,
  Color color, {
  VoidCallback? onPressed,
}) {
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

class FormGuru extends StatefulWidget {
  final Map<String, dynamic>? initialData;
  final Function(Map<String, dynamic>) onSave;

  const FormGuru({super.key, this.initialData, required this.onSave});

  @override
  State<FormGuru> createState() => _FormGuruState();
}

class _FormGuruState extends State<FormGuru> {
  final _formKey = GlobalKey<FormState>();
  final SupabaseClient supabase = Supabase.instance.client;
  late final TextEditingController _namaController;
  late final TextEditingController _emailController;

  String? _selectedRole;
  List<Kelas> _selectedKelas = [];
  bool _isUploading = false;

  // PERUBAHAN: State untuk menangani gambar
  Uint8List? _avatarBytes;
  String? _existingAvatarUrl;

  final List<String> _roleOptions = ['guru', 'admin'];
  final List<Kelas> _kelasOptions = [
    Kelas(id: '7A', nama: 'Kelas 7A'),
    Kelas(id: '7B', nama: 'Kelas 7B'),
    Kelas(id: '8A', nama: 'Kelas 8A'),
    Kelas(id: '8B', nama: 'Kelas 8B'),
    Kelas(id: '9A', nama: 'Kelas 9A'),
    Kelas(id: '9B', nama: 'Kelas 9B'),
  ];
  late final Map<String, Kelas> _kelasLookup;

  @override
  void initState() {
    super.initState();
    _kelasLookup = {for (var k in _kelasOptions) k.nama: k};

    final data = widget.initialData;
    _namaController = TextEditingController(text: data?['nama'] ?? '');
    _emailController = TextEditingController(text: data?['email'] ?? '');
    _selectedRole = data?['role'] ?? 'guru';
    _existingAvatarUrl = data?['avatar_url'];

    final dynamic kelasData = data?['kelas_diampu'];
    if (kelasData is Map<String, dynamic>) {
      final Map<String, dynamic> kelasDiampuMap = kelasData;
      List<Kelas> initialKelas = [];
      kelasDiampuMap.forEach((key, value) {
        if (value is List) {
          for (final String kelasNama in value.cast<String>()) {
            if (_kelasLookup.containsKey(kelasNama)) {
              initialKelas.add(_kelasLookup[kelasNama]!);
            }
          }
        }
      });
      _selectedKelas = initialKelas;
    }
  }

  @override
  void dispose() {
    _namaController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _pickAvatar() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes();
      setState(() {
        _avatarBytes = bytes;
      });
    }
  }

  Future<void> _submitForm() async {
    if (_isUploading) return; // Mencegah double-submit
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isUploading = true;
      });

      try {
        String? avatarUrl = _existingAvatarUrl;

        // Jika ada gambar baru yang dipilih, unggah ke storage
        if (_avatarBytes != null) {
          final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
          // Simpan di dalam folder public agar URLnya bisa diakses
          final filePath = 'public/$fileName';

          await supabase.storage
              .from('avatars') // Nama bucket Anda
              .uploadBinary(
                filePath,
                _avatarBytes!,
                fileOptions: const FileOptions(
                  cacheControl: '3600', // Cache 1 jam
                  upsert: false,
                ),
              );

          avatarUrl = supabase.storage.from('avatars').getPublicUrl(filePath);
        }

        Map<String, List<String>> groupedKelas = {};
        for (final kelas in _selectedKelas) {
          String tingkat = "Kelas ${kelas.id[0]}";
          if (!groupedKelas.containsKey(tingkat)) {
            groupedKelas[tingkat] = [];
          }
          groupedKelas[tingkat]!.add(kelas.nama);
        }

        groupedKelas.forEach((key, value) => value.sort());

        final dataToSave = {
          'nama': _namaController.text,
          'email': _emailController.text,
          'role': _selectedRole,
          'kelas_diampu': groupedKelas,
          'avatar_url': avatarUrl,
        };
        widget.onSave(dataToSave);
      } catch (e) {
        // Tampilkan error jika upload gagal
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Gagal mengunggah foto: $e"),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isUploading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // PERUBAHAN: Widget untuk memilih dan menampilkan avatar
          _buildAvatarPicker(),
          const SizedBox(height: 16),
          TextFormField(
            controller: _namaController,
            decoration: const InputDecoration(
              labelText: 'Nama Guru',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.person),
            ),
            validator: (v) =>
                v == null || v.isEmpty ? 'Nama harus diisi' : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _emailController,
            decoration: const InputDecoration(
              labelText: 'Email',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.email),
            ),
            validator: (v) {
              if (v == null || v.isEmpty) return 'Email harus diisi';
              if (!v.contains('@')) return 'Email tidak valid';
              return null;
            },
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _selectedRole,
            decoration: const InputDecoration(
              labelText: 'Role',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.work),
            ),
            items: _roleOptions
                .map(
                  (role) =>
                      DropdownMenuItem<String>(value: role, child: Text(role)),
                )
                .toList(),
            onChanged: (val) => setState(() => _selectedRole = val),
            validator: (v) => v == null ? 'Role harus dipilih' : null,
          ),
          const SizedBox(height: 16),
          MultiSelectChipField<Kelas?>(
            items: _kelasOptions
                .map((kelas) => MultiSelectItem<Kelas>(kelas, kelas.nama))
                .toList(),
            initialValue: _selectedKelas,
            title: const Text("Kelas Diampu"),
            headerColor: Colors.blue.withOpacity(0.1),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade400, width: 1.8),
              borderRadius: BorderRadius.circular(4),
            ),
            selectedChipColor: Colors.blue.withOpacity(0.5),
            selectedTextStyle: const TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
            ),
            chipShape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            onTap: (values) {
              _selectedKelas = values.whereType<Kelas>().toList();
            },
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
                // Menampilkan loading indicator saat upload
                child: _isUploading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text('Simpan'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // BARU: Widget untuk UI pemilihan avatar
  Widget _buildAvatarPicker() {
    ImageProvider? imageProvider;
    if (_avatarBytes != null) {
      imageProvider = MemoryImage(_avatarBytes!);
    } else if (_existingAvatarUrl != null && _existingAvatarUrl!.isNotEmpty) {
      imageProvider = NetworkImage(_existingAvatarUrl!);
    }

    return Column(
      children: [
        CircleAvatar(
          radius: 50,
          backgroundImage: imageProvider,
          child: imageProvider == null
              ? const Icon(Icons.person, size: 50)
              : null,
        ),
        const SizedBox(height: 8),
        TextButton.icon(
          icon: const Icon(Icons.upload_file),
          label: const Text('Ubah Foto'),
          onPressed: _pickAvatar,
        ),
      ],
    );
  }
}
