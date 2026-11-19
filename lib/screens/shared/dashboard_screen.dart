// lib/screens/shared/dashboard_screen.dart
import 'package:flutter/material.dart';
import '../../core/api_service.dart';
import '../../models/loan_model.dart';
import '../../models/tool_model.dart';
import '../../widgets/app_widgets.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String _username = '';
  List<Tool> _tools = [];
  List<Loan> _loans = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      _username = (await ApiService.getUsername()) ?? 'admin';
      final toolsData = await ApiService.get('/tools');
      final loansData = await ApiService.get('/loans');
      setState(() {
        _tools = (toolsData as List).map((e) => Tool.fromJson(e)).toList();
        _loans = (loansData as List).map((e) => Loan.fromJson(e)).toList()
          ..sort((a, b) => b.idLoan.compareTo(a.idLoan));
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) showError(context, e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: kBackground,
        body: LoadingWidget(message: 'Memuat data dashboard...'),
      );
    }

    // Hitungan metrik sesuai 7 fitur utama:
    final totalAlat = _tools.fold<int>(0, (sum, t) => sum + t.stokTotal);
    final totalJenis = _tools.length;
    final alatTersedia = _tools.fold<int>(0, (sum, t) => sum + t.stokTersedia);
    final totalTransaksi = _loans.length;
    final pinjamanAktif = _loans.where((l) => l.status == 'dipinjam').toList();
    final totalDipinjam = pinjamanAktif.length;
    final terlambat = _loans.where((l) => l.isTerlambat).toList();

    return RefreshIndicator(
      onRefresh: _loadData,
      color: kBrandAccent,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Hero Greeting Banner ──────────────────────────────
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: const LinearGradient(
                  colors: [Color(0xFF0F265C), Color(0xFF1E3A8A), Color(0xFF2563EB)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x221E3A8A),
                    blurRadius: 16,
                    offset: Offset(0, 6),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  Positioned(
                    right: -15,
                    bottom: -15,
                    child: Icon(
                      Icons.science_outlined,
                      size: 130,
                      color: Colors.white.withValues(alpha: 0.08),
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.16),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.school, size: 13, color: Colors.white),
                                SizedBox(width: 5),
                                Text(
                                  'UPT LABORATORIUM',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFF22C55E).withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFF22C55E).withValues(alpha: 0.4)),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                CircleAvatar(radius: 3, backgroundColor: Color(0xFF22C55E)),
                                SizedBox(width: 4),
                                Text(
                                  'Sistem Aktif',
                                  style: TextStyle(color: Colors.white, fontSize: 10.5, fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Selamat Bertugas, $_username 👋',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Sistem Informasi Peminjaman Alat Laboratorium & Sarpras Kampus.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withValues(alpha: 0.88),
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Peringatan Terlambat (Jika Ada)
            if (terlambat.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: kBgDanger,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: kColorDanger.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded, size: 20, color: kColorDanger),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Perhatian: ${terlambat.length} peminjaman melewati batas waktu pengembalian!',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: kColorDanger),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],

            // ── 4 Ringkasan Statistik Utama ───────────────────────
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 1.55,
              children: [
                StatCard(
                  label: 'Total Stok Alat',
                  value: '$totalAlat',
                  icon: Icons.inventory_2_outlined,
                  color: kBrandPrimary,
                  subtitle: '$totalJenis jenis terdaftar',
                ),
                StatCard(
                  label: 'Alat Tersedia',
                  value: '$alatTersedia',
                  icon: Icons.check_circle_outline,
                  color: kColorSuccess,
                  subtitle: 'Siap dipinjam',
                ),
                StatCard(
                  label: 'Sedang Dipinjam',
                  value: '$totalDipinjam',
                  icon: Icons.timelapse,
                  color: kColorInfo,
                  subtitle: 'Peminjaman aktif',
                ),
                StatCard(
                  label: 'Total Transaksi',
                  value: '$totalTransaksi',
                  icon: Icons.receipt_long_outlined,
                  color: kBrandAccent,
                  subtitle: 'Tercatat di sistem',
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Peminjaman Aktif Terkini
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Icon(Icons.assignment_outlined, size: 17, color: kBrandAccent),
                const SizedBox(width: 7),
                Expanded(
                  child: Text(
                    'Peminjaman Yang Sedang Berjalan',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: kTextMain),
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: kBrandAccent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${pinjamanAktif.length} transaksi',
                    style: const TextStyle(fontSize: 11, color: kBrandAccent, fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            if (pinjamanAktif.isEmpty)
              const CleanCard(
                padding: EdgeInsets.symmetric(vertical: 28, horizontal: 16),
                child: Center(
                  child: Text(
                    'Tidak ada peminjaman aktif saat ini. Semua alat telah dikembalikan.',
                    style: TextStyle(fontSize: 12.5, color: kTextMuted),
                  ),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: pinjamanAktif.take(4).length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (_, i) {
                  final loan = pinjamanAktif[i];
                  return CleanCard(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: loan.isTerlambat ? kBgDanger : const Color(0xFFEFF6FF),
                              radius: 17,
                              child: Text(
                                getInitial(loan.namaMahasiswa),
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: loan.isTerlambat ? kColorDanger : kBrandAccent,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    loan.namaMahasiswa,
                                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: kTextMain),
                                  ),
                                  Text(
                                    'NIM: ${loan.nimMahasiswa} • ${loan.prodiMahasiswa}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontSize: 11, color: kTextMuted),
                                  ),
                                ],
                              ),
                            ),
                            if (loan.isTerlambat)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: kBgDanger,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: kColorDanger.withValues(alpha: 0.3)),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.warning_amber_rounded, size: 12, color: kColorDanger),
                                    SizedBox(width: 3),
                                    Text('Terlambat', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: kColorDanger)),
                                  ],
                                ),
                              )
                            else
                              const StatusBadge('dipinjam'),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Row(
                                  children: [
                                    const Icon(Icons.event_outlined, size: 13, color: kTextMuted),
                                    const SizedBox(width: 5),
                                    Expanded(
                                      child: Text(
                                        'Batas: ${formatDate(loan.tanggalRencanaKembali)}',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 11.5,
                                          fontWeight: loan.isTerlambat ? FontWeight.w700 : FontWeight.w500,
                                          color: loan.isTerlambat ? kColorDanger : kTextMain,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '${loan.daftarAlat.length} item alat',
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: kBrandAccent),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}
