import 'package:flutter/material.dart';
import 'package:pamsimas_app/src/pages/akun/akun_screen.dart';
import 'package:pamsimas_app/src/pages/customers/pelanggan_screen.dart';
import 'package:pamsimas_app/src/pages/home/home_screen.dart';
import 'package:pamsimas_app/src/pages/meter/catat_meter_screen.dart';
import 'package:pamsimas_app/src/pages/tagihan/tagihan_screen.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({Key? key}) : super(key: key);

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _selectedIndex = 0;

  static const Color _activeColor   = Color(0xFF1565C0);
  static const Color _inactiveColor = Color(0xFF9CA3AF);
  static const Color _fabColor      = Color(0xFF1565C0);

  final List<Widget> _pages = [
    const HomeScreen(),
    const PelangganScreen(),
    const CatatMeterScreen(),
    const TagihanScreen(),
    const AkunScreen(),
  ];

  void _onItemTapped(int index) {
    // index 2 is the center FAB — handled by onPressed, skip here
    if (index == 2) return;
    setState(() => _selectedIndex = index);
  }

  void _onCatatTapped() {
    setState(() => _selectedIndex = 2);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F4F7),
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      floatingActionButton: _buildCenterFab(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  // ─── Center FAB ────────────────────────────────────────────────────────────
  Widget _buildCenterFab() {
    final bool isActive = _selectedIndex == 2;
    return GestureDetector(
      onTap: _onCatatTapped,
      child: Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isActive ? _fabColor : _fabColor.withOpacity(0.85),
          boxShadow: [
            BoxShadow(
              color: _fabColor.withOpacity(0.45),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.water_drop_outlined, color: Colors.white, size: 26),
            const SizedBox(height: 2),
            const Text(
              'Catat',
              style: TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Bottom Nav Bar ────────────────────────────────────────────────────────
  Widget _buildBottomNavBar() {
    return BottomAppBar(
      shape: const CircularNotchedRectangle(),
      notchMargin: 8,
      elevation: 0,
      color: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 64,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(index: 0, icon: Icons.home_outlined,          activeIcon: Icons.home_rounded,          label: 'Beranda'),
                _buildNavItem(index: 1, icon: Icons.people_alt_outlined,    activeIcon: Icons.people_alt_rounded,    label: 'Pelanggan'),
                const SizedBox(width: 56), // gap for FAB
                _buildNavItem(index: 3, icon: Icons.receipt_long_outlined,  activeIcon: Icons.receipt_long_rounded,  label: 'Tagihan'),
                _buildNavItem(index: 4, icon: Icons.account_circle_outlined, activeIcon: Icons.account_circle_rounded, label: 'Akun'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required IconData activeIcon,
    required String label,
  }) {
    final bool isActive = _selectedIndex == index;
    return GestureDetector(
      onTap: () => _onItemTapped(index),
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 72,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isActive ? activeIcon : icon,
              color: isActive ? _activeColor : _inactiveColor,
              size: 26,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
                color: isActive ? _activeColor : _inactiveColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Placeholder Screens ──────────────────────────────────────────────────────
