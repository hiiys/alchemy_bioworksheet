import 'package:sqflite/sqflite.dart';
import '../db.dart';
import '../models.dart';

class OrderDao {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  Future<int> insertOrder(OrderInfo order) async {
    final db = await _dbHelper.database;
    final data = order.toMap();
    data.remove('id');
    return await db.insert('orders', data);
  }

  Future<int> updateOrder(OrderInfo order) async {
    final db = await _dbHelper.database;
    return await db.update(
      'orders',
      order.toMap(),
      where: 'id = ?',
      whereArgs: [order.id],
    );
  }

  Future<OrderInfo?> getOrderById(int id) async {
    final db = await _dbHelper.database;
    final rows = await db.query('orders', where: 'id = ?', whereArgs: [id]);
    if (rows.isEmpty) return null;
    return OrderInfo.fromMap(rows.first);
  }

  Future<List<OrderInfo>> getAllOrders() async {
    final db = await _dbHelper.database;
    final rows = await db.query('orders', orderBy: 'id DESC');
    return rows.map((e) => OrderInfo.fromMap(e)).toList();
  }

  Future<List<OrderInfo>> getOrdersByType(String specimenType) async {
    final db = await _dbHelper.database;
    final rows = await db.query(
      'orders',
      where: 'specimenType = ?',
      whereArgs: [specimenType],
      orderBy: 'id DESC',
    );
    return rows.map((e) => OrderInfo.fromMap(e)).toList();
  }

  Future<int> deleteOrder(int id) async {
    final db = await _dbHelper.database;
    return await db.delete('orders', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> clearAll() async {
    final db = await _dbHelper.database;
    await db.delete('orders');
  }
}
