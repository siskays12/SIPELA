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

      if (mounted) {
        setState(() {
          _loans = (loansData as List).map((e) => Loan.fromJson(e)).toList()
            ..sort((a, b) => b.idLoan.compareTo(a.idLoan));
          _tools = (toolsData as List).map((e) => Tool.fromJson(e)).toList();
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

    return Scaffold(
      backgroundColor: kBackground,
      body: RefreshIndicator(
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
              const SizedBox(height: 12),

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
                          Expanded(
                            child: Text(
                              'Peringatan: ${terlambat.length} Peminjaman Melewati Tenggat!',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: kColorDanger),
                            ),
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
                    ? const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: Text('Belum ada data peminjaman alat', style: TextStyle(fontSize: 12, color: kTextMuted)),
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
                            padding: const EdgeInsets.symmetric(vertical: 5),
                            child: Row(
                              children: [
                                Container(
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
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    tool.namaAlat,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: kTextMain),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '${entry.value}x dipinjam',
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: kBrandPrimary),
                                ),
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
                      title: 'Perawatan',
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
}
