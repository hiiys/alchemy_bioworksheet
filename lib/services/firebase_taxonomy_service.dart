import 'package:cloud_firestore/cloud_firestore.dart';
import '../data/models.dart';
import '../data/dao/rank_definition_dao.dart';

class FirebaseTaxonomyService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get reference to taxonomy document
  DocumentReference _getTaxonomyRef(String specimenType) {
    return _firestore.collection('taxonomies').doc(specimenType);
  }

  // Get reference to taxa collection
  CollectionReference _getTaxaRef(String specimenType) {
    return _getTaxonomyRef(specimenType).collection('taxa');
  }

  // Get reference to rank definitions collection
  CollectionReference _getRanksRef(String specimenType) {
    return _getTaxonomyRef(specimenType).collection('rankDefinitions');
  }

  /// Stream real-time taxonomy updates
  Stream<List<Taxon>> getTaxaStream(String specimenType) {
    return _getTaxaRef(specimenType).snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return Taxon(
          id: int.tryParse(doc.id),
          parentId: data['parentId'] as int?,
          name: data['name'] as String,
          rank: data['rank'] as String?,
          notes: data['notes'] as String?,
          specimenType: data['specimenType'] as String?,
        );
      }).toList();
    });
  }

  /// Download taxonomy from cloud
  Future<List<Taxon>> downloadTaxonomy(String specimenType) async {
    try {
      final snapshot = await _getTaxaRef(specimenType).get();

      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return Taxon(
          id: int.tryParse(doc.id),
          parentId: data['parentId'] as int?,
          name: data['name'] as String,
          rank: data['rank'] as String?,
          notes: data['notes'] as String?,
          specimenType: data['specimenType'] as String?,
        );
      }).toList();
    } catch (e) {
      print('Error downloading taxonomy: $e');
      return [];
    }
  }

  /// Download rank definitions
  Future<List<RankDefinition>> downloadRankDefinitions(
    String specimenType,
  ) async {
    try {
      final snapshot = await _getRanksRef(specimenType)
          .orderBy('sequence')
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return RankDefinition(
          id: int.tryParse(doc.id),
          specimenType: data['specimenType'] as String,
          name: data['name'] as String,
          sequence: data['sequence'] as int,
        );
      }).toList();
    } catch (e) {
      print('Error downloading ranks: $e');
      return [];
    }
  }

  /// Upload taxonomy to cloud (Admin only)
  Future<bool> uploadTaxonomy(
    String specimenType,
    List<Taxon> taxa,
  ) async {
    try {
      final batch = _firestore.batch();

      // Update metadata
      batch.set(
        _getTaxonomyRef(specimenType),
        {
          'lastModified': FieldValue.serverTimestamp(),
          'modifiedBy': 'admin',
          'taxaCount': taxa.length,
        },
        SetOptions(merge: true),
      );

      // Upload each taxon
      for (final taxon in taxa) {
        if (taxon.id == null) continue;

        final docRef = _getTaxaRef(specimenType).doc(taxon.id.toString());
        batch.set(docRef, {
          'parentId': taxon.parentId,
          'name': taxon.name,
          'rank': taxon.rank,
          'notes': taxon.notes,
          'specimenType': specimenType,
        });
      }

      await batch.commit();
      return true;
    } catch (e) {
      print('Error uploading taxonomy: $e');
      return false;
    }
  }

  /// Upload rank definitions
  Future<bool> uploadRankDefinitions(
    String specimenType,
    List<RankDefinition> ranks,
  ) async {
    try {
      final batch = _firestore.batch();

      for (final rank in ranks) {
        final docRef = _getRanksRef(specimenType)
            .doc(rank.sequence.toString());
        batch.set(docRef, {
          'specimenType': specimenType,
          'name': rank.name,
          'sequence': rank.sequence,
        });
      }

      await batch.commit();
      return true;
    } catch (e) {
      print('Error uploading ranks: $e');
      return false;
    }
  }

  /// Check if cloud version is newer than local
  Future<bool> isCloudNewer(
    String specimenType,
    DateTime? localLastModified,
  ) async {
    if (localLastModified == null) return true;

    try {
      final doc = await _getTaxonomyRef(specimenType).get();

      if (!doc.exists) return false;

      final data = doc.data() as Map<String, dynamic>?;
      final cloudModified = data?['lastModified'] as Timestamp?;

      if (cloudModified == null) return false;

      return cloudModified.toDate().isAfter(localLastModified);
    } catch (e) {
      print('Error checking cloud version: $e');
      return false;
    }
  }

  /// Get taxonomy metadata
  Future<Map<String, dynamic>?> getTaxonomyMetadata(
    String specimenType,
  ) async {
    try {
      final doc = await _getTaxonomyRef(specimenType).get();
      return doc.data() as Map<String, dynamic>?;
    } catch (e) {
      print('Error getting metadata: $e');
      return null;
    }
  }
}
