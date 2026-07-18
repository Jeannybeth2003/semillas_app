import 'dart:async';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('semillas.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getApplicationDocumentsDirectory();
    final path = join(dbPath.path, filePath);

    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE lider (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nombre TEXT NOT NULL,
        aldea TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE cuentos_leidos (
        id_cuento INTEGER,
        nivel INTEGER,
        PRIMARY KEY (id_cuento, nivel)
      )
    ''');

    await db.execute('''
      CREATE TABLE descubiertos (
        id INTEGER PRIMARY KEY
      )
    ''');
  }

  // Métodos para Lider
  Future<int> crearNuevoLider(String nombre, String aldea) async {
    final db = await instance.database;
    // Eliminamos cualquier líder previo para mantener un único registro de usuario/líder
    await db.delete('lider');
    return await db.insert('lider', {'nombre': nombre, 'aldea': aldea});
  }

  Future<Map<String, dynamic>?> verificarLiderExistente() async {
    final db = await instance.database;
    final result = await db.query('lider', limit: 1);
    if (result.isNotEmpty) {
      return result.first;
    }
    return null;
  }

  // Métodos para Cuentos Leidos
  Future<int> guardarCuentoLeido(int idCuento, int nivel) async {
    final db = await database;
    return await db.insert('cuentos_leidos', {
      'id_cuento': idCuento,
      'nivel': nivel,
    }, conflictAlgorithm: ConflictAlgorithm.ignore);
  }

  Future<List<int>> obtenerCuentosLeidosPorNivel(int nivel) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'cuentos_leidos',
      where: 'nivel = ?',
      whereArgs: [nivel],
    );

    return List.generate(maps.length, (i) => maps[i]['id_cuento'] as int);
  }

  // Métodos para Descubiertos
  Future<List<int>> obtenerDescubiertos() async {
    final db = await instance.database;
    final res = await db.query('descubiertos');
    return res.map((row) => row['id'] as int).toList();
  }

  Future<void> descubrirElemento(int id) async {
    final db = await instance.database;
    await db.insert('descubiertos', {
      'id': id,
    }, conflictAlgorithm: ConflictAlgorithm.ignore);
  }
}
