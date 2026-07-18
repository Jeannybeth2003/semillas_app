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

  Future _createDB(Database db, int version) async {
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
      CREATE TABLE descubiertos (
        id INTEGER PRIMARY KEY
      )
    ''');

    await db.execute('''
      CREATE TABLE conuco (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        coordenadas TEXT NOT NULL,
        cultivo TEXT NOT NULL,
        etapa TEXT NOT NULL
      )
    ''');
  }

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

  Future<int> guardarCuentoLeido(int idCuento, int nivel) async {
    final db = await database;
    return await db.insert(
      'cuentos_leidos',
      {
        'id_cuento': idCuento,
        'nivel': nivel,
      },
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  Future<List<int>> obtenerCuentosLeidosPorNivel(int nivel) async {
    final db = await database;
    // Filtramos directamente por el nivel en el que se encuentra el jugador
    final List<Map<String, dynamic>> maps = await db.query(
      'cuentos_leidos',
      where: 'nivel = ?',
      whereArgs: [nivel],
    );
    
    return List.generate(maps.length, (i) => maps[i]['id_cuento'] as int);
  Future<List<int>> getDescubiertos() async {
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

  // --- Métodos para la tabla 'conuco' (Motor del Conuco) ---

  // 1. Obtener el estado actual de todas las parcelas plantadas
  Future<List<Map<String, dynamic>>> obtenerConucos() async {
    final db = await instance.database;
    return await db.query('conuco');
  }

  // 2. Guardar un nuevo progreso cuando se siembra una semilla
  Future<int> sembrarCultivo(String coordenadas, String cultivo, String etapa) async {
    final db = await instance.database;
    return await db.insert('conuco', {
      'coordenadas': coordenadas,
      'cultivo': cultivo,
      'etapa': etapa,
    });
  }

  // 3. Actualizar la etapa por el temporizador (ej. pasar de 'semilla' a 'crecimiento' o 'cosecha')
  Future<int> actualizarEtapaCultivo(int id, String nuevaEtapa) async {
    final db = await instance.database;
    return await db.update(
      'conuco',
      {'etapa': nuevaEtapa},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // 4. (Opcional) Eliminar el cultivo si el usuario lo cosecha o la planta muere
  Future<int> eliminarCultivo(int id) async {
    final db = await instance.database;
    return await db.delete(
      'conuco',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
