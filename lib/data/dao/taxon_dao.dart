import '../db.dart';
import '../models.dart';

class TaxonDao {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  Future<int> insertTaxon(Taxon taxon) async {
    final db = await _dbHelper.database;
    return await db.insert('taxon', taxon.toMap());
  }

  Future<List<Taxon>> getAllTaxa() async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query('taxon');
    return List.generate(maps.length, (i) => Taxon.fromMap(maps[i]));
  }

  Future<List<Taxon>> getAllTaxaByType(String specimenType) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'taxon',
      where: 'specimenType = ?',
      whereArgs: [specimenType],
    );
    return List.generate(maps.length, (i) => Taxon.fromMap(maps[i]));
  }

  Future<List<Taxon>> getTaxaByParentId(int? parentId) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'taxon',
      where: 'parentId = ?',
      whereArgs: [parentId],
    );
    return List.generate(maps.length, (i) => Taxon.fromMap(maps[i]));
  }

  Future<List<Taxon>> getRootTaxa() async {
    return await getTaxaByParentId(null);
  }

  Future<Taxon?> getTaxonById(int id) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'taxon',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return Taxon.fromMap(maps.first);
    }
    return null;
  }

  Future<Taxon?> getTaxonByParentAndName(int? parentId, String name, {String? specimenType}) async {
    final db = await _dbHelper.database;
    List<Map<String, dynamic>> maps;
    if (parentId == null) {
      maps = await db.query(
        'taxon',
        where: 'parentId IS NULL AND LOWER(name) = LOWER(?)' + (specimenType != null ? ' AND specimenType = ?' : ''),
        whereArgs: specimenType != null ? [name, specimenType] : [name],
      );
    } else {
      maps = await db.query(
        'taxon',
        where: 'parentId = ? AND LOWER(name) = LOWER(?)' + (specimenType != null ? ' AND specimenType = ?' : ''),
        whereArgs: specimenType != null ? [parentId, name, specimenType] : [parentId, name],
      );
    }
    if (maps.isNotEmpty) {
      return Taxon.fromMap(maps.first);
    }
    return null;
  }

  Future<Taxon> upsertTaxon(int? parentId, String name, {String? rank, String? notes, String? specimenType}) async {
    final existing = await getTaxonByParentAndName(parentId, name, specimenType: specimenType);
    if (existing != null) {
      return existing;
    }
    final id = await insertTaxon(Taxon(parentId: parentId, name: name, rank: rank, notes: notes, specimenType: specimenType));
    return Taxon(id: id, parentId: parentId, name: name, rank: rank, notes: notes, specimenType: specimenType);
  }

  Future<List<Taxon>> searchTaxa(String query) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'taxon',
      where: 'name LIKE ?',
      whereArgs: ['%$query%'],
    );
    return List.generate(maps.length, (i) => Taxon.fromMap(maps[i]));
  }

  Future<int> updateTaxon(Taxon taxon) async {
    final db = await _dbHelper.database;
    return await db.update(
      'taxon',
      taxon.toMap(),
      where: 'id = ?',
      whereArgs: [taxon.id],
    );
  }

  Future<int> deleteTaxon(int id) async {
    final db = await _dbHelper.database;
    return await db.delete(
      'taxon',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Get the full ancestry path for a taxon
  Future<List<Taxon>> getTaxonAncestry(int taxonId) async {
    final List<Taxon> ancestry = [];
    Taxon? current = await getTaxonById(taxonId);
    
    while (current != null) {
      ancestry.insert(0, current);
      if (current.parentId != null) {
        current = await getTaxonById(current.parentId!);
      } else {
        current = null;
      }
    }
    
    return ancestry;
  }

  // Check if a taxon has children
  Future<bool> hasChildren(int taxonId) async {
    final children = await getTaxaByParentId(taxonId);
    return children.isNotEmpty;
  }

  // Get all leaf taxa (taxa with no children)
  Future<List<Taxon>> getLeafTaxa() async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT t.* FROM taxon t 
      WHERE NOT EXISTS (
        SELECT 1 FROM taxon c WHERE c.parentId = t.id
      )
    ''');
    return List.generate(maps.length, (i) => Taxon.fromMap(maps[i]));
  }

  Future<List<Taxon>> getLeafTaxaByType(String specimenType) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT t.* FROM taxon t 
      WHERE t.specimenType = ? AND NOT EXISTS (
        SELECT 1 FROM taxon c WHERE c.parentId = t.id
      )
    ''', [specimenType]);
    return List.generate(maps.length, (i) => Taxon.fromMap(maps[i]));
  }
}
