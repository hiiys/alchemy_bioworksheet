import 'package:sqflite/sqflite.dart';
import '../db.dart';

class RankDefinition {
  final int? id;
  final String specimenType;
  final String name;
  final int sequence;
  RankDefinition({this.id, required this.specimenType, required this.name, required this.sequence});
  Map<String, dynamic> toMap() => {
    'id': id,
    'specimenType': specimenType,
    'name': name,
    'sequence': sequence,
  };
  factory RankDefinition.fromMap(Map<String, dynamic> m) => RankDefinition(
    id: m['id'] as int?,
    specimenType: m['specimenType'] as String,
    name: m['name'] as String,
    sequence: m['sequence'] as int,
  );
}

class RankDefinitionDao {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  Future<List<RankDefinition>> getRanksByType(String specimenType) async {
    final db = await _dbHelper.database;
    final rows = await db.query(
      'rank_definition',
      where: 'specimenType = ?',
      whereArgs: [specimenType],
      orderBy: 'sequence ASC',
    );
    return rows.map((e) => RankDefinition.fromMap(e)).toList();
  }

  Future<void> insertRank(String specimenType, String name, int sequence) async {
    final db = await _dbHelper.database;
    await db.transaction((txn) async {
      await txn.rawUpdate(
        'UPDATE rank_definition SET sequence = sequence + 1 WHERE specimenType = ? AND sequence >= ?',
        [specimenType, sequence],
      );
      await txn.insert('rank_definition', {
        'specimenType': specimenType,
        'name': name,
        'sequence': sequence,
      });
    });
  }

  Future<void> ensureRank(String specimenType, String name) async {
    final db = await _dbHelper.database;
    final rows = await db.query('rank_definition', where: 'specimenType = ? AND LOWER(name) = LOWER(?)', whereArgs: [specimenType, name]);
    if (rows.isNotEmpty) return;
    final maxSeq = Sqflite.firstIntValue(await db.rawQuery('SELECT COALESCE(MAX(sequence),0) FROM rank_definition WHERE specimenType = ?', [specimenType])) ?? 0;
    await db.insert('rank_definition', {'specimenType': specimenType, 'name': name, 'sequence': maxSeq + 1});
  }

  Future<void> reorderRank(String specimenType, String name, int newSequence) async {
    final db = await _dbHelper.database;
    await db.transaction((txn) async {
      final current = await txn.query('rank_definition', where: 'specimenType = ? AND LOWER(name) = LOWER(?)', whereArgs: [specimenType, name]);
      if (current.isEmpty) return;
      final currSeq = current.first['sequence'] as int;
      if (newSequence == currSeq) return;
      if (newSequence < currSeq) {
        await txn.rawUpdate('UPDATE rank_definition SET sequence = sequence + 1 WHERE specimenType = ? AND sequence >= ? AND sequence < ?', [specimenType, newSequence, currSeq]);
      } else {
        await txn.rawUpdate('UPDATE rank_definition SET sequence = sequence - 1 WHERE specimenType = ? AND sequence <= ? AND sequence > ?', [specimenType, newSequence, currSeq]);
      }
      await txn.update('rank_definition', {'sequence': newSequence}, where: 'specimenType = ? AND LOWER(name) = LOWER(?)', whereArgs: [specimenType, name]);
    });
  }

  Future<RankDefinition?> getBySequence(String specimenType, int sequence) async {
    final db = await _dbHelper.database;
    final rows = await db.query('rank_definition', where: 'specimenType = ? AND sequence = ?', whereArgs: [specimenType, sequence]);
    if (rows.isEmpty) return null;
    return RankDefinition.fromMap(rows.first);
  }

  Future<void> deleteRankBySequence(String specimenType, int sequence) async {
    final db = await _dbHelper.database;
    await db.transaction((txn) async {
      await txn.delete('rank_definition', where: 'specimenType = ? AND sequence = ?', whereArgs: [specimenType, sequence]);
      await txn.rawUpdate('UPDATE rank_definition SET sequence = sequence - 1 WHERE specimenType = ? AND sequence > ?', [specimenType, sequence]);
    });
  }
}