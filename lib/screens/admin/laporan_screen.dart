// lib/screens/admin/laporan_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart' show Share, XFile;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:excel/excel.dart' as ex;
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
  bool _exportingPdf = false;
  bool _exportingExcel = false;

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

  // ── Export PDF ─────────────────────────────────────────────────────────────
  Future<void> _exportPdf() async {
    setState(() => _exportingPdf = true);
    try {
      final totalPinjam = _loans.length;
      final sedangDipinjam = _loans.where((l) => l.status == 'dipinjam').length;
      final selesai = _loans.where((l) => l.status == 'selesai').length;
      int totalStokFisik = 0;
      int totalStokTersedia = 0;
      for (var t in _tools) {
        totalStokFisik += t.stokTotal;
        totalStokTersedia += t.stokTersedia;
      }

      // Frekuensi alat
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

      final pdf = pw.Document();
      final now = DateTime.now();
      final tanggalCetak =
          '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}  ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          build: (pw.Context ctx) => [
            // Header Resmi / Kop Laporan (Rapi, Di Tengah, Tanpa Kotak-Kotak)
            pw.Center(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  pw.Text(
                    'UPT LABORATORIUM & SARANA PRASARANA',
                    style: pw.TextStyle(
                      fontSize: 11,
                      fontWeight: pw.FontWeight.bold,
                      letterSpacing: 1.2,
                      color: PdfColors.grey700,
                    ),
                  ),
                  pw.SizedBox(height: 3),
                  pw.Text(
                    'SISTEM INFORMASI PEMINJAMAN ALAT (SIPELA)',
                    style: pw.TextStyle(
                      fontSize: 15,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.blue900,
                    ),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    'REKAPITULASI LAPORAN & STATISTIK LABORATORIUM',
                    style: pw.TextStyle(
                      fontSize: 11.5,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.black,
                    ),
                  ),
                  pw.SizedBox(height: 3),
                  pw.Text(
                    'Waktu Cetak: $tanggalCetak',
                    style: const pw.TextStyle(
                      fontSize: 8.5,
                      color: PdfColors.grey600,
                    ),
                  ),
                  pw.SizedBox(height: 8),
                  pw.Divider(thickness: 1.5, color: PdfColors.blue900),
                  pw.SizedBox(height: 1),
                  pw.Divider(thickness: 0.5, color: PdfColors.grey400),
                ],
              ),
            ),
            pw.SizedBox(height: 16),

            // Ringkasan Metrik
            pw.Text('Ringkasan Statistik',
                style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 8),
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey300),
              columnWidths: {
                0: const pw.FlexColumnWidth(2),
                1: const pw.FlexColumnWidth(1),
              },
              children: [
                _pdfHeaderRow(['Metrik', 'Nilai']),
                _pdfDataRow(['Total Peminjaman', '$totalPinjam transaksi']),
                _pdfDataRow(['Sedang Dipinjam', '$sedangDipinjam aktif']),
                _pdfDataRow(['Peminjaman Selesai', '$selesai selesai']),
                _pdfDataRow(['Total Stok Fisik', '$totalStokFisik unit']),
                _pdfDataRow(['Stok Tersedia', '$totalStokTersedia unit']),
                _pdfDataRow(['Jumlah Jenis Alat', '${_tools.length} jenis']),
                _pdfDataRow(['Data Mahasiswa', '$_customerCount mahasiswa']),
              ],
            ),
            pw.SizedBox(height: 20),

            // Kondisi Alat
            pw.Text('Kondisi Inventaris Alat',
                style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 8),
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey300),
              columnWidths: {
                0: const pw.FlexColumnWidth(2),
                1: const pw.FlexColumnWidth(1),
                2: const pw.FlexColumnWidth(1),
              },
              children: [
                _pdfHeaderRow(['Nama Alat', 'Stok Total', 'Kondisi']),
                ..._tools.map((t) => _pdfDataRow([
                      t.namaAlat,
                      '${t.stokTotal} unit',
                      t.kondisi,
                    ])),
              ],
            ),

            if (sortedToolEntries.isNotEmpty) ...[
              pw.SizedBox(height: 20),
              pw.Text('Top 5 Alat Paling Sering Dipinjam',
                  style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 8),
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey300),
                columnWidths: {
                  0: const pw.FixedColumnWidth(28),
                  1: const pw.FlexColumnWidth(3),
                  2: const pw.FlexColumnWidth(1),
                },
                children: [
                  _pdfHeaderRow(['#', 'Nama Alat', 'Frekuensi']),
                  ...sortedToolEntries.take(5).map((entry) {
                    final rank = sortedToolEntries.indexOf(entry) + 1;
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
                    return _pdfDataRow(['$rank', tool.namaAlat, '${entry.value}x']);
                  }),
                ],
              ),
            ],

            pw.SizedBox(height: 20),
            // Riwayat Peminjaman (20 terbaru)
            pw.Text('Riwayat Peminjaman (20 Terbaru)',
                style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 8),
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey300),
              columnWidths: {
                0: const pw.FixedColumnWidth(28),
                1: const pw.FlexColumnWidth(2),
                2: const pw.FlexColumnWidth(2),
                3: const pw.FlexColumnWidth(1),
              },
              children: [
                _pdfHeaderRow(['ID', 'Mahasiswa', 'Tanggal Pinjam', 'Status']),
                ..._loans.take(20).map((l) => _pdfDataRow([
                      '#${l.idLoan}',
                      '${l.namaMahasiswa}\n${l.nimMahasiswa}',
                      formatDate(l.tanggalPinjam),
                      l.status,
                    ])),
              ],
            ),
          ],
        ),
      );

      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/laporan_sipela_${now.millisecondsSinceEpoch}.pdf');
      await file.writeAsBytes(await pdf.save());

      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'Laporan SIPELA',
      );
    } catch (e) {
      if (mounted) showError(context, 'Gagal ekspor PDF: $e');
    } finally {
      if (mounted) setState(() => _exportingPdf = false);
    }
  }

  // ── Export Excel ───────────────────────────────────────────────────────────
  Future<void> _exportExcel() async {
    setState(() => _exportingExcel = true);
    try {
      final excel = ex.Excel.createExcel();

      // Sheet 1: Statistik
      final statSheet = excel['Statistik'];
      excel.setDefaultSheet('Statistik');
      final totalPinjam = _loans.length;
      final sedangDipinjam = _loans.where((l) => l.status == 'dipinjam').length;
      final selesai = _loans.where((l) => l.status == 'selesai').length;
      int totalStokFisik = 0;
      int totalStokTersedia = 0;
      for (var t in _tools) {
        totalStokFisik += t.stokTotal;
        totalStokTersedia += t.stokTersedia;
      }

      _excelHeader(statSheet, 0, ['Metrik', 'Nilai']);
      final statsRows = [
        ['Total Peminjaman', totalPinjam],
        ['Sedang Dipinjam', sedangDipinjam],
        ['Peminjaman Selesai', selesai],
        ['Total Stok Fisik (unit)', totalStokFisik],
        ['Stok Tersedia (unit)', totalStokTersedia],
        ['Jumlah Jenis Alat', _tools.length],
        ['Data Mahasiswa', _customerCount],
      ];
      for (var i = 0; i < statsRows.length; i++) {
        statSheet.cell(ex.CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: i + 1))
          .value = ex.TextCellValue(statsRows[i][0] as String);
        statSheet.cell(ex.CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: i + 1))
          .value = ex.IntCellValue(statsRows[i][1] as int);
      }

      // Sheet 2: Inventaris
      final invSheet = excel['Inventaris'];
      _excelHeader(invSheet, 0, ['ID', 'Kode', 'Nama Alat', 'Stok Total', 'Stok Tersedia', 'Kondisi']);
      for (var i = 0; i < _tools.length; i++) {
        final t = _tools[i];
        final row = i + 1;
        invSheet.cell(ex.CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row))
          .value = ex.IntCellValue(t.idTool);
        invSheet.cell(ex.CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: row))
          .value = ex.TextCellValue(t.kodeAlat);
        invSheet.cell(ex.CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: row))
          .value = ex.TextCellValue(t.namaAlat);
        invSheet.cell(ex.CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: row))
          .value = ex.IntCellValue(t.stokTotal);
        invSheet.cell(ex.CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: row))
          .value = ex.IntCellValue(t.stokTersedia);
        invSheet.cell(ex.CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: row))
          .value = ex.TextCellValue(t.kondisi);
      }

      // Sheet 3: Riwayat Peminjaman
      final loanSheet = excel['Peminjaman'];
      _excelHeader(loanSheet, 0, [
        'ID', 'Nama Mahasiswa', 'NIM', 'Program Studi',
        'Tgl Pinjam', 'Tgl Rencana Kembali', 'Status'
      ]);
      for (var i = 0; i < _loans.length; i++) {
        final l = _loans[i];
        final row = i + 1;
        loanSheet.cell(ex.CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row))
          .value = ex.IntCellValue(l.idLoan);
        loanSheet.cell(ex.CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: row))
          .value = ex.TextCellValue(l.namaMahasiswa);
        loanSheet.cell(ex.CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: row))
          .value = ex.TextCellValue(l.nimMahasiswa);
        loanSheet.cell(ex.CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: row))
          .value = ex.TextCellValue(l.prodiMahasiswa);
        loanSheet.cell(ex.CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: row))
          .value = ex.TextCellValue(formatDate(l.tanggalPinjam));
        loanSheet.cell(ex.CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: row))
          .value = ex.TextCellValue(formatDate(l.tanggalRencanaKembali));
        loanSheet.cell(ex.CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: row))
          .value = ex.TextCellValue(l.status);
      }

      final now = DateTime.now();
      final fileBytes = excel.save();
      if (fileBytes == null) throw Exception('Gagal generate file Excel');

      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/laporan_sipela_${now.millisecondsSinceEpoch}.xlsx');
      await file.writeAsBytes(fileBytes);

      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'Laporan SIPELA Excel',
      );
    } catch (e) {
      if (mounted) showError(context, 'Gagal ekspor Excel: $e');
    } finally {
      if (mounted) setState(() => _exportingExcel = false);
    }
  }

  // ── Helpers PDF ────────────────────────────────────────────────────────────
  pw.TableRow _pdfHeaderRow(List<String> cells) {
    return pw.TableRow(
      decoration: const pw.BoxDecoration(color: PdfColors.blue50),
      children: cells
          .map((c) => pw.Padding(
                padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
                child: pw.Text(c,
                    style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
              ))
          .toList(),
    );
  }

  pw.TableRow _pdfDataRow(List<String> cells) {
    return pw.TableRow(
      children: cells
          .map((c) => pw.Padding(
                padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                child: pw.Text(c, style: const pw.TextStyle(fontSize: 9)),
              ))
          .toList(),
    );
  }

  // ── Helpers Excel ──────────────────────────────────────────────────────────
  void _excelHeader(ex.Sheet sheet, int row, List<String> headers) {
    for (var i = 0; i < headers.length; i++) {
      sheet.cell(ex.CellIndex.indexByColumnRow(columnIndex: i, rowIndex: row))
        .value = ex.TextCellValue(headers[i]);
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────────
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

    int totalStokFisik = 0;
    int totalStokTersedia = 0;
    for (var t in _tools) {
      totalStokFisik += t.stokTotal;
      totalStokTersedia += t.stokTersedia;
    }

    // Alat paling sering dipinjam
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
              // ── 1. Header + Tombol Ekspor ───────────────────────
              Row(
                children: [
                  const Icon(Icons.analytics_outlined, size: 20, color: kBrandPrimary),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Statistik & Laporan Lab',
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
              const SizedBox(height: 10),

              // ── Tombol Ekspor PDF & Excel ───────────────────────
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: (_exportingPdf || _exportingExcel) ? null : _exportPdf,
                      icon: _exportingPdf
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFDC2626)),
                            )
                          : const Icon(Icons.picture_as_pdf_outlined, size: 16),
                      label: const Text('Ekspor PDF', style: TextStyle(fontSize: 12.5)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFDC2626),
                        side: const BorderSide(color: Color(0xFFDC2626)),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: (_exportingPdf || _exportingExcel) ? null : _exportExcel,
                      icon: _exportingExcel
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF16A34A)),
                            )
                          : const Icon(Icons.table_chart_outlined, size: 16),
                      label: const Text('Ekspor Excel', style: TextStyle(fontSize: 12.5)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF16A34A),
                        side: const BorderSide(color: Color(0xFF16A34A)),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

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

              // ── 4. Ringkasan Kondisi Fisik Alat ────────────────
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

              // ── 5. Alat Paling Sering Dipinjam ──────────────────
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
