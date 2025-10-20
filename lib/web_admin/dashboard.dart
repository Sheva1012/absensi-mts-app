// BARU: Import supabase dan intl (untuk format tanggal)
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

// MODIFIKASI: Ubah dari StatelessWidget menjadi StatefulWidget
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  // BARU: Instance Supabase dan state untuk data
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

    // GANTI: Panggil .onPostgresChanges dan masukkan 'callback'
    _absensiChannel
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'absensi',

          // INI YANG HILANG: parameter 'callback' wajib ada
          callback: (payload) {
            // 'payload' berisi data yg berubah
            debugPrint(
              'Perubahan terdeteksi di tabel absensi! (payload: $payload)',
            );

            // Panggil ulang fungsi fetch data
            if (mounted) {
              _fetchDashboardData();
            }
          },
        )
        // 3. Panggil .subscribe() di akhir untuk mengaktifkan listener
        .subscribe();
  }

  // BARU: Fungsi utama untuk mengambil dan menghitung data
  Future<void> _fetchDashboardData() async {
    if (!mounted) return;

    // Set loading hanya jika data belum ada
    if (_totalSiswa == 0) {
      setState(() => _isLoading = true);
    }

    try {
      // 1. Dapatkan tanggal hari ini dalam format YYYY-MM-DD
      final String tglHariIni = DateFormat('yyyy-MM-dd').format(DateTime.now());

      // 2. Hitung total siswa (Count)
      final totalSiswaRes = await supabase.from('siswa').count();
      final totalSiswa = totalSiswaRes;

      // 3. Ambil data absensi hari ini
      final absensiRes = await supabase
          .from('absensi')
          .select()
          .eq('tanggal', tglHariIni);

      // 4. Ambil 5 aktivitas terbaru (join dengan siswa)
      final aktivitasRes = await supabase
          .from('absensi')
          .select('*, siswa (nama)') // Join dengan tabel siswa
          .order('created_at', ascending: false)
          .limit(5);

      // 5. Hitung statistik
      int hadir = 0;
      int terlambat = 0;
      int absen = 0;

      for (var data in absensiRes) {
        final status = data['status']?.toString().toLowerCase();
        if (status == 'hadir') {
          hadir++;
        } else if (status == 'terlambat') {
          terlambat++;
        } else if (status == 'sakit' || status == 'izin' || status == 'alfa') {
          absen++;
        }
      }

      // 6. Update state
      setState(() {
        _totalSiswa = totalSiswa;
        _hadirHariIni = hadir;
        _terlambatHariIni = terlambat;
        _absenHariIni = absen;
        _aktivitasTerbaru = List<Map<String, dynamic>>.from(aktivitasRes);
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error fetching dashboard data: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memuat data dashboard: $e'),
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
                  const _WelcomeCard(), // Welcome card tetap statis
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
                  const _ChartsSection(), // Chart masih statis (dummy)
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

// ... Widget _AppHeader, _SearchBar, _NotificationBadge, _ProfileSection, _WelcomeCard ...
// (Tidak ada perubahan pada widget-widget ini, biarkan apa adanya)
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

class _WelcomeCard extends StatelessWidget {
  const _WelcomeCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF42A5F5), Color(0xFF1E88E5)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF42A5F5).withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Selamat Datang, Admin!',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Sistem Manajemen Absensi MTs Sunan Gunung Jati - Pantau kehadiran siswa secara real-time dan kelola data dengan mudah.',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 30),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.analytics_outlined,
              size: 60,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

// MODIFIKASI: Widget ini sekarang menerima data dinamis
class _QuickStats extends StatelessWidget {
  // BARU: Tambahkan parameter
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
    // BARU: Hitung persentase
    final int totalHadir = hadirHariIni + terlambatHariIni;
    final String persenHadir = (totalSiswa > 0)
        ? '${((totalHadir / totalSiswa) * 100).toStringAsFixed(0)}%'
        : '0%';

    // MODIFIKASI: Gunakan data dinamis
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
        'value': rataRataBulanan, // <-- Masih statis, bisa dikembangkan
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

// MODIFIKASI: Widget ini sekarang menerima data dinamis
class _DetailedStats extends StatelessWidget {
  // BARU: Tambahkan parameter
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
    // BARU: Hitung statistik detail
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

    // MODIFIKASI: Gunakan data dinamis
    final stats = [
      {
        'title': 'KEHADIRAN HARIAN',
        'value': '${(persenHadir * 100).toStringAsFixed(0)}%', // <-- Dinamis
        'change': '', // (Bisa ditambahkan jika ada perbandingan)
        'positive': true,
        'progress': persenHadir, // <-- Dinamis
        'subtitle': '$totalHadir/$totalSiswa Siswa', // <-- Dinamis
        'detail': 'Hari ini',
        'color': const Color(0xFF66BB6A),
        'icon': Icons.check_circle_outline,
      },
      {
        'title': 'KETERLAMBATAN',
        'value': terlambatHariIni.toString(), // <-- Dinamis
        'change': '',
        'positive': false,
        'progress': persenTerlambat, // <-- Dinamis
        'subtitle':
            '${(persenTerlambat * 100).toStringAsFixed(1)}% dari total', // <-- Dinamis
        'detail': 'Perlu perhatian',
        'color': const Color(0xFFFFA726),
        'icon': Icons.access_time,
      },
      {
        'title': 'KETIDAKHADIRAN',
        'value': absenHariIni.toString(), // <-- Dinamis
        'change': '',
        'positive': true,
        'progress': persenAbsen, // <-- Dinamis
        'subtitle':
            '${(persenAbsen * 100).toStringAsFixed(1)}% dari total', // <-- Dinamis
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

// MODIFIKASI: Widget ini sekarang menerima data statis
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
          // Hanya tampilkan jika ada data 'change'
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

// ... Widget _ChartsSection, _LineChartCard, _PieChartCard, _buildFilters ...
// (Tidak ada perubahan pada widget-widget ini, biarkan apa adanya)
// (Data chart masih statis/dummy)
class _ChartsSection extends StatelessWidget {
  const _ChartsSection();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: const [
        Expanded(flex: 2, child: _LineChartCard()),
        SizedBox(width: 20),
        Expanded(child: _PieChartCard()),
      ],
    );
  }
}

class _LineChartCard extends StatelessWidget {
  const _LineChartCard();

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
              const Text(
                'Statistik Kehadiran 7 Hari Terakhir',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              ..._buildFilters(['Minggu Ini', 'Bulan Ini', 'Tahun Ini'], 0),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 250,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 20,
                  getDrawingHorizontalLine: (v) =>
                      FlLine(color: Colors.grey.shade200, strokeWidth: 1),
                ),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 1,
                      getTitlesWidget: (v, _) => Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          [
                            'Sen',
                            'Sel',
                            'Rab',
                            'Kam',
                            'Jum',
                            'Sab',
                            'Min',
                          ][v.toInt() % 7],
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 20,
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
                minX: 0,
                maxX: 6,
                minY: 0,
                maxY: 100,
                lineBarsData: [
                  LineChartBarData(
                    spots: const [
                      FlSpot(0, 80),
                      FlSpot(1, 85),
                      FlSpot(2, 78),
                      FlSpot(3, 90),
                      FlSpot(4, 88),
                      FlSpot(5, 92),
                      FlSpot(6, 86),
                    ],
                    isCurved: true,
                    color: const Color(0xFF42A5F5),
                    barWidth: 3,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (_, __, ___, ____) => FlDotCirclePainter(
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

class _PieChartCard extends StatelessWidget {
  const _PieChartCard();

  @override
  Widget build(BuildContext context) {
    final data = [
      {'label': 'Kelas 7', 'value': 35.0, 'color': const Color(0xFF42A5F5)},
      {'label': 'Kelas 8', 'value': 40.0, 'color': const Color(0xFF66BB6A)},
      {'label': 'Kelas 9', 'value': 25.0, 'color': const Color(0xFFAB47BC)},
    ];

    return _WhiteCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.pie_chart_outline),
              const SizedBox(width: 10),
              const Text(
                'Distribusi per Kelas',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(children: _buildFilters(['Hari Ini', 'Minggu Ini'], 0)),
          const SizedBox(height: 24),
          SizedBox(
            height: 200,
            child: PieChart(
              PieChartData(
                sectionsSpace: 2,
                centerSpaceRadius: 50,
                sections: data
                    .map(
                      (d) => PieChartSectionData(
                        value: d['value'] as double,
                        color: d['color'] as Color,
                        title: '${(d['value'] as double).toInt()}%',
                        radius: 60,
                        titleStyle: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
          ),
          const SizedBox(height: 20),
          ...data.map(
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
                    '${(d['value'] as double).toInt()}%',
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

List<Widget> _buildFilters(List<String> labels, int selected) {
  return List.generate(
    labels.length,
    (i) => Padding(
      padding: EdgeInsets.only(left: i > 0 ? 8 : 0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: i == selected ? const Color(0xFF42A5F5) : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          labels[i],
          style: TextStyle(
            color: i == selected ? Colors.white : Colors.grey.shade600,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    ),
  );
}

// MODIFIKASI: Widget ini sekarang menerima data dinamis
class _BottomSection extends StatelessWidget {
  // BARU: Tambahkan parameter
  final List<Map<String, dynamic>> alerts;
  final List<Map<String, dynamic>> activities;

  const _BottomSection({required this.alerts, required this.activities});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // MODIFIKASI: Kirim data 'alerts'
        Expanded(flex: 2, child: _AlertsCard(alerts: alerts)),
        const SizedBox(width: 20),
        // MODIFIKASI: Kirim data 'activities'
        Expanded(child: _ActivityCard(activities: activities)),
      ],
    );
  }
}

// MODIFIKASI: Widget ini sekarang menerima data dinamis
class _AlertsCard extends StatelessWidget {
  // BARU: Tambahkan parameter
  final List<Map<String, dynamic>> alerts;
  const _AlertsCard({required this.alerts});

  @override
  Widget build(BuildContext context) {
    // MODIFIKASI: Hapus data statis
    // final alerts = [ ... ];

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
          // MODIFIKASI: Gunakan data dari 'widget.alerts'
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

// Widget ini tidak berubah, karena ia menerima Map
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

// MODIFIKASI: Widget ini sekarang menerima data dinamis
class _ActivityCard extends StatelessWidget {
  // BARU: Tambahkan parameter
  final List<Map<String, dynamic>> activities;
  const _ActivityCard({required this.activities});

  // BARU: Helper untuk menentukan ikon dan warna berdasarkan status
  IconData _getIconForStatus(String? status) {
    switch (status?.toLowerCase()) {
      case 'hadir':
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

  // BARU: Helper untuk format waktu (time ago) sederhana
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
          // MODIFIKASI: Gunakan data dinamis 'widget.activities'
          ...activities.map((a) {
            // BARU: Ekstrak data dari map Supabase
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

// Widget ini tidak berubah
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
