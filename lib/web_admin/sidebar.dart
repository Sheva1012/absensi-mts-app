import 'package:flutter/material.dart';

const Color _primaryColor = Color(0xFF3498db);
const double _sidebarWidthExpanded = 220.0;
const double _sidebarWidthCollapsed = 70.0;

class Sidebar extends StatefulWidget {
  final int selectedIndex;
  final Function(int) onMenuSelected;

  const Sidebar({
    super.key,
    required this.selectedIndex,
    required this.onMenuSelected,
  });

  @override
  State<Sidebar> createState() => _SidebarState();
}

class _SidebarState extends State<Sidebar> {
  bool _isCollapsed = false;

  void _toggleSidebar() {
    setState(() => _isCollapsed = !_isCollapsed);
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required int index,
    bool isLogout = false,
  }) {
    final bool isSelected = widget.selectedIndex == index;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: Material(
        color: isSelected ? _primaryColor.withOpacity(0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(6),
        child: InkWell(
          onTap: () => widget.onMenuSelected(index),
          borderRadius: BorderRadius.circular(6),
          // GANTI DENGAN AnimatedPadding
          child: AnimatedPadding(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            padding: EdgeInsets.symmetric(
              vertical: 15,
              horizontal: _isCollapsed ? 15.5 : 15.0,
            ),
            child: Row(
              // Jangan gunakan MainAxisAlignment.center, biarkan padding yg mengatur
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Icon(
                  icon,
                  color: isSelected
                      ? _primaryColor
                      : (isLogout ? Colors.red : Colors.black87),
                  size: 22,
                ),

                // 1. Animasikan lebar SizedBox
                AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeInOut,
                  width: _isCollapsed ? 0 : 20,
                ),

                // 2. Animasikan opacity Text
                Flexible(
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 100),
                    opacity: _isCollapsed ? 0.0 : 1.0,
                    child: Text(
                      title,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
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
    return AnimatedContainer(
      width: _isCollapsed ? _sidebarWidthCollapsed : _sidebarWidthExpanded,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(right: BorderSide(color: Colors.grey, width: 0.5)),
        boxShadow: [
          BoxShadow(
            color: Color.fromARGB(30, 0, 0, 0),
            blurRadius: 8,
            offset: Offset(2, 0),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: _isCollapsed
              ? CrossAxisAlignment.center
              : CrossAxisAlignment.start,
          children: [
            // header
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(
                vertical: 12,
                horizontal: _isCollapsed ? 0 : 12,
              ),
              child: _isCollapsed
                  ? Center(
                      child: IconButton(
                        icon: const Icon(
                          Icons.chevron_right,
                          color: _primaryColor,
                          size: 24,
                        ),
                        onPressed: _toggleSidebar,
                        tooltip: 'Buka Sidebar',
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Flexible(
                          child: Text(
                            'MTs Sunan Gunung Jati',
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: Colors.black,
                            ),
                          ),
                        ),
                        IconButton(
                          constraints: const BoxConstraints(),
                          padding: EdgeInsets.zero,
                          icon: const Icon(
                            Icons.chevron_left,
                            color: _primaryColor,
                            size: 24,
                          ),
                          onPressed: _toggleSidebar,
                          tooltip: 'Tutup Sidebar',
                        ),
                      ],
                    ),
            ),

            // logo + admin
            AnimatedPadding(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOut,
              padding: EdgeInsets.symmetric(
                vertical: 8,
                // (Lebar Collapsed 70px - Lebar Gambar 32px) / 2 = 19px
                horizontal: _isCollapsed ? 18.5 : 16.0,
              ),
              child: Row(
                // Gunakan center saat collapsed agar pas
                mainAxisAlignment: _isCollapsed
                    ? MainAxisAlignment.center
                    : MainAxisAlignment.start,
                children: [
                  Image.asset('assets/Logo MTS.png', width: 32, height: 32),

                  // 1. Animasikan lebar SizedBox
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeInOut,
                    width: _isCollapsed ? 0 : 10,
                  ),

                  // 2. Animasikan opacity Text
                  Flexible(
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 100),
                      opacity: _isCollapsed ? 0.0 : 1.0,
                      child: const Text(
                        'Admin User',
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const Divider(height: 1),

            // menu
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  _buildMenuItem(
                    icon: Icons.dashboard,
                    title: 'Dashboard',
                    index: 0,
                  ),
                  _buildMenuItem(
                    icon: Icons.assignment_turned_in,
                    title: 'Absensi',
                    index: 1,
                  ),
                  _buildMenuItem(icon: Icons.person, title: 'Guru', index: 2),
                  _buildMenuItem(icon: Icons.group, title: 'Kelas', index: 3),
                  _buildMenuItem(icon: Icons.school, title: 'Siswa', index: 4),
                  _buildMenuItem(icon: Icons.mail, title: 'Surat', index: 5),
                  const Divider(),
                  _buildMenuItem(
                    icon: Icons.logout,
                    title: 'Log Out',
                    index: 6,
                    isLogout: true,
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
