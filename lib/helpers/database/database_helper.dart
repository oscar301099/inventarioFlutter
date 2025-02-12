import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'dart:typed_data';
import 'dart:convert';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  factory DatabaseHelper() => instance;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('practica_inventario.db');
    return _database!;
  }

  Future<Database> _initDB(String fileName) async {
    final dbPath = await getDatabasesPath(); 
    final path = join(dbPath, fileName); 

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

Future _createDB(Database db, int version) async {
  await db.execute('''
    CREATE TABLE product (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL,
      description TEXT,
      stock INTEGER NOT NULL,
      imagePath TEXT -- Campo para almacenar la ruta de la imagen
    )
  ''');
}

Future<int> insertProduct(Map<String, dynamic> product) async {
  final db = await database;
  return await db.insert('product', product);
}
  Future<List<Map<String, dynamic>>> fetchProducts() async {
    final db = await database;
    return await db.query('product', orderBy: 'id');
  }
  Future<int> updateProduct(String id, Map<String, dynamic> product) async {
    final db = await database;
    return await db.update(
      'product',
      product,
      where: 'id = ?',
      whereArgs: [id],
    );
  }
  Future<int> deleteProduct(String id) async {
    final db = await database;
    return await db.delete(
      'product',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
  String imageToBase64(Uint8List imageBytes) {
    return base64Encode(imageBytes);
  }
  Uint8List base64ToImage(String base64String) {
    return base64Decode(base64String);
  }
}
