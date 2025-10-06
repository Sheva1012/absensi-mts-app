import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: const [
            _AppHeader(),
            SizedBox(height: 20),
            _WelcomeCard(),
            SizedBox(height: 20),
            _QuickStats(),
            SizedBox(height: 20),
            _DetailedStats(),
            SizedBox(height: 30),
            _ChartsSection(),
            SizedBox(height: 30),
            _BottomSection(),
          ],
        ),
      ),
    );
  }
}

class _AppHeader extends StatelessWidget {
  const _AppHeader();

  @override
  Widget build(BuildContext context) {
    return _WhiteCard(
      child: Row(
        children: [
          const Text("Dashboard Admin", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const Spacer(),
          Expanded(
            flex: 2,
            child: _SearchBar(),
          ),
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
          Expanded(child: TextField(
            decoration: InputDecoration(hintText: "Cari data...", hintStyle: TextStyle(color: Colors.grey, fontSize: 14), border: InputBorder.none, isDense: true),
          )),
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
          right: -2, top: -2,
          child: Container(
            padding: const EdgeInsets.all(5),
            decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
            child: const Text("3", style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
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
        const CircleAvatar(radius: 18, backgroundColor: Color(0xFF42A5F5), child: Text("AU", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14))),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: const [
            Text("Admin User", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            Text("MTs Sunan Gunung Jati", style: TextStyle(fontSize: 11, color: Colors.grey)),
          ],
        )
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
        gradient: const LinearGradient(colors: [Color(0xFF42A5F5), Color(0xFF1E88E5)]),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Color(0xFF42A5F5).withOpacity(0.3), blurRadius: 12, offset: Offset(0, 6))],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text('Selamat Datang, Admin!', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                SizedBox(height: 8),
                Text('Sistem Manajemen Absensi MTs Sunan Gunung Jati - Pantau kehadiran siswa secara real-time dan kelola data dengan mudah.', style: TextStyle(color: Colors.white, fontSize: 14, height: 1.5)),
              ],
            ),
          ),
          const SizedBox(width: 30),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.analytics_outlined, size: 60, color: Colors.white),
          ),
        ],
      ),
    );
  }
}

class _QuickStats extends StatelessWidget {
  const _QuickStats();

  @override
  Widget build(BuildContext context) {
    final stats = [
      {'value': '85%', 'title': 'Kehadiran Hari Ini', 'icon': Icons.people_outline, 'color': Color(0xFF42A5F5)},
      {'value': '12', 'title': 'Siswa Terlambat', 'icon': Icons.access_time, 'color': Color(0xFFFFA726)},
      {'value': '8', 'title': 'Siswa Absen', 'icon': Icons.person_off_outlined, 'color': Color(0xFFEF5350)},
      {'value': '92%', 'title': 'Rata-rata Bulanan', 'icon': Icons.pie_chart_outline, 'color': Color(0xFFAB47BC)},
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: 20,
        mainAxisSpacing: 20,
        childAspectRatio: 2, // ← Tambahkan sedikit ruang vertikal
      ),
      itemCount: stats.length,
      itemBuilder: (c, i) => _WhiteCard(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center, // ← tambahkan ini
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
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 2),
                  Flexible( // ← tambahan agar teks tidak overflow
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


class _DetailedStats extends StatelessWidget {
  const _DetailedStats();

  @override
  Widget build(BuildContext context) {
    final stats = [
      {'title': 'KEHADIRAN HARIAN', 'value': '80%', 'change': '5% dari kemarin', 'positive': true, 'progress': 0.80, 'subtitle': '240/300 Siswa', 'detail': 'Hari ini', 'color': Color(0xFF66BB6A), 'icon': Icons.check_circle_outline},
      {'title': 'KETERLAMBATAN', 'value': '12', 'change': '2 dari kemarin', 'positive': false, 'progress': 0.04, 'subtitle': '4% dari total', 'detail': 'Perlu perhatian', 'color': Color(0xFFFFA726), 'icon': Icons.access_time},
      {'title': 'KETIDAKHADIRAN', 'value': '8', 'change': '3 dari kemarin', 'positive': true, 'progress': 0.027, 'subtitle': '2.7% dari total', 'detail': 'Perlu konfirmasi', 'color': Color(0xFFEF5350), 'icon': Icons.person_off_outlined},
    ];

    return Row(
      children: stats.map((s) => Expanded(child: Padding(padding: EdgeInsets.only(right: s == stats.last ? 0 : 20), child: _DetailStatCard(s)))).toList(),
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
        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.08), blurRadius: 8, offset: Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(data['title'], style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.grey, letterSpacing: 0.5)),
              Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: (data['color'] as Color).withOpacity(0.1), borderRadius: BorderRadius.circular(8)), child: Icon(data['icon'], color: data['color'], size: 20)),
            ],
          ),
          const SizedBox(height: 16),
          Text(data['value'], style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(data['positive'] ? Icons.arrow_upward : Icons.arrow_downward, color: data['positive'] ? Colors.green : Colors.red, size: 14),
              const SizedBox(width: 4),
              Text(data['change'], style: TextStyle(fontSize: 12, color: data['positive'] ? Colors.green : Colors.red, fontWeight: FontWeight.w500)),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(borderRadius: BorderRadius.circular(4), child: LinearProgressIndicator(value: data['progress'], backgroundColor: Colors.grey.shade200, color: data['color'], minHeight: 6)),
          const SizedBox(height: 12),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(data['subtitle'], style: const TextStyle(fontSize: 12, color: Colors.grey)), Text(data['detail'], style: const TextStyle(fontSize: 11, color: Colors.grey))]),
        ],
      ),
    );
  }
}

