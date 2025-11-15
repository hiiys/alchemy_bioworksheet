import '../db.dart';
import '../models.dart';

class ProjectDao {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  Future<int> insertProjectInfo(ProjectInfo projectInfo) async {
    final db = await _dbHelper.database;
    return await db.insert('project_info', projectInfo.toMap());
  }

  Future<List<ProjectInfo>> getAllProjectInfos() async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query('project_info');
    return List.generate(maps.length, (i) => ProjectInfo.fromMap(maps[i]));
  }

  Future<ProjectInfo?> getProjectInfoById(int id) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'project_info',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return ProjectInfo.fromMap(maps.first);
    }
    return null;
  }

  Future<int> updateProjectInfo(ProjectInfo projectInfo) async {
    final db = await _dbHelper.database;
    return await db.update(
      'project_info',
      projectInfo.toMap(),
      where: 'id = ?',
      whereArgs: [projectInfo.id],
    );
  }

  Future<int> deleteProjectInfo(int id) async {
    final db = await _dbHelper.database;
    return await db.delete(
      'project_info',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Get the most recent project info
  Future<ProjectInfo?> getMostRecentProjectInfo() async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'project_info',
      orderBy: 'date DESC',
      limit: 1,
    );
    if (maps.isNotEmpty) {
      return ProjectInfo.fromMap(maps.first);
    }
    return null;
  }
}
