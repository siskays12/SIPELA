// lib/screens/admin/peminjaman_admin_screen.dart
import 'package:flutter/material.dart';
import '../../core/api_service.dart';
import '../../models/loan_model.dart';
import '../../models/tool_model.dart';
import '../../widgets/app_widgets.dart';
import 'mahasiswa_screen.dart';

class PeminjamanAdminScreen extends StatefulWidget {
  const PeminjamanAdminScreen({super.key});

  @override
  State<PeminjamanAdminScreen> createState() => _PeminjamanAdminScreenState();
}

class _PeminjamanAdminScreenState extends State<PeminjamanAdminScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Loan> _loans = [];
  List<Tool> _tools = [];
  Map<int, Tool> _toolsMap = {};
  bool _loading = true;
  String _searchLoan = '';
  String _filterStatus = 'semua'; // 'semua', 'dipinjam', 'terlambat'

  final List<String> _prodiList = const [
    'Teknologi Rekayasa Perangkat Lunak (D4)',
    'Teknologi Rekayasa Pemeliharaan Alat Berat (D4)',
    'Teknologi Rekayasa Logistik (D4)',
    'Akuntansi Perpajakan (D4)',
    'Bisnis Digital (D4)',
    'Teknik Listrik (D3)',
    'Teknik Elektronika (D3)',
    'Teknik Mesin (D3)',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() => setState(() {}));
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

      final toolsList = (toolsData as List).map((e) => Tool.fromJson(e)).toList();
      final map = <int, Tool>{};
      for (final t in toolsList) {
        map[t.idTool] = t;
      }

      setState(() {
        _loans = (loansData as List).map((e) => Loan.fromJson(e)).toList()
          ..sort((a, b) => b.idLoan.compareTo(a.idLoan));
        _tools = toolsList;
        _toolsMap = map;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) showError(context, e.toString());
    }
  }

  // ─── Modal Catat Peminjaman (Free-text: mahasiswa + alat) ─────────────────
  Future<void> _showCatatPeminjamanDialog() async {
    final formKey = GlobalKey<FormState>();

    // Identitas mahasiswa peminjam (inline form)
    final nimCtrl = TextEditingController();
    final namaCtrl = TextEditingController();
    String selectedProdi = _prodiList.first;
    final noHpCtrl = TextEditingController();

    // Rencana kembali & keperluan
    DateTime tanggalKembali = DateTime.now().add(const Duration(days: 3));
    final keperluanCtrl = TextEditingController();

    // Daftar alat (free-text)
    final List<_FreeTextItem> borrowItems = [_FreeTextItem()];
    bool saving = false;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          backgroundColor: kSurface,
          insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 540, maxHeight: 740),
            child: Padding(
              padding: const EdgeInsets.all(22),
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Header ────────────────────────────────────────────
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Pencatatan Peminjaman Alat',
                              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: kTextMain),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Isi data peminjam dan alat yang langsung diserahkan',
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

                    // ── Scrollable body ───────────────────────────────────
                    Flexible(
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // ── BAGIAN 1: Identitas Mahasiswa ──────────────
                            Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF0F7FF),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: const Color(0xFFBFDBFE)),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Row(
                                    children: [
                                      Icon(Icons.person_outline, size: 15, color: kBrandAccent),
                                      SizedBox(width: 6),
                                      Text(
                                        'Identitas Mahasiswa Peminjam',
                                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: kBrandAccent),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),

                                  // NIM
                                  const Text('NIM *', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: kTextMain)),
                                  const SizedBox(height: 4),
                                  TextFormField(
                                    controller: nimCtrl,
                                    decoration: _inputDec('Contoh: 2200101'),
                                    validator: (v) => v!.trim().isEmpty ? 'NIM wajib diisi' : null,
                                  ),
                                  const SizedBox(height: 10),

                                  // Nama Lengkap
                                  const Text('Nama Lengkap *', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: kTextMain)),
                                  const SizedBox(height: 4),
                                  TextFormField(
                                    controller: namaCtrl,
                                    decoration: _inputDec('Contoh: Budi Santoso'),
                                    validator: (v) => v!.trim().isEmpty ? 'Nama wajib diisi' : null,
                                  ),
                                  const SizedBox(height: 10),

                                  // Program Studi
                                  const Text('Program Studi *', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: kTextMain)),
                                  const SizedBox(height: 4),
                                  DropdownButtonFormField<String>(
                                    value: selectedProdi,
                                    isExpanded: true,
                                    decoration: _inputDec('Pilih Program Studi'),
                                    items: _prodiList.map((p) => DropdownMenuItem(
                                      value: p,
                                      child: Text(p, style: const TextStyle(fontSize: 12.5), overflow: TextOverflow.ellipsis),
                                    )).toList(),
                                    onChanged: (v) => setS(() => selectedProdi = v ?? _prodiList.first),
                                  ),
                                  const SizedBox(height: 10),

                                  // No HP
                                  const Text('No. HP (Opsional)', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: kTextMain)),
                                  const SizedBox(height: 4),
                                  TextFormField(
                                    controller: noHpCtrl,
                                    keyboardType: TextInputType.phone,
                                    decoration: _inputDec('Contoh: 081234567890'),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 14),

                            // ── BAGIAN 2: Tanggal Pengembalian ─────────────
                            const Text('Rencana Tanggal Pengembalian *',
                                style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: kTextMain)),
                            const SizedBox(height: 6),
                            InkWell(
                              onTap: () async {
                                final picked = await showDatePicker(
                                  context: ctx,
                                  initialDate: tanggalKembali,
                                  firstDate: DateTime.now(),
                                  lastDate: DateTime.now().add(const Duration(days: 60)),
                                );
                                if (picked != null) setS(() => tanggalKembali = picked);
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
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
                                      formatDate(tanggalKembali.toIso8601String()),
                                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: kTextMain),
                                    ),
                                    const Spacer(),
                                    const Text('Ubah', style: TextStyle(fontSize: 12, color: kBrandAccent, fontWeight: FontWeight.w600)),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 14),

                            // ── BAGIAN 3: Keperluan ────────────────────────
                            const Text('Keterangan / Keperluan Peminjaman *',
                                style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: kTextMain)),
                            const SizedBox(height: 6),
                            TextFormField(
                              controller: keperluanCtrl,
                              maxLines: 2,
                              decoration: _inputDec(
                                'Contoh: Praktikum Overhaul Mesin, Pemrograman Web, Uji Rangkaian Listrik...',
                              ),
                              validator: (v) => v!.trim().isEmpty ? 'Keperluan wajib diisi' : null,
                            ),
                            const SizedBox(height: 16),

                            // ── BAGIAN 4: Daftar Alat (Free-text) ──────────
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Daftar Alat yang Dipinjam *',
                                    style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: kTextMain)),
                                InkWell(
                                  onTap: () => setS(() => borrowItems.add(_FreeTextItem())),
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

                            ...borrowItems.asMap().entries.map((entry) {
                              final idx = entry.key;
                              final item = entry.value;
                              return Container(
                                key: ObjectKey(item),
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF8FAFC),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: kBorder),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Nomor urut
                                    Container(
                                      margin: const EdgeInsets.only(top: 10, right: 8),
                                      width: 20,
                                      height: 20,
                                      decoration: BoxDecoration(
                                        color: kBrandAccent.withValues(alpha: 0.1),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Center(
                                        child: Text('${idx + 1}',
                                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: kBrandAccent)),
                                      ),
                                    ),
                                    // Nama Alat
                                    Expanded(
                                      flex: 3,
                                      child: TextFormField(
                                        controller: item.namaCtrl,
                                        decoration: InputDecoration(
                                          hintText: 'Nama alat, mis. Jangka Sorong Digital',
                                          hintStyle: const TextStyle(fontSize: 11.5, color: kTextSubtle),
                                          isDense: true,
                                          contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 9),
                                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(7)),
                                          filled: true,
                                          fillColor: Colors.white,
                                        ),
                                        style: const TextStyle(fontSize: 13),
                                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Isi nama alat' : null,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    // Jumlah
                                    SizedBox(
                                      width: 72,
                                      child: TextFormField(
                                        controller: item.jumlahCtrl,
                                        keyboardType: TextInputType.number,
                                        textAlign: TextAlign.center,
                                        decoration: InputDecoration(
                                          labelText: 'Jml',
                                          labelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
                                          isDense: true,
                                          contentPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 9),
                                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(7)),
                                          filled: true,
                                          fillColor: Colors.white,
                                        ),
                                        style: const TextStyle(fontSize: 13),
                                        validator: (v) {
                                          final n = int.tryParse(v ?? '');
                                          if (n == null || n < 1) return 'Min 1';
                                          return null;
                                        },
                                      ),
                                    ),
                                    // Hapus
                                    if (borrowItems.length > 1)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 4, left: 2),
                                        child: IconButton(
                                          icon: const Icon(Icons.remove_circle_outline, size: 18, color: kColorDanger),
                                          onPressed: () {
                                            final removed = borrowItems.removeAt(idx);
                                            removed.dispose();
                                            setS(() {});
                                          },
                                          padding: const EdgeInsets.all(4),
                                          constraints: const BoxConstraints(),
                                        ),
                                      ),
                                  ],
                                ),
                              );
                            }),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // ── Action Buttons ────────────────────────────────────
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text('Batal', style: TextStyle(color: kTextMuted, fontSize: 13)),
                        ),
                        const SizedBox(width: 8),
                        AppButton(
                          label: 'Simpan & Serahkan Alat',
                          icon: Icons.check,
                          color: kColorSuccess,
                          isLoading: saving,
                          onPressed: () async {
                            if (!formKey.currentState!.validate()) return;
                            setS(() => saving = true);
                            try {
                              // 1. Daftarkan mahasiswa dulu
                              final mhsRes = await ApiService.post('/customer', {
                                'nim': nimCtrl.text.trim(),
                                'nama': namaCtrl.text.trim(),
                                'prodi': selectedProdi,
                                'no_hp': noHpCtrl.text.trim().isEmpty ? '-' : noHpCtrl.text.trim(),
                              });
                              final idCustomer = mhsRes['id_customer'] as int? ?? 0;

                              // 2. Catat peminjaman dengan nama alat free-text
                              final daftarAlat = borrowItems
                                  .map((i) => {'nama_alat': i.namaAlat.trim(), 'jumlah': i.jumlah})
                                  .toList();

                              await ApiService.post('/loans', {
                                'id_customer': idCustomer,
                                'nama_mahasiswa': namaCtrl.text.trim(),
                                'nim_mahasiswa': nimCtrl.text.trim(),
                                'prodi_mahasiswa': selectedProdi,
                                'tanggal_rencana_kembali': tanggalKembali.toIso8601String().substring(0, 10),
                                'keperluan': keperluanCtrl.text.trim(),
                                'daftar_alat': daftarAlat,
                              });

                              if (ctx.mounted) Navigator.pop(ctx);
                              if (mounted) {
                                showSuccess(context, 'Peminjaman berhasil disimpan! Alat telah diserahkan.');
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

  InputDecoration _inputDec(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(fontSize: 12.5, color: kTextSubtle),
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: kBorder)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: kBorder)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    );
  }

  @override
  Widget build(BuildContext context) {
    final aktifLoans = _loans.where((l) => l.status == 'dipinjam').toList();

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
              labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
              unselectedLabelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
              indicatorColor: kBrandAccent,
              indicatorWeight: 2.5,
              tabs: [
                Tab(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.assignment_outlined, size: 16),
                      const SizedBox(width: 8),
                      Text('Peminjaman Alat (${aktifLoans.length})'),
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.school_outlined, size: 16),
                      const SizedBox(width: 8),
                      Text('Data Mahasiswa'),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: kBorder),

          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildPeminjamanTab(aktifLoans),
                const MahasiswaScreen(),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: _tabController.index == 0
          ? FloatingActionButton.extended(
              onPressed: _showCatatPeminjamanDialog,
              backgroundColor: kBrandPrimary,
              elevation: 1,
              icon: const Icon(Icons.add, color: Colors.white, size: 18),
              label: const Text('Catat Peminjaman', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
            )
          : null,
    );
  }

  Widget _buildPeminjamanTab(List<Loan> aktifLoans) {
    final q = _searchLoan.toLowerCase();
    List<Loan> list = _loans;
    if (_filterStatus == 'dipinjam') {
      list = aktifLoans;
    } else if (_filterStatus == 'terlambat') {
      list = _loans.where((l) => l.isTerlambat).toList();
    }

    final filtered = list.where((l) =>
        l.namaMahasiswa.toLowerCase().contains(q) ||
        l.nimMahasiswa.toLowerCase().contains(q) ||
        '${l.idLoan}'.contains(q)).toList();

    return Column(
      children: [
        // Filter bar & Search
        Container(
          color: kSurface,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
          child: Column(
            children: [
              TextField(
                onChanged: (v) => setState(() => _searchLoan = v),
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
              const SizedBox(height: 8),
              Row(
                children: [
                  _filterChip(label: 'Semua (${_loans.length})', value: 'semua'),
                  const SizedBox(width: 8),
                  _filterChip(label: 'Sedang Dipinjam (${aktifLoans.length})', value: 'dipinjam'),
                  const SizedBox(width: 8),
                  _filterChip(
                    label: 'Terlambat (${_loans.where((l) => l.isTerlambat).length})',
                    value: 'terlambat',
                    color: kColorDanger,
                  ),
                ],
              ),
            ],
          ),
        ),
        const Divider(height: 1, color: kBorder),

        Expanded(
          child: _loading
              ? const LoadingWidget(message: 'Memuat data peminjaman...')
              : filtered.isEmpty
                  ? const EmptyState(
                      icon: Icons.assignment_outlined,
                      title: 'Tidak ada data peminjaman',
                      subtitle: 'Catat transaksi peminjaman baru saat mahasiswa datang ke laboratorium',
                    )
                  : RefreshIndicator(
                      onRefresh: _fetchData,
                      color: kBrandAccent,
                      child: ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                        itemCount: filtered.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 8),
                        itemBuilder: (_, i) => _loanCard(filtered[i]),
                      ),
                    ),
        ),
      ],
    );
  }

  Widget _filterChip({required String label, required String value, Color? color}) {
    final isSelected = _filterStatus == value;
    final activeColor = color ?? kBrandAccent;
    return InkWell(
      onTap: () => setState(() => _filterStatus = value),
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? activeColor.withValues(alpha: 0.12) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? activeColor : kBorder),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? activeColor : kTextMuted,
          ),
        ),
      ),
    );
  }

  Widget _loanCard(Loan loan) {
    return CleanCard(
      padding: const EdgeInsets.all(15),
      borderColor: loan.isTerlambat ? const Color(0xFFFCA5A5) : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'Peminjaman #${loan.idLoan}',
                  style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: kBrandPrimary),
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
                      SizedBox(width: 4),
                      Text('Terlambat', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: kColorDanger)),
                    ],
                  ),
                )
              else
                StatusBadge(loan.status),
            ],
          ),
          const SizedBox(height: 10),

          // Peminjam Info
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: loan.isTerlambat ? kBgDanger : const Color(0xFFEFF6FF),
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
                      style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: kTextMain),
                    ),
                    Text(
                      '${loan.nimMahasiswa} • ${loan.prodiMahasiswa}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 11.5, color: kTextMuted),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Tanggal Pinjam & Batas Kembali
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFF1F5F9)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      const Icon(Icons.outbox_rounded, size: 14, color: kTextMuted),
                      const SizedBox(width: 5),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Pinjam', style: TextStyle(fontSize: 10, color: kTextSubtle, fontWeight: FontWeight.w500)),
                          Text(formatDate(loan.tanggalPinjam), style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: kTextMain)),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(width: 1, height: 24, color: kBorder),
                const SizedBox(width: 10),
                Expanded(
                  child: Row(
                    children: [
                      Icon(Icons.event_available_outlined, size: 14, color: loan.isTerlambat ? kColorDanger : kBrandAccent),
                      const SizedBox(width: 5),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Batas Kembali', style: TextStyle(fontSize: 10, color: kTextSubtle, fontWeight: FontWeight.w500)),
                          Text(
                            formatDate(loan.tanggalRencanaKembali),
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: loan.isTerlambat ? kColorDanger : kBrandAccent,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          if (loan.keperluan != null && loan.keperluan!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Text(
                'Keperluan: ${loan.keperluan!}',
                style: const TextStyle(fontSize: 11.5, color: kTextMuted, fontStyle: FontStyle.italic),
              ),
            ),
          ],

          const SizedBox(height: 10),
          // Daftar Alat
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFF1F5F9)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.handyman_outlined, size: 13, color: kTextMuted),
                    const SizedBox(width: 6),
                    Text(
                      'Daftar Alat (${loan.daftarAlat.length} barang)',
                      style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: kTextMuted),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ...loan.daftarAlat.map((item) {
                  final tool = item.idTool != null ? _toolsMap[item.idTool] : null;
                  final displayName = item.namaAlat?.isNotEmpty == true
                      ? item.namaAlat!
                      : (tool?.namaAlat ?? (item.idTool != null ? 'Alat #${item.idTool}' : 'Alat tidak diketahui'));
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
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
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '${item.jumlah} unit',
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: kTextMain),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Free-text item untuk daftar alat yang dipinjam (tanpa dropdown)
class _FreeTextItem {
  final TextEditingController namaCtrl;
  final TextEditingController jumlahCtrl;

  _FreeTextItem({String nama = '', int jumlah = 1})
      : namaCtrl = TextEditingController(text: nama),
        jumlahCtrl = TextEditingController(text: jumlah.toString());

  String get namaAlat => namaCtrl.text.trim();
  int get jumlah => int.tryParse(jumlahCtrl.text.trim()) ?? 1;

  void dispose() {
    namaCtrl.dispose();
    jumlahCtrl.dispose();
  }
}
