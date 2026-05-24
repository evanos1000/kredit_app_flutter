import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/peminjam.dart';
import '../models/pinjaman.dart';
import '../utils/app_theme.dart';
import '../utils/currency_formatter.dart';
import 'form_peminjam_screen.dart';
import 'form_pinjaman_screen.dart';
import 'detail_pinjaman_screen.dart';

class DetailPeminjamScreen extends StatefulWidget {
  final Peminjam peminjam;

  const DetailPeminjamScreen({super.key, required this.peminjam});

  @override
  State<DetailPeminjamScreen> createState() => _DetailPeminjamScreenState();
}

class _DetailPeminjamScreenState extends State<DetailPeminjamScreen> {
  final _db = DatabaseHelper();
  late Peminjam _peminjam;
  List<Pinjaman> _pinjamanList = [];
  Pinjaman? _pinjamanAktif;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _peminjam = widget.peminjam;
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final list = await _db.getPinjamanByPeminjam(_peminjam.id!);
      final aktif = await _db.getPinjamanAktif(_peminjam.id!);
      final updated = await _db.getPeminjamById(_peminjam.id!);
      setState(() {
        _pinjamanList = list;
        _pinjamanAktif = aktif;
        if (updated != null) _peminjam = updated;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _editPeminjam() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
          builder: (_) => FormPeminjamScreen(peminjam: _peminjam)),
    );
    if (result == true) _loadData();
  }

  Future<void> _hapusPeminjam() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Peminjam?'),
        content: Text(
            'Semua data pinjaman dan riwayat pembayaran ${_peminjam.nama} akan ikut terhapus.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Batal')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: TextButton.styleFrom(foregroundColor: AppTheme.danger),
              child: const Text('Hapus')),
        ],
      ),
    );
    if (confirm == true) {
      await _db.deletePeminjam(_peminjam.id!);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('${_peminjam.nama} berhasil dihapus'),
              backgroundColor: AppTheme.danger),
        );
      }
    }
  }

  Future<void> _ajukanPinjaman() async {
    final nomorBerikutnya = _pinjamanList.length + 1;
    // Hitung total sisa hutang dari semua pinjaman aktif
    double totalSisaLama = 0;
    for (final p in _pinjamanList) {
      if (p.status == StatusPinjaman.aktif) {
        totalSisaLama += p.sisaTagihan;
      }
    }
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => FormPinjamanScreen(
          peminjam: _peminjam,
          nomorPinjaman: nomorBerikutnya,
          sisaHutangLama: totalSisaLama,
        ),
      ),
    );
    if (result == true) _loadData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        title: Text(_peminjam.nama),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_rounded),
            onPressed: _editPeminjam,
          ),
          IconButton(
            icon: const Icon(Icons.delete_rounded),
            onPressed: _hapusPeminjam,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildProfileCard(),
                    const SizedBox(height: 16),
                    if (_pinjamanAktif != null) ...[
                      _buildPinjamanAktifCard(_pinjamanAktif!),
                      const SizedBox(height: 16),
                    ],
                    _buildRiwayatHeader(),
                    const SizedBox(height: 10),
                    if (_pinjamanList.isEmpty)
                      _buildEmptyPinjaman()
                    else
                      ..._pinjamanList.map((p) => _buildPinjamanItem(p)),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _ajukanPinjaman,
        backgroundColor: AppTheme.primary,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text('Ajukan Pinjaman',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
      ),
    );
  }

  Widget _buildProfileCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: const BoxDecoration(
                color: AppTheme.primary, shape: BoxShape.circle),
            child: Center(
              child: Text(
                _peminjam.nama[0].toUpperCase(),
                style: const TextStyle(
                    fontSize: 24, fontWeight: FontWeight.w800, color: Colors.white),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_peminjam.nama,
                    style: const TextStyle(
                        fontSize: 17, fontWeight: FontWeight.w700)),
                if (_peminjam.nomorHp != null) ...[
                  const SizedBox(height: 2),
                  Text(_peminjam.nomorHp!,
                      style: const TextStyle(
                          fontSize: 13, color: AppTheme.textSecondary)),
                ],
                if (_peminjam.catatan != null) ...[
                  const SizedBox(height: 2),
                  Text(_peminjam.catatan!,
                      style: const TextStyle(
                          fontSize: 12, color: AppTheme.textSecondary),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis),
                ],
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('${_pinjamanList.length} Pinjaman',
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.primary)),
              const SizedBox(height: 2),
              Text(
                  'Sejak ${DateFormatter.formatDate(_peminjam.createdAt)}',
                  style: const TextStyle(fontSize: 10, color: AppTheme.textSecondary)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPinjamanAktifCard(Pinjaman pinjaman) {
    final progress = (pinjaman.totalSudahBayar / pinjaman.totalWajibBayar).clamp(0.0, 1.0);
    return GestureDetector(
      onTap: () => _navigasiDetailPinjaman(pinjaman),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFFF6F00), Color(0xFFFF8F00)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppTheme.accentOrange.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Pinjaman Aktif',
                    style: TextStyle(color: Colors.white70, fontSize: 13)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Ke-${pinjaman.nomorPinjaman}',
                    style: const TextStyle(
                        color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              CurrencyFormatter.format(pinjaman.sisaTagihan),
              style: const TextStyle(
                  color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800),
            ),
            const Text('Sisa tagihan',
                style: TextStyle(color: Colors.white70, fontSize: 12)),
            const SizedBox(height: 14),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: Colors.white.withOpacity(0.3),
                valueColor: const AlwaysStoppedAnimation(Colors.white),
                minHeight: 6,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Terbayar: ${CurrencyFormatter.format(pinjaman.totalSudahBayar)}',
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
                Text(
                  'Total: ${CurrencyFormatter.format(pinjaman.totalWajibBayar)}',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.calendar_today_rounded, color: Colors.white70, size: 12),
                const SizedBox(width: 4),
                Text(
                  '${_getDurasiLabel(pinjaman.durasiTipe)} · Mulai ${DateFormatter.formatDate(pinjaman.tanggalMulai)}',
                  style: const TextStyle(color: Colors.white70, fontSize: 11),
                ),
                const Spacer(),
                const Text('Tap untuk detail →',
                    style: TextStyle(color: Colors.white, fontSize: 11)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRiwayatHeader() {
    return const Text('Riwayat Pinjaman',
        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700));
  }

  Widget _buildPinjamanItem(Pinjaman pinjaman) {
    final isAktif = pinjaman.status == StatusPinjaman.aktif;
    return GestureDetector(
      onTap: () => _navigasiDetailPinjaman(pinjaman),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTheme.cardBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.divider),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isAktif
                    ? AppTheme.warning.withOpacity(0.1)
                    : AppTheme.accent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                isAktif ? Icons.pending_rounded : Icons.check_circle_rounded,
                color: isAktif ? AppTheme.warning : AppTheme.accent,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Pinjaman ke-${pinjaman.nomorPinjaman}',
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 2),
                  Text(
                    'Pokok: ${CurrencyFormatter.format(pinjaman.pokokPinjaman)} · ${_getDurasiLabel(pinjaman.durasiTipe)}',
                    style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                  ),
                  if (!isAktif && pinjaman.tanggalLunas != null)
                    Text(
                      'Lunas: ${DateFormatter.formatDate(pinjaman.tanggalLunas!)}',
                      style: const TextStyle(fontSize: 11, color: AppTheme.accent),
                    ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  CurrencyFormatter.format(pinjaman.totalWajibBayar),
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: isAktif
                        ? AppTheme.warning.withOpacity(0.1)
                        : AppTheme.accent.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    isAktif ? 'Aktif' : 'Lunas',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: isAktif ? AppTheme.warning : AppTheme.accent,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyPinjaman() {
    return Container(
      padding: const EdgeInsets.all(32),
      alignment: Alignment.center,
      child: Column(
        children: [
          Icon(Icons.receipt_long_rounded,
              size: 48, color: AppTheme.textSecondary.withOpacity(0.5)),
          const SizedBox(height: 12),
          const Text('Belum ada pinjaman',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 14)),
        ],
      ),
    );
  }

  String _getDurasiLabel(DurasiTipe tipe) {
    switch (tipe) {
      case DurasiTipe.harian:
        return 'Bayar Harian';
      case DurasiTipe.mingguan:
        return 'Bayar Mingguan';
      case DurasiTipe.bulanan:
        return 'Bayar Bulanan';
    }
  }

  void _navigasiDetailPinjaman(Pinjaman pinjaman) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DetailPinjamanScreen(
          pinjaman: pinjaman,
          peminjam: _peminjam,
        ),
      ),
    );
    _loadData();
  }
}
