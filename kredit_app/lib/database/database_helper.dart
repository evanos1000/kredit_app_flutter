import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/peminjam.dart';
import '../models/pinjaman.dart';
import '../models/pembayaran.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'kredit_app.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE peminjam (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nama TEXT NOT NULL,
        nomor_hp TEXT,
        catatan TEXT,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE pinjaman (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        peminjam_id INTEGER NOT NULL,
        nomor_pinjaman INTEGER NOT NULL,
        pokok_pinjaman REAL NOT NULL,
        bunga_flat REAL NOT NULL,
        total_bunga REAL NOT NULL,
        total_wajib_bayar REAL NOT NULL,
        total_sudah_bayar REAL NOT NULL DEFAULT 0,
        durasi_tipe TEXT NOT NULL,
        status TEXT NOT NULL DEFAULT 'aktif',
        tanggal_mulai TEXT NOT NULL,
        tanggal_lunas TEXT,
        catatan TEXT,
        FOREIGN KEY (peminjam_id) REFERENCES peminjam (id)
      )
    ''');

    await db.execute('''
      CREATE TABLE pembayaran (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        pinjaman_id INTEGER NOT NULL,
        peminjam_id INTEGER NOT NULL,
        jumlah_bayar REAL NOT NULL,
        sisa_sebelum REAL NOT NULL,
        sisa_setelah REAL NOT NULL,
        tanggal_bayar TEXT NOT NULL,
        catatan TEXT,
        FOREIGN KEY (pinjaman_id) REFERENCES pinjaman (id),
        FOREIGN KEY (peminjam_id) REFERENCES peminjam (id)
      )
    ''');
  }

  // ─── PEMINJAM ───────────────────────────────────────────────

  Future<int> insertPeminjam(Peminjam peminjam) async {
    final db = await database;
    return await db.insert('peminjam', peminjam.toMap()..remove('id'));
  }

  Future<List<Peminjam>> getAllPeminjam() async {
    final db = await database;
    final maps = await db.query('peminjam', orderBy: 'nama ASC');
    return maps.map((m) => Peminjam.fromMap(m)).toList();
  }

  Future<Peminjam?> getPeminjamById(int id) async {
    final db = await database;
    final maps = await db.query('peminjam', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return Peminjam.fromMap(maps.first);
  }

  Future<int> updatePeminjam(Peminjam peminjam) async {
    final db = await database;
    return await db.update(
      'peminjam',
      peminjam.toMap(),
      where: 'id = ?',
      whereArgs: [peminjam.id],
    );
  }

  Future<int> deletePeminjam(int id) async {
    final db = await database;
    // Hapus semua data terkait
    final pinjamans = await getPinjamanByPeminjam(id);
    for (final p in pinjamans) {
      if (p.id != null) await deletePembayaranByPinjaman(p.id!);
    }
    await db.delete('pinjaman', where: 'peminjam_id = ?', whereArgs: [id]);
    return await db.delete('peminjam', where: 'id = ?', whereArgs: [id]);
  }

  // ─── PINJAMAN ───────────────────────────────────────────────

  Future<int> insertPinjaman(Pinjaman pinjaman) async {
    final db = await database;
    return await db.insert('pinjaman', pinjaman.toMap()..remove('id'));
  }

  Future<List<Pinjaman>> getPinjamanByPeminjam(int peminjamId) async {
    final db = await database;
    final maps = await db.query(
      'pinjaman',
      where: 'peminjam_id = ?',
      whereArgs: [peminjamId],
      orderBy: 'nomor_pinjaman DESC',
    );
    return maps.map((m) => Pinjaman.fromMap(m)).toList();
  }

  Future<Pinjaman?> getPinjamanAktif(int peminjamId) async {
    final db = await database;
    final maps = await db.query(
      'pinjaman',
      where: 'peminjam_id = ? AND status = ?',
      whereArgs: [peminjamId, 'aktif'],
    );
    if (maps.isEmpty) return null;
    return Pinjaman.fromMap(maps.first);
  }

  Future<int> getJumlahPinjamanSelesai(int peminjamId) async {
    final db = await database;
    final result = await db.query(
      'pinjaman',
      where: 'peminjam_id = ? AND status = ?',
      whereArgs: [peminjamId, 'lunas'],
    );
    return result.length;
  }

  Future<int> updatePinjaman(Pinjaman pinjaman) async {
    final db = await database;
    return await db.update(
      'pinjaman',
      pinjaman.toMap(),
      where: 'id = ?',
      whereArgs: [pinjaman.id],
    );
  }

  Future<Pinjaman?> getPinjamanById(int id) async {
    final db = await database;
    final maps = await db.query('pinjaman', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return Pinjaman.fromMap(maps.first);
  }

  // ─── PEMBAYARAN ─────────────────────────────────────────────

  Future<int> insertPembayaran(Pembayaran pembayaran) async {
    final db = await database;
    return await db.insert('pembayaran', pembayaran.toMap()..remove('id'));
  }

  Future<List<Pembayaran>> getPembayaranByPinjaman(int pinjamanId) async {
    final db = await database;
    final maps = await db.query(
      'pembayaran',
      where: 'pinjaman_id = ?',
      whereArgs: [pinjamanId],
      orderBy: 'tanggal_bayar DESC',
    );
    return maps.map((m) => Pembayaran.fromMap(m)).toList();
  }

  Future<List<Pembayaran>> getPembayaranByPeminjam(int peminjamId) async {
    final db = await database;
    final maps = await db.query(
      'pembayaran',
      where: 'peminjam_id = ?',
      whereArgs: [peminjamId],
      orderBy: 'tanggal_bayar DESC',
    );
    return maps.map((m) => Pembayaran.fromMap(m)).toList();
  }

  Future<int> deletePembayaranByPinjaman(int pinjamanId) async {
    final db = await database;
    return await db.delete('pembayaran', where: 'pinjaman_id = ?', whereArgs: [pinjamanId]);
  }

  // ─── STATISTIK ──────────────────────────────────────────────

  Future<Map<String, double>> getStatistikGlobal() async {
    final db = await database;

    final pinjamanResult = await db.rawQuery(
      'SELECT SUM(total_wajib_bayar) as total_piutang, SUM(total_sudah_bayar) as total_terkumpul FROM pinjaman WHERE status = "aktif"',
    );

    final totalPiutang = (pinjamanResult.first['total_piutang'] as num?)?.toDouble() ?? 0.0;
    final totalTerkumpul = (pinjamanResult.first['total_terkumpul'] as num?)?.toDouble() ?? 0.0;

    final lunasResult = await db.rawQuery(
      'SELECT SUM(total_wajib_bayar) as total_lunas FROM pinjaman WHERE status = "lunas"',
    );
    final totalLunas = (lunasResult.first['total_lunas'] as num?)?.toDouble() ?? 0.0;

    return {
      'total_piutang_aktif': totalPiutang - totalTerkumpul,
      'total_terkumpul': totalTerkumpul,
      'total_lunas': totalLunas,
    };
  }
}
