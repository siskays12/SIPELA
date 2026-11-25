// lib/screens/customer/katalog_screen.dart
import 'package:flutter/material.dart';
import '../../core/api_service.dart';
import '../../models/tool_model.dart';
import '../../widgets/app_widgets.dart';

class KatalogScreen extends StatefulWidget {
  const KatalogScreen({super.key});

  @override
  State<KatalogScreen> createState() => _KatalogScreenState();
}

class _KatalogScreenState extends State<KatalogScreen> {
  List<Tool> _tools = [];
  List<Tool> _filtered = [];
  bool _loading = true;
  String _search = '';
  String _filterKondisi = '';

  @override
  void initState() {
    super.initState();
    _fetchTools();
  }

  Future<void> _fetchTools() async {
    setState(() => _loading = true);
    try {
      final data = await ApiService.get('/tools');
      setState(() {
        _tools = (data as List).map((e) => Tool.fromJson(e)).toList();
        _applyFilter();
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) showError(context, e.toString());
    }
  }

  void _applyFilter() {
    final q = _search.toLowerCase();
    setState(() {
      _filtered = _tools.where((t) {
        final matchSearch = t.namaAlat.toLowerCase().contains(q) || t.kodeAlat.toLowerCase().contains(q);
        final matchKondisi = _filterKondisi.isEmpty || t.kondisi == _filterKondisi;
        return matchSearch && matchKondisi;
      }).toList();
    });
  }

  void _showDetail(Tool tool) {
    showModalBottomSheet(
      context: context,
      backgroundColor: kSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tool.namaAlat,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: kTextMain),
                      ),
                      const SizedBox(height: 2),
                      Text(tool.kodeAlat, style: const TextStyle(fontSize: 12, color: kTextMuted)),
                    ],
                  ),
                ),
                KondisiBadge(tool.kondisi),
              ],
            ),
            const SizedBox(height: 14),
            const Divider(height: 1, color: kBorder),
            const SizedBox(height: 12),
            if (tool.deskripsi != null && tool.deskripsi!.isNotEmpty) ...[
              const Text('Deskripsi Alat', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: kTextMuted)),
              const SizedBox(height: 4),
              Text(tool.deskripsi!, style: const TextStyle(fontSize: 13, color: kTextMain)),
              const SizedBox(height: 14),
            ],
            Row(
              children: [
                Expanded(
                  child: _stockInfoBox(
                    label: 'Stok Tersedia',
                    value: '${tool.stokTersedia} unit',
                    color: tool.stokTersedia > 0 ? kColorSuccess : kColorDanger,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _stockInfoBox(
                    label: 'Total Inventaris',
                    value: '${tool.stokTotal} unit',
                    color: kTextMain,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Untuk meminjam alat ini, buka menu "Pinjaman Saya" dan klik "Ajukan Peminjaman".',
              style: TextStyle(fontSize: 11.5, color: kTextMuted),
            ),
          ],
        ),
      ),
    );
  }

  Widget _stockInfoBox({required String label, required String value, required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: kBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 11.5, color: kTextMuted)),
          const SizedBox(height: 2),
          Text(value, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: color)),
        ],
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
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Column(
              children: [
                TextField(
                  onChanged: (v) {
                    _search = v;
                    _applyFilter();
                  },
                  decoration: InputDecoration(
                    hintText: 'Cari alat...',
                    hintStyle: const TextStyle(fontSize: 13, color: kTextSubtle),
                    prefixIcon: const Icon(Icons.search, size: 18, color: kTextMuted),
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: kBorder)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: kBorder)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _chip('Semua', ''),
                      const SizedBox(width: 6),
                      _chip('Baik', 'baik'),
                      const SizedBox(width: 6),
                      _chip('Rusak', 'rusak'),
                      const SizedBox(width: 6),
                      _chip('Perawatan', 'perawatan'),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: kBorder),

          Expanded(
            child: _loading
                ? const LoadingWidget(message: 'Memuat katalog alat...')
                : _filtered.isEmpty
                    ? const EmptyState(
                        icon: Icons.science_outlined,
                        title: 'Tidak ada alat ditemukan',
                        subtitle: 'Coba ubah kata kunci atau filter kondisi alat',
                      )
                    : RefreshIndicator(
                        onRefresh: _fetchTools,
                        color: kBrandAccent,
                        child: ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: _filtered.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 8),
                          itemBuilder: (_, i) {
                            final t = _filtered[i];
                            final ready = t.kondisi == 'baik' && t.stokTersedia > 0;

                            return CleanCard(
                              onTap: () => _showDetail(t),
                              padding: const EdgeInsets.all(14),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF1F5F9),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(
                                      Icons.science_outlined,
                                      size: 20,
                                      color: ready ? kBrandAccent : kTextSubtle,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          t.namaAlat,
                                          style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: kTextMain),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          t.kodeAlat,
                                          style: const TextStyle(fontSize: 11.5, color: kTextMuted),
                                        ),
                                        const SizedBox(height: 6),
                                        Row(
                                          children: [
                                            Text(
                                              'Tersedia: ',
                                              style: const TextStyle(fontSize: 12, color: kTextMuted),
                                            ),
                                            Text(
                                              '${t.stokTersedia} unit',
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                                color: ready ? kColorSuccess : kColorDanger,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  KondisiBadge(t.kondisi),
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

  Widget _chip(String label, String value) {
    final active = _filterKondisi == value;
    return GestureDetector(
      onTap: () {
        setState(() => _filterKondisi = value);
        _applyFilter();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: active ? kBrandPrimary : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: active ? FontWeight.w600 : FontWeight.w500,
            color: active ? Colors.white : kTextMuted,
          ),
        ),
      ),
    );
  }
}
