import 'package:flutter/material.dart';

const Color _primaryColor = Color(0xFF3498db); // Biru
const double _sidebarWidth = 140.0;

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
  late bool isKelas7Expanded;
  late bool isKelas8Expanded;
  late bool isKelas9Expanded;

  @override
  void initState() {
    super.initState();
    isKelas7Expanded = widget.selectedIndex >= 1 && widget.selectedIndex <= 3;
    isKelas8Expanded = widget.selectedIndex >= 4 && widget.selectedIndex <= 6;
    isKelas9Expanded = widget.selectedIndex >= 7 && widget.selectedIndex <= 9;
  }

  @override
  void didUpdateWidget(covariant Sidebar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedIndex != oldWidget.selectedIndex) {
      isKelas7Expanded = widget.selectedIndex >= 1 && widget.selectedIndex <= 3;
      isKelas8Expanded = widget.selectedIndex >= 4 && widget.selectedIndex <= 6;
      isKelas9Expanded = widget.selectedIndex >= 7 && widget.selectedIndex <= 9;
    }
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
          onTap: () {
            widget.onMenuSelected(index);
          },
          borderRadius: BorderRadius.circular(6),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: isSelected ? _primaryColor : (isLogout ? Colors.red : Colors.black87),
                  size: 20,
                ),
                const SizedBox(width: 16),
                Text(
                  title,
                  style: TextStyle(
                    color: isSelected ? _primaryColor : (isLogout ? Colors.red : Colors.black87),
                    fontSize: 14,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSubMenuItem({
    required String title,
    required int index,
  }) {
    final bool isSelected = widget.selectedIndex == index;
    return InkWell(
      onTap: () {
        widget.onMenuSelected(index);
      },
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        color: isSelected ? _primaryColor.withOpacity(0.1) : Colors.transparent,
        child: Text(
          title,
          style: TextStyle(
            color: isSelected ? _primaryColor : Colors.black87,
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildClassDropdown({
    required String title,
    required List<String> subMenus,
    required int startIndex,
    required bool isExpanded,
    required ValueChanged<bool> onExpansionChanged,
  }) {
    return Theme(
      data: Theme.of(context).copyWith(
        dividerColor: Colors.transparent,
        splashColor: _primaryColor.withOpacity(0.1),
      ),
      child: ExpansionTile(
        initiallyExpanded: isExpanded,
        onExpansionChanged: onExpansionChanged,
        tilePadding: const EdgeInsets.symmetric(horizontal: 12),
        leading: Icon(
          Icons.people,
          color: isExpanded || (widget.selectedIndex >= startIndex && widget.selectedIndex < startIndex + subMenus.length) ? _primaryColor : Colors.black87,
        ),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 14,
            color: isExpanded || (widget.selectedIndex >= startIndex && widget.selectedIndex < startIndex + subMenus.length) ? _primaryColor : Colors.black87,
            fontWeight: isExpanded ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
        children: subMenus
            .asMap()
            .entries
            .map((entry) => _buildSubMenuItem(title: entry.value, index: startIndex + entry.key))
            .toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: _sidebarWidth,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          right: BorderSide(color: Colors.grey, width: 0.5), // garis pemisah
        ),
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
                Image.asset(
                  'assets/Logo MTS.png',
                  width: 32,
                  height: 32,
                ),
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
          // Menu
          Expanded(
            child: ListView(
              children: [
                _buildMenuItem(icon: Icons.dashboard, title: "Dashboard", index: 0),
                _buildClassDropdown(
                  title: "Kelas 7",
                  subMenus: const ["Kelas 7A", "Kelas 7B", "Kelas 7C"],
                  startIndex: 1,
                  isExpanded: isKelas7Expanded,
                  onExpansionChanged: (isExpanded) {
                    setState(() {
                      isKelas7Expanded = isExpanded;
                    });
                  },
                ),
                _buildClassDropdown(
                  title: "Kelas 8",
                  subMenus: const ["Kelas 8A", "Kelas 8B", "Kelas 8C"],
                  startIndex: 4,
                  isExpanded: isKelas8Expanded,
                  onExpansionChanged: (isExpanded) {
                    setState(() {
                      isKelas8Expanded = isExpanded;
                    });
                  },
                ),
                _buildClassDropdown(
                  title: "Kelas 9",
                  subMenus: const ["Kelas 9A", "Kelas 9B", "Kelas 9C"],
                  startIndex: 7,
                  isExpanded: isKelas9Expanded,
                  onExpansionChanged: (isExpanded) {
                    setState(() {
                      isKelas9Expanded = isExpanded;
                    });
                  },
                ),
                _buildMenuItem(icon: Icons.access_time, title: "Data Orang Tua", index: 10),
                const Divider(),
                _buildMenuItem(icon: Icons.logout, title: "Log Out", index: 11, isLogout: true),
              ],
            ),
          ),
        ],
      ),
    );
  }
}