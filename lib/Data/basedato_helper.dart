import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class BasedatoHelper {
  BasedatoHelper._privateConstructor();
  static final BasedatoHelper instance = BasedatoHelper._privateConstructor();

  Database? _database;

  Future<Database> openDataBase() async {
    if (_database != null) return _database!;

    final databasePath = await getDatabasesPath();
    final path = join(databasePath, 'mydatabase.db');

    _database = await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute(
          'CREATE TABLE mitabla (id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT)',
        );

        await db.execute(
          'CREATE TABLE tipos_cultivo (id INTEGER PRIMARY KEY AUTOINCREMENT, nombre TEXT NOT NULL)',
        );

        await db.execute(
          'CREATE TABLE categorias (id INTEGER PRIMARY KEY AUTOINCREMENT, nombre TEXT NOT NULL)',
        );

        await db.execute(
          'CREATE TABLE cultivos (id INTEGER PRIMARY KEY AUTOINCREMENT, nombre TEXT NOT NULL, tipoSuelo TEXT NOT NULL, area REAL NOT NULL, fechaSiembra TEXT NOT NULL, fechaCosecha TEXT, estado TEXT NOT NULL, notas TEXT, imagenUrl TEXT, tipoId INTEGER, categoriaId INTEGER, tipoRiego TEXT, cantidadCosechada REAL, ingresos REAL, egresos REAL)',
        );
      },
      onOpen: (db) async {
        // Ensure the tables exist if the DB was created earlier without them
        await db.execute(
          'CREATE TABLE IF NOT EXISTS tipos_cultivo (id INTEGER PRIMARY KEY AUTOINCREMENT, nombre TEXT NOT NULL)',
        );
        await db.execute(
          'CREATE TABLE IF NOT EXISTS categorias (id INTEGER PRIMARY KEY AUTOINCREMENT, nombre TEXT NOT NULL)',
        );
        await db.execute(
          'CREATE TABLE IF NOT EXISTS cultivos (id INTEGER PRIMARY KEY AUTOINCREMENT, nombre TEXT NOT NULL, tipoSuelo TEXT NOT NULL, area REAL NOT NULL, fechaSiembra TEXT NOT NULL, fechaCosecha TEXT, estado TEXT NOT NULL, notas TEXT, imagenUrl TEXT, tipoId INTEGER, categoriaId INTEGER, tipoRiego TEXT, cantidadCosechada REAL, ingresos REAL, egresos REAL)',
        );

        // Agregar columnas si no existen (migración)
        try {
          await db.execute(
            'ALTER TABLE cultivos ADD COLUMN cantidadCosechada REAL',
          );
        } catch (e) {
          // Columna ya existe
        }
        try {
          await db.execute('ALTER TABLE cultivos ADD COLUMN ingresos REAL');
        } catch (e) {
          // Columna ya existe
        }
        try {
          await db.execute('ALTER TABLE cultivos ADD COLUMN egresos REAL');
        } catch (e) {
          // Columna ya existe
        }
      },
    );

    return _database!;
  }

  Future<int> addData(Map<String, Object?> row) async {
    final db = await openDataBase();
    return await db.insert(
      'mitabla',
      row,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // --- Cultivo specific methods ---
  Future<int> insertCultivo(Map<String, Object?> cultivoRow) async {
    final db = await openDataBase();
    return await db.insert(
      'cultivos',
      cultivoRow,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Map<String, Object?>>> getAllCultivos() async {
    final db = await openDataBase();
    return await db.query('cultivos');
  }

  Future<int> updateCultivo(int id, Map<String, Object?> row) async {
    final db = await openDataBase();
    return await db.update('cultivos', row, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> updateEstado(int id, String nuevoEstado) async {
    final db = await openDataBase();
    return await db.update(
      'cultivos',
      {'estado': nuevoEstado},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteCultivo(int id) async {
    final db = await openDataBase();
    return await db.delete('cultivos', where: 'id = ?', whereArgs: [id]);
  }

  // --- TipoCultivo methods ---
  Future<int> insertTipoCultivo(Map<String, Object?> row) async {
    final db = await openDataBase();
    return await db.insert(
      'tipos_cultivo',
      row,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Map<String, Object?>>> getAllTiposCultivo() async {
    final db = await openDataBase();
    return await db.query('tipos_cultivo');
  }

  Future<int> deleteTipoCultivo(int id) async {
    final db = await openDataBase();
    return await db.delete('tipos_cultivo', where: 'id = ?', whereArgs: [id]);
  }

  // --- Categoria methods ---
  Future<int> insertCategoria(Map<String, Object?> row) async {
    final db = await openDataBase();
    return await db.insert(
      'categorias',
      row,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Map<String, Object?>>> getAllCategorias() async {
    final db = await openDataBase();
    return await db.query('categorias');
  }

  Future<int> deleteCategoria(int id) async {
    final db = await openDataBase();
    return await db.delete('categorias', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Map<String, Object?>>> getAllData() async {
    final db = await openDataBase();
    return await db.query('mitabla');
  }

  Future<int> deleteById(int id) async {
    final db = await openDataBase();
    return await db.delete('mitabla', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }
}
