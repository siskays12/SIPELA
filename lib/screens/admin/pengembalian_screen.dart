// lib/screens/admin/pengembalian_screen.dart
import 'package:flutter/material.dart';
import '../../core/api_service.dart';
import '../../models/loan_model.dart';
import '../../models/tool_model.dart';
import '../../models/return_model.dart';
import '../../widgets/app_widgets.dart';

class PengembalianScreen extends StatefulWidget {
  const PengembalianScreen({super.key});

  @override
  State<PengembalianScreen> createState() => _PengembalianScreenState();
}

class _PengembalianScreenState extends State<PengembalianScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Loan> _loansDipinjam = [];
  List<Pengembalian> _returns = [];
  Map<int, Tool> _toolsMap = {};
  bool _loading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchData() async {
    setState(() => _loading = true);
    try {
      final loansData = await ApiService.get('/loans');
      final toolsData = await ApiService.get('/tools');
      final returnsData = await ApiService.get('/returns');
      final map = <int, Tool>{};
      for (final t in toolsData as List) {
        final tool = Tool.fromJson(t);
        map[tool.idTool] = tool;
      }
      setState(() {
        final allLoans = (loansData as List).map((e) => Loan.fromJson(e)).toList();
        _loansDipinjam = allLoans.where((l) => l.status == 'dipinjam').toList();
        _returns = (returnsData as List).map((e) => Pengembalian.fromJson(e)).toList()
          ..sort((a, b) => b.idReturn.compareTo(a.idReturn));
        _toolsMap = map;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) showError(context, e.toString());
    }
  }

  Future<void> _prosesKembali(Loan loan) async {
    final items = loan.daftarAlat.map((item) {
      final tool = item.idTool != null ? _toolsMap[item.idTool] : null;
      // Prioritas nama: free-text namaAlat → lookup toolsMap → fallback
      final displayName = (item.namaAlat?.isNotEmpty == true)
          ? item.namaAlat!
          : (tool?.namaAlat ?? (item.idTool != null ? 'Alat #${item.idTool}' : 'Alat tidak diketahui'));
      return _ReturnItem(
        idTool: item.idTool ?? 0,
        namaAlat: displayName,
        kodeAlat: tool?.kodeAlat ?? '-',
        jumlah: item.jumlah,
        kondisi: 'baik',
      );
    }).toList();

    final catatanCtrl = TextEditingController();
    bool saving = false;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          backgroundColor: kSurface,
          insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560, maxHeight: 720),
            child: Padding(
              padding: const EdgeInsets.all(22),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Dialog Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Proses Pengembalian Alat',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: kTextMain,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            'Transaksi #${loan.idLoan} • ${loan.namaMahasiswa.isNotEmpty ? "${loan.namaMahasiswa} (${loan.nimMahasiswa})" : "Mahasiswa #${loan.idCustomer}"}',
                            style: const TextStyle(fontSize: 12.5, color: kTextMuted),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, size: 20, color: kTextMuted),
                        onPressed: () => Navigator.pop(ctx),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  const Divider(height: 1, color: kBorder),
                  const SizedBox(height: 14),

                  // Scrollable Body
                  Flexible(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Cek Kondisi Fisik Alat:',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: kTextMain,
                                ),
                              ),
                              Text(
                                '${items.length} jenis alat',
                                style: const TextStyle(fontSize: 12, color: kTextMuted),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),

                          // Tools list with clean Condition Chips
                          ...items.map((item) => Container(
                                margin: const EdgeInsets.only(bottom: 10),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF8FAFC),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: kBorder),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                item.namaAlat,
                                                style: const TextStyle(
                                                  fontSize: 13.5,
                                                  fontWeight: FontWeight.w600,
                                                  color: kTextMain,
                                                ),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                item.kodeAlat,
                                                style: const TextStyle(fontSize: 11.5, color: kTextMuted),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFE2E8F0),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            '${item.jumlah} unit',
                                            style: const TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w700,
                                              color: kTextMain,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 10),
                                    const Text(
                                      'Kondisi Saat Dikembalikan:',
                                      style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w500, color: kTextMuted),
                                    ),
                                    const SizedBox(height: 6),

                                    // Clear Segmented / Chip Selector
                                    Row(
                                      children: [
                                        Expanded(
                                          child: _conditionChip(
                                            label: 'Baik',
                                            icon: Icons.check_circle_outline,
                                            isSelected: item.kondisi == 'baik',
                                            activeColor: kColorSuccess,
                                            onTap: () => setS(() => item.kondisi = 'baik'),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: _conditionChip(
                                            label: 'Rusak',
                                            icon: Icons.error_outline,
                                            isSelected: item.kondisi == 'rusak',
                                            activeColor: kColorDanger,
                                            onTap: () => setS(() => item.kondisi = 'rusak'),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: _conditionChip(
                                            label: 'Hilang',
                                            icon: Icons.help_outline,
                                            isSelected: item.kondisi == 'hilang',
                                            activeColor: const Color(0xFF7C3AED),
                                            onTap: () => setS(() => item.kondisi = 'hilang'),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              )),

                          const SizedBox(height: 10),
                          const Text(
                            'Catatan Petugas Lab (Opsional):',
                            style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: kTextMain),
                          ),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: catatanCtrl,
                            maxLines: 2,
                            decoration: InputDecoration(
                              hintText: 'Contoh: Alat dikembalikan dalam keadaan bersih dan lengkap kabelnya',
                              hintStyle: const TextStyle(fontSize: 12, color: kTextSubtle),
                              filled: true,
                              fillColor: const Color(0xFFF8FAFC),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(color: kBorder),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(color: kBorder),
                              ),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),
                  const Divider(height: 1, color: kBorder),
                  const SizedBox(height: 14),

                  // Dialog Actions
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('Batal', style: TextStyle(color: kTextMuted, fontSize: 13)),
                      ),
                      const SizedBox(width: 8),
                      AppButton(
                        label: 'Selesaikan Pengembalian',
                        color: kColorSuccess,
                        icon: Icons.check,
                        isLoading: saving,
                        onPressed: () async {
                          setS(() => saving = true);
                          try {
                            final detail = items
                                .map((item) => {
                                      'id_tool': item.idTool,
                                      'nama_alat': item.namaAlat,
                                      'jumlah': item.jumlah,
                                      'kondisi': item.kondisi,
                                    })
                                .toList();
                            await ApiService.post('/returns/${loan.idLoan}', {
                              'detail_pengembalian': detail,
                              'catatan': catatanCtrl.text.trim().isEmpty ? null : catatanCtrl.text.trim(),
                            });
                            if (ctx.mounted) Navigator.pop(ctx);
                            if (mounted) {
                              showSuccess(context, 'Pengembalian peminjaman #${loan.idLoan} berhasil dicatat');
                              _fetchData();
                            }
                          } catch (e) {
                            if (mounted) showError(context, e.toString());
                          } finally {
                            setS(() => saving = false);
                          }
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _conditionChip({
    required String label,
    required IconData icon,
    required bool isSelected,
    required Color activeColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 9),
        decoration: BoxDecoration(
          color: isSelected ? activeColor.withValues(alpha: 0.1) : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? activeColor : kBorder,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 14,
              color: isSelected ? activeColor : kTextMuted,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? activeColor : kTextMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
              tabs: [
                Tab(text: 'Sedang Dipinjam (${_loansDipinjam.length})'),
                Tab(text: 'Riwayat Selesai (${_returns.length})'),
              ],
            ),
          ),
          const Divider(height: 1, color: kBorder),

          Expanded(
            child: _loading
                ? const LoadingWidget(message: 'Memuat data pengembalian...')
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _buildDipinjamList(),
                      _buildReturnsList(),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildDipinjamList() {
    final q = _searchQuery.toLowerCase();
    final filtered = _loansDipinjam.where((l) =>
        l.namaMahasiswa.toLowerCase().contains(q) ||
        l.nimMahasiswa.toLowerCase().contains(q) ||
        '${l.idLoan}'.contains(q)).toList();

    return Column(
      children: [
        Container(
          color: kSurface,
          padding: const EdgeInsets.all(12),
          child: TextField(
            onChanged: (v) => setState(() => _searchQuery = v),
            decoration: InputDecoration(
              hintText: 'Cari transaksi berdasarkan Nama Mahasiswa, NIM, atau No. Pinjam...',
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
              ? const EmptyState(
                  icon: Icons.check_circle_outline,
                  title: 'Tidak ada transaksi ditemukan',
                  subtitle: 'Semua alat telah dikembalikan atau tidak cocok dengan pencarian',
                )
              : RefreshIndicator(
                  onRefresh: _fetchData,
                  color: kBrandAccent,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: filtered.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (_, i) {
                      final loan = filtered[i];

                      return CleanCard(
                        padding: const EdgeInsets.all(16),
                        borderColor: loan.isTerlambat ? const Color(0xFFFCA5A5) : null,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: loan.isTerlambat ? kBgDanger : const Color(0xFFEFF6FF),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Icon(
                                        loan.isTerlambat ? Icons.warning_amber : Icons.assignment_outlined,
                                        size: 16,
                                        color: loan.isTerlambat ? kColorDanger : kBrandAccent,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Peminjaman #${loan.idLoan}',
                                      style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700, color: kTextMain),
                                    ),
                                  ],
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
                                        SizedBox(width: 4),
                                        Text('Terlambat', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: kColorDanger)),
                                      ],
                                    ),
                                  )
                                else
                                  const StatusBadge('dipinjam'),
                              ],
                            ),
                            const SizedBox(height: 12),

                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: const Color(0xFFF1F5F9)),
                              ),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 15,
                                    backgroundColor: kBrandPrimary,
                                    child: Text(
                                      getInitial(loan.namaMahasiswa),
                                      style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text('Mahasiswa Peminjam', style: TextStyle(fontSize: 10.5, color: kTextMuted)),
                                        Text(
                                          '${loan.namaMahasiswa} (${loan.nimMahasiswa})',
                                          style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: kTextMain),
                                        ),
                                        Text(
                                          loan.prodiMahasiswa,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(fontSize: 11, color: kBrandAccent, fontWeight: FontWeight.w500),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(height: 32, width: 1, color: kBorder),
                                  const SizedBox(width: 12),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text('Batas Pengembalian', style: TextStyle(fontSize: 10.5, color: kTextMuted)),
                                      const SizedBox(height: 1),
                                      Text(
                                        formatDate(loan.tanggalRencanaKembali),
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          color: loan.isTerlambat ? kColorDanger : kTextMain,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),

                            const Text('Daftar Alat yang Dipinjam:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: kTextMain)),
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: kBorder),
                              ),
                              child: Column(
                                children: loan.daftarAlat.map((item) {
                                  final tool = item.idTool != null ? _toolsMap[item.idTool] : null;
                                  final displayName = (item.namaAlat?.isNotEmpty == true)
                                      ? item.namaAlat!
                                      : (tool?.namaAlat ?? (item.idTool != null ? 'Alat #${item.idTool}' : 'Alat'));
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 3),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.circle, size: 5, color: kBrandAccent),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            displayName,
                                            style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w500, color: kTextMain),
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFF1F5F9),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            '${item.jumlah} unit',
                                            style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: kTextMuted),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),

                            const SizedBox(height: 14),
                            const Divider(height: 1, color: Color(0xFFF1F5F9)),
                            const SizedBox(height: 12),

                            Align(
                              alignment: Alignment.centerRight,
                              child: AppButton(
                                label: 'Proses Pengembalian',
                                icon: Icons.assignment_return_outlined,
                                color: kColorSuccess,
                                onPressed: () => _prosesKembali(loan),
                              ),
                            ),
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

  Widget _buildReturnsList() {
    if (_returns.isEmpty) {
      return const EmptyState(
        icon: Icons.history,
        title: 'Belum ada riwayat',
        subtitle: 'Riwayat pengembalian alat akan muncul di sini',
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchData,
      color: kBrandAccent,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _returns.length,
        separatorBuilder: (_, _) => const SizedBox(height: 8),
        itemBuilder: (_, i) {
          final r = _returns[i];
          return CleanCard(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Pengembalian #${r.idReturn}',
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: kTextMain),
                    ),
                    const StatusBadge('selesai'),
                  ],
                ),
                const SizedBox(height: 8),
                InfoLine(label: 'No. Pinjaman', value: '#${r.idLoan}'),
                InfoLine(label: 'Waktu Kembali', value: formatDateTime(r.tanggalPengembalian)),
                if (r.catatan != null && r.catatan!.isNotEmpty)
                  InfoLine(label: 'Catatan', value: r.catatan!),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Column(
                    children: r.detailPengembalian.map((d) {
                      final tool = d.idTool > 0 ? _toolsMap[d.idTool] : null;
                      final namaAlat = (d.namaAlat?.isNotEmpty == true)
                          ? d.namaAlat!
                          : (tool?.namaAlat ?? (d.idTool > 0 ? 'Alat #${d.idTool}' : 'Alat'));
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                namaAlat,
                                style: const TextStyle(fontSize: 12, color: kTextMain),
                              ),
                            ),
                            Text('${d.jumlah} unit', style: const TextStyle(fontSize: 12, color: kTextMuted)),
                            const SizedBox(width: 8),
                            KondisiBadge(d.kondisi),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ReturnItem {
  final int idTool; // 0 jika free-text (tanpa id_tool)
  final String namaAlat;
  final String kodeAlat;
  final int jumlah;
  String kondisi;

  _ReturnItem({
    required this.idTool,
    required this.namaAlat,
    required this.kodeAlat,
    required this.jumlah,
    required this.kondisi,
  });
}
