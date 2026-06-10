import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'savings_model.dart';
import 'wishlist_model.dart';

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
    String path = join(await getDatabasesPath(), 'savings.db');
    return await openDatabase(
      path,
      version: 3, // Naik ke versi 3 untuk akomodasi perubahan kolom baru
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE savings(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        amount REAL,
        date TEXT,
        description TEXT,
        type TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE wishlist(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        itemName TEXT,
        price REAL,
        targetDate TEXT,
        imagePath TEXT -- 2. Pastikan baris ini ada saat bikin baru
      )
    ''');
  }

  // 3. Sesuaikan fungsi _onUpgrade agar mendeteksi migrasi ke versi 3
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute("ALTER TABLE savings ADD COLUMN type TEXT");
    }
    if (oldVersion < 3) {
      // Perintah sakti untuk menyisipkan kolom gambar ke tabel wishlist lama tanpa hapus data
      await db.execute("ALTER TABLE wishlist ADD COLUMN imagePath TEXT");
    }
  }

  Future<int> insertSavings(SavingsEntry entry) async {
    Database db = await database;
    return await db.insert('savings', entry.toMap());
  }

  Future<List<SavingsEntry>> getSavings() async {
    Database db = await database;
    List<Map<String, dynamic>> maps = await db.query(
      'savings',
      orderBy: 'date DESC',
    );
    return List.generate(maps.length, (i) => SavingsEntry.fromMap(maps[i]));
  }

  // Menghitung sisa saldo bersih (Pemasukan - Pengeluaran)
  Future<double> getTotalSavings() async {
    Database db = await database;
    List<Map<String, dynamic>> incomeResult = await db.rawQuery(
      "SELECT SUM(amount) as total FROM savings WHERE type = 'pemasukan'",
    );
    List<Map<String, dynamic>> expenseResult = await db.rawQuery(
      "SELECT SUM(amount) as total FROM savings WHERE type = 'pengeluaran'",
    );

    double totalIncome = incomeResult.first['total'] ?? 0.0;
    double totalExpense = expenseResult.first['total'] ?? 0.0;

    return totalIncome - totalExpense;
  }

  Future<int> deleteSavings(int id) async {
    Database db = await database;
    return await db.delete('savings', where: 'id = ?', whereArgs: [id]);
  }

  // --- Wishlist Methods ---
  Future<int> insertWishlist(WishlistItem item) async {
    Database db = await database;
    return await db.insert('wishlist', item.toMap());
  }

  Future<List<WishlistItem>> getWishlist() async {
    Database db = await database;
    List<Map<String, dynamic>> maps = await db.query('wishlist');
    return List.generate(maps.length, (i) => WishlistItem.fromMap(maps[i]));
  }

  Future<int> deleteWishlist(int id) async {
    Database db = await database;
    return await db.delete('wishlist', where: 'id = ?', whereArgs: [id]);
  }
}
