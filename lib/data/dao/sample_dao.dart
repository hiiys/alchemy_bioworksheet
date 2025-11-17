import '../db.dart';
import '../models.dart';

class SampleDao {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  Future<int> insertSample(Sample sample) async {
    final db = await _dbHelper.database;
    final data = sample.toMap();
    data.remove('id');
    return await db.insert('sample', data);
  }

  Future<List<Sample>> getAllSamples() async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query('sample');
    return List.generate(maps.length, (i) => Sample.fromMap(maps[i]));
  }

  Future<Sample?> getSampleById(int id) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'sample',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return Sample.fromMap(maps.first);
    }
    return null;
  }

  Future<int> updateSample(Sample sample) async {
    final db = await _dbHelper.database;
    return await db.update(
      'sample',
      sample.toMap(),
      where: 'id = ?',
      whereArgs: [sample.id],
    );
  }

  Future<int> deleteSample(int id) async {
    final db = await _dbHelper.database;

    // First delete associated count records
    await db.delete('count_record', where: 'sampleId = ?', whereArgs: [id]);

    // Then delete the sample
    return await db.delete('sample', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> clearAll() async {
    final db = await _dbHelper.database;
    await db.delete('count_record');
    await db.delete('sample');
  }

  // Get total count for a sample
  Future<int> getTotalCountForSample(int sampleId) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> result = await db.rawQuery(
      '''
      SELECT SUM(count) as total FROM count_record WHERE sampleId = ?
    ''',
      [sampleId],
    );

    if (result.isNotEmpty && result.first['total'] != null) {
      return result.first['total'] as int;
    }
    return 0;
  }

  // Get samples with their total counts
  Future<List<Map<String, dynamic>>> getSamplesWithCounts() async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT s.*, COALESCE(SUM(cr.count), 0) as totalCount
      FROM sample s
      LEFT JOIN count_record cr ON s.id = cr.sampleId
      GROUP BY s.id
      ORDER BY s.date DESC
    ''');
    return maps;
  }

  Future<List<Sample>> getSamplesByClientAndDateRange(
    String client,
    DateTime start,
    DateTime end,
  ) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.rawQuery(
      '''
      SELECT * FROM sample 
      WHERE client = ? AND date BETWEEN ? AND ?
      ORDER BY date DESC
    ''',
      [client, start.millisecondsSinceEpoch, end.millisecondsSinceEpoch],
    );
    return List.generate(maps.length, (i) => Sample.fromMap(maps[i]));
  }

  Future<List<Sample>> getSamplesByOrder(int orderId) async {
    final db = await _dbHelper.database;
    final rows = await db.query(
      'sample',
      where: 'orderId = ?',
      whereArgs: [orderId],
      orderBy: 'id ASC',
    );
    return rows.map((e) => Sample.fromMap(e)).toList();
  }

  Future<void> markSampleCompleted(int id, bool completed) async {
    final db = await _dbHelper.database;
    await db.update(
      'sample',
      {'completed': completed ? 1 : 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
