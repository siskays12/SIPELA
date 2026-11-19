// lib/screens/admin/laporan_screen.dart
import 'package:flutter/material.dart';
import '../../core/api_service.dart';
import '../../models/loan_model.dart';
import '../../models/tool_model.dart';
import '../../widgets/app_widgets.dart';

class LaporanScreen extends StatefulWidget {
  const LaporanScreen({super.key});

  @override
  State<LaporanScreen> createState() => _LaporanScreenState();
}

class _LaporanScreenState extends State<LaporanScreen> {
  List<Loan> _loans = [];
  List<Tool> _tools = [];
  int _customerCount = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final loansData = await ApiService.get('/loans');
      final toolsData = await ApiService.get('/tools');
      final customerData = await ApiService.get('/customer');

      if (mounted) {
        setState(() {
          _loans = (loansData as List).map((e) => Loan.fromJson(e)).toList()
            ..sort((a, b) => b.idLoan.compareTo(a.idLoan));
          _tools = (toolsData as List).map((e) => Tool.fromJson(e)).toList();
          _customerCount = (customerData as List).length;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        showError(context, e.toString());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: kBackground,
        body: LoadingWidget(message: 'Memuat statistik & laporan lab...'),
      );
    }

    final totalPinjam = _loans.length;
    final sedangDipinjam = _loans.where((l) => l.status == 'dipinjam').length;
    final selesai = _loans.where((l) => l.status == 'selesai').length;
    final terlambat = _loans.where((l) => l.isTerlambat).toList();

    // Hitung stok total unit fisik dan stok tersedia
    int totalStokFisik = 0;
    int totalStokTersedia = 0;
    for (var t in _tools) {
      totalStokFisik += t.stokTotal;
      totalStokTersedia += t.stokTersedia;
    }
    final totalStokDipinjam = (totalStokFisik - totalStokTersedia).clamp(0, totalStokFisik);

    // Hitung alat paling sering dipinjam
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
    final rawatCount = _tools.where((t) => t.kondisi == 'perawatan').length;
    final rusakCount = _tools.where((t) => t.kondisi == 'rusak').length;

    // Distribusi Peminjaman per Program Studi
    final Map<String, int> prodiMap = {};
    for (var l in _loans) {
      final p = l.prodiMahasiswa.trim();
      if (p.isNotEmpty && p != '-') {
        // Ambil nama prodi yang rapi
        final cleanP = p.replaceAll('(D4)', '').replaceAll('(D3)', '').trim();
        prodiMap[cleanP] = (prodiMap[cleanP] ?? 0) + 1;
      }
    }
    final sortedProdi = prodiMap.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // Distribusi Kategori Alat
    final Map<String, int> kategoriMap = {};
    for (var t in _tools) {
      final k = t.kategori.trim();
      if (k.isNotEmpty) {
        kategoriMap[k] = (kategoriMap[k] ?? 0) + 1;
      }
    }
    final sortedKategori = kategoriMap.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // Persentase utilisasi stok
    final double utilPercent = totalStokFisik > 0
        ? (totalStokDipinjam / totalStokFisik)
        : 0.0;

    return Scaffold(
      backgroundColor: kBackground,
      body: RefreshIndicator(
        onRefresh: _loadData,
        color: kBrandAccent,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── 1. Header Ringkasan Statistik ──────────────────
              Row(
                children: [
                  const Icon(Icons.analytics_outlined, size: 20, color: kBrandPrimary),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Statistik & Laporan Laboratorium',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: kTextMain),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${_tools.length} Jenis Alat',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: kBrandAccent),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // ── 2. Grid 4 Kartu Metrik Utama ──────────────────
              Row(
                children: [
                  Expanded(
                    child: StatCard(
                      label: 'Total Peminjaman',
                      value: '$totalPinjam',
                      subtitle: '$selesai selesai',
                      icon: Icons.history,
                      color: kBrandPrimary,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: StatCard(
                      label: 'Sedang Berjalan',
                      value: '$sedangDipinjam',
                      subtitle: 'Peminjaman aktif',
                      icon: Icons.timelapse,
                      color: kColorInfo,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: StatCard(
                      label: 'Total Stok Fisik',
                      value: '$totalStokFisik unit',
                      subtitle: '$totalStokTersedia unit ready',
                      icon: Icons.inventory_2_outlined,
                      color: kColorSuccess,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: StatCard(
                      label: 'Data Mahasiswa',
                      value: '$_customerCount',
                      subtitle: 'Mahasiswa terdata',
                      icon: Icons.people_outline,
                      color: const Color(0xFF7C3AED),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // ── 3. Peringatan Terlambat (Jika Ada) ──────────────
              if (terlambat.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.all(12),
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
                          Expanded(
                            child: Text(
                              'Peringatan: ${terlambat.length} Peminjaman Melewati Tenggat!',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: kColorDanger),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ...terlambat.take(3).map((l) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 2),
                            child: Text(
                              '• #${l.idLoan} ${l.namaMahasiswa} (${l.nimMahasiswa}) — batas: ${formatDate(l.tanggalRencanaKembali)}',
                              style: const TextStyle(fontSize: 11.5, color: kTextMain),
                            ),
                          )),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // ── 4. Utilisasi & Ketersediaan Stok Lab ─────────────
              const Text(
                'Ketersediaan & Utilisasi Stok Lab',
                style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: kTextMain),
              ),
              const SizedBox(height: 8),
              CleanCard(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${(utilPercent * 100).toStringAsFixed(1)}% Stok Sedang Dipakai',
                          style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: kTextMain),
                        ),
                        Text(
                          '$totalStokDipinjam dari $totalStokFisik unit',
                          style: const TextStyle(fontSize: 11.5, color: kTextMuted, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: totalStokFisik > 0 ? utilPercent : 0.0,
                        backgroundColor: const Color(0xFFE2E8F0),
                        valueColor: const AlwaysStoppedAnimation<Color>(kBrandAccent),
                        minHeight: 8,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        _dotIndicator(color: kColorSuccess, label: 'Siap Dipinjam ($totalStokTersedia unit)'),
                        const Spacer(),
                        _dotIndicator(color: kBrandAccent, label: 'Dipinjam ($totalStokDipinjam unit)'),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // ── 5. Ringkasan Kondisi Fisik Alat ────────────────
              const Text(
                'Status Kondisi Fisik Inventaris',
                style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: kTextMain),
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
                      icon: Icons.check_circle_outline,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _conditionSummaryCard(
                      title: 'Perawatan',
                      count: rawatCount,
                      color: kColorWarning,
                      bg: kBgWarning,
                      icon: Icons.build_outlined,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _conditionSummaryCard(
                      title: 'Rusak',
                      count: rusakCount,
                      color: kColorDanger,
                      bg: kBgDanger,
                      icon: Icons.error_outline,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // ── 6. Alat Paling Sering Dipinjam ──────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Alat Paling Sering Dipinjam',
                    style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: kTextMain),
                  ),
                  if (sortedToolEntries.isNotEmpty)
                    Text(
                      'Top ${sortedToolEntries.take(5).length} Alat',
                      style: const TextStyle(fontSize: 11, color: kBrandAccent, fontWeight: FontWeight.w600),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              CleanCard(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                child: sortedToolEntries.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Center(
                          child: Text(
                            'Belum ada data riwayat peminjaman alat lab.',
                            style: TextStyle(fontSize: 12, color: kTextMuted),
                          ),
                        ),
                      )
                    : Column(
                        children: sortedToolEntries.take(5).map((entry) {
                          final tool = _tools.firstWhere(
                            (t) => t.idTool == entry.key,
                            orElse: () => Tool(
                              idTool: 0,
                              kodeAlat: '',
                              namaAlat: 'Alat #${entry.key}',
                              stokTotal: 0,
                              stokTersedia: 0,
                              kondisi: 'baik',
                            ),
                          );
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

                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: Row(
                              children: [
                                Container(
                                  width: 24,
                                  height: 24,
                                  decoration: BoxDecoration(
                                    color: badgeBg,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Center(
                                    child: Text(
                                      '$rank',
                                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: badgeFg),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        tool.namaAlat,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: kTextMain),
                                      ),
                                      Text(
                                        'Ready: ${tool.stokTersedia} unit',
                                        style: const TextStyle(fontSize: 10.5, color: kTextMuted),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF1F5F9),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    '${entry.value}x dipinjam',
                                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: kBrandPrimary),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
              ),
              const SizedBox(height: 18),

              // ── 7. Peminjaman Berdasarkan Program Studi ─────────
              if (sortedProdi.isNotEmpty) ...[
                const Text(
                  'Aktivitas Peminjaman per Program Studi',
                  style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: kTextMain),
                ),
                const SizedBox(height: 8),
                CleanCard(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    children: sortedProdi.take(4).map((e) {
                      final maxProdi = sortedProdi.first.value;
                      final ratio = maxProdi > 0 ? (e.value / maxProdi) : 0.0;
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    e.key,
                                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: kTextMain),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '${e.value}x pinjam',
                                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: kBrandAccent),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: ratio,
                                backgroundColor: const Color(0xFFF1F5F9),
                                valueColor: const AlwaysStoppedAnimation<Color>(kBrandAccent),
                                minHeight: 6,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 18),
              ],

              // ── 8. Distribusi Inventaris per Kategori ───────────
              if (sortedKategori.isNotEmpty) ...[
                const Text(
                  'Sebaran Inventaris per Kategori Alat',
                  style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: kTextMain),
                ),
                const SizedBox(height: 8),
                CleanCard(
                  padding: const EdgeInsets.all(12),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: sortedKategori.map((k) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: kBorder),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              k.key,
                              style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w500, color: kTextMain),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEFF6FF),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '${k.value}',
                                style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: kBrandAccent),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _dotIndicator({required Color color, required String label}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: TextStyle(fontSize: 11, color: kTextMuted, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  Widget _conditionSummaryCard({
    required String title,
    required int count,
    required Color color,
    required Color bg,
    required IconData icon,
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
          Icon(icon, size: 18, color: color),
          const SizedBox(height: 4),
          Text('$count', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: color)),
          const SizedBox(height: 1),
          Text(title, textAlign: TextAlign.center, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color)),
        ],
      ),
    );
  }
}
