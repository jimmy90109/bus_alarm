import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../model/place.dart';

const String favTable = "favPlaces";
const String hisTable = "hisPlaces";
const String searchTable = "searchPlaces";

class PlacesDatabase {
  static final PlacesDatabase instance = PlacesDatabase._init();
  static Database? _database;
  PlacesDatabase._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('places.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);
    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future _createDB(Database db, int version) async {
    const idType = 'TEXT PRIMARY KEY';
    const textType = 'TEXT NOT NULL';
    const realType = 'REAL NOT NULL';
    // const boolType = 'BOOLEAN NOT NULL';
    // const integerType = 'INTEGER NOT NULL';

    await db.execute('''
CREATE TABLE IF NOT EXISTS $favTable ( 
  ${PlaceFields.id} $idType, 
  ${PlaceFields.name} $textType,
  ${PlaceFields.lat} $realType,
  ${PlaceFields.lng} $realType
  )
''');

    await db.execute('''
CREATE TABLE IF NOT EXISTS $hisTable ( 
  ${PlaceFields.id} $idType, 
  ${PlaceFields.name} $textType,
  ${PlaceFields.lat} $realType,
  ${PlaceFields.lng} $realType
  )
''');

    await db.execute('''
CREATE TABLE IF NOT EXISTS $searchTable ( 
  ${PlaceFields.id} $idType, 
  ${PlaceFields.name} $textType,
  ${PlaceFields.lat} $realType,
  ${PlaceFields.lng} $realType
  )
''');
  }

  Future create(String table, Place place) async {
    final db = await instance.database;

    // final json = place.toJson();
    // final columns =
    //     '${PlaceFields.title}, ${PlaceFields.description}, ${PlaceFields.time}';
    // final values =
    //     '${json[PlaceFields.title]}, ${json[PlaceFields.description]}, ${json[PlaceFields.time]}';
    // final id = await db
    //     .rawInsert('INSERT INTO table_name ($columns) VALUES ($values)');

    final maps = await db.query(
      table,
      columns: PlaceFields.values,
      where: '${PlaceFields.id} = ?',
      whereArgs: [place.id],
    );

    if (maps.isNotEmpty) {
      await db.delete(
        table,
        where: '${PlaceFields.id} = ?',
        whereArgs: [place.id],
      );
    }

    //final id =
    await db.insert(table, place.toJson());
    //return place.copy(id: id);
  }

  // Future<Place> readPlace(int id) async {
  //   final db = await instance.database;
  //
  //   final maps = await db.query(
  //     tablePlaces,
  //     columns: PlaceFields.values,
  //     where: '${PlaceFields.id} = ?',
  //     whereArgs: [id],
  //   );
  //
  //   if (maps.isNotEmpty) {
  //     return Place.fromJson(maps.first);
  //   } else {
  //     throw Exception('ID $id not found');
  //   }
  // }

  Future<List<Place>> readAllPlaces(String table) async {
    final db = await instance.database;
    final result = await db.query(table);
    return result.map((json) => Place.fromJson(json)).toList();

    //const orderBy = '${PlaceFields.id} ASC';
    // final result =
    //     await db.rawQuery('SELECT * FROM $tablePlaces ORDER BY $orderBy');
  }

  // Future<int> update(Place place) async {
  //   final db = await instance.database;
  //
  //   return db.update(
  //     tablePlaces,
  //     place.toJson(),
  //     where: '${PlaceFields.id} = ?',
  //     whereArgs: [place.id],
  //   );
  // }

  Future<int> delete(String table, String id) async {
    final db = await instance.database;
    return await db.delete(
      table,
      where: '${PlaceFields.id} = ?',
      whereArgs: [id],
    );
  }

  Future clear(String table) async {
    final db = await instance.database;
    await db.rawQuery('DELETE FROM $table');
  }

  Future close() async {
    final db = await instance.database;
    db.close();
  }
}
