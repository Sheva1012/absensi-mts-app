import 'package:flutter/material.dart';

const Color _primaryColor = Color(0xFF3498db); // Biru
const double _sidebarWidth = 200.0;

class Sidebar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onMenuSelected;

  const Sidebar({
    super.key,
    required this.selectedIndex,
    required this.onMenuSelected,
  });

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required int index,
    bool isLogout = false,
  }) {
    final bool isSelected = selectedIndex == index;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: Material(
        color: isSelected ? _primaryColor.withOpacity(0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(6),
        child: InkWell(
          onTap: () {
            onMenuSelected(index);
          },
          borderRadius: BorderRadius.circular(6),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: isSelected
                      ? _primaryColor
                      : (isLogout ? Colors.red : Colors.black87),
                  size: 20,
                ),
                const SizedBox(width: 16),
                Text(
                  title,
                  style: TextStyle(
                    color: isSelected
                        ? _primaryColor
                        : (isLogout ? Colors.red : Colors.black87),
                    fontSize: 14,
                    fontWeight: isSelected
                        ? FontWeight.w600
                        : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: _sidebarWidth,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(right: BorderSide(color: Colors.grey, width: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            child: const Text(
              "MTs Sunan Gunung Jati",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Colors.black,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Image.asset('assets/Logo MTS.png', width: 32, height: 32),
                const SizedBox(width: 10),
                const Text(
                  "Admin User",
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Menu items
          Expanded(
            child: ListView(
              children: [
                // Menu sesuai gambar
                _buildMenuItem(
                  icon: Icons.dashboard,
                  title: "Dashboard",
                  index: 0,
                ), // Dashboard tetap ada
                _buildMenuItem(
                  icon: Icons.assignment_turned_in,
                  title: "Absensi",
                  index: 1,
                ),
                _buildMenuItem(icon: Icons.person, title: "Guru", index: 2),
                _buildMenuItem(icon: Icons.group, title: "Kelas", index: 3),
                _buildMenuItem(icon: Icons.school, title: "Siswa", index: 4),
                _buildMenuItem(icon: Icons.mail, title: "Surat", index: 5),
                const Divider(),
                _buildMenuItem(
                  icon: Icons.logout,
                  title: "Log Out",
                  index: 6,
                  isLogout: true,
                ), // Log Out tetap ada
              ],
            ),
          ),
        ],
      ),
    );
  }
}
