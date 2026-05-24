enum DurasiTipe { harian, mingguan, bulanan }

enum StatusPinjaman { aktif, lunas }

class Pinjaman {
  final int? id;
  final int peminjamId;
  final int nomorPinjaman;
  final double pokokPinjaman;
  final double bungaFlat; // persentase, misal 25.0
  final double totalBunga; // nominal bunga
  final double totalWajibBayar; // pokok + bunga
  final double totalSudahBayar;
  final DurasiTipe durasiTipe;
  final StatusPinjaman status;
  final DateTime tanggalMulai;
  final DateTime? tanggalLunas;
  final String? catatan;

  Pinjaman({
    this.id,
    required this.peminjamId,
    required this.nomorPinjaman,
    required this.pokokPinjaman,
    required this.bungaFlat,
    required this.totalBunga,
    required this.totalWajibBayar,
    required this.totalSudahBayar,
    required this.durasiTipe,
    required this.status,
    required this.tanggalMulai,
    this.tanggalLunas,
    this.catatan,
  });

  double get sisaTagihan => totalWajibBayar - totalSudahBayar;
  bool get sudahLunas => status == StatusPinjaman.lunas;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'peminjam_id': peminjamId,
      'nomor_pinjaman': nomorPinjaman,
      'pokok_pinjaman': pokokPinjaman,
      'bunga_flat': bungaFlat,
      'total_bunga': totalBunga,
      'total_wajib_bayar': totalWajibBayar,
      'total_sudah_bayar': totalSudahBayar,
      'durasi_tipe': durasiTipe.name,
      'status': status.name,
      'tanggal_mulai': tanggalMulai.toIso8601String(),
      'tanggal_lunas': tanggalLunas?.toIso8601String(),
      'catatan': catatan,
    };
  }

  factory Pinjaman.fromMap(Map<String, dynamic> map) {
    return Pinjaman(
      id: map['id'] as int?,
      peminjamId: map['peminjam_id'] as int,
      nomorPinjaman: map['nomor_pinjaman'] as int,
      pokokPinjaman: (map['pokok_pinjaman'] as num).toDouble(),
      bungaFlat: (map['bunga_flat'] as num).toDouble(),
      totalBunga: (map['total_bunga'] as num).toDouble(),
      totalWajibBayar: (map['total_wajib_bayar'] as num).toDouble(),
      totalSudahBayar: (map['total_sudah_bayar'] as num).toDouble(),
      durasiTipe: DurasiTipe.values.firstWhere((e) => e.name == map['durasi_tipe']),
      status: StatusPinjaman.values.firstWhere((e) => e.name == map['status']),
      tanggalMulai: DateTime.parse(map['tanggal_mulai'] as String),
      tanggalLunas: map['tanggal_lunas'] != null ? DateTime.parse(map['tanggal_lunas'] as String) : null,
      catatan: map['catatan'] as String?,
    );
  }

  Pinjaman copyWith({
    int? id,
    int? peminjamId,
    int? nomorPinjaman,
    double? pokokPinjaman,
    double? bungaFlat,
    double? totalBunga,
    double? totalWajibBayar,
    double? totalSudahBayar,
    DurasiTipe? durasiTipe,
    StatusPinjaman? status,
    DateTime? tanggalMulai,
    DateTime? tanggalLunas,
    String? catatan,
  }) {
    return Pinjaman(
      id: id ?? this.id,
      peminjamId: peminjamId ?? this.peminjamId,
      nomorPinjaman: nomorPinjaman ?? this.nomorPinjaman,
      pokokPinjaman: pokokPinjaman ?? this.pokokPinjaman,
      bungaFlat: bungaFlat ?? this.bungaFlat,
      totalBunga: totalBunga ?? this.totalBunga,
      totalWajibBayar: totalWajibBayar ?? this.totalWajibBayar,
      totalSudahBayar: totalSudahBayar ?? this.totalSudahBayar,
      durasiTipe: durasiTipe ?? this.durasiTipe,
      status: status ?? this.status,
      tanggalMulai: tanggalMulai ?? this.tanggalMulai,
      tanggalLunas: tanggalLunas ?? this.tanggalLunas,
      catatan: catatan ?? this.catatan,
    );
  }
}
