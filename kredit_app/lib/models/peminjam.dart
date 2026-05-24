class Peminjam {
  final int? id;
  final String nama;
  final String? nomorHp;
  final String? catatan;
  final DateTime createdAt;

  Peminjam({
    this.id,
    required this.nama,
    this.nomorHp,
    this.catatan,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nama': nama,
      'nomor_hp': nomorHp,
      'catatan': catatan,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory Peminjam.fromMap(Map<String, dynamic> map) {
    return Peminjam(
      id: map['id'] as int?,
      nama: map['nama'] as String,
      nomorHp: map['nomor_hp'] as String?,
      catatan: map['catatan'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  Peminjam copyWith({
    int? id,
    String? nama,
    String? nomorHp,
    String? catatan,
    DateTime? createdAt,
  }) {
    return Peminjam(
      id: id ?? this.id,
      nama: nama ?? this.nama,
      nomorHp: nomorHp ?? this.nomorHp,
      catatan: catatan ?? this.catatan,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
