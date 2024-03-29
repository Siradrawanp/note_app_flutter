import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../models/note_model.dart';

class NoteDatabase {
  NoteDatabase._init();

  static final NoteDatabase instance = NoteDatabase._init();
  final String tableName = 'notes';
  
  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDb('notes.db');
    return _database!;
  }

  Future _createDb(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $tableName (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        description TEXT NOT NULL,
        time TEXT NOT NULL
      )
    ''');
  }

  Future<Database> _initDb(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);
    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDb,
    );
  }

  Future<Note> createNote(Note note) async {
    final db = await instance.database;
    final id = await db.insert(tableName, note.toMap());
    return note.copyWith(id: id);
  }

  Future<Note> readNote(int id) async {
    final db = await instance.database;
    final maps = await db.query(tableName,
        columns: ['id', 'title', 'description', 'time'],
        where: 'id = ?',
        whereArgs: [id]
      );
    if (maps.isNotEmpty) {
      return Note.fromMap(maps.first);
    } else {
      throw Exception('id $id not found');
    }
  }

  Future<List<Note>> readAllNotes() async {
    final db = await instance.database;
    const orderBy = 'time DESC';
    final result = await db.query(tableName, orderBy: orderBy);
    return result.map((e) => Note.fromMap(e)).toList();
  }

  Future<int> updateNote(Note note) async {
    final db = await instance.database;

    return db.update(tableName,
      note.toMap(),
      where: 'id = ?',
      whereArgs: [note.id],
    );
  }

  Future<int> deleteNote(int id) async {
    final db = await instance.database;
    return await db.delete(tableName,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future closeDb() async {
    final db = await instance.database;
    db.close();
  }

}