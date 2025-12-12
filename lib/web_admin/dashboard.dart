import 'dart:async';

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

  RealtimeChannel? _absensiChannel;
  Timer? _refreshDebounce;

  bool _isLoading = true;
  String? _errorMessage;
  DateTime? _lastUpdated;

  // Quick Stats (Hari ini)
  int _totalSiswaAktif = 0;
  int _hadirHariIni = 0;
  int _terlambatHariIni = 0;
  int _absenHariIni = 0;

  // Aktivitas + Alerts
  List<Map<String, dynamic>> _aktivitasTerbaru = [];
  List<Map<String, dynamic>> _alerts = [];

  // Distribusi kelas
  List<Map<String, dynamic>> _distribusiKelas = [];

  // Rekapan semester
  int _hadirSemester = 0;
  int _terlambatSemester = 0;
  int _absenSemester = 0;
  int _totalHariSemester = 0;

  final List<Color> _pieColors = const [
    Color(0xFF42A5F5),
    Color(0xFF66BB6A),
    Color(0xFFAB47BC),
    Color(0xFFFFA726),
    Color(0xFFEF5350),
    Color(0xFF26C6DA),
    Color(0xFF7E57C2),
    Color(0xFFD4E157),
  ];

  @override
  void initState() {
    super.initState();
    Intl.defaultLocale = 'id_ID';
    _initializeDashboard();
  }

  @override
  void dispose() {
    _refreshDebounce?.cancel();
    final ch = _absensiChannel;
    if (ch != null) supabase.removeChannel(ch);
    super.dispose();
  }

  Future<void> _initializeDashboard() async {
    await _fetchDashboardData(showLoadingOverlay: true);

    // Realtime listener: debounce agar tidak spam fetch
    _absensiChannel = supabase.channel('public:absensi');

    _absensiChannel!
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'absensi',
          callback: (_) {
            _refreshDebounce?.cancel();
            _refreshDebounce = Timer(const Duration(milliseconds: 500), () {
              if (mounted) _fetchDashboardData(showLoadingOverlay: false);
            });
          },
        )
        .subscribe();
  }

  // =========================
  // DATA CONSISTENCY HELPERS
  // =========================
  String _normStatus(dynamic s) => (s ?? '').toString().trim().toLowerCase();

  bool _isHadirLike(String status) => status == 'hadir' || status == 'pulang';

  bool _isAbsenLike(String status) =>
      status == 'sakit' || status == 'izin' || status == 'alfa';

  // =========================
  // FETCH
  // =========================
  Future<void> _fetchDashboardData({required bool showLoadingOverlay}) async {
    if (!mounted) return;

    if (showLoadingOverlay) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    } else {
      // keep UI stable; update quietly
      setState(() => _errorMessage = null);
    }

    try {
      final now = DateTime.now();
      final tglHariIni = DateFormat('yyyy-MM-dd').format(now);

      // Semester: Jan-Jun (semester genap) / Jul-Dec (semester ganjil)
      final currentYear = now.year;
      final bool isJanToJun = now.month >= 1 && now.month <= 6;

      final tglMulaiSemester = DateFormat('yyyy-MM-dd').format(
        DateTime(currentYear, isJanToJun ? 1 : 7, 1),
      );

      final tglAkhirSemester = DateFormat('yyyy-MM-dd').format(
        DateTime(currentYear, isJanToJun ? 6 : 12, isJanToJun ? 30 : 31),
      );

      // 1) Total siswa aktif (lebih aman compile: select id lalu length)
      final siswaRes =
          await supabase.from('siswa').select('id').eq('status', 'aktif');
      final totalSiswaAktif = (siswaRes as List).length;

      // 2) Absensi hari ini (ambil minimal kolom yang dibutuhkan)
      final absensiHariIni = await supabase
          .from('absensi')
          .select('status, created_at, waktu_masuk, siswa_id')
          .eq('tanggal', tglHariIni);

      // 3) Aktivitas terbaru (join siswa)
      final aktivitasRes = await supabase
          .from('absensi')
          .select('status, created_at, waktu_masuk, siswa(nama)')
          .order('created_at', ascending: false)
          .limit(6);

      // 4) Distribusi kelas (kelas dengan count siswa)
      final distribusiRes =
          await supabase.from('kelas').select('id, nama_kelas, siswa(count)');

      // 5) Rekapan semester (status + tanggal)
      final rekapanSemesterRes = await supabase
          .from('absensi')
          .select('status, tanggal')
          .gte('tanggal', tglMulaiSemester)
          .lte('tanggal', tglAkhirSemester);

      // =========================
      // PROCESS: HARI INI
      // =========================
      int hadir = 0;
      int terlambat = 0;
      int absen = 0;

      int inputLuarJam = 0;
      int totalTerlambatHariIni = 0;

      for (final row in (absensiHariIni as List)) {
        final status = _normStatus(row['status']);

        if (_isHadirLike(status)) {
          hadir++;
        } else if (status == 'terlambat') {
          terlambat++;
          totalTerlambatHariIni++;
        } else if (_isAbsenLike(status)) {
          absen++;
        }

        final createdAt = row['created_at']?.toString();
        if (createdAt != null) {
          final dt = DateTime.tryParse(createdAt)?.toLocal();
          if (dt != null) {
            if (dt.hour < 6 || dt.hour >= 17) inputLuarJam++;
          }
        }
      }

      // =========================
      // PROCESS: DISTRIBUSI KELAS
      // =========================
      final List<Map<String, dynamic>> distribusiData = [];
      int colorIndex = 0;

      for (final item in (distribusiRes as List)) {
        final siswaCountList = item['siswa'];
        final int count = (siswaCountList is List && siswaCountList.isNotEmpty)
            ? (siswaCountList[0]['count'] as int? ?? 0)
            : 0;

        if (count > 0) {
          distribusiData.add({
            'label': (item['nama_kelas'] ?? '-').toString(),
            'value': count.toDouble(),
            'color': _pieColors[colorIndex % _pieColors.length],
          });
          colorIndex++;
        }
      }

      // =========================
      // PROCESS: SEMESTER
      // =========================
      int hadirSem = 0;
      int terlambatSem = 0;
      int absenSem = 0;
      final Set<String> hariUnik = {};

      for (final row in (rekapanSemesterRes as List)) {
        final status = _normStatus(row['status']);
        final tgl = row['tanggal']?.toString();
        if (tgl != null) hariUnik.add(tgl);

        if (_isHadirLike(status)) {
          hadirSem++;
        } else if (status == 'terlambat') {
          terlambatSem++;
        } else if (_isAbsenLike(status)) {
          absenSem++;
        }
      }

      // =========================
      // ALERTS (konsisten, deterministic)
      // =========================
      final List<Map<String, dynamic>> anomalyAlerts = [];

      if (inputLuarJam > 0) {
        anomalyAlerts.add({
          'icon': Icons.access_time_filled,
          'color': const Color(0xFFEF5350),
          'title': 'Aktivitas Luar Jam Operasional',
          'subtitle': 'Terdeteksi $inputLuarJam data diinput di luar jam sekolah.',
        });
      }

      if (now.weekday == DateTime.sunday && (absensiHariIni as List).isNotEmpty) {
        anomalyAlerts.add({
          'icon': Icons.event_busy,
          'color': const Color(0xFFFFA726),
          'title': 'Aktivitas di Hari Libur',
          'subtitle': 'Terdeteksi input absensi pada hari Minggu.',
        });
      }

      if (totalSiswaAktif > 0) {
        final p = totalTerlambatHariIni / totalSiswaAktif;
        if (p > 0.20) {
          anomalyAlerts.add({
            'icon': Icons.warning_rounded,
            'color': const Color(0xFF7E57C2),
            'title': 'Lonjakan Keterlambatan',
            'subtitle': 'Lebih dari 20% siswa terlambat hari ini.',
          });
        }
      }

      if (anomalyAlerts.isEmpty) {
        anomalyAlerts.add({
          'icon': Icons.verified_user,
          'color': const Color(0xFF66BB6A),
          'title': 'Sistem Berjalan Normal',
          'subtitle': 'Tidak ditemukan anomali pada data absensi hari ini.',
        });
      }

      // =========================
      // APPLY STATE
      // =========================
      if (!mounted) return;
      setState(() {
        _totalSiswaAktif = totalSiswaAktif;

        _hadirHariIni = hadir;
        _terlambatHariIni = terlambat;
        _absenHariIni = absen;

        _aktivitasTerbaru = List<Map<String, dynamic>>.from(aktivitasRes as List);
        _distribusiKelas = distribusiData;

        _hadirSemester = hadirSem;
        _terlambatSemester = terlambatSem;
        _absenSemester = absenSem;
        _totalHariSemester = hariUnik.length;

        _alerts = anomalyAlerts;

        _lastUpdated = DateTime.now();
        _isLoading = false;
        _errorMessage = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal memuat dashboard: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // =========================
  // UI
  // =========================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: () => _fetchDashboardData(showLoadingOverlay: false),
                child: LayoutBuilder(
                  builder: (context, c) {
                    final w = c.maxWidth;

                    // Responsive breakpoints
                    final bool isMobile = w < 700;
                    final bool isTablet = w >= 700 && w < 1100;

                    return SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: EdgeInsets.all(isMobile ? 14 : 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _AppHeader(
                            lastUpdated: _lastUpdated,
                            errorMessage: _errorMessage,
                            onRefresh: () => _fetchDashboardData(
                              showLoadingOverlay: false,
                            ),
                          ),
                          const SizedBox(height: 16),

                          _SectionTitle(
                            title: 'Ringkasan Hari Ini',
                            subtitle: 'Konsisten dengan siswa aktif dan status absensi.',
                          ),
                          const SizedBox(height: 12),

                          _QuickStatsResponsive(
                            isMobile: isMobile,
                            isTablet: isTablet,
                            totalSiswa: _totalSiswaAktif,
                            hadirHariIni: _hadirHariIni,
                            terlambatHariIni: _terlambatHariIni,
                            absenHariIni: _absenHariIni,
                          ),

                          const SizedBox(height: 18),

                          _SectionTitle(
                            title: 'Rekapan Semester',
                            subtitle: 'Menghitung total potensi kehadiran berdasarkan hari unik yang memiliki data.',
                          ),
                          const SizedBox(height: 12),

                          _DetailedStatsResponsive(
                            isMobile: isMobile,
                            totalSiswa: _totalSiswaAktif,
                            hadirSemester: _hadirSemester,
                            terlambatSemester: _terlambatSemester,
                            absenSemester: _absenSemester,
                            totalHariSemester: _totalHariSemester,
                          ),

                          const SizedBox(height: 18),

                          _SectionTitle(
                            title: 'Visualisasi',
                            subtitle: 'Tren dan distribusi untuk membantu keputusan.',
                          ),
                          const SizedBox(height: 12),

                          _ChartsSectionResponsive(
                            isMobile: isMobile,
                            distribusiKelas: _distribusiKelas,
                          ),

                          const SizedBox(height: 18),

                          _SectionTitle(
                            title: 'Monitoring',
                            subtitle: 'Peringatan sistem dan aktivitas terbaru.',
                          ),
                          const SizedBox(height: 12),

                          _BottomSectionResponsive(
                            isMobile: isMobile,
                            alerts: _alerts,
                            activities: _aktivitasTerbaru,
                          ),

                          const SizedBox(height: 24),
                        ],
                      ),
                    );
                  },
                ),
              ),
      ),
    );
  }
}

