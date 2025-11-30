import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final SupabaseClient supabase = Supabase.instance.client;
  late final RealtimeChannel _absensiChannel;

  bool _isLoading = true;

  // State untuk Quick Stats & Detailed Stats
  int _totalSiswa = 0;
  int _hadirHariIni = 0;
  int _terlambatHariIni = 0;
  int _absenHariIni = 0; // (Sakit, Izin, Alfa)

  // State untuk Aktivitas Terbaru
  List<Map<String, dynamic>> _aktivitasTerbaru = [];

  // --- BARU: State untuk Distribusi Kelas ---
  List<Map<String, dynamic>> _distribusiKelas = [];

  // BARU: Daftar warna untuk pie chart
  final List<Color> _pieColors = [
    const Color(0xFF42A5F5), // Biru
    const Color(0xFF66BB6A), // Hijau
    const Color(0xFFAB47BC), // Ungu
    const Color(0xFFFFA726), // Oranye
    const Color(0xFFEF5350), // Merah
    const Color(0xFF26C6DA), // Cyan
    const Color(0xFF7E57C2), // Deep Purple
    const Color(0xFFD4E157), // Lime
  ];
  // --- AKHIR BARU ---

  // Data statis (belum dihubungkan ke Supabase)
  final String _rataRataBulanan = '92%'; // Contoh
  final List<Map<String, dynamic>> _alerts = [
    {
      'icon': Icons.warning_amber_rounded,
      'color': const Color(0xFFFFA726),
      'title': 'Guru yang belum input validasi',
      'subtitle': '5 guru belum melakukan validasi kehadiran hari ini',
    },
    {
      'icon': Icons.person_off_outlined,
      'color': const Color(0xFFEF5350),
      'title': 'Siswa dengan alpha beruntun',
      'subtitle': '12 siswa telah alpha lebih dari 3 hari berturut-turut',
    },
  ];

  @override
  void initState() {
    super.initState();
    _initializeDashboard();
  }

  @override
  void dispose() {
    // BARU: Pastikan untuk unsubscribe channel (SYNTAX V2 BARU)
    supabase.removeChannel(_absensiChannel);
    super.dispose();
  }

  // BARU: Fungsi untuk setup awal dan listener
  Future<void> _initializeDashboard() async {
    // 1. Ambil data awal
    await _fetchDashboardData();

    // 2. Siapkan listener realtime (SYNTAX V2 YANG BENAR)
    _absensiChannel = supabase.channel('public:absensi');

    _absensiChannel
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'absensi',

          // --- INI ADALAH PERBAIKANNYA ---
          callback: (payload) {
            debugPrint(
              'Perubahan terdeteksi di tabel absensi! (payload: $payload)',
            );

            if (mounted) {
              _fetchDashboardData();
            }
          },
        )
        .subscribe();
  }

  // BARU: Fungsi utama untuk mengambil dan menghitung data
  // GANTI FUNGSI _fetchDashboardData LAMA ANDA DENGAN INI

  Future<void> _fetchDashboardData() async {
    if (!mounted) return;

    // Set loading hanya jika data belum ada
    if (_totalSiswa == 0) {
      setState(() => _isLoading = true);
    }

    try {
      // --- PERBAIKAN: Tentukan tanggal hari ini (format YYYY-MM-DD) ---
      final String tglHariIni = DateFormat('yyyy-MM-dd').format(DateTime.now());
      // --- AKHIR PERBAIKAN ---

      // Query 1: Total Siswa
      final totalSiswa = await supabase.from('siswa').count();

      // Query 2: Absensi Hari Ini (KEMBALI KE 'eq' KARENA TANGGAL ADALAH 'date')
      final absensiRes = await supabase
          .from('absensi')
          .select()
          .eq('tanggal', tglHariIni); // <-- INI PERBAIKANNYA

      // Query 3: Aktivitas Terbaru (ini sudah benar)
      final aktivitasRes = await supabase
          .from('absensi')
          .select('*, siswa (nama)') // Join dengan tabel siswa
          .order('created_at', ascending: false)
          .limit(5);

      // Query 4: Distribusi Siswa per Kelas (ini sudah benar)
      final distribusiRes = await supabase
          .from('kelas')
          .select('id, nama_kelas, siswa(count)');

      // --- AKHIR PERBAIKAN ---

      // --- Mulai Proses Data ---

      // 1. Proses Total Siswa (sudah jadi int)

      // 2. Proses Absensi Hari Ini
      int hadir = 0;
      int terlambat = 0;
      int absen = 0;

      for (var data in absensiRes) {
        // Gunakan absensiRes
        final status = data['status']?.toString().toLowerCase();

        if (status == 'hadir' || status == 'pulang') {
          hadir++;
        } else if (status == 'terlambat') {
          terlambat++;
        } else if (status == 'sakit' || status == 'izin' || status == 'alfa') {
          absen++;
        }
      }

      // 3. Proses Aktivitas Terbaru

      // 4. Proses Distribusi Kelas
      final List<Map<String, dynamic>> distribusiData = [];
      int colorIndex = 0;
      for (var item in distribusiRes) {
        // Gunakan distribusiRes
        final count = item['siswa'].isNotEmpty
            ? item['siswa'][0]['count'] as int
            : 0;

        if (count > 0) {
          distribusiData.add({
            'label': item['nama_kelas'],
            'value': count.toDouble(),
            'color': _pieColors[colorIndex % _pieColors.length],
          });
          colorIndex++;
        }
      }

      // 6. Update state
      setState(() {
        _totalSiswa = totalSiswa;
        _hadirHariIni = hadir;
        _terlambatHariIni = terlambat;
        _absenHariIni = absen;
        _aktivitasTerbaru = List<Map<String, dynamic>>.from(
          aktivitasRes,
        ); // Gunakan aktivitasRes
        _distribusiKelas = distribusiData;
        _isLoading = false;
      });
    } catch (e, st) {
      debugPrint('--- ERROR FETCHING DASHBOARD ---');
      debugPrint('ERROR: $e');
      debugPrint('STACK TRACE: $st');
      debugPrint('----------------------------------');

      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memuat data: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: _isLoading
          // Tampilkan loading di tengah jika data belum siap
          ? const Center(child: CircularProgressIndicator())
          // Tampilkan dashboard jika data sudah siap
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              // MODIFIKASI: Hapus 'const' dari Column dan widget di dalamnya
              child: Column(
                children: [
                  const _AppHeader(), // Header tetap statis
                  const SizedBox(height: 20),
                  const SizedBox(height: 20),
                  // MODIFIKASI: Kirim data dinamis ke _QuickStats
                  _QuickStats(
                    totalSiswa: _totalSiswa,
                    hadirHariIni: _hadirHariIni,
                    terlambatHariIni: _terlambatHariIni,
                    absenHariIni: _absenHariIni,
                    rataRataBulanan: _rataRataBulanan,
                  ),
                  const SizedBox(height: 20),
                  // MODIFIKASI: Kirim data dinamis ke _DetailedStats
                  _DetailedStats(
                    totalSiswa: _totalSiswa,
                    hadirHariIni: _hadirHariIni,
                    terlambatHariIni: _terlambatHariIni,
                    absenHariIni: _absenHariIni,
                  ),
                  const SizedBox(height: 30),
                  // MODIFIKASI: Kirim data dinamis ke _ChartsSection
                  _ChartsSection(distribusiKelas: _distribusiKelas),
                  const SizedBox(height: 30),
                  // MODIFIKASI: Kirim data dinamis ke _BottomSection
                  _BottomSection(
                    alerts: _alerts,
                    activities: _aktivitasTerbaru,
                  ),
                ],
              ),
            ),
    );
  }
}

