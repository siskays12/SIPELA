// lib/screens/customer/peminjaman_saya_screen.dart
import 'package:flutter/material.dart';
import '../../core/api_service.dart';
import '../../models/loan_model.dart';
import '../../models/tool_model.dart';
import '../../widgets/app_widgets.dart';

class PeminjamanSayaScreen extends StatefulWidget {
  const PeminjamanSayaScreen({super.key});

  @override
  State<PeminjamanSayaScreen> createState() => _PeminjamanSayaScreenState();
}

class _PeminjamanSayaScreenState extends State<PeminjamanSayaScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Loan> _loans = [];
  Map<int, Tool> _toolsMap = {};
  bool _loading = true;

  final _tabs = ['Semua', 'Menunggu', 'Dipinjam', 'Selesai'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
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
      final map = <int, Tool>{};
      for (final t in toolsData as List) {
        final tool = Tool.fromJson(t);
        map[tool.idTool] = tool;
      }
      setState(() {
        _loans = (loansData as List).map((e) => Loan.fromJson(e)).toList()
          ..sort((a, b) => b.idLoan.compareTo(a.idLoan));
        _toolsMap = map;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) showError(context, e.toString());
    }
  }

  List<Loan> _getFiltered(int tabIndex) {
    if (tabIndex == 0) return _loans;
    final status = _tabs[tabIndex].toLowerCase();
    return _loans.where((l) => l.status.toLowerCase() == status).toList();
  }

  Future<void> _showAjukanForm() async {
    List<Tool> availableTools = [];
    try {
      final data = await ApiService.get('/tools');
      availableTools = (data as List)
          .map((e) => Tool.fromJson(e))
          .where((t) => t.kondisi == 'baik' && t.stokTersedia > 0)
          .toList();
    } catch (e) {
      if (mounted) showError(context, e.toString());
      return;
    }

    if (availableTools.isEmpty) {
      if (mounted) showError(context, 'Tidak ada alat laboratorium yang tersedia saat ini.');
      return;
    }
    if (!mounted) return;

    final formKey = GlobalKey<FormState>();
    DateTime? tanggalKembali = DateTime.now().add(const Duration(days: 3));
    final keperluan = TextEditingController();
    final List<_LoanItem> items = [_LoanItem(tools: availableTools)];
    bool saving = false;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          backgroundColor: kSurface,
          insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520, maxHeight: 700),
            child: Padding(
              padding: const EdgeInsets.all(22),
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Form Pengajuan Peminjaman',
                              style: TextStyle(fontSize: 16.5, fontWeight: FontWeight.w700, color: kTextMain),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Pilih tanggal pengembalian dan daftar alat yang dibutuhkan',
                              style: TextStyle(fontSize: 12, color: kTextMuted),
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

                    // Scrollable content
                    Flexible(
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Rencana Tanggal Pengembalian', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: kTextMain)),
                            const SizedBox(height: 6),
                            InkWell(
                              onTap: () async {
                                final picked = await showDatePicker(
                                  context: ctx,
                                  initialDate: tanggalKembali ?? DateTime.now().add(const Duration(days: 1)),
                                  firstDate: DateTime.now().add(const Duration(days: 1)),
                                  lastDate: DateTime.now().add(const Duration(days: 60)),
                                );
                                if (picked != null) {
                                  setS(() => tanggalKembali = picked);
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF8FAFC),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: kBorder),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.calendar_today_outlined, size: 16, color: kBrandAccent),
                                    const SizedBox(width: 10),
                                    Text(
                                      tanggalKembali != null ? formatDate(tanggalKembali!.toIso8601String()) : 'Pilih tanggal pengembalian',
                                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: kTextMain),
                                    ),
                                    const Spacer(),
                                    const Text('Ubah', style: TextStyle(fontSize: 12, color: kBrandAccent, fontWeight: FontWeight.w600)),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 14),

                            const Text('Keperluan Peminjaman', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: kTextMain)),
                            const SizedBox(height: 6),
                            TextFormField(
                              controller: keperluan,
                              maxLines: 2,
                              decoration: InputDecoration(
                                hintText: 'Contoh: Praktikum Elektronika Dasar Modul 3',
                                hintStyle: const TextStyle(fontSize: 12.5, color: kTextSubtle),
                                filled: true,
                                fillColor: const Color(0xFFF8FAFC),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: kBorder)),
                                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: kBorder)),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              ),
                              validator: (v) => v!.trim().isEmpty ? 'Keperluan wajib diisi' : null,
                            ),
                            const SizedBox(height: 16),

                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Daftar Alat Laboratorium', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: kTextMain)),
                                InkWell(
                                  onTap: () => setS(() => items.add(_LoanItem(tools: availableTools))),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFEFF6FF),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: const Row(
                                      children: [
                                        Icon(Icons.add, size: 14, color: kBrandAccent),
                                        SizedBox(width: 4),
                                        Text('Tambah Alat', style: TextStyle(fontSize: 12, color: kBrandAccent, fontWeight: FontWeight.w600)),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),

                            ...items.asMap().entries.map((entry) {
                              final idx = entry.key;
                              final item = entry.value;

                              return Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF8FAFC),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: kBorder),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      flex: 3,
                                      child: DropdownButtonFormField<int>(
                                        initialValue: item.idTool,
                                        isExpanded: true,
                                        decoration: const InputDecoration(
                                          isDense: true,
                                          contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                          border: InputBorder.none,
                                        ),
                                        items: availableTools
                                            .map((t) => DropdownMenuItem(
                                                  value: t.idTool,
                                                  child: Text(
                                                    '${t.namaAlat} (Sisa ${t.stokTersedia})',
                                                    overflow: TextOverflow.ellipsis,
                                                    style: const TextStyle(fontSize: 12.5),
                                                  ),
                                                ))
                                            .toList(),
                                        onChanged: (v) => setS(() => item.idTool = v),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    SizedBox(
                                      width: 75,
                                      child: TextFormField(
                                        initialValue: '${item.jumlah}',
                                        keyboardType: TextInputType.number,
                                        textAlign: TextAlign.center,
                                        decoration: InputDecoration(
                                          isDense: true,
                                          labelText: 'Jumlah',
                                          labelStyle: const TextStyle(fontSize: 11),
                                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                                          contentPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                                        ),
                                        onChanged: (v) => item.jumlah = int.tryParse(v) ?? 1,
                                        validator: (v) {
                                          final n = int.tryParse(v ?? '');
                                          if (n == null || n < 1) return 'Min 1';
                                          return null;
                                        },
                                      ),
                                    ),
                                    if (items.length > 1)
                                      IconButton(
                                        icon: const Icon(Icons.remove_circle_outline, size: 18, color: kColorDanger),
                                        onPressed: () => setS(() => items.removeAt(idx)),
                                        padding: const EdgeInsets.only(left: 4),
                                        constraints: const BoxConstraints(),
                                      ),
                                  ],
                                ),
                              );
                            }),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),
                    const Divider(height: 1, color: kBorder),
                    const SizedBox(height: 14),

                    // Actions
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text('Batal', style: TextStyle(color: kTextMuted, fontSize: 13)),
                        ),
                        const SizedBox(width: 8),
                        AppButton(
                          label: 'Kirim Pengajuan',
                          isLoading: saving,
                          icon: Icons.send_outlined,
                          onPressed: () async {
                            if (tanggalKembali == null) {
                              showError(context, 'Tentukan tanggal rencana pengembalian');
                              return;
                            }
                            if (!formKey.currentState!.validate()) return;
                            setS(() => saving = true);
                            try {
                              final daftarAlat = items
                                  .where((item) => item.idTool != null)
                                  .map((item) => {
                                        'id_tool': item.idTool!,
                                        'jumlah': item.jumlah,
                                      })
                                  .toList();

                              await ApiService.post('/loans', {
                                'tanggal_rencana_kembali': tanggalKembali!.toIso8601String().substring(0, 10),
                                'keperluan': keperluan.text.trim(),
                                'daftar_alat': daftarAlat,
                              });
                              if (ctx.mounted) Navigator.pop(ctx);
                              if (mounted) {
                                showSuccess(context, 'Pengajuan peminjaman berhasil dikirim');
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
              tabs: _tabs.map((t) => Tab(text: t)).toList(),
            ),
          ),
          const Divider(height: 1, color: kBorder),

          Expanded(
            child: _loading
                ? const LoadingWidget(message: 'Memuat data pinjaman...')
                : TabBarView(
                    controller: _tabController,
                    children: List.generate(_tabs.length, (i) => _buildLoanList(_getFiltered(i))),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAjukanForm,
        backgroundColor: kBrandPrimary,
        elevation: 1,
        icon: const Icon(Icons.add, color: Colors.white, size: 18),
        label: const Text('Ajukan Pinjam', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
      ),
    );
  }

  Widget _buildLoanList(List<Loan> loans) {
    if (loans.isEmpty) {
      return EmptyState(
        icon: Icons.assignment_outlined,
        title: 'Belum ada data peminjaman',
        subtitle: 'Ajukan peminjaman alat praktikum kapan pun dibutuhkan',
        action: AppButton(
          label: 'Ajukan Pinjam Sekarang',
          icon: Icons.add,
          onPressed: _showAjukanForm,
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchData,
      color: kBrandAccent,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
        itemCount: loans.length,
        separatorBuilder: (_, _) => const SizedBox(height: 8),
        itemBuilder: (_, i) => _loanCard(loans[i]),
      ),
    );
  }

  Widget _loanCard(Loan loan) {
    return CleanCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Peminjaman #${loan.idLoan}',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: kTextMain),
              ),
              StatusBadge(loan.status),
            ],
          ),
          const SizedBox(height: 8),
          InfoLine(label: 'Target Kembali', value: formatDate(loan.tanggalRencanaKembali)),
          if (loan.keperluan != null && loan.keperluan!.isNotEmpty)
            InfoLine(label: 'Keperluan', value: loan.keperluan!),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: const Color(0xFFF1F5F9)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: loan.daftarAlat.map((item) {
                final tool = item.idTool != null ? _toolsMap[item.idTool] : null;
                final displayName = (item.namaAlat?.isNotEmpty == true)
                    ? item.namaAlat!
                    : (tool?.namaAlat ?? (item.idTool != null ? 'Alat #${item.idTool}' : 'Alat'));
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    children: [
                      const Icon(Icons.circle, size: 5, color: kTextSubtle),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          displayName,
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: kTextMain),
                        ),
                      ),
                      Text(
                        '${item.jumlah} unit',
                        style: const TextStyle(fontSize: 11.5, color: kTextMuted),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
          if (loan.catatanAdmin != null && loan.catatanAdmin!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: kBgWarning,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, size: 14, color: kColorWarning),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Pesan Lab: ${loan.catatanAdmin}',
                      style: const TextStyle(fontSize: 11.5, color: kColorWarning),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _LoanItem {
  int? idTool;
  int jumlah = 1;
  final List<Tool> tools;

  _LoanItem({required this.tools}) {
    idTool = tools.isNotEmpty ? tools.first.idTool : null;
  }
}
