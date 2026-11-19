// lib/screens/shared/main_screen.dart
import 'package:flutter/material.dart';
import '../../core/api_service.dart';
import '../../widgets/app_widgets.dart';
import '../shared/login_screen.dart';
import '../shared/dashboard_screen.dart';
import '../shared/profile_screen.dart';
import '../admin/alat_screen.dart';
import '../admin/peminjaman_admin_screen.dart';
import '../admin/pengembalian_screen.dart';
import '../admin/laporan_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  String _username = '';
  bool _loading = true;

  final List<_NavItem> _navItems = const [
    _NavItem('Ringkasan', Icons.grid_view_outlined, Icons.grid_view, DashboardScreen()),
    _NavItem('Alat Lab', Icons.inventory_2_outlined, Icons.inventory_2, AlatScreen()),
    _NavItem('Peminjaman', Icons.assignment_outlined, Icons.assignment, PeminjamanAdminScreen()),
    _NavItem('Riwayat', Icons.history_outlined, Icons.history, PengembalianScreen()),
    _NavItem('Laporan', Icons.analytics_outlined, Icons.analytics, LaporanScreen()),
  ];

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final username = await ApiService.getUsername();
    setState(() {
      _username = username ?? 'Petugas';
      _loading = false;
    });
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text('Keluar Aplikasi', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        content: const Text('Keluar dari sistem SIPELA Laboratorium?', style: TextStyle(fontSize: 13, color: kTextMuted)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal', style: TextStyle(color: kTextMuted)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: kColorDanger,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
            ),
            child: const Text('Keluar', style: TextStyle(color: Colors.white, fontSize: 13)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await ApiService.clearAuth();
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: kBackground,
        body: LoadingWidget(message: 'Memuat aplikasi...'),
      );
    }

    final isWide = MediaQuery.of(context).size.width >= 768;

    if (isWide) {
      // Desktop / Tablet layout with Rail
      return Scaffold(
        backgroundColor: kBackground,
        body: Row(
          children: [
            NavigationRail(
              selectedIndex: _selectedIndex,
              onDestinationSelected: (i) => setState(() => _selectedIndex = i),
              extended: MediaQuery.of(context).size.width >= 1080,
              backgroundColor: kSurface,
              selectedIconTheme: const IconThemeData(color: kBrandAccent),
              unselectedIconTheme: const IconThemeData(color: kTextMuted),
              selectedLabelTextStyle: const TextStyle(color: kBrandAccent, fontWeight: FontWeight.w700, fontSize: 12.5),
              unselectedLabelTextStyle: const TextStyle(color: kTextMuted, fontSize: 12.5),
              leading: Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: kBrandPrimary,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.science, color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 8),
                    const Text('SIPELA LAB', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: kTextMain)),
                  ],
                ),
              ),
              trailing: Expanded(
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: CircleAvatar(
                            backgroundColor: kBrandPrimary,
                            radius: 14,
                            child: Text(
                              getInitial(_username),
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 11),
                            ),
                          ),
                          tooltip: 'Profil Petugas',
                          onPressed: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const ProfileScreen()),
                            );
                            _loadUser();
                          },
                        ),
                        const SizedBox(height: 6),
                        IconButton(
                          icon: const Icon(Icons.logout, size: 20, color: kTextMuted),
                          tooltip: 'Keluar',
                          onPressed: _logout,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              destinations: _navItems
                  .map((e) => NavigationRailDestination(
                        icon: Icon(e.iconOutlined, size: 20),
                        selectedIcon: Icon(e.iconFilled, size: 20),
                        label: Text(e.label),
                      ))
                  .toList(),
            ),
            const VerticalDivider(width: 1, color: kBorder),
            Expanded(child: _navItems[_selectedIndex].screen),
          ],
        ),
      );
    }

    // Mobile layout dengan Bottom Navigation Bar Modern & Sejajar
    return Scaffold(
      backgroundColor: kBackground,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _navItems[_selectedIndex].label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: kTextMain, letterSpacing: -0.3),
            ),
            const Text(
              'SIPELA • UPT Laboratorium',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w500, color: kTextMuted),
            ),
          ],
        ),
        backgroundColor: kSurface,
        elevation: 0,
        scrolledUnderElevation: 1,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: kBorder, height: 1),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              children: [
                InkWell(
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ProfileScreen()),
                    );
                    _loadUser();
                  },
                  borderRadius: BorderRadius.circular(24),
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(4, 3, 10, 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: kBorder),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircleAvatar(
                          backgroundColor: kBrandPrimary,
                          radius: 13,
                          child: Text(
                            getInitial(_username),
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 11),
                          ),
                        ),
                        const SizedBox(width: 7),
                        Text(
                          _username == 'admin' ? 'Petugas Lab' : _username,
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: kTextMain),
                        ),
                        const SizedBox(width: 3),
                        const Icon(Icons.chevron_right, size: 14, color: kTextMuted),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: _navItems[_selectedIndex].screen,
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: kSurface,
          border: Border(top: BorderSide(color: kBorder)),
          boxShadow: [
            BoxShadow(
              color: Color(0x0C000000),
              blurRadius: 14,
              offset: Offset(0, -3),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 64,
            child: Row(
              children: List.generate(_navItems.length, (i) {
                final item = _navItems[i];
                final isSelected = _selectedIndex == i;

                return Expanded(
                  child: InkWell(
                    onTap: () => setState(() => _selectedIndex = i),
                    splashColor: Colors.transparent,
                    highlightColor: Colors.transparent,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 5),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Pill Icon Container
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            curve: Curves.easeInOut,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4.5),
                            decoration: BoxDecoration(
                              color: isSelected ? const Color(0xFFDBEAFE) : Colors.transparent,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Icon(
                              isSelected ? item.iconFilled : item.iconOutlined,
                              size: 20,
                              color: isSelected ? kBrandAccent : kTextMuted,
                            ),
                          ),
                          const SizedBox(height: 3),
                          // Single-line Aligned Label
                          Text(
                            item.label,
                            maxLines: 1,
                            softWrap: false,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                              color: isSelected ? kBrandAccent : kTextMuted,
                              letterSpacing: -0.2,
                              height: 1.1,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  final String label;
  final IconData iconOutlined;
  final IconData iconFilled;
  final Widget screen;

  const _NavItem(this.label, this.iconOutlined, this.iconFilled, this.screen);
}
