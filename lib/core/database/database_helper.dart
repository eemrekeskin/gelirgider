import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/category_model.dart';
import '../models/transaction_model.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('keskin_hafriyat.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future _createDB(Database db, int version) async {
    const idType = 'INTEGER PRIMARY KEY AUTOINCREMENT';
    const textType = 'TEXT NOT NULL';
    const doubleType = 'REAL NOT NULL';
    const integerType = 'INTEGER NOT NULL';

    await db.execute('''
CREATE TABLE categories (
  id $idType,
  name $textType,
  type $textType
  )
''');

    await db.execute('''
CREATE TABLE transactions (
  id $idType,
  amount $doubleType,
  categoryId $integerType,
  description $textType,
  date $textType,
  type $textType,
  FOREIGN KEY (categoryId) REFERENCES categories (id)
  )
''');

    // Default categories for ease of use
    await db.insert('categories', {'name': 'Hafriyat Geliri', 'type': 'income'});
    await db.insert('categories', {'name': 'Proje Avansı', 'type': 'income'});
    await db.insert('categories', {'name': 'Yakıt', 'type': 'expense'});
    await db.insert('categories', {'name': 'Personel Maaş', 'type': 'expense'});
    await db.insert('categories', {'name': 'Bakım Onarım', 'type': 'expense'});
    await db.insert('categories', {'name': 'Yemek/Kumanya', 'type': 'expense'});
  }

  Future<CategoryModel> createCategory(CategoryModel category) async {
    final db = await instance.database;
    final id = await db.insert('categories', category.toMap());
    category.id = id;
    return category;
  }

  Future<List<CategoryModel>> readAllCategories() async {
    final db = await instance.database;
    final result = await db.query('categories');
    return result.map((json) => CategoryModel.fromMap(json)).toList();
  }

  Future<int> deleteCategory(int id) async {
    final db = await instance.database;
    return await db.delete('categories', where: 'id = ?', whereArgs: [id]);
  }

  Future<TransactionModel> createTransaction(TransactionModel transaction) async {
    final db = await instance.database;
    final id = await db.insert('transactions', transaction.toMap());
    transaction.id = id;
    return transaction;
  }

  Future<List<TransactionModel>> readAllTransactions() async {
    final db = await instance.database;
    final result = await db.query('transactions', orderBy: 'date DESC');
    return result.map((json) => TransactionModel.fromMap(json)).toList();
  }

  Future<int> deleteTransaction(int id) async {
    final db = await instance.database;
    return await db.delete('transactions', where: 'id = ?', whereArgs: [id]);
  }
}