// ============================================================================
// UI COMPONENTS (lebih konsisten & responsive)
// ============================================================================

class _SectionTitle extends StatelessWidget {
  final String title;
  final String subtitle;

  const _SectionTitle({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 2),
          Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        ],
      ),
    );
  }
}

class _AppHeader extends StatelessWidget {
  final DateTime? lastUpdated;
  final String? errorMessage;
  final VoidCallback onRefresh;

  const _AppHeader({
    required this.lastUpdated,
    required this.errorMessage,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final last = lastUpdated == null ? '-' : DateFormat('dd MMM yyyy, HH:mm').format(lastUpdated!);

    return _WhiteCard(
      child: Row(
        children: [
          const Icon(Icons.dashboard_rounded, color: Color(0xFF42A5F5)),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'Dashboard Admin',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('Terakhir update', style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
              Text(last, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(width: 12),
          IconButton(
            tooltip: 'Refresh',
            onPressed: onRefresh,
            icon: const Icon(Icons.refresh),
          ),
          const SizedBox(width: 6),
          const _ProfileSection(),
          if (errorMessage != null) ...[
            const SizedBox(width: 10),
            Tooltip(
              message: errorMessage!,
              child: const Icon(Icons.error_outline, color: Colors.red),
            ),
          ],
        ],
      ),
    );
  }
}

class _ProfileSection extends StatelessWidget {
  const _ProfileSection();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const CircleAvatar(
          radius: 16,
          backgroundColor: Color(0xFF42A5F5),
          child: Text(
            "A",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
          ),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: const [
            Text("Admin", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
            Text("MTs Sunan Gunung Jati", style: TextStyle(fontSize: 11, color: Colors.grey)),
          ],
        ),
      ],
    );
  }
}

class _QuickStatsResponsive extends StatelessWidget {
  final bool isMobile;
  final bool isTablet;

