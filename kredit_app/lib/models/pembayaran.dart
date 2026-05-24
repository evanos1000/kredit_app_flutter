class Pembayaran {
  final int? id;
  final int pinjamanId;
  final int peminjamId;
  final double jumlahBayar;
  final double sisaSebelum;
  final double sisaSetelah;
  final DateTime tanggalBayar;
  final String? catatan;

  Pembayaran({
    this.id,
    required this.pinjamanId,
    required this.peminjamId,
    required this.jumlahBayar,
    required this.sisaSebelum,
    required this.sisaSetelah,
    required this.tanggalBayar,
    this.catatan,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'pinjaman_id': pinjamanId,
      'peminjam_id': peminjamId,
      'jumlah_bayar': jumlahBayar,
      'sisa_sebelum': sisaSebelum,
      'sisa_setelah': sisaSetelah,
      'tanggal_bayar': tanggalBayar.toIso8601String(),
      'catatan': catatan,
    };
  }

  factory Pembayaran.fromMap(Map<String, dynamic> map) {
    return Pembayaran(
      id: map['id'] as int?,
      pinjamanId: map['pinjaman_id'] as int,
      peminjamId: map['peminjam_id'] as int,
      jumlahBayar: (map['jumlah_bayar'] as num).toDouble(),
      sisaSebelum: (map['sisa_sebelum'] as num).toDouble(),
      sisaSetelah: (map['sisa_setelah'] as num).toDouble(),
      tanggalBayar: DateTime.parse(map['tanggal_bayar'] as String),
      catatan: map['catatan'] as String?,
    );
  }
}
