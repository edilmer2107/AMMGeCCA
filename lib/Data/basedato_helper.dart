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
      version: 3, // 🔥 Incrementar versión para agregar tablas de chat
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

        // 🆕 TABLAS DE CHAT
        await db.execute('''
          CREATE TABLE conversaciones (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            titulo TEXT NOT NULL,
            fechaCreacion TEXT NOT NULL,
            ultimaActualizacion TEXT NOT NULL,
            mensajesCount INTEGER DEFAULT 0
          )
        ''');

        await db.execute('''
          CREATE TABLE mensajes (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            conversacionId INTEGER NOT NULL,
            tipo TEXT NOT NULL,
            contenido TEXT NOT NULL,
            fecha TEXT NOT NULL,
            archivoPath TEXT,
            archivoNombre TEXT,
            archivoTipo TEXT,
            FOREIGN KEY (conversacionId) REFERENCES conversaciones (id) ON DELETE CASCADE
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
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

        if (oldVersion < 3) {
          // 🆕 Crear tablas de chat
          await db.execute('''
            CREATE TABLE IF NOT EXISTS conversaciones (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              titulo TEXT NOT NULL,
              fechaCreacion TEXT NOT NULL,
              ultimaActualizacion TEXT NOT NULL,
              mensajesCount INTEGER DEFAULT 0
            )
          ''');

          await db.execute('''
            CREATE TABLE IF NOT EXISTS mensajes (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              conversacionId INTEGER NOT NULL,
              tipo TEXT NOT NULL,
              contenido TEXT NOT NULL,
              fecha TEXT NOT NULL,
              archivoPath TEXT,
              archivoNombre TEXT,
              archivoTipo TEXT,
              FOREIGN KEY (conversacionId) REFERENCES conversaciones (id) ON DELETE CASCADE
            )
          ''');
        }
      },
      onOpen: (db) async {
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

        // 🆕 Crear tablas de chat si no existen
        await db.execute('''
          CREATE TABLE IF NOT EXISTS conversaciones (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            titulo TEXT NOT NULL,
            fechaCreacion TEXT NOT NULL,
            ultimaActualizacion TEXT NOT NULL,
            mensajesCount INTEGER DEFAULT 0
          )
        ''');

        await db.execute('''
          CREATE TABLE IF NOT EXISTS mensajes (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            conversacionId INTEGER NOT NULL,
            tipo TEXT NOT NULL,
            contenido TEXT NOT NULL,
            fecha TEXT NOT NULL,
            archivoPath TEXT,
            archivoNombre TEXT,
            archivoTipo TEXT,
            FOREIGN KEY (conversacionId) REFERENCES conversaciones (id) ON DELETE CASCADE
          )
        ''');

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

        try {
          await db.execute(
            'ALTER TABLE cultivos ADD COLUMN cantidadCosechada REAL',
          );
        } catch (e) {}
        try {
          await db.execute('ALTER TABLE cultivos ADD COLUMN ingresos REAL');
        } catch (e) {}
        try {
          await db.execute('ALTER TABLE cultivos ADD COLUMN egresos REAL');
        } catch (e) {}
      },
    );

    return _database!;
  }

  // ========== 🆕 MÉTODOS DE CONVERSACIONES ==========

  Future<int> crearConversacion(String titulo) async {
    final db = await openDataBase();
    final now = DateTime.now().toIso8601String();

    return await db.insert('conversaciones', {
      'titulo': titulo,
      'fechaCreacion': now,
      'ultimaActualizacion': now,
      'mensajesCount': 0,
    });
  }

  Future<List<Map<String, Object?>>> getAllConversaciones() async {
    final db = await openDataBase();
    return await db.query(
      'conversaciones',
      orderBy: 'ultimaActualizacion DESC',
    );
  }

  Future<int> actualizarTituloConversacion(int id, String nuevoTitulo) async {
    final db = await openDataBase();
    return await db.update(
      'conversaciones',
      {
        'titulo': nuevoTitulo,
        'ultimaActualizacion': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> eliminarConversacion(int id) async {
    final db = await openDataBase();
    return await db.delete('conversaciones', where: 'id = ?', whereArgs: [id]);
  }

  // ========== 🆕 MÉTODOS DE MENSAJES ==========

  Future<int> insertarMensaje(Map<String, Object?> mensaje) async {
    final db = await openDataBase();

    final conversacionId = mensaje['conversacionId'] as int;

    final mensajeId = await db.insert('mensajes', mensaje);

    await db.rawUpdate(
      '''
      UPDATE conversaciones 
      SET mensajesCount = mensajesCount + 1,
          ultimaActualizacion = ?
      WHERE id = ?
    ''',
      [DateTime.now().toIso8601String(), conversacionId],
    );

    return mensajeId;
  }

  Future<List<Map<String, Object?>>> getMensajes(int conversacionId) async {
    final db = await openDataBase();
    return await db.query(
      'mensajes',
      where: 'conversacionId = ?',
      whereArgs: [conversacionId],
      orderBy: 'fecha ASC',
    );
  }

  Future<Map<String, Object?>?> getUltimoMensaje(int conversacionId) async {
    final db = await openDataBase();
    final result = await db.query(
      'mensajes',
      where: 'conversacionId = ?',
      whereArgs: [conversacionId],
      orderBy: 'fecha DESC',
      limit: 1,
    );

    return result.isNotEmpty ? result.first : null;
  }

  // ========== MÉTODOS EXISTENTES ==========

  Future<int> addData(Map<String, Object?> row) async {
    final db = await openDataBase();
    return await db.insert(
      'mitabla',
      row,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

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

  Future<int> insertVenta(Map<String, Object?> ventaRow) async {
    final db = await openDataBase();
    return await db.insert(
      'ventas',
      ventaRow,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Map<String, Object?>>> getAllVentas() async {
    final db = await openDataBase();
    return await db.query('ventas', orderBy: 'fecha DESC');
  }

  Future<int> updateVenta(int id, Map<String, Object?> row) async {
    final db = await openDataBase();
    return await db.update('ventas', row, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deleteVenta(int id) async {
    final db = await openDataBase();
    return await db.delete('ventas', where: 'id = ?', whereArgs: [id]);
  }

  Future<double> getTotalVentas() async {
    final db = await openDataBase();
    final result = await db.rawQuery('SELECT SUM(total) as total FROM ventas');
    return (result.first['total'] as num?)?.toDouble() ?? 0.0;
  }

  Future<List<Map<String, Object?>>> getVentasPorCultivo(int cultivoId) async {
    final db = await openDataBase();
    return await db.query(
      'ventas',
      where: 'cultivoId = ?',
      whereArgs: [cultivoId],
      orderBy: 'fecha DESC',
    );
  }

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

  Future<Map<String, dynamic>> registrarUsuario(
    String nombre,
    String correo,
    String password,
  ) async {
    final db = await openDataBase();

    final existingUser = await db.query(
      'usuarios',
      where: 'correo = ?',
      whereArgs: [correo],
    );

    if (existingUser.isNotEmpty) {
      throw Exception('Ya existe un usuario con este correo');
    }

    final passwordHash = _hashPassword(password);

    final id = await db.insert('usuarios', {
      'nombre': nombre,
      'correo': correo,
      'passwordHash': passwordHash,
    });

    return {'id': id, 'nombre': nombre, 'correo': correo};
  }

  Future<Map<String, dynamic>> iniciarSesion(
    String correo,
    String password,
  ) async {
    final db = await openDataBase();

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

    if (!_verifyPassword(password, storedHash)) {
      throw Exception('Usuario o contraseña incorrectos');
    }

    return {
      'id': user['id'],
      'nombre': user['nombre'],
      'correo': user['correo'],
    };
  }

  Future<void> generarTokenRecuperacion(String correo) async {
    final db = await openDataBase();

    final result = await db.query(
      'usuarios',
      where: 'correo = ?',
      whereArgs: [correo],
    );

    if (result.isEmpty) return;

    final token = (100000 + DateTime.now().millisecondsSinceEpoch % 900000)
        .toString()
        .substring(0, 6);
    final expiryTime = DateTime.now()
        .add(const Duration(hours: 1))
        .millisecondsSinceEpoch;

    await db.update(
      'usuarios',
      {'resetToken': token, 'resetTokenExpiry': expiryTime},
      where: 'correo = ?',
      whereArgs: [correo],
    );

    print('Token de recuperación para $correo: $token');
  }

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

    return storedToken == token &&
        DateTime.now().millisecondsSinceEpoch < expiryTime;
  }

  Future<void> actualizarContrasena(String correo, String nuevaPassword) async {
    final db = await openDataBase();

    final newHash = _hashPassword(nuevaPassword);

    await db.update(
      'usuarios',
      {'passwordHash': newHash, 'resetToken': null, 'resetTokenExpiry': null},
      where: 'correo = ?',
      whereArgs: [correo],
    );
  }

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
