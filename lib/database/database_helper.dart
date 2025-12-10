import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/pokemon.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('pokedex.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 2,
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );
  }

  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      const idType = 'INTEGER PRIMARY KEY';
      const textType = 'TEXT NOT NULL';
      const integerType = 'INTEGER NOT NULL';

      await db.execute('''
        CREATE TABLE team (
          id $idType,
          name $textType,
          imageUrl $textType,
          height $integerType,
          weight $integerType,
          types $textType,
          abilities $textType,
          stats $textType,
          position $integerType
        )
      ''');
    }
  }

  Future _createDB(Database db, int version) async {
    const idType = 'INTEGER PRIMARY KEY';
    const textType = 'TEXT NOT NULL';
    const integerType = 'INTEGER NOT NULL';

    await db.execute('''
      CREATE TABLE favorites (
        id $idType,
        name $textType,
        imageUrl $textType,
        height $integerType,
        weight $integerType,
        types $textType,
        abilities $textType,
        stats $textType,
        isFavorite $integerType
      )
    ''');

    await db.execute('''
      CREATE TABLE team (
        id $idType,
        name $textType,
        imageUrl $textType,
        height $integerType,
        weight $integerType,
        types $textType,
        abilities $textType,
        stats $textType,
        position $integerType
      )
    ''');
  }

  // CREATE - Agregar pokemon a favoritos
  Future<int> addFavorite(Pokemon pokemon) async {
    final db = await database;
    return await db.insert(
      'favorites',
      pokemon.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // READ - Obtener todos los favoritos
  Future<List<Pokemon>> getAllFavorites() async {
    final db = await database;
    final result = await db.query('favorites', orderBy: 'id ASC');
    return result.map((json) => Pokemon.fromMap(json)).toList();
  }

  // READ - Obtener un favorito por ID
  Future<Pokemon?> getFavoriteById(int id) async {
    final db = await database;
    final result = await db.query(
      'favorites',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (result.isNotEmpty) {
      return Pokemon.fromMap(result.first);
    }
    return null;
  }

  // READ - Verificar si un pokemon está en favoritos
  Future<bool> isFavorite(int id) async {
    final db = await database;
    final result = await db.query(
      'favorites',
      where: 'id = ?',
      whereArgs: [id],
    );
    return result.isNotEmpty;
  }

  // UPDATE - Actualizar un favorito
  Future<int> updateFavorite(Pokemon pokemon) async {
    final db = await database;
    return await db.update(
      'favorites',
      pokemon.toMap(),
      where: 'id = ?',
      whereArgs: [pokemon.id],
    );
  }

  // DELETE - Eliminar un favorito
  Future<int> deleteFavorite(int id) async {
    final db = await database;
    return await db.delete('favorites', where: 'id = ?', whereArgs: [id]);
  }

  // DELETE - Eliminar todos los favoritos
  Future<int> deleteAllFavorites() async {
    final db = await database;
    return await db.delete('favorites');
  }

  // Obtener conteo de favoritos
  Future<int> getFavoritesCount() async {
    final db = await database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM favorites');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  // ============== CRUD EQUIPO POKEMON ==============

  // CREATE - Agregar pokemon al equipo (máximo 6)
  Future<bool> addToTeam(Pokemon pokemon) async {
    final db = await database;
    final count = await getTeamCount();

    if (count >= 6) {
      return false; // Equipo lleno
    }

    // Verificar si ya está en el equipo
    if (await isInTeam(pokemon.id)) {
      return false; // Ya está en el equipo
    }

    final teamMap = pokemon.toMap();
    teamMap['position'] = count + 1;
    teamMap.remove('isFavorite');

    await db.insert(
      'team',
      teamMap,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    return true;
  }

  // READ - Obtener todos los pokemones del equipo
  Future<List<Pokemon>> getTeam() async {
    final db = await database;
    final result = await db.query('team', orderBy: 'position ASC');
    return result.map((json) => Pokemon.fromMap(json)).toList();
  }

  // READ - Verificar si un pokemon está en el equipo
  Future<bool> isInTeam(int id) async {
    final db = await database;
    final result = await db.query('team', where: 'id = ?', whereArgs: [id]);
    return result.isNotEmpty;
  }

  // READ - Obtener conteo del equipo
  Future<int> getTeamCount() async {
    final db = await database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM team');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  // UPDATE - Actualizar posición de un pokemon en el equipo
  Future<int> updateTeamPosition(int id, int newPosition) async {
    final db = await database;
    return await db.update(
      'team',
      {'position': newPosition},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // DELETE - Eliminar un pokemon del equipo
  Future<int> removeFromTeam(int id) async {
    final db = await database;
    final result = await db.delete('team', where: 'id = ?', whereArgs: [id]);

    // Reordenar posiciones
    final team = await getTeam();
    for (int i = 0; i < team.length; i++) {
      await updateTeamPosition(team[i].id, i + 1);
    }

    return result;
  }

  // DELETE - Eliminar todo el equipo
  Future<int> clearTeam() async {
    final db = await database;
    return await db.delete('team');
  }

  // Cerrar base de datos
  Future close() async {
    final db = await database;
    db.close();
  }
}
