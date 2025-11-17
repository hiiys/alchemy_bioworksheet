import '../db.dart';
import '../models.dart';

class CountDao {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  Future<int> insertCountRecord(CountRecord countRecord) async {
    final db = await _dbHelper.database;
    return await db.insert('count_record', countRecord.toMap());
  }

  Future<List<CountRecord>> getCountRecordsForSample(int sampleId) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'count_record',
      where: 'sampleId = ?',
      whereArgs: [sampleId],
    );
    return List.generate(maps.length, (i) => CountRecord.fromMap(maps[i]));
  }

  Future<CountRecord?> getCountRecord(int sampleId, int taxonId) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'count_record',
      where: 'sampleId = ? AND taxonId = ?',
      whereArgs: [sampleId, taxonId],
    );
    if (maps.isNotEmpty) {
      return CountRecord.fromMap(maps.first);
    }
    return null;
  }

  Future<int> updateCountRecord(CountRecord countRecord) async {
    final db = await _dbHelper.database;
    return await db.update(
      'count_record',
      countRecord.toMap(),
      where: 'id = ?',
      whereArgs: [countRecord.id],
    );
  }

  Future<int> deleteCountRecord(int id) async {
    final db = await _dbHelper.database;
    return await db.delete('count_record', where: 'id = ?', whereArgs: [id]);
  }

  // Increment count for a taxon in a sample
  Future<void> incrementCount(int sampleId, int taxonId) async {
    final existingRecord = await getCountRecord(sampleId, taxonId);

    if (existingRecord != null) {
      // Update existing record
      final updatedRecord = CountRecord(
        id: existingRecord.id,
        sampleId: sampleId,
        taxonId: taxonId,
        count: existingRecord.count + 1,
        note: existingRecord.note,
        photoPath: existingRecord.photoPath,
      );
      await updateCountRecord(updatedRecord);
    } else {
      // Create new record
      final newRecord = CountRecord(
        sampleId: sampleId,
        taxonId: taxonId,
        count: 1,
      );
      await insertCountRecord(newRecord);
    }
  }

  // Decrement count for a taxon in a sample
  Future<void> decrementCount(int sampleId, int taxonId) async {
    final existingRecord = await getCountRecord(sampleId, taxonId);

    if (existingRecord != null && existingRecord.count > 0) {
      if (existingRecord.count == 1) {
        // Delete record if count becomes 0
        await deleteCountRecord(existingRecord.id!);
      } else {
        // Update existing record
        final updatedRecord = CountRecord(
          id: existingRecord.id,
          sampleId: sampleId,
          taxonId: taxonId,
          count: existingRecord.count - 1,
          note: existingRecord.note,
          photoPath: existingRecord.photoPath,
        );
        await updateCountRecord(updatedRecord);
      }
    }
  }

  // Set specific count for a taxon in a sample
  Future<void> setCount(int sampleId, int taxonId, int count) async {
    final existingRecord = await getCountRecord(sampleId, taxonId);

    if (count == 0) {
      // Delete record if count is 0
      if (existingRecord != null) {
        await deleteCountRecord(existingRecord.id!);
      }
    } else if (existingRecord != null) {
      // Update existing record
      final updatedRecord = CountRecord(
        id: existingRecord.id,
        sampleId: sampleId,
        taxonId: taxonId,
        count: count,
        note: existingRecord.note,
        photoPath: existingRecord.photoPath,
      );
      await updateCountRecord(updatedRecord);
    } else {
      // Create new record
      final newRecord = CountRecord(
        sampleId: sampleId,
        taxonId: taxonId,
        count: count,
      );
      await insertCountRecord(newRecord);
    }
  }

  // Get count for a specific taxon in a sample
  Future<int> getCount(int sampleId, int taxonId) async {
    final record = await getCountRecord(sampleId, taxonId);
    return record?.count ?? 0;
  }

  // Get counts with taxon information for a sample
  Future<List<Map<String, dynamic>>> getCountsWithTaxa(int sampleId) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.rawQuery(
      '''
      SELECT cr.*, t.name as taxonName, t.parentId, t.rank
      FROM count_record cr
      JOIN taxon t ON cr.taxonId = t.id
      WHERE cr.sampleId = ?
    ''',
      [sampleId],
    );
    return maps;
  }

  // Clear all counts for a sample
  Future<void> clearSampleCounts(int sampleId) async {
    final db = await _dbHelper.database;
    await db.delete(
      'count_record',
      where: 'sampleId = ?',
      whereArgs: [sampleId],
    );
  }

  Future<void> clearAll() async {
    final db = await _dbHelper.database;
    await db.delete('count_record');
  }
}
