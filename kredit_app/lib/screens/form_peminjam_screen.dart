import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/peminjam.dart';
import '../utils/app_theme.dart';

class FormPeminjamScreen extends StatefulWidget {
  final Peminjam? peminjam; // null = tambah baru, ada nilai = edit

  const FormPeminjamScreen({super.key, this.peminjam});

  @override
  State<FormPeminjamScreen> createState() => _FormPeminjamScreenState();
}

class _FormPeminjamScreenState extends State<FormPeminjamScreen> {
  final _formKey = GlobalKey<FormState>();
  final _namaCtrl = TextEditingController();
  final _hpCtrl = TextEditingController();
  final _catatanCtrl = TextEditingController();
  final _db = DatabaseHelper();
  bool _isLoading = false;

  bool get _isEdit => widget.peminjam != null;

  @override
  void initState() {
    super.initState();
    if (_isEdit) {
      _namaCtrl.text = widget.peminjam!.nama;
      _hpCtrl.text = widget.peminjam!.nomorHp ?? '';
      _catatanCtrl.text = widget.peminjam!.catatan ?? '';
    }
  }

  @override
  void dispose() {
    _namaCtrl.dispose();
    _hpCtrl.dispose();
    _catatanCtrl.dispose();
    super.dispose();
  }

  Future<void> _simpan() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final peminjam = Peminjam(
        id: widget.peminjam?.id,
        nama: _namaCtrl.text.trim(),
        nomorHp: _hpCtrl.text.trim().isEmpty ? null : _hpCtrl.text.trim(),
        catatan: _catatanCtrl.text.trim().isEmpty ? null : _catatanCtrl.text.trim(),
        createdAt: widget.peminjam?.createdAt ?? DateTime.now(),
      );

      if (_isEdit) {
        await _db.updatePeminjam(peminjam);
      } else {
        await _db.insertPeminjam(peminjam);
      }

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEdit ? 'Data peminjam diperbarui' : 'Peminjam berhasil ditambahkan'),
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
        title: Text(_isEdit ? 'Edit Peminjam' : 'Tambah Peminjam'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.person_rounded,
                      size: 40, color: AppTheme.primary),
                ),
              ),
              const SizedBox(height: 28),
              _buildLabel('Nama Lengkap *'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _namaCtrl,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  hintText: 'Contoh: Evan Pratama',
                  prefixIcon: Icon(Icons.person_outline_rounded),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Nama tidak boleh kosong';
                  if (v.trim().length < 2) return 'Nama minimal 2 karakter';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              _buildLabel('Nomor HP (Opsional)'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _hpCtrl,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  hintText: '08xx-xxxx-xxxx',
                  prefixIcon: Icon(Icons.phone_outlined),
                ),
              ),
              const SizedBox(height: 16),
              _buildLabel('Catatan (Opsional)'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _catatanCtrl,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: 'Tambahkan catatan jika perlu...',
                  prefixIcon: Padding(
                    padding: EdgeInsets.only(bottom: 48),
                    child: Icon(Icons.notes_rounded),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _simpan,
                  icon: _isLoading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2))
                      : Icon(_isEdit ? Icons.save_rounded : Icons.person_add_rounded),
                  label: Text(_isEdit ? 'Simpan Perubahan' : 'Tambah Peminjam'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(text,
        style: const TextStyle(
            fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textPrimary));
  }
}