class _ChartsSection extends StatelessWidget {
  const _ChartsSection();

  @override
  Widget build(BuildContext context) {
    return Row(children: const [Expanded(flex: 2, child: _LineChartCard()), SizedBox(width: 20), Expanded(child: _PieChartCard())]);
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
              const Text('Statistik Kehadiran 7 Hari Terakhir', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const Spacer(),
              ..._buildFilters(['Minggu Ini', 'Bulan Ini', 'Tahun Ini'], 0),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(height: 250, child: LineChart(LineChartData(
            gridData: FlGridData(show: true, drawVerticalLine: false, horizontalInterval: 20, getDrawingHorizontalLine: (v) => FlLine(color: Colors.grey.shade200, strokeWidth: 1)),
            titlesData: FlTitlesData(
              bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, interval: 1, getTitlesWidget: (v, _) => Padding(padding: const EdgeInsets.only(top: 8), child: Text(['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'][v.toInt() % 7], style: const TextStyle(color: Colors.grey, fontSize: 12))))),
              leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, interval: 20, reservedSize: 40, getTitlesWidget: (v, _) => Text('${v.toInt()}%', style: const TextStyle(color: Colors.grey, fontSize: 12)))),
              rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
              topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            ),
            borderData: FlBorderData(show: false),
            minX: 0, maxX: 6, minY: 0, maxY: 100,
            lineBarsData: [LineChartBarData(spots: const [FlSpot(0, 80), FlSpot(1, 85), FlSpot(2, 78), FlSpot(3, 90), FlSpot(4, 88), FlSpot(5, 92), FlSpot(6, 86)], isCurved: true, color: Color(0xFF42A5F5), barWidth: 3, dotData: FlDotData(show: true, getDotPainter: (_, __, ___, ____) => FlDotCirclePainter(radius: 4, color: Colors.white, strokeWidth: 2, strokeColor: Color(0xFF42A5F5))), belowBarData: BarAreaData(show: true, color: Color(0xFF42A5F5).withOpacity(0.1)))],
          ))),
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
      {'label': 'Kelas 7', 'value': 35.0, 'color': Color(0xFF42A5F5)},
      {'label': 'Kelas 8', 'value': 40.0, 'color': Color(0xFF66BB6A)},
      {'label': 'Kelas 9', 'value': 25.0, 'color': Color(0xFFAB47BC)},
    ];

    return _WhiteCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [const Icon(Icons.pie_chart_outline), const SizedBox(width: 10), const Text('Distribusi per Kelas', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold))]),
          const SizedBox(height: 8),
          Row(children: _buildFilters(['Hari Ini', 'Minggu Ini'], 0)),
          const SizedBox(height: 24),
          SizedBox(height: 200, child: PieChart(PieChartData(sectionsSpace: 2, centerSpaceRadius: 50, sections: data.map((d) => PieChartSectionData(value: d['value'] as double, color: d['color'] as Color, title: '${(d['value'] as double).toInt()}%', radius: 60, titleStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white))).toList()))),
          const SizedBox(height: 20),
          ...data.map((d) => Padding(padding: const EdgeInsets.only(bottom: 8), child: Row(children: [Container(width: 12, height: 12, decoration: BoxDecoration(color: d['color'] as Color, shape: BoxShape.circle)), const SizedBox(width: 8), Text(d['label'] as String, style: const TextStyle(fontSize: 13)), const Spacer(), Text('${(d['value'] as double).toInt()}%', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold))]))),
        ],
      ),
    );
  }
}

