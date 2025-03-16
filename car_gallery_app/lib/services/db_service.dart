import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/car.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  static Database? _database;

  factory DatabaseService() {
    return _instance;
  }

  DatabaseService._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'car_gallery.db');

    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE cars(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        brand TEXT NOT NULL,
        model TEXT NOT NULL,
        year INTEGER NOT NULL,
        color TEXT NOT NULL,
        price REAL NOT NULL,
        imageUrl TEXT NOT NULL
      )
    ''');
  }

  // Araba ekle
  Future<int> insertCar(Car car) async {
    Database db = await database;
    return await db.insert('cars', car.toMap());
  }

  // Tüm arabaları getir
  Future<List<Car>> getCars() async {
    Database db = await database;
    List<Map<String, dynamic>> maps = await db.query('cars');

    return List.generate(maps.length, (i) {
      return Car.fromMap(maps[i]);
    });
  }

  // Araba güncelle
  Future<int> updateCar(Car car) async {
    Database db = await database;
    return await db.update(
      'cars',
      car.toMap(),
      where: 'id = ?',
      whereArgs: [car.id],
    );
  }

  // Araba sil
  Future<int> deleteCar(int id) async {
    Database db = await database;
    return await db.delete('cars', where: 'id = ?', whereArgs: [id]);
  }

  // ID'ye göre araba getir
  Future<Car?> getCarById(int id) async {
    Database db = await database;
    List<Map<String, dynamic>> maps = await db.query(
      'cars',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return Car.fromMap(maps.first);
    }
    return null;
  }
}
