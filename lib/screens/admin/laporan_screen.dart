// lib/screens/admin/laporan_screen.dart
import 'package:flutter/material.dart';
import '../../core/api_service.dart';
import '../../models/loan_model.dart';
import '../../models/tool_model.dart';
import '../../models/return_model.dart';
import '../../widgets/app_widgets.dart';

class LaporanScreen extends StatefulWidget {
  const LaporanScreen({super.key});

  @override
  State<LaporanScreen> createState() => _LaporanScreenState();
}

class _LaporanScreenState extends State<LaporanScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Loan> _loans = [];
  List<Pengembalian> _returns = [];
  List<Tool> _tools = [];
  bool _loading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final loansData = await ApiService.get('/loans');
      final returnsData = await ApiService.get('/returns');
      final toolsData = await ApiService.get('/tools');

      setState(() {
        _loans = (loansData as List).map((e) => Loan.fromJson(e)).toList()
          ..sort((a, b) => b.idLoan.compareTo(a.idLoan));
        _returns = (returnsData as List).map((e) => Pengembalian.fromJson(e)).toList()
          ..sort((a, b) => b.idReturn.compareTo(a.idReturn));
        _tools = (toolsData as List).map((e) => Tool.fromJson(e)).toList();
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
        body: LoadingWidget(message: 'Memuat laporan & riwayat...'),
      );
    }

    return Scaffold(
      backgroundColor: kBackground,
      body: Column(
        children: [
          Container(
            color: kSurface,
            child: TabBar(
              controller: _tabController,
              labelColor: kBrandAccent,
              unselectedLabelColor: kTextMuted,
              labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              unselectedLabelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.normal),
              indicatorColor: kBrandAccent,
              indicatorWeight: 2.5,
              tabs: const [
                Tab(text: 'Statistik & Laporan Lab'),
                Tab(text: 'Semua Riwayat'),
              ],
            ),
          ),
          const Divider(height: 1, color: kBorder),

          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildLaporanTab(),
                _buildRiwayatTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Tab 1: Ringkasan Laporan ─────────────────
  Widget _buildLaporanTab() {
    final totalPinjam = _loans.length;
    final sedangDipinjam = _loans.where((l) => l.status == 'dipinjam').length;
    final terlambat = _loans.where((l) => l.isTerlambat).toList();

    // Hitung alat paling sering dipinjam (hanya yang punya id_tool)
    final Map<int, int> toolFreq = {};
    for (var loan in _loans) {
      for (var item in loan.daftarAlat) {
        if (item.idTool != null) {
          toolFreq[item.idTool!] = (toolFreq[item.idTool!] ?? 0) + item.jumlah;
        }
      }
    }
    final sortedToolEntries = toolFreq.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // Kondisi alat
    final baikCount = _tools.where((t) => t.kondisi == 'baik').length;
    final rusakCount = _tools.where((t) => t.kondisi == 'rusak').length;
    final rawatCount = _tools.where((t) => t.kondisi == 'perawatan').length;

    return RefreshIndicator(
      onRefresh: _loadData,
      color: kBrandAccent,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Cards
            Row(
              children: [
                Expanded(
                  child: StatCard(
                    label: 'Total Peminjaman',
                    value: '$totalPinjam kali',
                    icon: Icons.history,
                    color: kBrandPrimary,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: StatCard(
                    label: 'Belum Kembali',
                    value: '$sedangDipinjam transaksi',
                    icon: Icons.timelapse,
                    color: kColorInfo,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Terlambat Alert
            if (terlambat.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: kBgDanger,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: kColorDanger.withValues(alpha: 0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.warning_amber_rounded, size: 18, color: kColorDanger),
                        const SizedBox(width: 8),
                        Text(
                          'Peringatan: ${terlambat.length} Peminjaman Melewati Tenggat!',
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: kColorDanger),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ...terlambat.map((l) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 3),
                          child: Text(
                            '• Peminjaman #${l.idLoan} (${l.namaMahasiswa} - ${l.nimMahasiswa}) batas: ${formatDate(l.tanggalRencanaKembali)}',
                            style: const TextStyle(fontSize: 12, color: kTextMain),
                          ),
                        )),
                  ],
                ),
              ),
              const SizedBox(height: 14),
            ],

            // Section 1: Alat Paling Sering Dipinjam
            const Text(
              'Alat Laboratorium Paling Sering Dipinjam',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: kTextMain),
            ),
            const SizedBox(height: 8),
            CleanCard(
              padding: const EdgeInsets.all(14),
              child: sortedToolEntries.isEmpty
                  ? const Text('Belum ada data peminjaman', style: TextStyle(fontSize: 12, color: kTextMuted))
                  : Column(
                      children: sortedToolEntries.take(5).map((entry) {
                        final tool = _tools.firstWhere((t) => t.idTool == entry.key, orElse: () => Tool(idTool: 0, kodeAlat: '', namaAlat: 'Alat #${entry.key}', stokTotal: 0, stokTersedia: 0, kondisi: 'baik'));
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 5),
                          child: Row(
                            children: [
                              Builder(
                                builder: (_) {
                                  final rank = sortedToolEntries.indexOf(entry) + 1;
                                  Color badgeBg = const Color(0xFFEFF6FF);
                                  Color badgeFg = kBrandAccent;
                                  if (rank == 1) {
                                    badgeBg = const Color(0xFFFEF3C7);
                                    badgeFg = const Color(0xFFD97706);
                                  } else if (rank == 2) {
                                    badgeBg = const Color(0xFFF1F5F9);
                                    badgeFg = const Color(0xFF475569);
                                  } else if (rank == 3) {
                                    badgeBg = const Color(0xFFFFEDD5);
                                    badgeFg = const Color(0xFFC2410C);
                                  }
                                  return Container(
                                    width: 26,
                                    height: 26,
                                    decoration: BoxDecoration(
                                      color: badgeBg,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Center(
                                      child: Text(
                                        '$rank',
                                        style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: badgeFg),
                                      ),
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(tool.namaAlat, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: kTextMain)),
                              ),
                              Text('${entry.value}x dipinjam', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: kBrandPrimary)),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
            ),
            const SizedBox(height: 18),

            // Section 2: Laporan Kondisi Alat
            const Text(
              'Ringkasan Kondisi Alat Laboratorium',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: kTextMain),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _conditionSummaryCard(
                    title: 'Kondisi Baik',
                    count: baikCount,
                    color: kColorSuccess,
                    bg: kBgSuccess,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _conditionSummaryCard(
                    title: 'Perlu Perawatan',
                    count: rawatCount,
                    color: kColorWarning,
                    bg: kBgWarning,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _conditionSummaryCard(
                    title: 'Kondisi Rusak',
                    count: rusakCount,
                    color: kColorDanger,
                    bg: kBgDanger,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _conditionSummaryCard({
    required String title,
    required int count,
    required Color color,
    required Color bg,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Text('$count', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: color)),
          const SizedBox(height: 2),
          Text(title, textAlign: TextAlign.center, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color)),
        ],
      ),
    );
  }

  // ─── Tab 2: Riwayat Transaksi Lengkap ─────────
  Widget _buildRiwayatTab() {
    final filtered = _loans.where((l) {
      final q = _searchQuery.toLowerCase();
      return l.namaMahasiswa.toLowerCase().contains(q) ||
          l.nimMahasiswa.toLowerCase().contains(q) ||
          '${l.idLoan}'.contains(q);
    }).toList();

    return Column(
      children: [
        Container(
          color: kSurface,
          padding: const EdgeInsets.all(12),
          child: TextField(
            onChanged: (v) => setState(() => _searchQuery = v),
            decoration: InputDecoration(
              hintText: 'Cari riwayat berdasarkan NIM, Nama, atau No. Pinjam...',
              hintStyle: const TextStyle(fontSize: 12.5, color: kTextSubtle),
              prefixIcon: const Icon(Icons.search, size: 18, color: kTextMuted),
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: kBorder)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: kBorder)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              isDense: true,
            ),
          ),
        ),
        const Divider(height: 1, color: kBorder),

        Expanded(
          child: filtered.isEmpty
              ? const EmptyState(icon: Icons.history, title: 'Tidak ada riwayat peminjaman')
              : RefreshIndicator(
                  onRefresh: _loadData,
                  color: kBrandAccent,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: filtered.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (_, i) {
                      final loan = filtered[i];
                      final ret = _returns.firstWhere((r) => r.idLoan == loan.idLoan, orElse: () => Pengembalian(idReturn: 0, idLoan: 0, idAdmin: 0, detailPengembalian: []));

                      return CleanCard(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Riwayat #${loan.idLoan}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: kTextMain)),
                                if (loan.isTerlambat)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(color: kBgDanger, borderRadius: BorderRadius.circular(6)),
                                    child: const Text('Terlambat', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: kColorDanger)),
                                  )
                                else
                                  StatusBadge(loan.status),
                              ],
                            ),
                            const SizedBox(height: 6),
                            InfoLine(label: 'Mahasiswa', value: '${loan.namaMahasiswa} (${loan.nimMahasiswa})'),
                            InfoLine(label: 'Waktu Pinjam', value: formatDateTime(loan.tanggalPinjam)),
                            InfoLine(label: 'Target Kembali', value: formatDate(loan.tanggalRencanaKembali)),
                            if (loan.status == 'selesai' && ret.idReturn != 0)
                              InfoLine(label: 'Waktu Pengembalian', value: formatDateTime(ret.tanggalPengembalian)),
                            if (loan.keperluan != null && loan.keperluan!.isNotEmpty)
                              InfoLine(label: 'Keperluan', value: loan.keperluan!),
                          ],
                        ),
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }
}