  final int totalSiswa;
  final int hadirHariIni;
  final int terlambatHariIni;
  final int absenHariIni;

  const _QuickStatsResponsive({
    required this.isMobile,
    required this.isTablet,
    required this.totalSiswa,
    required this.hadirHariIni,
    required this.terlambatHariIni,
    required this.absenHariIni,
  });

  @override
  Widget build(BuildContext context) {
    final totalHadir = hadirHariIni + terlambatHariIni;
    final persenHadir = (totalSiswa > 0) ? ((totalHadir / totalSiswa) * 100).toStringAsFixed(0) : '0';

    final cards = [
      _StatCardData(
        title: 'Kehadiran Hari Ini',
        value: '$persenHadir%',
        subtitle: '$totalHadir dari $totalSiswa siswa aktif',
        icon: Icons.people_outline,
        color: const Color(0xFF42A5F5),
      ),
      _StatCardData(
        title: 'Terlambat',
        value: terlambatHariIni.toString(),
        subtitle: 'Hari ini',
        icon: Icons.access_time,
        color: const Color(0xFFFFA726),
      ),
      _StatCardData(
        title: 'Absen',
        value: absenHariIni.toString(),
        subtitle: 'Sakit / Izin / Alfa',
        icon: Icons.person_off_outlined,
        color: const Color(0xFFEF5350),
      ),
      _StatCardData(
        title: 'Total Siswa Aktif',
        value: totalSiswa.toString(),
        subtitle: 'Status: aktif',
        icon: Icons.school_outlined,
        color: const Color(0xFFAB47BC),
      ),
    ];

    int crossAxisCount = 4;
    double childAspect = 2.3;

    if (isMobile) {
      crossAxisCount = 1;
      childAspect = 3.2;
    } else if (isTablet) {
      crossAxisCount = 2;
      childAspect = 2.6;
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: cards.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: childAspect,
      ),
      itemBuilder: (_, i) => _StatCard(cards[i]),
    );
  }
}

