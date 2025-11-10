import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PageKelasLogic with ChangeNotifier {
  // 1. State
  bool _isLoading = true;
  List<Map<String, dynamic>> _kelasData = [];
  List<Map<String, dynamic>> _guruData = [];

  // 2. Getter
  bool get isLoading => _isLoading;
  List<Map<String, dynamic>> get kelasData => _kelasData;
  List<Map<String, dynamic>> get guruData => _guruData;

  // 3. Metode Logika

  /// Mengambil data kelas dan guru dari Supabase
  Future<void> fetchData() async {
    _setLoading(true);
    try {
      final supabase = Supabase.instance.client;

      // DIUBAH: Ambil data guru dulu (agar lebih mudah dicari nanti jika perlu)
      final guruResponse = await supabase.from('guru').select('id, nama');
      _guruData = List<Map<String, dynamic>>.from(guruResponse);

      // DIUBAH: Query 'kelas' diubah agar mengambil data guru (wali_nama)
      // dan di-sort berdasarkan nama_kelas
      final kelasResponse = await supabase
          .from('kelas')
          .select('*, guru(nama)') // Ambil data guru terkait
          .order('nama_kelas', ascending: true); // Sortir berdasarkan nama

      // DIUBAH: Gunakan _formatKelasData untuk memproses setiap baris
      _kelasData = List<Map<String, dynamic>>.from(
        kelasResponse.map((kelas) => _formatKelasData(kelas)),
      );

      print('Kelas: ${_kelasData.length}, Guru: ${_guruData.length}');
    } catch (e) {
      print('Error fetching data: $e');
      // _errorMessage = 'Gagal memuat data: $e';
    } finally {
      _setLoading(false);
    }
  }

  /// Memperbarui data kelas yang ada di Supabase
  Future<String?> updateKelas(
    Map<String, dynamic> kelas,
    String namaKelas,
    String jamMasuk,
    String jamPulang,
    String? waliGuruId,
  ) async {
    try {
      final supabase = Supabase.instance.client;

      // DIUBAH: Minta Supabase mengembalikan data yang sudah di-update
      final List<Map<String, dynamic>> response = await supabase
          .from('kelas')
          .update({
            'nama_kelas': namaKelas,
            'jam_masuk': jamMasuk,
            'jam_pulang': jamPulang,
            'wali_kelas': waliGuruId,
          })
          .eq('id', kelas['id'])
          .select('*, guru(nama)'); // Minta data baru + data guru

      if (response.isEmpty) {
        return 'Gagal memperbarui, data tidak ditemukan.';
      }

      // DIUBAH: Optimasi, perbarui data lokal tanpa re-fetch
      final updatedKelas = _formatKelasData(response.first);
      final index = _kelasData.indexWhere((k) => k['id'] == updatedKelas['id']);
      if (index != -1) {
        _kelasData[index] = updatedKelas;
      }

      // Jaga agar tetap terurut
      _kelasData.sort(
        (a, b) => (a['nama_kelas'] ?? '').compareTo(b['nama_kelas'] ?? ''),
      );

      notifyListeners(); // Beri tahu UI
      return null; // Tidak ada error
    } catch (e) {
      print('Error updating data: $e');
      return 'Gagal memperbarui data kelas. Error: $e'; // Kembalikan pesan error
    }
  }

  /// Menambahkan kelas baru ke Supabase
  Future<String?> createKelas(
    String nama,
    String jamMasuk,
    String jamPulang,
    String? waliId,
  ) async {
    try {
      // DITAMBAHKAN: Definisikan supabase client
      final supabase = Supabase.instance.client;

      final newData = {
        'nama_kelas': nama,
        'jam_masuk': jamMasuk,
        'jam_pulang': jamPulang,
        'wali_kelas': waliId,
      };

      final List<Map<String, dynamic>> response = await supabase
          .from('kelas')
          .insert(newData)
          .select('*, guru(nama)'); // Ambil juga data guru

      if (response.isEmpty) {
        return 'Gagal menambahkan kelas, tidak ada data yang dikembalikan.';
      }

      final newKelas = _formatKelasData(response.first);

      // Tambahkan data baru ke state lokal
      _kelasData.add(newKelas);
      _kelasData.sort(
        (a, b) => (a['nama_kelas'] ?? '').compareTo(b['nama_kelas'] ?? ''),
      ); // Jaga agar tetap terurut

      notifyListeners(); // Beri tahu UI untuk update
      return null; // Sukses, tidak ada error
    } catch (e) {
      debugPrint('Error createKelas: $e');
      return 'Terjadi kesalahan: $e';
    }
  }

  /// Helper untuk memformat data relasi guru
  Map<String, dynamic> _formatKelasData(Map<String, dynamic> kelas) {
    // Ambil data 'guru' dari dalam map 'kelas'
    final Map<String, dynamic>? guruData =
        kelas['guru'] as Map<String, dynamic>?;

    // Hapus data relasi 'guru' agar tidak menumpuk
    kelas.remove('guru');

    // Tambahkan 'wali_nama' ke data 'kelas'
    kelas['wali_nama'] = guruData?['nama'] ?? '-';
    return kelas;
  }

  // Helper pribadi untuk mengatur loading dan memberi tahu UI
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
}
