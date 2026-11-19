// lib/screens/admin/pengembalian_screen.dart
import 'package:flutter/material.dart';
import '../../core/api_service.dart';
import '../../models/tool_model.dart';
import '../../models/loan_model.dart';
import '../../models/return_model.dart';
import '../../widgets/app_widgets.dart';

class PengembalianScreen extends StatefulWidget {
  const PengembalianScreen({super.key});

  @override
  State<PengembalianScreen> createState() => _PengembalianScreenState();
}

class _PengembalianScreenState extends State<PengembalianScreen> {
  List<Pengembalian> _returns = [];
  Map<int, Loan> _loansMap = {};
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
      final loansData = await ApiService.get('/loans');

      final toolMap = <int, Tool>{};
      for (final t in toolsData as List) {
        final tool = Tool.fromJson(t);
        toolMap[tool.idTool] = tool;
      }

      final loanMap = <int, Loan>{};
      for (final l in loansData as List) {
        final loan = Loan.fromJson(l);
        loanMap[loan.idLoan] = loan;
      }

      setState(() {
        _returns = (returnsData as List).map((e) => Pengembalian.fromJson(e)).toList()
          ..sort((a, b) => b.idReturn.compareTo(a.idReturn));
        _toolsMap = toolMap;
        _loansMap = loanMap;
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
      final loan = _loansMap[r.idLoan];
      if ('${r.idReturn}'.contains(q) || '${r.idLoan}'.contains(q)) return true;
      if (loan != null) {
        if (loan.namaMahasiswa.toLowerCase().contains(q) ||
            loan.nimMahasiswa.toLowerCase().contains(q) ||
            loan.prodiMahasiswa.toLowerCase().contains(q)) {
          return true;
        }
      }
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
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
            child: Column(
              children: [
                TextField(
                  onChanged: (v) => setState(() => _searchQuery = v),
                  decoration: InputDecoration(
                    hintText: 'Cari riwayat (Nama, NIM, No. Pinjam, Alat)...',
                    hintStyle: const TextStyle(fontSize: 12.5, color: kTextSubtle),
                    prefixIcon: const Icon(Icons.search, size: 17, color: kTextMuted),
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
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total: ${_returns.length} riwayat selesai',
                      style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: kTextMuted),
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
                        subtitle: 'Alat yang telah diproses kembali akan tercatat di sini',
                      )
                    : RefreshIndicator(
                        onRefresh: _fetchData,
                        color: kBrandAccent,
                        child: ListView.separated(
                          padding: const EdgeInsets.all(12),
                          itemCount: filtered.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 8),
                          itemBuilder: (_, i) {
                            final r = filtered[i];
                            final loan = _loansMap[r.idLoan];
                            final namaMahasiswa = loan?.namaMahasiswa.isNotEmpty == true
                                ? loan!.namaMahasiswa
                                : 'Mahasiswa #${loan?.idCustomer ?? "-"}';
                            final nimMahasiswa = loan?.nimMahasiswa ?? '-';

                            return CleanCard(
                              padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Header: Nomor Riwayat & Pinjaman
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          const Icon(Icons.check_circle_outline, size: 15, color: kColorSuccess),
                                          const SizedBox(width: 5),
                                          Text(
                                            'Riwayat #${r.idReturn}',
                                            style: const TextStyle(
                                                fontSize: 13, fontWeight: FontWeight.w700, color: kTextMain),
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            '(Pinjam #${r.idLoan})',
                                            style: const TextStyle(fontSize: 11.5, color: kTextMuted),
                                          ),
                                        ],
                                      ),
                                      const StatusBadge('selesai'),
                                    ],
                                  ),
                                  const SizedBox(height: 6),

                                  // Identitas Peminjam
                                  Row(
                                    children: [
                                      const Icon(Icons.person_outline, size: 14, color: kTextMuted),
                                      const SizedBox(width: 5),
                                      Expanded(
                                        child: Text(
                                          '$namaMahasiswa ($nimMahasiswa)',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                              fontSize: 12, fontWeight: FontWeight.w600, color: kTextMain),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),

                                  // Baris Waktu: Pinjam ➔ Kembali (Kompak & Rapi)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF8FAFC),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(color: const Color(0xFFF1F5F9)),
                                    ),
                                    child: Row(
                                      children: [
                                        // Waktu Pinjam
                                        Expanded(
                                          child: Row(
                                            children: [
                                              const Icon(Icons.outbox_rounded, size: 12, color: kTextMuted),
                                              const SizedBox(width: 4),
                                              Expanded(
                                                child: Text(
                                                  loan != null ? formatDateTime(loan.tanggalPinjam) : '-',
                                                  style: const TextStyle(fontSize: 11, color: kTextMain),
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const Text(' ➔ ', style: TextStyle(fontSize: 11, color: kTextMuted)),
                                        // Waktu Kembali
                                        Expanded(
                                          child: Row(
                                            children: [
                                              const Icon(Icons.assignment_turned_in, size: 12, color: kColorSuccess),
                                              const SizedBox(width: 4),
                                              Expanded(
                                                child: Text(
                                                  formatDateTime(r.tanggalPengembalian),
                                                  style: const TextStyle(
                                                      fontSize: 11, fontWeight: FontWeight.w600, color: kColorSuccess),
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  // Daftar Alat yang dikembalikan
                                  const SizedBox(height: 6),
                                  Column(
                                    children: r.detailPengembalian.map((d) {
                                      final tool = d.idTool > 0 ? _toolsMap[d.idTool] : null;
                                      final namaAlat = (d.namaAlat?.isNotEmpty == true)
                                          ? d.namaAlat!
                                          : (tool?.namaAlat ?? (d.idTool > 0 ? 'Alat #${d.idTool}' : 'Alat'));
                                      return Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 1.5),
                                        child: Row(
                                          children: [
                                            const Text('• ', style: TextStyle(fontSize: 11, color: kBrandAccent)),
                                            Expanded(
                                              child: Text(
                                                namaAlat,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(fontSize: 11.5, color: kTextMain),
                                              ),
                                            ),
                                            Text('${d.jumlah} unit',
                                                style: const TextStyle(fontSize: 11, color: kTextMuted)),
                                            const SizedBox(width: 6),
                                            KondisiBadge(d.kondisi),
                                          ],
                                        ),
                                      );
                                    }).toList(),
                                  ),

                                  if (r.catatan != null && r.catatan!.isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      'Catatan: ${r.catatan!}',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                          fontSize: 10.5, color: kTextMuted, fontStyle: FontStyle.italic),
                                    ),
                                  ],
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
