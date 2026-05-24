import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../database/database_helper.dart';
import '../models/peminjam.dart';
import '../models/pinjaman.dart';
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

class FormPinjamanScreen extends StatefulWidget {
  final Peminjam peminjam;
  final int nomorPinjaman;
  final double sisaHutangLama;

  const FormPinjamanScreen({
    super.key,
    required this.peminjam,
    required this.nomorPinjaman,
    this.sisaHutangLama = 0,
  });

  @override
  State<FormPinjamanScreen> createState() => _FormPinjamanScreenState();
}

class _FormPinjamanScreenState extends State<FormPinjamanScreen> {
  final _formKey = GlobalKey<FormState>();
  final _pokokCtrl = TextEditingController();
  final _bungaManualCtrl = TextEditingController();
  final _catatanCtrl = TextEditingController();
  final _db = DatabaseHelper();

  DurasiTipe _durasiTipe = DurasiTipe.mingguan;

  // Mode bunga: 'persen' atau 'nominal'
  String _modeBunga = 'persen';
  double _bungaPersen = 25.0; // kalau mode persen
  // kalau mode nominal, ambil dari _bungaManualCtrl

  double _previewPokok = 0;
  double _previewBunga = 0;
  double _previewTotal = 0;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _pokokCtrl.addListener(_hitungPreview);
    _bungaManualCtrl.addListener(_hitungPreview);
  }

  @override
  void dispose() {
    _pokokCtrl.removeListener(_hitungPreview);
    _bungaManualCtrl.removeListener(_hitungPreview);
    _pokokCtrl.dispose();
    _bungaManualCtrl.dispose();
    _catatanCtrl.dispose();
    super.dispose();
  }

  void _hitungPreview() {
    final pokokRaw = _pokokCtrl.text.trim().replaceAll('.', '');
    final pokok = double.tryParse(pokokRaw) ?? 0;
    double bunga = 0;

    if (_modeBunga == 'persen') {
      bunga = pokok * (_bungaPersen / 100);
    } else {
      final bungaRaw = _bungaManualCtrl.text.trim().replaceAll('.', '');
      bunga = double.tryParse(bungaRaw) ?? 0;
    }

    setState(() {
      _previewPokok = pokok;
      _previewBunga = bunga;
      // Total = pokok baru + bunga dari pokok baru + sisa hutang lama
      _previewTotal = pokok + bunga + widget.sisaHutangLama;
    });
  }

  // Hitung persen bunga untuk disimpan ke DB
  double get _bungaPersenFinal {
    if (_modeBunga == 'persen') return _bungaPersen;
    if (_previewPokok <= 0) return 0;
    return (_previewBunga / _previewPokok) * 100;
  }

  Future<void> _simpan() async {
    if (!_formKey.currentState!.validate()) return;
    // Strip dots from formatted numbers before final check
    if (_previewPokok <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Jumlah pinjaman tidak valid')),
      );
      return;
    }
    if (_previewBunga < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bunga tidak boleh negatif')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final pinjaman = Pinjaman(
        peminjamId: widget.peminjam.id!,
        nomorPinjaman: widget.nomorPinjaman,
        pokokPinjaman: _previewPokok,
        bungaFlat: _bungaPersenFinal,
        totalBunga: _previewBunga,
        totalWajibBayar: _previewTotal, // sudah include sisa lama
        totalSudahBayar: 0,
        durasiTipe: _durasiTipe,
        status: StatusPinjaman.aktif,
        tanggalMulai: DateTime.now(),
        catatan: _catatanCtrl.text.trim().isEmpty
            ? null
            : _catatanCtrl.text.trim(),
      );

      await _db.insertPinjaman(pinjaman);

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Pinjaman ke-${widget.nomorPinjaman} ${widget.peminjam.nama} berhasil dibuat'),
            backgroundColor: AppTheme.accent,
          ),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Terjadi kesalahan, coba lagi')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Pinjaman Ke-${widget.nomorPinjaman}'),
      ),
      body: SingleChildScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 60),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildInfoBanner(),
              const SizedBox(height: 20),

              // ── Jumlah Pokok ──
              _buildLabel('Jumlah Pinjaman (Pokok) *'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _pokokCtrl,
                keyboardType: TextInputType.number,
                inputFormatters: [ThousandsSeparatorInputFormatter()],
                decoration: const InputDecoration(
                  hintText: '500.000',
                  prefixText: 'Rp ',
                  prefixStyle: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty)
                    return 'Jumlah pinjaman wajib diisi';
                  final val = double.tryParse(v.trim().replaceAll('.', ''));
                  if (val == null || val <= 0) return 'Jumlah tidak valid';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // ── Jenis Pembayaran ──
              _buildLabel('Jenis Pembayaran *'),
              const SizedBox(height: 8),
              _buildDurasiSelector(),
              const SizedBox(height: 16),

              // ── Bunga ──
              _buildLabel('Bunga'),
              const SizedBox(height: 8),
              _buildModeBungaToggle(),
              const SizedBox(height: 10),
              if (_modeBunga == 'persen') ...[
                _buildBungaPersenSelector(),
              ] else ...[
                _buildBungaNominalInput(),
              ],
              const SizedBox(height: 16),

              // ── Catatan ──
              _buildLabel('Catatan (Opsional)'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _catatanCtrl,
                maxLines: 2,
                decoration: const InputDecoration(
                  hintText: 'Keperluan pinjaman, dll...',
                ),
              ),
              const SizedBox(height: 24),

              // ── Preview ──
              if (_previewPokok > 0) ...[
                _buildPreviewKalkulasi(),
                const SizedBox(height: 24),
              ],

              const Divider(height: 32),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _simpan,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    elevation: 2,
                  ),
                  icon: _isLoading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2))
                      : const Icon(Icons.save_rounded, size: 20),
                  label: const Text('Buat Pinjaman',
                      style: TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w700)),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  // ── Toggle mode bunga ──
  Widget _buildModeBungaToggle() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.divider.withOpacity(0.5),
        borderRadius: BorderRadius.circular(10),
      ),
      padding: const EdgeInsets.all(3),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() => _modeBunga = 'persen');
                _hitungPreview();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: _modeBunga == 'persen'
                      ? Colors.white
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: _modeBunga == 'persen'
                      ? [
                          BoxShadow(
                              color: Colors.black.withOpacity(0.06),
                              blurRadius: 4)
                        ]
                      : [],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.percent_rounded,
                        size: 16,
                        color: _modeBunga == 'persen'
                            ? AppTheme.primary
                            : AppTheme.textSecondary),
                    const SizedBox(width: 6),
                    Text('Persentase (%)',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: _modeBunga == 'persen'
                                ? AppTheme.primary
                                : AppTheme.textSecondary)),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() => _modeBunga = 'nominal');
                _hitungPreview();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: _modeBunga == 'nominal'
                      ? Colors.white
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: _modeBunga == 'nominal'
                      ? [
                          BoxShadow(
                              color: Colors.black.withOpacity(0.06),
                              blurRadius: 4)
                        ]
                      : [],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.edit_rounded,
                        size: 16,
                        color: _modeBunga == 'nominal'
                            ? AppTheme.accentOrange
                            : AppTheme.textSecondary),
                    const SizedBox(width: 6),
                    Text('Nominal (Rp)',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: _modeBunga == 'nominal'
                                ? AppTheme.accentOrange
                                : AppTheme.textSecondary)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Pilihan bunga persen ──
  Widget _buildBungaPersenSelector() {
    final options = [5.0, 10.0, 15.0, 20.0, 25.0, 30.0];
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options.map((b) {
        final isSelected = _bungaPersen == b;
        return GestureDetector(
          onTap: () {
            setState(() => _bungaPersen = b);
            _hitungPreview();
          },
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected ? AppTheme.accentOrange : Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isSelected
                    ? AppTheme.accentOrange
                    : AppTheme.divider,
              ),
            ),
            child: Text(
              '${b.toInt()}%',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color:
                    isSelected ? Colors.white : AppTheme.textSecondary,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  // ── Input bunga nominal manual ──
  Widget _buildBungaNominalInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: _bungaManualCtrl,
          keyboardType: TextInputType.number,
          inputFormatters: [ThousandsSeparatorInputFormatter()],
          decoration: const InputDecoration(
            hintText: 'Contoh: 15.000',
            prefixText: 'Rp ',
            prefixStyle: TextStyle(
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary),
            helperText: 'Masukkan nominal bunga secara langsung',
          ),
          validator: (v) {
            if (_modeBunga != 'nominal') return null;
            if (v == null || v.trim().isEmpty)
              return 'Nominal bunga wajib diisi';
            final val = double.tryParse(v.trim().replaceAll('.', ''));
            if (val == null || val < 0) return 'Nominal tidak valid';
            return null;
          },
        ),
        if (_previewPokok > 0 && _previewBunga > 0) ...[
          const SizedBox(height: 6),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.accentOrange.withOpacity(0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'Setara ${_bungaPersenFinal.toStringAsFixed(1)}% dari pokok',
              style: const TextStyle(
                  fontSize: 12,
                  color: AppTheme.accentOrange,
                  fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildInfoBanner() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppTheme.primary.withOpacity(0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.primary.withOpacity(0.2)),
          ),
          child: Row(
            children: [
              const Icon(Icons.info_outline_rounded,
                  color: AppTheme.primary, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Pinjaman ke-${widget.nomorPinjaman} untuk ${widget.peminjam.nama}',
                  style: const TextStyle(
                      fontSize: 13,
                      color: AppTheme.primary,
                      fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
        if (widget.sisaHutangLama > 0) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTheme.danger.withOpacity(0.06),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.danger.withOpacity(0.2)),
            ),
            child: Row(
              children: [
                const Icon(Icons.warning_amber_rounded,
                    color: AppTheme.danger, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Masih ada sisa hutang lama: ${CurrencyFormatter.format(widget.sisaHutangLama)} — akan digabung ke pinjaman ini',
                    style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.danger,
                        fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildDurasiSelector() {
    return Row(
      children: DurasiTipe.values.map((tipe) {
        final isSelected = _durasiTipe == tipe;
        final label = tipe == DurasiTipe.harian
            ? 'Harian'
            : tipe == DurasiTipe.mingguan
                ? 'Mingguan'
                : 'Bulanan';
        final icon = tipe == DurasiTipe.harian
            ? Icons.today_rounded
            : tipe == DurasiTipe.mingguan
                ? Icons.view_week_rounded
                : Icons.calendar_month_rounded;
        return Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _durasiTipe = tipe),
            child: Container(
              margin: EdgeInsets.only(
                  right: tipe != DurasiTipe.bulanan ? 8 : 0),
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: isSelected ? AppTheme.primary : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected
                      ? AppTheme.primary
                      : AppTheme.divider,
                ),
              ),
              child: Column(
                children: [
                  Icon(icon,
                      color: isSelected
                          ? Colors.white
                          : AppTheme.textSecondary,
                      size: 20),
                  const SizedBox(height: 4),
                  Text(label,
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: isSelected
                              ? Colors.white
                              : AppTheme.textSecondary)),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPreviewKalkulasi() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Ringkasan Pinjaman',
              style:
                  TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          _buildPreviewRow('Pokok Pinjaman',
              CurrencyFormatter.format(_previewPokok),
              color: AppTheme.textPrimary),
          const SizedBox(height: 6),
          _buildPreviewRow(
            _modeBunga == 'persen'
                ? 'Bunga (${_bungaPersen.toInt()}%)'
                : 'Bunga (${_bungaPersenFinal.toStringAsFixed(1)}%)',
            '+ ${CurrencyFormatter.format(_previewBunga)}',
            color: AppTheme.accentOrange,
          ),
          if (widget.sisaHutangLama > 0) ...[
            const SizedBox(height: 6),
            _buildPreviewRow(
              'Sisa Hutang Lama',
              '+ ${CurrencyFormatter.format(widget.sisaHutangLama)}',
              color: AppTheme.danger,
            ),
          ],
          const Divider(height: 16),
          _buildPreviewRow(
            'Total Wajib Bayar',
            CurrencyFormatter.format(_previewTotal),
            color: AppTheme.primary,
            isBold: true,
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.accent.withOpacity(0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline_rounded,
                    color: AppTheme.accent, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.sisaHutangLama > 0
                        ? 'Total sudah termasuk sisa hutang lama ${CurrencyFormatter.format(widget.sisaHutangLama)}. Bunga hanya dihitung dari pokok baru ${CurrencyFormatter.format(_previewPokok)}.'
                        : 'Peminjam harus melunasi ${CurrencyFormatter.format(_previewTotal)} secara ${_getDurasiLabel(_durasiTipe).toLowerCase()} tanpa batas waktu.',
                    style: const TextStyle(
                        fontSize: 11, color: AppTheme.accent),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewRow(String label, String value,
      {Color? color, bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 13, color: AppTheme.textSecondary)),
        Text(value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isBold ? FontWeight.w800 : FontWeight.w600,
              color: color ?? AppTheme.textPrimary,
            )),
      ],
    );
  }

  Widget _buildLabel(String text) {
    return Text(text,
        style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary));
  }

  String _getDurasiLabel(DurasiTipe tipe) {
    switch (tipe) {
      case DurasiTipe.harian:
        return 'Harian';
      case DurasiTipe.mingguan:
        return 'Mingguan';
      case DurasiTipe.bulanan:
        return 'Bulanan';
    }
  }
}