List<Widget> _buildFilters(List<String> labels, int selected) {
  return List.generate(labels.length, (i) => Padding(padding: EdgeInsets.only(left: i > 0 ? 8 : 0), child: Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), decoration: BoxDecoration(color: i == selected ? const Color(0xFF42A5F5) : Colors.grey.shade100, borderRadius: BorderRadius.circular(20)), child: Text(labels[i], style: TextStyle(color: i == selected ? Colors.white : Colors.grey.shade600, fontSize: 12, fontWeight: FontWeight.w500)))));
}

class _BottomSection extends StatelessWidget {
  const _BottomSection();

  @override
  Widget build(BuildContext context) {
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: const [Expanded(flex: 2, child: _AlertsCard()), SizedBox(width: 20), Expanded(child: _ActivityCard())]);
  }
}

class _AlertsCard extends StatelessWidget {
  const _AlertsCard();

  @override
  Widget build(BuildContext context) {
    final alerts = [
      {'icon': Icons.warning_amber_rounded, 'color': Color(0xFFFFA726), 'title': 'Guru yang belum input validasi', 'subtitle': '5 guru belum melakukan validasi kehadiran hari ini'},
      {'icon': Icons.person_off_outlined, 'color': Color(0xFFEF5350), 'title': 'Siswa dengan alpha beruntun', 'subtitle': '12 siswa telah alpha lebih dari 3 hari berturut-turut'},
      {'icon': Icons.info_outline, 'color': Color(0xFF42A5F5), 'title': 'System anomalies', 'subtitle': 'Terjadi peningkatan scan ganda di gerbang utama'},
    ];

    return _WhiteCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: const [Icon(Icons.notifications_outlined), SizedBox(width: 10), Text('Peringatan Sistem', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold))]),
          const SizedBox(height: 20),
          ...alerts.map((a) => Padding(padding: const EdgeInsets.only(bottom: 16), child: _AlertItem(a))),
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
      decoration: BoxDecoration(color: (data['color'] as Color).withOpacity(0.05), borderRadius: BorderRadius.circular(10), border: Border.all(color: (data['color'] as Color).withOpacity(0.2))),
      child: Row(
        children: [
          Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: data['color'], borderRadius: BorderRadius.circular(8)), child: Icon(data['icon'], color: Colors.white, size: 22)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(data['title'], style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)), const SizedBox(height: 4), Text(data['subtitle'], style: const TextStyle(fontSize: 12, color: Colors.grey))])),
        ],
      ),
    );
  }
}

class _ActivityCard extends StatelessWidget {
  const _ActivityCard();

  @override
  Widget build(BuildContext context) {
    final activities = [
      {'icon': Icons.check_circle, 'color': Color(0xFF66BB6A), 'title': 'Andi Pratama hadir', 'subtitle': 'Kelas 7A - Scan pada 07:45', 'time': '5 menit yang lalu'},
      {'icon': Icons.access_time, 'color': Color(0xFFFFA726), 'title': 'Budi Santoso terlambat', 'subtitle': 'Kelas 8B - Scan pada 08:05', 'time': '15 menit yang lalu'},
      {'icon': Icons.qr_code, 'color': Color(0xFF42A5F5), 'title': 'QR Code diperbarui', 'subtitle': 'Kelas 9C - Generate batch baru', 'time': '1 jam yang lalu'},
      {'icon': Icons.cloud_download, 'color': Color(0xFFAB47BC), 'title': 'Data diimpor', 'subtitle': '25 data siswa baru dari Excel', 'time': '2 jam yang lalu'},
    ];

    return _WhiteCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: const [Icon(Icons.update), SizedBox(width: 10), Text('Aktivitas Terbaru', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold))]),
          const SizedBox(height: 20),
          ...activities.map((a) => Padding(padding: const EdgeInsets.only(bottom: 16), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: (a['color'] as Color).withOpacity(0.1), borderRadius: BorderRadius.circular(8)), child: Icon(a['icon'] as IconData, color: a['color'] as Color, size: 20)), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(a['title'] as String, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)), const SizedBox(height: 4), Text(a['subtitle'] as String, style: const TextStyle(fontSize: 11, color: Colors.grey)), const SizedBox(height: 2), Text(a['time'] as String, style: const TextStyle(fontSize: 10, color: Colors.grey))]))]))),
        ],
      ),
    );
  }
}

class _WhiteCard extends StatelessWidget {
  final Widget child;
  const _WhiteCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.08), blurRadius: 8, offset: Offset(0, 2))]),
      child: child,
    );
  }
}