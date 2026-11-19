// lib/screens/admin/pengembalian_screen.dart
import 'package:flutter/material.dart';
import '../../core/api_service.dart';
import '../../models/tool_model.dart';
import '../../models/return_model.dart';
import '../../widgets/app_widgets.dart';

class PengembalianScreen extends StatefulWidget {
  const PengembalianScreen({super.key});

  @override
  State<PengembalianScreen> createState() => _PengembalianScreenState();
}

class _PengembalianScreenState extends State<PengembalianScreen> {
  List<Pengembalian> _returns = [];
  Map<int, Tool> _toolsMap = {};
  bool _loading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _loading = true);
    try {
      final toolsData = await ApiService.get('/tools');
      final returnsData = await ApiService.get('/returns');
      final map = <int, Tool>{};
      for (final t in toolsData as List) {
        final tool = Tool.fromJson(t);
        map[tool.idTool] = tool;
      }
      setState(() {
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

  @override
  Widget build(BuildContext context) {
    final q = _searchQuery.toLowerCase();
    final filtered = _returns.where((r) {
      if ('${r.idReturn}'.contains(q) || '${r.idLoan}'.contains(q)) return true;
      if (r.catatan?.toLowerCase().contains(q) == true) return true;
      for (final d in r.detailPengembalian) {
        if (d.namaAlat?.toLowerCase().contains(q) == true) return true;
        final tool = d.idTool > 0 ? _toolsMap[d.idTool] : null;
        if (tool?.namaAlat.toLowerCase().contains(q) == true) return true;
      }
      return false;
    }).toList();

    return Scaffold(
      backgroundColor: kBackground,
      body: Column(
        children: [
          // Search & Summary Header
          Container(
            color: kSurface,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Column(
              children: [
                TextField(
                  onChanged: (v) => setState(() => _searchQuery = v),
                  decoration: InputDecoration(
                    hintText: 'Cari riwayat (No. Riwayat, No. Pinjam, nama alat)...',
                    hintStyle: const TextStyle(fontSize: 12.5, color: kTextSubtle),
                    prefixIcon: const Icon(Icons.search, size: 18, color: kTextMuted),
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
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: kBorder),
                      ),
                      child: Text(
                        'Total Riwayat Selesai: ${_returns.length}',
                        style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: kTextMain),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: kBorder),

          Expanded(
            child: _loading
                ? const LoadingWidget(message: 'Memuat riwayat pengembalian...')
                : filtered.isEmpty
                    ? const EmptyState(
                        icon: Icons.history,
                        title: 'Belum ada riwayat pengembalian',
                        subtitle: 'Alat yang telah diproses kembali akan tercatat otomatis di sini',
                      )
                    : RefreshIndicator(
                        onRefresh: _fetchData,
                        color: kBrandAccent,
                        child: ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: filtered.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 10),
                          itemBuilder: (_, i) {
                            final r = filtered[i];
                            return CleanCard(
                              padding: const EdgeInsets.all(15),
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
                                              color: const Color(0xFFDCFCE7),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: const Icon(
                                              Icons.assignment_turned_in_outlined,
                                              size: 16,
                                              color: kColorSuccess,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            'Riwayat #${r.idReturn}',
                                            style: const TextStyle(
                                                fontSize: 14, fontWeight: FontWeight.w700, color: kTextMain),
                                          ),
                                        ],
                                      ),
                                      const StatusBadge('selesai'),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF8FAFC),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: const Color(0xFFF1F5F9)),
                                    ),
                                    child: Column(
                                      children: [
                                        InfoLine(label: 'No. Peminjaman', value: '#${r.idLoan}'),
                                        const SizedBox(height: 4),
                                        InfoLine(
                                            label: 'Waktu Pengembalian',
                                            value: formatDateTime(r.tanggalPengembalian)),
                                        if (r.catatan != null && r.catatan!.isNotEmpty) ...[
                                          const SizedBox(height: 4),
                                          InfoLine(label: 'Catatan Petugas', value: r.catatan!),
                                        ],
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  const Text(
                                    'Detail Alat yang Dikembalikan:',
                                    style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: kTextMuted),
                                  ),
                                  const SizedBox(height: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: kBorder),
                                    ),
                                    child: Column(
                                      children: r.detailPengembalian.map((d) {
                                        final tool = d.idTool > 0 ? _toolsMap[d.idTool] : null;
                                        final namaAlat = (d.namaAlat?.isNotEmpty == true)
                                            ? d.namaAlat!
                                            : (tool?.namaAlat ?? (d.idTool > 0 ? 'Alat #${d.idTool}' : 'Alat'));
                                        return Padding(
                                          padding: const EdgeInsets.symmetric(vertical: 3),
                                          child: Row(
                                            children: [
                                              const Icon(Icons.circle, size: 5, color: kBrandAccent),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: Text(
                                                  namaAlat,
                                                  style: const TextStyle(
                                                      fontSize: 12.5, fontWeight: FontWeight.w500, color: kTextMain),
                                                ),
                                              ),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                                decoration: BoxDecoration(
                                                  color: const Color(0xFFF1F5F9),
                                                  borderRadius: BorderRadius.circular(4),
                                                ),
                                                child: Text(
                                                  '${d.jumlah} unit',
                                                  style: const TextStyle(
                                                      fontSize: 11, fontWeight: FontWeight.w600, color: kTextMain),
                                                ),
                                              ),
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
                      ),
          ),
        ],
      ),
    );
  }
}