// =========================================================================
// WIDGET-WIDGET BAGIAN UI
// =========================================================================

// --- HEADER & PROFILE ---
class _AppHeader extends StatelessWidget {
  const _AppHeader();

  @override
  Widget build(BuildContext context) {
    return _WhiteCard(
      child: Row(
        children: [
          const Text(
            "Dashboard Admin",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const Spacer(),
          Expanded(flex: 2, child: _SearchBar()),
          const SizedBox(width: 20),
          _NotificationBadge(),
          const SizedBox(width: 20),
          _ProfileSection(),
        ],
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 15),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: const Row(
        children: [
          Icon(Icons.search, color: Colors.grey, size: 20),
          SizedBox(width: 10),
          Expanded(
            child: TextField(
              decoration: InputDecoration(
                hintText: "Cari data...",
                hintStyle: TextStyle(color: Colors.grey, fontSize: 14),
                border: InputBorder.none,
                isDense: true,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NotificationBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        const Icon(Icons.notifications_none, size: 26),
        Positioned(
          right: -2,
          top: -2,
          child: Container(
            padding: const EdgeInsets.all(5),
            decoration: const BoxDecoration(
              color: Colors.red,
              shape: BoxShape.circle,
            ),
            child: const Text(
              "3", // Ini masih statis, bisa di-update nanti
              style: TextStyle(
                color: Colors.white,
                fontSize: 9,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ProfileSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const CircleAvatar(
          radius: 18,
          backgroundColor: Color(0xFF42A5F5),
          child: Text(
            "AU",
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: const [
            Text(
              "Admin User",
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
            Text(
              "MTs Sunan Gunung Jati",
              style: TextStyle(fontSize: 11, color: Colors.grey),
            ),
          ],
        ),
      ],
    );
  }
}


// --- STATS CEPAT (QUICK STATS) ---
class _QuickStats extends StatelessWidget {
  final int totalSiswa;
  final int hadirHariIni;
  final int terlambatHariIni;
  final int absenHariIni;
  final String rataRataBulanan;

  const _QuickStats({
    required this.totalSiswa,
    required this.hadirHariIni,
    required this.terlambatHariIni,
    required this.absenHariIni,
    required this.rataRataBulanan,
  });

  @override
  Widget build(BuildContext context) {
    // Hitung persentase
    final int totalHadir = hadirHariIni + terlambatHariIni;
    final String persenHadir = (totalSiswa > 0)
        ? '${((totalHadir / totalSiswa) * 100).toStringAsFixed(0)}%'
        : '0%';

    final stats = [
      {
        'value': persenHadir, // <-- Data dinamis
        'title': 'Kehadiran Hari Ini',
        'icon': Icons.people_outline,
        'color': const Color(0xFF42A5F5),
      },
      {
        'value': terlambatHariIni.toString(), // <-- Data dinamis
        'title': 'Siswa Terlambat',
        'icon': Icons.access_time,
        'color': const Color(0xFFFFA726),
      },
      {
        'value': absenHariIni.toString(), // <-- Data dinamis
        'title': 'Siswa Absen',
        'icon': Icons.person_off_outlined,
        'color': const Color(0xFFEF5350),
      },
      {
        'value': rataRataBulanan, // <-- Masih statis
        'title': 'Rata-rata Bulanan',
        'icon': Icons.pie_chart_outline,
        'color': const Color(0xFFAB47BC),
      },
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: 20,
        mainAxisSpacing: 20,
        childAspectRatio: 2,
      ),
      itemCount: stats.length,
      itemBuilder: (c, i) => _WhiteCard(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: (stats[i]['color'] as Color).withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                stats[i]['icon'] as IconData,
                color: stats[i]['color'] as Color,
                size: 28,
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    stats[i]['value'] as String,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Flexible(
                    child: Text(
                      stats[i]['title'] as String,
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- STATS DETAIL (DETAILED STATS) ---
class _DetailedStats extends StatelessWidget {
  final int totalSiswa;
  final int hadirHariIni;
  final int terlambatHariIni;
  final int absenHariIni;

  const _DetailedStats({
    required this.totalSiswa,
    required this.hadirHariIni,
    required this.terlambatHariIni,
    required this.absenHariIni,
  });

  @override
  Widget build(BuildContext context) {
    final int totalHadir = hadirHariIni + terlambatHariIni;
    final double persenHadir = (totalSiswa > 0)
        ? (totalHadir / totalSiswa)
        : 0.0;
    final double persenTerlambat = (totalSiswa > 0)
        ? (terlambatHariIni / totalSiswa)
        : 0.0;
    final double persenAbsen = (totalSiswa > 0)
        ? (absenHariIni / totalSiswa)
        : 0.0;

    final stats = [
      {
        'title': 'KEHADIRAN HARIAN',
        'value': '${(persenHadir * 100).toStringAsFixed(0)}%',
        'change': '',
        'positive': true,
        'progress': persenHadir,
        'subtitle': '$totalHadir/$totalSiswa Siswa',
        'detail': 'Hari ini',
        'color': const Color(0xFF66BB6A),
        'icon': Icons.check_circle_outline,
      },
      {
        'title': 'KETERLAMBATAN',
        'value': terlambatHariIni.toString(),
        'change': '',
        'positive': false,
        'progress': persenTerlambat,
        'subtitle': '${(persenTerlambat * 100).toStringAsFixed(1)}% dari total',
        'detail': 'Perlu perhatian',
        'color': const Color(0xFFFFA726),
        'icon': Icons.access_time,
      },
      {
        'title': 'KETIDAKHADIRAN',
        'value': absenHariIni.toString(),
        'change': '',
        'positive': true,
        'progress': persenAbsen,
        'subtitle': '${(persenAbsen * 100).toStringAsFixed(1)}% dari total',
        'detail': 'Perlu konfirmasi',
        'color': const Color(0xFFEF5350),
        'icon': Icons.person_off_outlined,
      },
    ];

    return Row(
      children: stats
          .map(
            (s) => Expanded(
              child: Padding(
                padding: EdgeInsets.only(right: s == stats.last ? 0 : 20),
                child: _DetailStatCard(s),
              ),
            ),
          )
          .toList(),
    );
  }
}

class _DetailStatCard extends StatelessWidget {
  final Map<String, dynamic> data;
  const _DetailStatCard(this.data);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border(top: BorderSide(color: data['color'], width: 3)),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                data['title'],
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey,
                  letterSpacing: 0.5,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: (data['color'] as Color).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(data['icon'], color: data['color'], size: 20),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            data['value'],
            style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          if (data['change'].isNotEmpty)
            Row(
              children: [
                Icon(
                  data['positive'] ? Icons.arrow_upward : Icons.arrow_downward,
                  color: data['positive'] ? Colors.green : Colors.red,
                  size: 14,
                ),
                const SizedBox(width: 4),
                Text(
                  data['change'],
                  style: TextStyle(
                    fontSize: 12,
                    color: data['positive'] ? Colors.green : Colors.red,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: data['progress'],
              backgroundColor: Colors.grey.shade200,
              color: data['color'],
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                data['subtitle'],
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
              Text(
                data['detail'],
                style: const TextStyle(fontSize: 11, color: Colors.grey),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// --- BAGIAN CHARTS ---
class _ChartsSection extends StatelessWidget {
  final List<Map<String, dynamic>> distribusiKelas;

  const _ChartsSection({required this.distribusiKelas});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(flex: 2, child: _StatistikKehadiranChart()),
        const SizedBox(width: 20),
        Expanded(child: _PieChartCard(distribusiData: distribusiKelas)),
      ],
    );
  }
}

// --- LINE CHART (BARU) ---
class _StatistikKehadiranChart extends StatefulWidget {
  const _StatistikKehadiranChart();

  @override
  State<_StatistikKehadiranChart> createState() =>
      _StatistikKehadiranChartState();
}

class _StatistikKehadiranChartState extends State<_StatistikKehadiranChart> {
  final SupabaseClient supabase = Supabase.instance.client;

  int _selectedFilterIndex = 0; // 0: Minggu, 1: Bulan, 2: Tahun
  final List<String> _filters = [
    'Hari Ini',
    'Minggu Ini',
    'Bulan Ini',
    'Tahun Ini',
  ];

  bool _isLoading = true;
  List<FlSpot> _spots = [];
  Map<double, String> _bottomTitles = {};
  double _maxY = 100; // Default
  double _minX = 0; // Default
  double _maxX = 6; // Default
  double _intervalX = 1; // Default

  @override
  void initState() {
    super.initState();
    _fetchChartData(_selectedFilterIndex);
  }

  Future<void> _fetchChartData(int index) async {
    setState(() => _isLoading = true);

    try {
      String rpcName;
      switch (index) {
        case 1: // Minggu
          rpcName = 'get_statistik_mingguan';
          break;
        case 2: // Bulan
          rpcName = 'get_statistik_bulanan';
          break;
        case 3: // Tahun
          rpcName = 'get_statistik_tahunan';
          break;
        case 0:
        default:
          rpcName = 'get_statistik_harian';
          break;
      }

      final List<dynamic> result = await supabase.rpc(rpcName);

      // --- PERBAIKAN LOGIKA ADA DI SINI ---

      List<FlSpot> spots = [];
      Map<double, String> titles = {};
      double i = 0;
      double maxVal = 0;

      // Cek jika hasilnya KOSONG (misal, tidak ada data sama sekali)
      if (result.isEmpty) {
        // Jangan error. Buat data default yang "kosong" tapi valid.
        spots.add(const FlSpot(0, 0)); // Satu titik di (0,0)
        titles[0] = 'N/A'; // Label default
        maxVal = 100; // Default max Y
        i = 1; // Set 'i' ke 1 agar maxX tidak negatif
      } else {
        // Jika ada data, proses seperti biasa
        for (var item in result) {
          final label = item['label'].toString();
          final value = double.tryParse(item['value'].toString()) ?? 0.0;

          spots.add(FlSpot(i, value));
          titles[i] = label;
          if (value > maxVal) maxVal = value;
          i++;
        }
      }

      setState(() {
        _spots = spots;
        _bottomTitles = titles;
        _minX = 0;
        _maxX = i - 1; // Sekarang ini minimal akan menjadi 0 (dari 1-1)

        // Atur maxY. Jika maxVal 0 (data kosong), set default ke 100.
        _maxY = (maxVal == 0) ? 100 : (maxVal * 1.2).ceilToDouble();

        _intervalX = (i > 12) ? (i / 12).floorToDouble() : 1;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error fetching chart data: $e');
      // Perbarui juga blok catch agar aman
      setState(() {
        _isLoading = false;
        _spots = [const FlSpot(0, 0)];
        _bottomTitles = {0: 'Error'};
        _minX = 0;
        _maxX = 0; // Pastikan maxX valid saat error
        _maxY = 100;
      });
    }
  }

  List<Widget> _buildFilters() {
    return List.generate(
      _filters.length,
      (i) => Padding(
        padding: EdgeInsets.only(left: i > 0 ? 8 : 0),
        child: InkWell(
          onTap: () {
            setState(() {
              _selectedFilterIndex = i;
            });
            _fetchChartData(i);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: i == _selectedFilterIndex
                  ? const Color(0xFF42A5F5)
                  : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              _filters[i],
              style: TextStyle(
                color: i == _selectedFilterIndex
                    ? Colors.white
                    : Colors.grey.shade600,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _WhiteCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.show_chart),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Statistik Kehadiran',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 10),
              Flexible(
                child: Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: _buildFilters(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 250,
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : LineChart(
                    LineChartData(
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        horizontalInterval: _maxY / 5,
                        getDrawingHorizontalLine: (v) =>
                            FlLine(color: Colors.grey.shade200, strokeWidth: 1),
                      ),
                      titlesData: FlTitlesData(
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            interval: _intervalX,
                            getTitlesWidget: (value, meta) {
                              final title = _bottomTitles[value.toDouble()];
                              if (title == null) return const SizedBox();
                              return Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(
                                  title,
                                  style: const TextStyle(
                                    color: Colors.grey,
                                    fontSize: 12,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            interval: _maxY / 5,
                            reservedSize: 40,
                            getTitlesWidget: (v, _) => Text(
                              '${v.toInt()}%',
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                        rightTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        topTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      minX: _minX,
                      maxX: _maxX,
                      minY: 0,
                      maxY: _maxY,
                      lineBarsData: [
                        LineChartBarData(
                          spots: _spots,
                          isCurved: true,
                          color: const Color(0xFF42A5F5),
                          barWidth: 3,
                          dotData: FlDotData(
                            show: true,
                            getDotPainter: (_, __, ___, ____) =>
                                FlDotCirclePainter(
                                  radius: 4,
                                  color: Colors.white,
                                  strokeWidth: 2,
                                  strokeColor: const Color(0xFF42A5F5),
                                ),
                          ),
                          belowBarData: BarAreaData(
                            show: true,
                            color: const Color(0xFF42A5F5).withOpacity(0.1),
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

// --- PIE CHART (BARU) ---
class _PieChartCard extends StatelessWidget {
  final List<Map<String, dynamic>> distribusiData;

  const _PieChartCard({required this.distribusiData});

  @override
  Widget build(BuildContext context) {
    final double totalSiswa = distribusiData.fold(
      0.0,
      (sum, item) => sum + (item['value'] as double),
    );

    return _WhiteCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.pie_chart_outline),
              SizedBox(width: 10),
              Text(
                'Distribusi per Kelas',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 200,
            child: PieChart(
              PieChartData(
                sectionsSpace: 2,
                centerSpaceRadius: 50,
                sections: distribusiData.map((d) {
                  final percent = (d['value'] / totalSiswa * 100);
                  return PieChartSectionData(
                    value: d['value'] as double,
                    color: d['color'] as Color,
                    title: percent > 5 ? '${percent.toStringAsFixed(0)}%' : '',
                    radius: 60,
                    titleStyle: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 20),
          ...distribusiData.map(
            (d) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: d['color'] as Color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    d['label'] as String,
                    style: const TextStyle(fontSize: 13),
                  ),
                  const Spacer(),
                  Text(
                    '${(d['value'] as double).toInt()} siswa',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// --- BAGIAN BAWAH (ALERTS & ACTIVITY) ---
class _BottomSection extends StatelessWidget {
  final List<Map<String, dynamic>> alerts;
  final List<Map<String, dynamic>> activities;

  const _BottomSection({required this.alerts, required this.activities});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(flex: 2, child: _AlertsCard(alerts: alerts)),
        const SizedBox(width: 20),
        Expanded(child: _ActivityCard(activities: activities)),
      ],
    );
  }
}

class _AlertsCard extends StatelessWidget {
  final List<Map<String, dynamic>> alerts;
  const _AlertsCard({required this.alerts});

  @override
  Widget build(BuildContext context) {
    return _WhiteCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.notifications_outlined),
              SizedBox(width: 10),
              Text(
                'Peringatan Sistem',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ...alerts.map(
            (a) => Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _AlertItem(a),
            ),
          ),
        ],
      ),
    );
  }
}

class _AlertItem extends StatelessWidget {
  final Map<String, dynamic> data;
  const _AlertItem(this.data);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: (data['color'] as Color).withOpacity(0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: (data['color'] as Color).withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: data['color'],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(data['icon'], color: Colors.white, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data['title'],
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  data['subtitle'],
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActivityCard extends StatelessWidget {
  final List<Map<String, dynamic>> activities;
  const _ActivityCard({required this.activities});

  IconData _getIconForStatus(String? status) {
    switch (status?.toLowerCase()) {
      case 'hadir':
      case 'pulang': // <-- Tambahkan 'pulang'
        return Icons.check_circle;
      case 'terlambat':
        return Icons.access_time;
      case 'sakit':
      case 'izin':
        return Icons.mail_outline;
      case 'alfa':
        return Icons.cancel;
      default:
        return Icons.qr_code;
    }
  }

  Color _getColorForStatus(String? status) {
    switch (status?.toLowerCase()) {
      case 'hadir':
      case 'pulang': // <-- Tambahkan 'pulang'
        return const Color(0xFF66BB6A);
      case 'terlambat':
        return const Color(0xFFFFA726);
      case 'sakit':
      case 'izin':
        return const Color(0xFF42A5F5);
      case 'alfa':
        return const Color(0xFFEF5350);
      default:
        return Colors.grey;
    }
  }

  String _formatTimeAgo(String? isoString) {
    if (isoString == null) return '';
    try {
      final dateTime = DateTime.parse(isoString).toLocal();
      final difference = DateTime.now().difference(dateTime);

      if (difference.inMinutes < 60) {
        return '${difference.inMinutes} menit yang lalu';
      } else if (difference.inHours < 24) {
        return '${difference.inHours} jam yang lalu';
      } else {
        return DateFormat('dd MMM yyyy, HH:mm').format(dateTime);
      }
    } catch (e) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return _WhiteCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.update),
              SizedBox(width: 10),
              Text(
                'Aktivitas Terbaru',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ...activities.map((a) {
            final status = a['status'] as String?;
            final namaSiswa = (a['siswa'] is Map)
                ? (a['siswa']['nama'] ?? 'Siswa tidak dikenal')
                : 'Siswa tidak dikenal';
            final waktuMasuk = a['waktu_masuk'] as String?;
            final createdAt = a['created_at'] as String?;

            final title =
                '$namaSiswa ${status?.toLowerCase() ?? 'melakukan scan'}';
            final subtitle =
                'Scan pada ${waktuMasuk ?? DateFormat("HH:mm").format(DateTime.parse(createdAt!).toLocal())}';
            final time = _formatTimeAgo(createdAt);
            final icon = _getIconForStatus(status);
            final color = _getColorForStatus(status);

            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(icon, color: color, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          subtitle,
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          time,
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

// --- WIDGET DASAR (BASE CARD) ---
class _WhiteCard extends StatelessWidget {
  final Widget child;
  const _WhiteCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }
}
