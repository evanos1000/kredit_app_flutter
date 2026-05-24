import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/peminjam.dart';
import '../models/pinjaman.dart';
import '../utils/app_theme.dart';
import '../utils/currency_formatter.dart';
import 'form_peminjam_screen.dart';
import 'detail_peminjam_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _db = DatabaseHelper();
  List<Peminjam> _peminjamList = [];
  Map<int, Pinjaman?> _pinjamanAktifMap = {};
  Map<int, int> _jumlahPinjamanMap = {};
  Map<String, double> _statistik = {};
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final peminjamList = await _db.getAllPeminjam();
      final Map<int, Pinjaman?> pinjamanAktifMap = {};
      final Map<int, int> jumlahPinjamanMap = {};

      for (final p in peminjamList) {
        if (p.id != null) {
          pinjamanAktifMap[p.id!] = await _db.getPinjamanAktif(p.id!);
          final semuaPinjaman = await _db.getPinjamanByPeminjam(p.id!);
          jumlahPinjamanMap[p.id!] = semuaPinjaman.length;
        }
      }

      final statistik = await _db.getStatistikGlobal();
      setState(() {
        _peminjamList = peminjamList;
        _pinjamanAktifMap = pinjamanAktifMap;
        _jumlahPinjamanMap = jumlahPinjamanMap;
        _statistik = statistik;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  List<Peminjam> get _filteredList {
    if (_searchQuery.isEmpty) return _peminjamList;
    return _peminjamList
        .where((p) => p.nama.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: RefreshIndicator(
        onRefresh: _loadData,
        color: AppTheme.primary,
        child: CustomScrollView(
          slivers: [
            _buildAppBar(),
            SliverToBoxAdapter(child: _buildStatistikCard()),
            SliverToBoxAdapter(child: _buildSearchBar()),
            SliverToBoxAdapter(child: _buildListHeader()),
            _isLoading
                ? const SliverFillRemaining(
                    child: Center(child: CircularProgressIndicator()))
                : _filteredList.isEmpty
                    ? SliverFillRemaining(child: _buildEmptyState())
                    : SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (ctx, i) => _buildPeminjamCard(_filteredList[i]),
                          childCount: _filteredList.length,
                        ),
                      ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _navigasiTambahPeminjam,
        backgroundColor: AppTheme.primary,
        icon: const Icon(Icons.person_add_rounded, color: Colors.white),
        label: const Text('Tambah Peminjam',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 80,
      floating: true,
      pinned: true,
      backgroundColor: AppTheme.primary,
      flexibleSpace: FlexibleSpaceBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.account_balance_wallet_rounded,
                  color: Colors.white, size: 18),
            ),
            const SizedBox(width: 10),
            const Text('KreditKu',
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 18)),
          ],
        ),
        titlePadding: const EdgeInsets.only(left: 16, bottom: 14),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh_rounded, color: Colors.white),
          onPressed: _loadData,
        ),
      ],
    );
  }

  Widget _buildStatistikCard() {
    final piutangAktif = _statistik['total_piutang_aktif'] ?? 0;
    final terkumpul = _statistik['total_terkumpul'] ?? 0;
    final lunas = _statistik['total_lunas'] ?? 0;
    final peminjamAktif =
        _pinjamanAktifMap.values.where((p) => p != null).length;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.primary, AppTheme.primaryLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Total Piutang Aktif',
              style: TextStyle(color: Colors.white70, fontSize: 13)),
          const SizedBox(height: 4),
          Text(
            CurrencyFormatter.format(piutangAktif),
            style: const TextStyle(
                color: Colors.white,
                fontSize: 26,
                fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                  child: _buildStatItem(
                      'Terkumpul',
                      CurrencyFormatter.formatCompact(terkumpul),
                      Icons.trending_down_rounded,
                      Colors.greenAccent)),
              const SizedBox(width: 12),
              Expanded(
                  child: _buildStatItem(
                      'Total Lunas',
                      CurrencyFormatter.formatCompact(lunas),
                      Icons.check_circle_rounded,
                      Colors.lightGreenAccent)),
              const SizedBox(width: 12),
              Expanded(
                  child: _buildStatItem(
                      'Aktif',
                      '$peminjamAktif Orang',
                      Icons.people_rounded,
                      Colors.orangeAccent)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
      String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(height: 4),
          Text(value,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w700)),
          Text(label,
              style:
                  const TextStyle(color: Colors.white60, fontSize: 10)),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: TextField(
        onChanged: (v) => setState(() => _searchQuery = v),
        decoration: InputDecoration(
          hintText: 'Cari nama peminjam...',
          prefixIcon: const Icon(Icons.search_rounded,
              color: AppTheme.textSecondary),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear_rounded,
                      color: AppTheme.textSecondary),
                  onPressed: () => setState(() => _searchQuery = ''),
                )
              : null,
        ),
      ),
    );
  }

  Widget _buildListHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Text(
        'Daftar Peminjam (${_filteredList.length})',
        style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary),
      ),
    );
  }

  Widget _buildPeminjamCard(Peminjam peminjam) {
    final pinjamanAktif =
        peminjam.id != null ? _pinjamanAktifMap[peminjam.id] : null;
    final hasAktif = pinjamanAktif != null;
    final jumlahPinjaman =
        peminjam.id != null ? (_jumlahPinjamanMap[peminjam.id!] ?? 0) : 0;
    final pernahPinjam = jumlahPinjaman > 0;

    // Badge logic
    String badgeLabel;
    Color badgeColor;
    Color badgeBg;
    if (hasAktif) {
      badgeLabel = 'Aktif';
      badgeColor = AppTheme.warning;
      badgeBg = AppTheme.warning.withOpacity(0.12);
    } else if (pernahPinjam) {
      badgeLabel = 'Lunas';
      badgeColor = AppTheme.accent;
      badgeBg = AppTheme.accent.withOpacity(0.12);
    } else {
      badgeLabel = 'Baru';
      badgeColor = AppTheme.textSecondary;
      badgeBg = AppTheme.divider;
    }

    return GestureDetector(
      onTap: () => _navigasiDetail(peminjam),
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: hasAktif
                ? AppTheme.primary.withOpacity(0.2)
                : AppTheme.divider,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Avatar — huruf inisial nama
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: hasAktif
                    ? AppTheme.primary.withOpacity(0.1)
                    : AppTheme.divider.withOpacity(0.5),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(
                peminjam.nama.trim().isNotEmpty
                    ? peminjam.nama.trim()[0].toUpperCase()
                    : '?',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: hasAktif
                      ? AppTheme.primary
                      : AppTheme.textSecondary,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(peminjam.nama,
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 2),
                  if (hasAktif) ...[
                    Text(
                      'Sisa: ${CurrencyFormatter.format(pinjamanAktif.sisaTagihan)}',
                      style: const TextStyle(
                          fontSize: 13,
                          color: AppTheme.danger,
                          fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    _buildProgressBar(pinjamanAktif),
                  ] else if (pernahPinjam)
                    const Text('Semua pinjaman sudah lunas',
                        style:
                            TextStyle(fontSize: 12, color: AppTheme.accent))
                  else
                    const Text('Belum ada pinjaman',
                        style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.textSecondary)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: badgeBg,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(badgeLabel,
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: badgeColor)),
                ),
                const SizedBox(height: 8),
                const Icon(Icons.chevron_right_rounded,
                    color: AppTheme.textSecondary, size: 20),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressBar(Pinjaman pinjaman) {
    final progress =
        (pinjaman.totalSudahBayar / pinjaman.totalWajibBayar).clamp(0.0, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: AppTheme.divider,
            valueColor: AlwaysStoppedAnimation(
              progress < 0.5 ? AppTheme.danger : AppTheme.warning,
            ),
            minHeight: 4,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          '${(progress * 100).toStringAsFixed(0)}% terbayar',
          style: const TextStyle(
              fontSize: 10, color: AppTheme.textSecondary),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.primary.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.people_outline_rounded,
                size: 56, color: AppTheme.primary),
          ),
          const SizedBox(height: 16),
          const Text('Belum ada peminjam',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary)),
          const SizedBox(height: 6),
          const Text('Tap tombol + untuk menambah peminjam baru',
              style: TextStyle(
                  fontSize: 13, color: AppTheme.textSecondary)),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Future<void> _navigasiTambahPeminjam() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const FormPeminjamScreen()),
    );
    if (result == true) _loadData();
  }

  Future<void> _navigasiDetail(Peminjam peminjam) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
          builder: (_) => DetailPeminjamScreen(peminjam: peminjam)),
    );
    _loadData();
  }
}
