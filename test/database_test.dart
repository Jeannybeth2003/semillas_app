import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:semillas_app/core/database/database_helper.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class MockPathProviderPlatform extends Fake
    with MockPlatformInterfaceMixin
    implements PathProviderPlatform {
  @override
  Future<String?> getApplicationDocumentsPath() async {
    return '.';
  }
}

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    PathProviderPlatform.instance = MockPathProviderPlatform();
  });

  test('Prueba de creación e inserción en la tabla conuco', () async {
    final dbHelper = DatabaseHelper.instance;
    final db = await dbHelper.database;

    // Limpiar tabla por si quedó sucia de una prueba anterior
    await db.delete('conuco');

    // Limpiar tabla por si quedó sucia de una prueba anterior
    await db.delete('conuco');

    // 1. Probar sembrarCultivo
    final id = await dbHelper.sembrarCultivo(
      '10.0, -60.5',
      'Maíz',
      'semilla',
      1,
    );
    expect(id, isNotNull);

    // 2. Probar obtenerConucos
    var resultados = await dbHelper.obtenerConucos();
    expect(resultados.length, 1);
    expect(resultados.first['cultivo'], 'Maíz');
    expect(resultados.first['etapa'], 'semilla');

    // 3. Probar actualizarEtapaCultivo
    await dbHelper.actualizarEtapaCultivo(id, 'cosecha');
    resultados = await dbHelper.obtenerConucos();
    expect(resultados.first['etapa'], 'cosecha');

    // 4. Probar eliminarCultivo
    await dbHelper.eliminarCultivo(id);
    resultados = await dbHelper.obtenerConucos();
    expect(resultados.length, 0);

    // Clean up
    await db.close();
    final file = File('./semillas.db');
    if (file.existsSync()) {
      file.deleteSync();
    }
  });
}
