// lib/Data/basedato_helper.dart
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

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
      version: 2, // Incrementar versión para agregar tabla ventas
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
          'CREATE TABLE cultivos (id INTEGER PRIMARY KEY AUTOINCREMENT, nombre TEXT NOT NULL, tipoSuelo TEXT NOT NULL, area REAL NOT NULL, fechaSiembra TEXT NOT NULL, fechaCosecha TEXT, estado TEXT NOT NULL, notas TEXT, imagenUrl TEXT, tipoId INTEGER, categoriaId INTEGER, tipoRiego TEXT, cantidadCosechada REAL, ingresos REAL, egresos REAL, isRisk INTEGER DEFAULT 0, riskReason TEXT, riskType TEXT, riskDate TEXT)',
        );

        // Crear tabla de usuarios
        await db.execute('''
          CREATE TABLE usuarios (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            nombre TEXT NOT NULL,
            correo TEXT UNIQUE NOT NULL,
            passwordHash TEXT NOT NULL,
            resetToken TEXT,
            resetTokenExpiry INTEGER
          )
        ''');

        // Crear tabla de ventas
        await db.execute('''
          CREATE TABLE ventas (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            cultivoId INTEGER NOT NULL,
            cultivoNombre TEXT NOT NULL,
            cantidad REAL NOT NULL,
            unidad TEXT NOT NULL,
            precioUnitario REAL NOT NULL,
            total REAL NOT NULL,
            cliente TEXT NOT NULL,
            fecha TEXT NOT NULL,
            notas TEXT,
            FOREIGN KEY (cultivoId) REFERENCES cultivos (id) ON DELETE CASCADE
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          // Crear tabla de ventas si no existe
          await db.execute('''
            CREATE TABLE IF NOT EXISTS ventas (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              cultivoId INTEGER NOT NULL,
              cultivoNombre TEXT NOT NULL,
              cantidad REAL NOT NULL,
              unidad TEXT NOT NULL,
              precioUnitario REAL NOT NULL,
              total REAL NOT NULL,
              cliente TEXT NOT NULL,
              fecha TEXT NOT NULL,
              notas TEXT,
              FOREIGN KEY (cultivoId) REFERENCES cultivos (id) ON DELETE CASCADE
            )
          ''');
        }
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
          'CREATE TABLE IF NOT EXISTS cultivos'
          '(id INTEGER PRIMARY KEY AUTOINCREMENT, '
          'nombre TEXT NOT NULL, tipoSuelo TEXT NOT NULL,'
          'area REAL NOT NULL, fechaSiembra TEXT NOT NULL, '
          'fechaCosecha TEXT, estado TEXT NOT NULL, notas TEXT,'
          'imagenUrl TEXT, tipoId INTEGER, categoriaId INTEGER,'
          'tipoRiego TEXT, cantidadCosechada REAL, ingresos REAL, '
          'egresos REAL, isRisk INTEGER DEFAULT 0, riskReason TEXT, '
          'riskType TEXT, riskDate TEXT)',
        );

        // Crear tabla de usuarios si no existe
        await db.execute('''
          CREATE TABLE IF NOT EXISTS usuarios (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            nombre TEXT NOT NULL,
            correo TEXT UNIQUE NOT NULL,
            passwordHash TEXT NOT NULL,
            resetToken TEXT,
            resetTokenExpiry INTEGER
          )
        ''');

        // Crear tabla de ventas si no existe
        await db.execute('''
          CREATE TABLE IF NOT EXISTS ventas (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            cultivoId INTEGER NOT NULL,
            cultivoNombre TEXT NOT NULL,
            cantidad REAL NOT NULL,
            unidad TEXT NOT NULL,
            precioUnitario REAL NOT NULL,
            total REAL NOT NULL,
            cliente TEXT NOT NULL,
            fecha TEXT NOT NULL,
            notas TEXT,
            FOREIGN KEY (cultivoId) REFERENCES cultivos (id) ON DELETE CASCADE
          )
        ''');

        // Agregar columnas de riesgo si no existen
        final columns = await db.rawQuery('PRAGMA table_info(cultivos)');
        final columnNames = columns.map((c) => c['name'] as String).toList();

        if (!columnNames.contains('isRisk')) {
          await db.execute(
            'ALTER TABLE cultivos ADD COLUMN isRisk INTEGER DEFAULT 0',
          );
        }
        if (!columnNames.contains('riskReason')) {
          await db.execute('ALTER TABLE cultivos ADD COLUMN riskReason TEXT');
        }
        if (!columnNames.contains('riskType')) {
          await db.execute('ALTER TABLE cultivos ADD COLUMN riskType TEXT');
        }
        if (!columnNames.contains('riskDate')) {
          await db.execute('ALTER TABLE cultivos ADD COLUMN riskDate TEXT');
        }

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

  // ========== MÉTODOS DE VENTAS ==========

  // Insertar nueva venta
  Future<int> insertVenta(Map<String, Object?> ventaRow) async {
    final db = await openDataBase();
    return await db.insert(
      'ventas',
      ventaRow,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Obtener todas las ventas
  Future<List<Map<String, Object?>>> getAllVentas() async {
    final db = await openDataBase();
    return await db.query('ventas', orderBy: 'fecha DESC');
  }

  // Actualizar una venta
  Future<int> updateVenta(int id, Map<String, Object?> row) async {
    final db = await openDataBase();
    return await db.update('ventas', row, where: 'id = ?', whereArgs: [id]);
  }

  // Eliminar una venta
  Future<int> deleteVenta(int id) async {
    final db = await openDataBase();
    return await db.delete('ventas', where: 'id = ?', whereArgs: [id]);
  }

  // Obtener total de ventas
  Future<double> getTotalVentas() async {
    final db = await openDataBase();
    final result = await db.rawQuery('SELECT SUM(total) as total FROM ventas');
    return (result.first['total'] as num?)?.toDouble() ?? 0.0;
  }

  // Obtener ventas por cultivo
  Future<List<Map<String, Object?>>> getVentasPorCultivo(int cultivoId) async {
    final db = await openDataBase();
    return await db.query(
      'ventas',
      where: 'cultivoId = ?',
      whereArgs: [cultivoId],
      orderBy: 'fecha DESC',
    );
  }

  // Obtener ventas por rango de fechas
  Future<List<Map<String, Object?>>> getVentasPorFechas(
    String fechaInicio,
    String fechaFin,
  ) async {
    final db = await openDataBase();
    return await db.query(
      'ventas',
      where: 'fecha BETWEEN ? AND ?',
      whereArgs: [fechaInicio, fechaFin],
      orderBy: 'fecha DESC',
    );
  }

  // ========== MÉTODOS DE AUTENTICACIÓN ==========

  // Registrar un nuevo usuario
  Future<Map<String, dynamic>> registrarUsuario(
    String nombre,
    String correo,
    String password,
  ) async {
    final db = await openDataBase();

    // Verificar si el correo ya existe
    final existingUser = await db.query(
      'usuarios',
      where: 'correo = ?',
      whereArgs: [correo],
    );

    if (existingUser.isNotEmpty) {
      throw Exception('Ya existe un usuario con este correo');
    }

    // Crear hash de la contraseña
    final passwordHash = _hashPassword(password);

    // Insertar nuevo usuario
    final id = await db.insert('usuarios', {
      'nombre': nombre,
      'correo': correo,
      'passwordHash': passwordHash,
    });

    return {'id': id, 'nombre': nombre, 'correo': correo};
  }

  // Iniciar sesión
  Future<Map<String, dynamic>> iniciarSesion(
    String correo,
    String password,
  ) async {
    final db = await openDataBase();

    // Buscar usuario por correo
    final result = await db.query(
      'usuarios',
      where: 'correo = ?',
      whereArgs: [correo],
    );

    if (result.isEmpty) {
      throw Exception('Usuario o contraseña incorrectos');
    }

    final user = result.first;
    final storedHash = user['passwordHash'] as String;

    // Verificar contraseña
    if (!_verifyPassword(password, storedHash)) {
      throw Exception('Usuario o contraseña incorrectos');
    }

    return {
      'id': user['id'],
      'nombre': user['nombre'],
      'correo': user['correo'],
    };
  }

  // Generar token de recuperación
  Future<void> generarTokenRecuperacion(String correo) async {
    final db = await openDataBase();

    // Verificar si el correo existe
    final result = await db.query(
      'usuarios',
      where: 'correo = ?',
      whereArgs: [correo],
    );

    if (result.isEmpty) {
      // No revelamos que el correo no existe por seguridad
      return;
    }

    // Generar token de 6 dígitos
    final token = (100000 + DateTime.now().millisecondsSinceEpoch % 900000)
        .toString()
        .substring(0, 6);
    final expiryTime = DateTime.now()
        .add(const Duration(hours: 1))
        .millisecondsSinceEpoch;

    // Actualizar usuario con token y tiempo de expiración
    await db.update(
      'usuarios',
      {'resetToken': token, 'resetTokenExpiry': expiryTime},
      where: 'correo = ?',
      whereArgs: [correo],
    );

    // Enviar correo con el token (implementación simulada)
    print('Token de recuperación para $correo: $token');
  }

  // Verificar token de recuperación
  Future<bool> verificarTokenRecuperacion(String correo, String token) async {
    final db = await openDataBase();

    final result = await db.query(
      'usuarios',
      columns: ['resetToken', 'resetTokenExpiry'],
      where: 'correo = ?',
      whereArgs: [correo],
    );

    if (result.isEmpty) return false;

    final storedToken = result.first['resetToken'] as String?;
    final expiryTime = result.first['resetTokenExpiry'] as int?;

    if (storedToken == null || expiryTime == null) return false;

    // Verificar si el token coincide y no ha expirado
    return storedToken == token &&
        DateTime.now().millisecondsSinceEpoch < expiryTime;
  }

  // Actualizar contraseña
  Future<void> actualizarContrasena(String correo, String nuevaPassword) async {
    final db = await openDataBase();

    // Generar nuevo hash
    final newHash = _hashPassword(nuevaPassword);

    // Actualizar contraseña y limpiar token
    await db.update(
      'usuarios',
      {'passwordHash': newHash, 'resetToken': null, 'resetTokenExpiry': null},
      where: 'correo = ?',
      whereArgs: [correo],
    );
  }

  // Métodos auxiliares para el manejo de contraseñas
  String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  bool _verifyPassword(String password, String storedHash) {
    return _hashPassword(password) == storedHash;
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
