import 'package:shared_preferences/shared_preferences.dart';
import 'firebase_taxonomy_service.dart';
import '../data/dao/taxon_dao.dart';
import '../data/dao/rank_definition_dao.dart';
import '../data/db.dart';

class SyncService {
  final FirebaseTaxonomyService _firebaseService = FirebaseTaxonomyService();
  final TaxonDao _taxonDao = TaxonDao();
  final RankDefinitionDao _rankDao = RankDefinitionDao();

  /// Sync taxonomy from cloud to local database
  Future<SyncResult> syncTaxonomy(String specimenType) async {
    try {
      print('Starting sync for $specimenType...');

      // 1. Check if local database has any data for this specimen type
      final localTaxa = await _taxonDao.getAllTaxaByType(specimenType);
      final isLocalEmpty = localTaxa.isEmpty;

      if (isLocalEmpty) {
        print('Local database is empty for $specimenType, forcing sync from cloud');
      }

      // 2. Check if cloud is newer (skip if local is empty)
      final prefs = await SharedPreferences.getInstance();
      final lastSyncKey = 'last_sync_$specimenType';
      final lastSyncMillis = prefs.getInt(lastSyncKey);
      final lastSync = lastSyncMillis != null
          ? DateTime.fromMillisecondsSinceEpoch(lastSyncMillis)
          : null;

      if (!isLocalEmpty) {
        final isNewer = await _firebaseService.isCloudNewer(
          specimenType,
          lastSync,
        );

        if (!isNewer && lastSync != null) {
          print('Local taxonomy is up to date');
          return SyncResult.success(
            message: 'Already up to date',
            taxaSynced: 0,
          );
        }
      }

      // 2. Download from cloud
      print('Downloading taxonomy from cloud...');
      final cloudTaxa = await _firebaseService.downloadTaxonomy(specimenType);
      final cloudRanks = await _firebaseService.downloadRankDefinitions(
        specimenType,
      );

      if (cloudTaxa.isEmpty) {
        print('No cloud data found');
        return SyncResult.error('No cloud data available for $specimenType');
      }

      // 3. Clear local taxonomy for this specimen type
      print('Clearing local taxonomy...');
      final db = await DatabaseHelper().database;
      await db.delete(
        'taxon',
        where: 'specimenType = ?',
        whereArgs: [specimenType],
      );
      await db.delete(
        'rank_definition',
        where: 'specimenType = ?',
        whereArgs: [specimenType],
      );

      // 4. Insert cloud data to local database
      print('Inserting ${cloudTaxa.length} taxa...');
      for (final taxon in cloudTaxa) {
        await _taxonDao.insertTaxon(taxon);
      }

      print('Inserting ${cloudRanks.length} ranks...');
      for (final rank in cloudRanks) {
        await db.insert('rank_definition', {
          'specimenType': rank.specimenType,
          'name': rank.name,
          'sequence': rank.sequence,
        });
      }

      // 5. Update last sync time
      await prefs.setInt(lastSyncKey, DateTime.now().millisecondsSinceEpoch);

      print('Sync completed successfully');
      return SyncResult.success(
        message: 'Synced ${cloudTaxa.length} taxa',
        taxaSynced: cloudTaxa.length,
      );
    } catch (e) {
      print('Sync error: $e');
      return SyncResult.error('Sync failed: $e');
    }
  }

  /// Sync all specimen types
  Future<Map<String, SyncResult>> syncAllTaxonomies() async {
    final results = <String, SyncResult>{};

    for (final type in ['Macrobenthos', 'Zooplankton', 'Phytoplankton']) {
      results[type] = await syncTaxonomy(type);
    }

    return results;
  }

  /// Get last sync time for specimen type
  Future<DateTime?> getLastSyncTime(String specimenType) async {
    final prefs = await SharedPreferences.getInstance();
    final millis = prefs.getInt('last_sync_$specimenType');
    return millis != null
        ? DateTime.fromMillisecondsSinceEpoch(millis)
        : null;
  }

  /// Upload local taxonomy to cloud (Admin function)
  Future<SyncResult> uploadTaxonomy(String specimenType) async {
    try {
      print('Starting upload for $specimenType...');

      // Get local data
      final taxa = await _taxonDao.getAllTaxaByType(specimenType);
      final ranks = await _rankDao.getRanksByType(specimenType);

      if (taxa.isEmpty) {
        return SyncResult.error('No local data to upload for $specimenType');
      }

      // Upload to Firebase
      print('Uploading ${taxa.length} taxa...');
      final taxaSuccess = await _firebaseService.uploadTaxonomy(
        specimenType,
        taxa,
      );

      print('Uploading ${ranks.length} ranks...');
      final ranksSuccess = await _firebaseService.uploadRankDefinitions(
        specimenType,
        ranks,
      );

      if (taxaSuccess && ranksSuccess) {
        // Update last sync time
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt(
          'last_sync_$specimenType',
          DateTime.now().millisecondsSinceEpoch,
        );

        return SyncResult.success(
          message: 'Uploaded ${taxa.length} taxa',
          taxaSynced: taxa.length,
        );
      } else {
        return SyncResult.error('Upload failed');
      }
    } catch (e) {
      print('Upload error: $e');
      return SyncResult.error('Upload failed: $e');
    }
  }

  /// Upload all specimen types to cloud
  Future<Map<String, SyncResult>> uploadAllTaxonomies() async {
    final results = <String, SyncResult>{};

    for (final type in ['Macrobenthos', 'Zooplankton', 'Phytoplankton']) {
      results[type] = await uploadTaxonomy(type);
    }

    return results;
  }
}

class SyncResult {
  final bool success;
  final String message;
  final int taxaSynced;

  SyncResult({
    required this.success,
    required this.message,
    required this.taxaSynced,
  });

  factory SyncResult.success({
    required String message,
    required int taxaSynced,
  }) {
    return SyncResult(
      success: true,
      message: message,
      taxaSynced: taxaSynced,
    );
  }

  factory SyncResult.error(String message) {
    return SyncResult(
      success: false,
      message: message,
      taxaSynced: 0,
    );
  }
}
