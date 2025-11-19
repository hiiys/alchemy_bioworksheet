import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:device_info_plus/device_info_plus.dart';
import '../data/db.dart';
import '../data/models.dart';

class ChangeTrackingService {
  static ChangeTrackingService? _instance;
  String? _deviceId;

  ChangeTrackingService._internal();

  factory ChangeTrackingService() {
    _instance ??= ChangeTrackingService._internal();
    return _instance!;
  }

  Future<String> _getDeviceId() async {
    if (_deviceId != null) return _deviceId!;

    final deviceInfo = DeviceInfoPlugin();
    try {
      final androidInfo = await deviceInfo.androidInfo;
      _deviceId = androidInfo.id;
    } catch (e) {
      _deviceId = 'unknown_device';
    }
    return _deviceId!;
  }

  /// Log a taxon creation
  Future<void> logCreate(Taxon taxon) async {
    final db = await DatabaseHelper().database;
    final deviceId = await _getDeviceId();

    final change = PendingChange(
      changeType: 'create',
      specimenType: taxon.specimenType ?? 'Macrobenthos',
      taxonId: taxon.id,
      oldData: null,
      newData: jsonEncode(taxon.toMap()),
      timestamp: DateTime.now(),
      deviceId: deviceId,
    );

    await db.insert('pending_change', change.toMap());
    print('Logged create change for taxon: ${taxon.name}');
  }

  /// Log a taxon update
  Future<void> logUpdate(Taxon oldTaxon, Taxon newTaxon) async {
    final db = await DatabaseHelper().database;
    final deviceId = await _getDeviceId();

    final change = PendingChange(
      changeType: 'update',
      specimenType: newTaxon.specimenType ?? oldTaxon.specimenType ?? 'Macrobenthos',
      taxonId: newTaxon.id,
      oldData: jsonEncode(oldTaxon.toMap()),
      newData: jsonEncode(newTaxon.toMap()),
      timestamp: DateTime.now(),
      deviceId: deviceId,
    );

    await db.insert('pending_change', change.toMap());
    print('Logged update change for taxon: ${newTaxon.name}');
  }

  /// Log a taxon deletion
  Future<void> logDelete(Taxon taxon) async {
    final db = await DatabaseHelper().database;
    final deviceId = await _getDeviceId();

    final change = PendingChange(
      changeType: 'delete',
      specimenType: taxon.specimenType ?? 'Macrobenthos',
      taxonId: taxon.id,
      oldData: jsonEncode(taxon.toMap()),
      newData: null,
      timestamp: DateTime.now(),
      deviceId: deviceId,
    );

    await db.insert('pending_change', change.toMap());
    print('Logged delete change for taxon: ${taxon.name}');
  }

  /// Get all unsynced changes
  Future<List<PendingChange>> getUnsyncedChanges() async {
    final db = await DatabaseHelper().database;
    final results = await db.query(
      'pending_change',
      where: 'synced = ?',
      whereArgs: [0],
      orderBy: 'timestamp ASC',
    );
    return results.map((m) => PendingChange.fromMap(m)).toList();
  }

  /// Get count of unsynced changes
  Future<int> getUnsyncedCount() async {
    final db = await DatabaseHelper().database;
    final result = await db.rawQuery(
      'SELECT COUNT(1) as count FROM pending_change WHERE synced = 0',
    );
    return result.first['count'] as int? ?? 0;
  }

  /// Upload pending changes to Firebase
  Future<int> syncPendingChanges() async {
    final db = await DatabaseHelper().database;
    final firestore = FirebaseFirestore.instance;

    final unsyncedChanges = await getUnsyncedChanges();
    if (unsyncedChanges.isEmpty) {
      print('No pending changes to sync');
      return 0;
    }

    int syncedCount = 0;

    for (final change in unsyncedChanges) {
      try {
        // Upload to Firebase pending_changes collection
        await firestore.collection('pending_changes').add(change.toFirestore());

        // Mark as synced in local database
        await db.update(
          'pending_change',
          {'synced': 1},
          where: 'id = ?',
          whereArgs: [change.id],
        );

        syncedCount++;
        print('Synced change ${change.id}: ${change.changeType} for taxon ${change.taxonId}');
      } catch (e) {
        print('Failed to sync change ${change.id}: $e');
      }
    }

    print('Synced $syncedCount pending changes to Firebase');
    return syncedCount;
  }

  /// Clear all synced changes from local database
  Future<int> clearSyncedChanges() async {
    final db = await DatabaseHelper().database;
    final deleted = await db.delete(
      'pending_change',
      where: 'synced = ?',
      whereArgs: [1],
    );
    print('Cleared $deleted synced changes from local database');
    return deleted;
  }

  /// Clear all changes (for testing/reset purposes)
  Future<int> clearAllChanges() async {
    final db = await DatabaseHelper().database;
    final deleted = await db.delete('pending_change');
    print('Cleared $deleted changes from local database');
    return deleted;
  }
}
