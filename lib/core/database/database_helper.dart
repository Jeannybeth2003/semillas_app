import 'dart:async';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  // Cantidad de semillas con la que arranca cada jugador nuevo.
  static const Map<String, int> valoresInicialesSemillas = {
    'cacao': 2,
    'maiz': 3,
    'melon': 5,
    'patilla': 3,
    'platano': 4,
    'yuca': 4,
  };

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('semillas.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getApplicationDocumentsDirectory();
    final path = join(dbPath.path, filePath);

    return await openDatabase(
      path,
      version: 3,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
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

    await db.execute('''
      CREATE TABLE conuco (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        coordenadas TEXT NOT NULL,
        cultivo TEXT NOT NULL,
        etapa TEXT NOT NULL,
        cantidad INTEGER NOT NULL DEFAULT 1
      )
    ''');

    await db.execute('''
      CREATE TABLE inventario_semillas (
        cultivo TEXT PRIMARY KEY,
        cantidad INTEGER NOT NULL DEFAULT 0
      )
    ''');
  }

  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute(
        'ALTER TABLE conuco ADD COLUMN cantidad INTEGER NOT NULL DEFAULT 1',
      );
    }
    if (oldVersion < 3) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS inventario_semillas (
          cultivo TEXT PRIMARY KEY,
          cantidad INTEGER NOT NULL DEFAULT 0
        )
      ''');
    }
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

  // --- Métodos para la tabla 'conuco' (Motor del Conuco) ---

  // 1. Obtener el estado actual de todas las parcelas plantadas
  Future<List<Map<String, dynamic>>> obtenerConucos() async {
    final db = await instance.database;
    return await db.query('conuco');
  }

  // 2. Guardar un nuevo progreso cuando se siembra una semilla
  Future<int> sembrarCultivo(
    String coordenadas,
    String cultivo,
    String etapa,
    int cantidad,
  ) async {
    final db = await instance.database;
    return await db.insert('conuco', {
      'coordenadas': coordenadas,
      'cultivo': cultivo,
      'etapa': etapa,
      'cantidad': cantidad,
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
    return await db.delete('conuco', where: 'id = ?', whereArgs: [id]);
  }

  // --- Métodos para la tabla 'inventario_semillas' (semillas sin sembrar) ---

  // Siembra los valores iniciales de cada cultivo la primera vez que se
  // necesitan. Usa 'ignore' para no pisar el progreso del jugador: si ya
  // existe una fila para ese cultivo (porque sembró, intercambió, etc.),
  // no se toca.
  Future<void> inicializarInventarioSemillas() async {
    final db = await instance.database;
    final batch = db.batch();
    valoresInicialesSemillas.forEach((cultivo, cantidad) {
      batch.insert('inventario_semillas', {
        'cultivo': cultivo,
        'cantidad': cantidad,
      }, conflictAlgorithm: ConflictAlgorithm.ignore);
    });
    await batch.commit(noResult: true);
  }

  // Obtener todo el inventario de semillas del jugador
  Future<List<Map<String, dynamic>>> obtenerInventarioSemillas() async {
    final db = await instance.database;
    return await db.query('inventario_semillas');
  }

  // Obtener la cantidad disponible de una semilla específica
  Future<int> obtenerCantidadSemilla(String cultivo) async {
    final db = await instance.database;
    final result = await db.query(
      'inventario_semillas',
      where: 'cultivo = ?',
      whereArgs: [cultivo],
    );
    if (result.isEmpty) return 0;
    return result.first['cantidad'] as int;
  }

  // Sumar semillas al inventario (ej. al comprar, cosechar o recibir en un intercambio)
  Future<void> agregarSemillas(String cultivo, int cantidad) async {
    final db = await instance.database;
    final actual = await obtenerCantidadSemilla(cultivo);
    await db.insert('inventario_semillas', {
      'cultivo': cultivo,
      'cantidad': actual + cantidad,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  // Restar semillas del inventario (ej. al sembrar). Devuelve false si no hay suficientes.
  Future<bool> restarSemillas(String cultivo, int cantidad) async {
    final db = await instance.database;
    final actual = await obtenerCantidadSemilla(cultivo);
    if (actual < cantidad) return false;
    await db.insert('inventario_semillas', {
      'cultivo': cultivo,
      'cantidad': actual - cantidad,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
    return true;
  }

  // Intercambio atómico 1x1: doy una unidad de [semillaQueDoy] y recibo
  // una unidad de [semillaQueRecibo]. Devuelve false si no tenías la semilla que ofrecías.
  Future<bool> intercambiarSemilla({
    required String semillaQueDoy,
    required String semillaQueRecibo,
  }) async {
    final db = await instance.database;
    return await db.transaction<bool>((txn) async {
      final result = await txn.query(
        'inventario_semillas',
        where: 'cultivo = ?',
        whereArgs: [semillaQueDoy],
      );
      final actual = result.isEmpty ? 0 : result.first['cantidad'] as int;
      if (actual < 1) return false;

      await txn.insert('inventario_semillas', {
        'cultivo': semillaQueDoy,
        'cantidad': actual - 1,
      }, conflictAlgorithm: ConflictAlgorithm.replace);

      final resultRecibo = await txn.query(
        'inventario_semillas',
        where: 'cultivo = ?',
        whereArgs: [semillaQueRecibo],
      );
      final actualRecibo =
          resultRecibo.isEmpty ? 0 : resultRecibo.first['cantidad'] as int;

      await txn.insert('inventario_semillas', {
        'cultivo': semillaQueRecibo,
        'cantidad': actualRecibo + 1,
      }, conflictAlgorithm: ConflictAlgorithm.replace);

      return true;
    });
  }
}
