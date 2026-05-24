import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../database/database_helper.dart';
import '../models/peminjam.dart';
import '../models/pinjaman.dart';
import '../models/pembayaran.dart';
import '../utils/app_theme.dart';
import '../utils/currency_formatter.dart';

class ThousandsSeparatorInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.text.isEmpty) return newValue;
    final digitsOnly = newValue.text.replaceAll('.', '');
    if (digitsOnly.isEmpty) return newValue.copyWith(text: '');
    final number = int.tryParse(digitsOnly);
    if (number == null) return oldValue;
    final formatted = _formatNumber(number);
    return newValue.copyWith(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }

  String _formatNumber(int number) {
    final str = number.toString();
    final result = StringBuffer();
    for (int i = 0; i < str.length; i++) {
      if (i > 0 && (str.length - i) % 3 == 0) result.write('.');
      result.write(str[i]);
    }
    return result.toString();
  }
}

class DetailPinjamanScreen extends StatefulWidget {
  final Pinjaman pinjaman;
  final Peminjam peminjam;

  const DetailPinjamanScreen({
    super.key,
    required this.pinjaman,
    required this.peminjam,
  });

  @override
  State<DetailPinjamanScreen> createState() => _DetailPinjamanScreenState();
}

class _DetailPinjamanScreenState extends State<DetailPinjamanScreen> {
  final _db = DatabaseHelper();
  late Pinjaman _pinjaman;
  List<Pembayaran> _riwayatBayar = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _pinjaman = widget.pinjaman;
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final updated = await _db.getPinjamanById(_pinjaman.id!);
      final riwayat = await _db.getPembayaranByPinjaman(_pinjaman.id!);
      setState(() {
        if (updated != null) _pinjaman = updated;
        _riwayatBayar = riwayat;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _showFormBayar() {
    if (_pinjaman.sudahLunas) return;

    final ctrl = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool isProcessing = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Container(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppTheme.divider,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text('Catat Pembayaran',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                Text(
                  'Sisa tagihan: ${CurrencyFormatter.format(_pinjaman.sisaTagihan)}',
                  style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                ),
                const SizedBox(height: 20),
                // Quick amount buttons
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildQuickAmount('50.000', 50000, ctrl, setSheetState),
                    _buildQuickAmount('100.000', 100000, ctrl, setSheetState),
                    _buildQuickAmount('200.000', 200000, ctrl, setSheetState),
                    _buildQuickAmount('500.000', 500000, ctrl, setSheetState),
                    _buildQuickAmountLunas(ctrl, setSheetState),
                  ],
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: ctrl,
                  keyboardType: TextInputType.number,
                  inputFormatters: [ThousandsSeparatorInputFormatter()],
                  decoration: const InputDecoration(
                    labelText: 'Jumlah Bayar',
                    prefixText: 'Rp ',
                    prefixIcon: Icon(Icons.payments_rounded),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Jumlah wajib diisi';
                    final val = double.tryParse(v.trim());
                    if (val == null || val <= 0) return 'Jumlah tidak valid';
                    if (val > _pinjaman.sisaTagihan) {
                      return 'Melebihi sisa tagihan (${CurrencyFormatter.format(_pinjaman.sisaTagihan)})';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: isProcessing
                        ? null
                        : () async {
                            if (!formKey.currentState!.validate()) return;
                            setSheetState(() => isProcessing = true);
                            await _prosessBayar(double.parse(ctrl.text.trim().replaceAll('.', '')));
                            if (ctx.mounted) Navigator.pop(ctx);
                          },
                    child: isProcessing
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2))
                        : const Text('Konfirmasi Bayar'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickAmount(
      String label, double amount, TextEditingController ctrl, StateSetter set) {
    return GestureDetector(
      onTap: () => set(() => ctrl.text = amount.toInt().toString()),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          border: Border.all(color: AppTheme.primary.withOpacity(0.4)),
          borderRadius: BorderRadius.circular(20),
          color: AppTheme.primary.withOpacity(0.05),
        ),
        child: Text(label,
            style: const TextStyle(
                fontSize: 12, color: AppTheme.primary, fontWeight: FontWeight.w600)),
      ),
    );
  }

  Widget _buildQuickAmountLunas(
      TextEditingController ctrl, StateSetter set) {
    return GestureDetector(
      onTap: () => set(() => ctrl.text = _pinjaman.sisaTagihan.toInt().toString()),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          border: Border.all(color: AppTheme.accent),
          borderRadius: BorderRadius.circular(20),
          color: AppTheme.accent.withOpacity(0.08),
        ),
        child: const Text('Lunaskan',
            style: TextStyle(
                fontSize: 12, color: AppTheme.accent, fontWeight: FontWeight.w700)),
      ),
    );
  }

  Future<void> _prosessBayar(double jumlah) async {
    try {
      final sisaSebelum = _pinjaman.sisaTagihan;
      final sisaSetelah = sisaSebelum - jumlah;
      final sudahLunas = sisaSetelah <= 0;

      final pembayaran = Pembayaran(
        pinjamanId: _pinjaman.id!,
        peminjamId: widget.peminjam.id!,
        jumlahBayar: jumlah,
        sisaSebelum: sisaSebelum,
        sisaSetelah: sisaSetelah < 0 ? 0 : sisaSetelah,
        tanggalBayar: DateTime.now(),
      );

      await _db.insertPembayaran(pembayaran);

      final totalSudahBayarBaru = _pinjaman.totalSudahBayar + jumlah;
      final pinjamanUpdated = _pinjaman.copyWith(
        totalSudahBayar: totalSudahBayarBaru,
        status: sudahLunas ? StatusPinjaman.lunas : StatusPinjaman.aktif,
        tanggalLunas: sudahLunas ? DateTime.now() : null,
      );

      await _db.updatePinjaman(pinjamanUpdated);
      await _loadData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(sudahLunas
                ? '🎉 Pinjaman LUNAS! Terima kasih ${widget.peminjam.nama}'
                : 'Pembayaran ${CurrencyFormatter.format(jumlah)} berhasil dicatat'),
            backgroundColor: sudahLunas ? AppTheme.accent : AppTheme.primary,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal menyimpan pembayaran')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        title: Text('Pinjaman Ke-${_pinjaman.nomorPinjaman}'),
        actions: [
          if (!_pinjaman.sudahLunas)
            Container(
              margin: const EdgeInsets.only(right: 16),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text('Aktif',
                  style: TextStyle(
                      color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
            ),
          if (_pinjaman.sudahLunas)
            Container(
              margin: const EdgeInsets.only(right: 16),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.accent.withOpacity(0.3),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text('LUNAS',
                  style: TextStyle(
                      color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
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
                    _buildRingkasanCard(),
                    const SizedBox(height: 16),
                    _buildProgressCard(),
                    const SizedBox(height: 16),
                    _buildRiwayatHeader(),
                    const SizedBox(height: 10),
                    if (_riwayatBayar.isEmpty)
                      _buildEmptyRiwayat()
                    else
                      ..._riwayatBayar.map((p) => _buildRiwayatItem(p)),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
      floatingActionButton: _pinjaman.sudahLunas
          ? null
          : FloatingActionButton.extended(
              onPressed: _showFormBayar,
              backgroundColor: AppTheme.accent,
              icon: const Icon(Icons.payments_rounded, color: Colors.white),
              label: const Text('Catat Bayar',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
            ),
    );
  }

  Widget _buildRingkasanCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Detail Pinjaman',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
              _buildBadgeDurasi(),
            ],
          ),
          const SizedBox(height: 14),
          _buildDetailRow('Peminjam', widget.peminjam.nama),
          _buildDetailRow('Pokok Pinjaman',
              CurrencyFormatter.format(_pinjaman.pokokPinjaman)),
          _buildDetailRow('Bunga Flat (${_pinjaman.bungaFlat.toInt()}%)',
              '+ ${CurrencyFormatter.format(_pinjaman.totalBunga)}',
              valueColor: AppTheme.accentOrange),
          const Divider(height: 16),
          _buildDetailRow('Total Wajib Bayar',
              CurrencyFormatter.format(_pinjaman.totalWajibBayar),
              valueColor: AppTheme.primary, isBold: true),
          const SizedBox(height: 4),
          _buildDetailRow('Tanggal Mulai',
              DateFormatter.formatDate(_pinjaman.tanggalMulai)),
          if (_pinjaman.tanggalLunas != null)
            _buildDetailRow('Tanggal Lunas',
                DateFormatter.formatDate(_pinjaman.tanggalLunas!),
                valueColor: AppTheme.accent),
          if (_pinjaman.catatan != null) ...[
            const SizedBox(height: 4),
            _buildDetailRow('Catatan', _pinjaman.catatan!),
          ],
        ],
      ),
    );
  }

  Widget _buildProgressCard() {
    final progress =
        (_pinjaman.totalSudahBayar / _pinjaman.totalWajibBayar).clamp(0.0, 1.0);
    final sisa = _pinjaman.sisaTagihan;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _pinjaman.sudahLunas
            ? AppTheme.accent.withOpacity(0.08)
            : AppTheme.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _pinjaman.sudahLunas
              ? AppTheme.accent.withOpacity(0.3)
              : AppTheme.divider,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _pinjaman.sudahLunas ? '✅ LUNAS' : 'Progress Pembayaran',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: _pinjaman.sudahLunas ? AppTheme.accent : AppTheme.textPrimary,
                ),
              ),
              Text(
                '${(progress * 100).toStringAsFixed(1)}%',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: _pinjaman.sudahLunas ? AppTheme.accent : AppTheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: AppTheme.divider,
              valueColor: AlwaysStoppedAnimation(
                _pinjaman.sudahLunas ? AppTheme.accent : AppTheme.primary,
              ),
              minHeight: 10,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildProgressStat(
                    'Terbayar',
                    CurrencyFormatter.format(_pinjaman.totalSudahBayar),
                    AppTheme.accent),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildProgressStat(
                    'Sisa',
                    CurrencyFormatter.format(sisa < 0 ? 0 : sisa),
                    _pinjaman.sudahLunas ? AppTheme.textSecondary : AppTheme.danger),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildProgressStat(
                    'Total Bayar',
                    CurrencyFormatter.format(_pinjaman.totalWajibBayar),
                    AppTheme.primary),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProgressStat(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value,
              style: TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w800, color: color)),
          Text(label,
              style: const TextStyle(fontSize: 10, color: AppTheme.textSecondary)),
        ],
      ),
    );
  }

  Widget _buildRiwayatHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text('Riwayat Pembayaran',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
        Text('${_riwayatBayar.length} transaksi',
            style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
      ],
    );
  }

  Widget _buildRiwayatItem(Pembayaran bayar) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppTheme.accent.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.payments_rounded, color: AppTheme.accent, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  CurrencyFormatter.format(bayar.jumlahBayar),
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.accent),
                ),
                const SizedBox(height: 2),
                Text(
                  DateFormatter.formatDateTime(bayar.tanggalBayar),
                  style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                ),
                if (bayar.catatan != null)
                  Text(bayar.catatan!,
                      style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'Sisa: ${CurrencyFormatter.format(bayar.sisaSetelah < 0 ? 0 : bayar.sisaSetelah)}',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.danger),
              ),
              Text(
                'Dari: ${CurrencyFormatter.format(bayar.sisaSebelum)}',
                style: const TextStyle(fontSize: 10, color: AppTheme.textSecondary),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyRiwayat() {
    return Container(
      padding: const EdgeInsets.all(32),
      alignment: Alignment.center,
      child: Column(
        children: [
          Icon(Icons.receipt_long_outlined,
              size: 48, color: AppTheme.textSecondary.withOpacity(0.5)),
          const SizedBox(height: 12),
          const Text('Belum ada pembayaran',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value,
      {Color? valueColor, bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
          const SizedBox(width: 16),
          Flexible(
            child: Text(value,
                textAlign: TextAlign.end,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isBold ? FontWeight.w800 : FontWeight.w600,
                  color: valueColor ?? AppTheme.textPrimary,
                )),
          ),
        ],
      ),
    );
  }

  Widget _buildBadgeDurasi() {
    final tipe = _pinjaman.durasiTipe;
    final label = tipe == DurasiTipe.harian
        ? 'Harian'
        : tipe == DurasiTipe.mingguan
            ? 'Mingguan'
            : 'Bulanan';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label,
          style: const TextStyle(
              fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.primary)),
    );
  }
}