class _StatCardData {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;

  _StatCardData({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
  });
}

class _StatCard extends StatelessWidget {
  final _StatCardData data;
  const _StatCard(this.data);

  @override
  Widget build(BuildContext context) {
    return _WhiteCard(
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: data.color.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(data.icon, color: data.color, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(data.value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 2),
                Text(data.title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(data.subtitle, style: const TextStyle(fontSize: 11, color: Colors.grey), overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailedStatsResponsive extends StatelessWidget {
  final bool isMobile;

  final int totalSiswa;
  final int hadirSemester;
  final int terlambatSemester;
  final int absenSemester;
  final int totalHariSemester;

  const _DetailedStatsResponsive({
    required this.isMobile,
    required this.totalSiswa,
    required this.hadirSemester,
    required this.terlambatSemester,
    required this.absenSemester,
    required this.totalHariSemester,
  });

  @override
  Widget build(BuildContext context) {
    final totalPotensi = (totalSiswa * totalHariSemester).toDouble();
    final totalHadir = hadirSemester + terlambatSemester;

    if (totalPotensi == 0) {
      return _WhiteCard(
        child: SizedBox(
          height: 140,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.info_outline, color: Colors.grey.shade400, size: 40),
                const SizedBox(height: 10),
                const Text(
                  'Data rekapan semester belum tersedia.',
                  style: TextStyle(fontSize: 13, color: Colors.grey),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final pHadir = totalPotensi > 0 ? totalHadir / totalPotensi : 0.0;
    final pTerlambat = totalPotensi > 0 ? terlambatSemester / totalPotensi : 0.0;
    final pAbsen = totalPotensi > 0 ? absenSemester / totalPotensi : 0.0;

    final cards = [
      _DetailCardData(
        title: 'Rata-rata Kehadiran',
        value: '${(pHadir * 100).toStringAsFixed(0)}%',
        subtitle: '$totalHadir dari ${totalPotensi.toInt()} potensi',
        color: const Color(0xFF66BB6A),
        icon: Icons.check_circle_outline,
        progress: pHadir,
      ),
      _DetailCardData(
        title: 'Total Keterlambatan',
        value: terlambatSemester.toString(),
        subtitle: '${(pTerlambat * 100).toStringAsFixed(1)}% dari total',
        color: const Color(0xFFFFA726),
        icon: Icons.access_time,
        progress: pTerlambat,
      ),
      _DetailCardData(
        title: 'Total Ketidakhadiran',
        value: absenSemester.toString(),
        subtitle: '${(pAbsen * 100).toStringAsFixed(1)}% dari total',
        color: const Color(0xFFEF5350),
        icon: Icons.person_off_outlined,
        progress: pAbsen,
      ),
      _DetailCardData(
        title: 'Hari (berdasarkan data)',
        value: totalHariSemester.toString(),
        subtitle: 'Hari unik yang memiliki input',
        color: const Color(0xFF42A5F5),
        icon: Icons.calendar_today,
        progress: 1.0,
      ),
    ];

    if (isMobile) {
      return Column(
        children: [
          for (int i = 0; i < cards.length; i++) ...[
            _DetailStatCard(cards[i]),
            if (i != cards.length - 1) const SizedBox(height: 12),
          ],
        ],
      );
    }

    return Row(
      children: [
        for (int i = 0; i < cards.length; i++) ...[
          Expanded(child: _DetailStatCard(cards[i])),
          if (i != cards.length - 1) const SizedBox(width: 12),
        ],
      ],
    );
  }
}

class _DetailCardData {
  final String title;
  final String value;
  final String subtitle;
  final Color color;
  final IconData icon;
  final double progress;

  _DetailCardData({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.color,
    required this.icon,
    required this.progress,
  });
}

class _DetailStatCard extends StatelessWidget {
  final _DetailCardData data;
  const _DetailStatCard(this.data);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border(top: BorderSide(color: data.color, width: 3)),
        boxShadow: [
          BoxShadow(color: Colors.grey.withValues(alpha: 0.08), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  data.title.toUpperCase(),
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.grey, letterSpacing: 0.4),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: data.color.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(data.icon, color: data.color, size: 20),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(data.value, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(data.subtitle, style: const TextStyle(fontSize: 12, color: Colors.grey), overflow: TextOverflow.ellipsis),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: data.progress.clamp(0.0, 1.0),
              minHeight: 7,
              backgroundColor: Colors.grey.shade200,
              color: data.color,
            ),
          ),
        ],
      ),
    );
  }
}

class _ChartsSectionResponsive extends StatelessWidget {
  final bool isMobile;
  final List<Map<String, dynamic>> distribusiKelas;

  const _ChartsSectionResponsive({
    required this.isMobile,
    required this.distribusiKelas,
  });

  @override
  Widget build(BuildContext context) {
    if (isMobile) {
      return Column(
        children: [
          const _StatistikKehadiranChart(),
          const SizedBox(height: 12),
          _PieChartCard(distribusiData: distribusiKelas),
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Expanded(flex: 2, child: _StatistikKehadiranChart()),
        const SizedBox(width: 12),
        Expanded(child: _PieChartCard(distribusiData: distribusiKelas)),
      ],
    );
  }
}

class _BottomSectionResponsive extends StatelessWidget {
  final bool isMobile;
  final List<Map<String, dynamic>> alerts;
  final List<Map<String, dynamic>> activities;

  const _BottomSectionResponsive({
    required this.isMobile,
    required this.alerts,
    required this.activities,
  });

  @override
  Widget build(BuildContext context) {
    if (isMobile) {
      return Column(
        children: [
          _AlertsCard(alerts: alerts),
          const SizedBox(height: 12),
          _ActivityCard(activities: activities),
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(flex: 2, child: _AlertsCard(alerts: alerts)),
        const SizedBox(width: 12),
        Expanded(child: _ActivityCard(activities: activities)),
      ],
    );
  }
}

// ============================================================================
// CHARTS (pakai kode kamu, tapi dibikin lebih konsisten)
// ============================================================================

class _StatistikKehadiranChart extends StatefulWidget {
  const _StatistikKehadiranChart();

  @override
  State<_StatistikKehadiranChart> createState() => _StatistikKehadiranChartState();
}

class _StatistikKehadiranChartState extends State<_StatistikKehadiranChart> {
  final SupabaseClient supabase = Supabase.instance.client;

  int _selectedFilterIndex = 0;
  final List<String> _filters = const ['Hari Ini', 'Minggu Ini', 'Bulan Ini', 'Periode'];

  bool _isLoading = true;
  List<FlSpot> _spots = const [];
  Map<double, String> _bottomTitles = const {};

  double _maxY = 10;
  double _minX = 0;
  double _maxX = 6;
  double _intervalX = 1;

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
        case 1:
          rpcName = 'get_statistik_mingguan';
          break;
        case 2:
          rpcName = 'get_statistik_bulanan';
          break;
        case 3:
          rpcName = 'get_statistik_tahunan';
          break;
        default:
          rpcName = 'get_statistik_harian';
          break;
      }

      final List<dynamic> result = await supabase.rpc(rpcName);

      final List<FlSpot> spots = [];
      final Map<double, String> titles = {};
      double i = 0;
      double maxVal = 0;

      if (result.isEmpty) {
        spots.add(const FlSpot(0, 0));
        titles[0] = '-';
        maxVal = 10;
        i = 1;
      } else {
        for (final item in result) {
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
        _maxX = (i - 1).clamp(0, double.infinity);
        _maxY = (maxVal == 0) ? 10 : (maxVal * 1.2).ceilToDouble();
        _intervalX = (i > 10) ? (i / 10).floorToDouble().clamp(1, 999) : 1;
        _isLoading = false;
      });
    } catch (_) {
      setState(() {
        _isLoading = false;
        _spots = const [FlSpot(0, 0)];
        _bottomTitles = {0: 'Err'};
        _minX = 0;
        _maxX = 0;
        _maxY = 10;
        _intervalX = 1;
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
            setState(() => _selectedFilterIndex = i);
            _fetchChartData(i);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: i == _selectedFilterIndex ? const Color(0xFF42A5F5) : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: i == _selectedFilterIndex ? const Color(0xFF42A5F5) : Colors.grey.shade200,
              ),
            ),
            child: Text(
              _filters[i],
              style: TextStyle(
                color: i == _selectedFilterIndex ? Colors.white : Colors.grey.shade700,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _getLeftTitle(double v) => v.toInt().toString();

  @override
  Widget build(BuildContext context) {
    return _WhiteCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.bar_chart_rounded, color: Color(0xFF42A5F5)),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Statistik Kehadiran',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(children: _buildFilters())),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 260,
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : LineChart(
                    LineChartData(
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        horizontalInterval: _maxY > 0 ? _maxY / 5 : 5,
                        getDrawingHorizontalLine: (v) => FlLine(color: Colors.grey.shade200, strokeWidth: 1),
                      ),
                      titlesData: FlTitlesData(
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            interval: _intervalX,
                            getTitlesWidget: (value, meta) {
                              final title = _bottomTitles[value.toDouble()];
                              if (title == null) return const SizedBox.shrink();
                              return Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(title, style: const TextStyle(color: Colors.grey, fontSize: 10)),
                              );
                            },
                          ),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            interval: _maxY > 0 ? _maxY / 5 : 5,
                            reservedSize: 36,
                            getTitlesWidget: (v, _) => Text(
                              _getLeftTitle(v),
                              style: const TextStyle(color: Colors.grey, fontSize: 11),
                            ),
                          ),
                        ),
                        rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
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
                            getDotPainter: (_, __, ___, ____) => FlDotCirclePainter(
                              radius: 4,
                              color: Colors.white,
                              strokeWidth: 2,
                              strokeColor: const Color(0xFF42A5F5),
                            ),
                          ),
                          belowBarData: BarAreaData(
                            show: true,
                            color: const Color(0xFF42A5F5).withValues(alpha: 0.10),
                          ),
                        ),
                      ],
                      lineTouchData: LineTouchData(
                        touchTooltipData: LineTouchTooltipData(
                          getTooltipColor: (_) => Colors.blueAccent,
                          getTooltipItems: (spots) => spots
                              .map(
                                (s) => LineTooltipItem(
                                  '${s.y.toInt()} siswa',
                                  const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                ),
                              )
                              .toList(),
                        ),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _PieChartCard extends StatelessWidget {
  final List<Map<String, dynamic>> distribusiData;
  const _PieChartCard({required this.distribusiData});

  @override
  Widget build(BuildContext context) {
    final total = distribusiData.fold<double>(0.0, (sum, item) => sum + (item['value'] as double));

    return _WhiteCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.pie_chart_outline, color: Color(0xFF42A5F5)),
              SizedBox(width: 10),
              Text('Distribusi per Kelas', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 210,
            child: total == 0
                ? Center(
                    child: Text('Belum ada data distribusi siswa', style: TextStyle(color: Colors.grey.shade600)),
                  )
                : PieChart(
                    PieChartData(
                      sectionsSpace: 2,
                      centerSpaceRadius: 52,
                      sections: distribusiData.map((d) {
                        final v = d['value'] as double;
                        final percent = (v / total * 100);
                        return PieChartSectionData(
                          value: v,
                          color: d['color'] as Color,
                          title: percent >= 7 ? '${percent.toStringAsFixed(0)}%' : '',
                          radius: 62,
                          titleStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
                        );
                      }).toList(),
                    ),
                  ),
          ),
          const SizedBox(height: 12),
          ...distribusiData.take(8).map(
                (d) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(color: d['color'] as Color, shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          d['label'] as String,
                          style: const TextStyle(fontSize: 12),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        '${(d['value'] as double).toInt()}',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
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

// ============================================================================
// MONITORING
// ============================================================================

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
              Icon(Icons.notifications_outlined, color: Color(0xFF42A5F5)),
              SizedBox(width: 10),
              Text('Peringatan Sistem', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 14),
          ...alerts.map((a) => Padding(padding: const EdgeInsets.only(bottom: 12), child: _AlertItem(a))),
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
    final Color c = data['color'] as Color;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: c.withValues(alpha: 0.18)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(10)),
            child: Icon(data['icon'] as IconData, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(data['title']?.toString() ?? '-', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(data['subtitle']?.toString() ?? '-', style: const TextStyle(fontSize: 12, color: Colors.grey)),
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
      case 'pulang':
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
      case 'pulang':
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
    if (isoString == null) return '-';
    final dt = DateTime.tryParse(isoString)?.toLocal();
    if (dt == null) return '-';

    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Baru saja';
    if (diff.inMinutes < 60) return '${diff.inMinutes} menit lalu';
    if (diff.inHours < 24) return '${diff.inHours} jam lalu';
    return DateFormat('dd MMM yyyy, HH:mm').format(dt);
  }

  @override
  Widget build(BuildContext context) {
    return _WhiteCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.update, color: Color(0xFF42A5F5)),
              SizedBox(width: 10),
              Text('Aktivitas Terbaru', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 14),
          if (activities.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 28),
              child: Center(child: Text('Belum ada aktivitas hari ini', style: TextStyle(color: Colors.grey.shade600))),
            ),
          ...activities.map((a) {
            final status = a['status'] as String?;
            final namaSiswa = (a['siswa'] is Map) ? (a['siswa']['nama'] ?? 'Siswa tidak dikenal') : 'Siswa tidak dikenal';
            final waktuMasuk = a['waktu_masuk']?.toString();
            final createdAt = a['created_at']?.toString();

            final color = _getColorForStatus(status);
            final icon = _getIconForStatus(status);

            final timeLabel = waktuMasuk ??
                (createdAt != null ? DateFormat("HH:mm").format(DateTime.parse(createdAt).toLocal()) : '-');

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, color: color, size: 18),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$namaSiswa • ${status?.toLowerCase() ?? 'scan'}',
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 3),
                        Text('Scan pada $timeLabel', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                        const SizedBox(height: 2),
                        Text(_formatTimeAgo(createdAt), style: const TextStyle(fontSize: 11, color: Colors.grey)),
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

// ============================================================================
// BASE CARD
// ============================================================================
class _WhiteCard extends StatelessWidget {
  final Widget child;
  const _WhiteCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.grey.withValues(alpha: 0.08), blurRadius: 10, offset: const Offset(0, 2))],
      ),
      child: child,
    );
  }
}
