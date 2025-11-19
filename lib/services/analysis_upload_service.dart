import 'package:cloud_firestore/cloud_firestore.dart';
import '../data/models.dart';
import '../data/dao/count_dao.dart';
import '../data/dao/order_dao.dart';
import '../data/dao/sample_dao.dart';
import '../data/dao/taxon_dao.dart';

class AnalysisUploadService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final CountDao _countDao = CountDao();
  final OrderDao _orderDao = OrderDao();
  final SampleDao _sampleDao = SampleDao();
  final TaxonDao _taxonDao = TaxonDao();

  /// Get reference to analysis results collection
  CollectionReference get _analysisResultsRef {
    return _firestore.collection('analysis_results');
  }

  /// Upload a completed sample analysis to Firebase
  Future<String?> uploadSampleAnalysis({
    required int sampleId,
    required String deviceId,
  }) async {
    try {
      // Get sample
      final sample = await _sampleDao.getSampleById(sampleId);
      if (sample == null) {
        print('Sample not found: $sampleId');
        return null;
      }

      // Get order
      OrderInfo? order;
      if (sample.orderId != null) {
        order = await _orderDao.getOrderById(sample.orderId!);
      }

      // Get counts for this sample
      final counts = await _countDao.getCountRecordsForSample(sampleId);
      if (counts.isEmpty) {
        print('No counts found for sample: $sampleId');
        return null;
      }

      // Build taxon counts with hierarchy and density
      final taxonCounts = <TaxonCount>[];
      for (final count in counts) {
        final taxon = await _taxonDao.getTaxonById(count.taxonId);
        if (taxon == null) continue;

        // Build hierarchy
        final hierarchy = await _buildTaxonHierarchy(count.taxonId);

        // Calculate density
        double? density;
        if (sample.sampleType == 'Macrobenthos') {
          // Density = Count / Area of grab (ind/m²)
          final areaOfGrab = _parseDouble(order?.areaOfGrab);
          if (areaOfGrab != null && areaOfGrab > 0) {
            density = count.count / areaOfGrab;
          }
        } else {
          // Plankton: Density = Count × Dilution Factor / Volume Filtered (units/L)
          final filteredVolume = _parseDouble(order?.filteredVolume);
          double? dilutionFactor;

          if (order?.sampleVolume != null && order?.srCellVolume != null &&
              order!.srCellsCounted != null && order.srCellsCounted! > 0) {
            // Dilution Factor = Sample Volume / Volume Counted
            // Volume Counted = SR Cell Volume × Number of SR Cells Counted
            final volumeCounted = order.srCellVolume! * order.srCellsCounted!;
            if (volumeCounted > 0) {
              dilutionFactor = order.sampleVolume! / volumeCounted;
            }
          }

          if (filteredVolume != null && filteredVolume > 0 && dilutionFactor != null) {
            density = (count.count * dilutionFactor) / filteredVolume;
          }
        }

        taxonCounts.add(TaxonCount(
          taxonId: count.taxonId,
          taxonName: taxon.name,
          taxonRank: taxon.rank,
          hierarchy: hierarchy,
          count: count.count,
          density: density,
          note: count.note,
        ));
      }

      // Calculate dilution factor for storage
      double? dilutionFactor;
      if (order?.sampleVolume != null && order?.srCellVolume != null &&
          order!.srCellsCounted != null && order.srCellsCounted! > 0) {
        final volumeCounted = order.srCellVolume! * order.srCellsCounted!;
        if (volumeCounted > 0) {
          dilutionFactor = order.sampleVolume! / volumeCounted;
        }
      }

      // Create analysis result
      final analysisResult = AnalysisResult(
        orderId: sample.orderId ?? 0,
        sampleId: sampleId,
        stationId: sample.stationId,
        specimenType: sample.sampleType,
        biologistId: sample.biologistId ?? 'unknown',
        analyzedDate: sample.analyzedDate ?? DateTime.now(),
        deviceId: deviceId,
        counts: taxonCounts,
        clientName: order?.clientName ?? sample.client ?? 'Unknown',
        clientAddress: order?.clientAddress,
        sammNo: order?.sammNo,
        authorizedBy: order?.authorizedBy,
        institution: order?.institution,
        reportNo: order?.reportNo,
        referenceId: order?.referenceId ?? sample.receiveId,
        areaOfGrab: _parseDouble(order?.areaOfGrab),
        filteredVolume: _parseDouble(order?.filteredVolume),
        dilutionFactor: dilutionFactor,
      );

      // Upload to Firebase
      final docRef = await _analysisResultsRef.add(analysisResult.toFirestore());

      print('Analysis uploaded successfully: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      print('Error uploading analysis: $e');
      return null;
    }
  }

  /// Build taxonomic hierarchy for a taxon
  Future<List<String>> _buildTaxonHierarchy(int taxonId) async {
    final hierarchy = <String>[];
    int? currentId = taxonId;

    while (currentId != null) {
      final taxon = await _taxonDao.getTaxonById(currentId);
      if (taxon == null) break;

      hierarchy.insert(0, taxon.name);
      currentId = taxon.parentId;
    }

    return hierarchy;
  }

  /// Parse double from string, handling various formats
  double? _parseDouble(String? value) {
    if (value == null || value.isEmpty) return null;

    // Remove any units or extra text
    final cleaned = value.replaceAll(RegExp(r'[^0-9.]'), '');
    return double.tryParse(cleaned);
  }

  /// Get all analysis results for a specimen type
  Future<List<AnalysisResult>> getAnalysisResults({
    String? specimenType,
    String? clientName,
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    try {
      Query query = _analysisResultsRef;

      if (specimenType != null) {
        query = query.where('specimenType', isEqualTo: specimenType);
      }

      if (clientName != null) {
        query = query.where('clientName', isEqualTo: clientName);
      }

      final snapshot = await query.orderBy('uploadedAt', descending: true).get();

      return snapshot.docs.map((doc) {
        return AnalysisResult.fromFirestore(
          doc.data() as Map<String, dynamic>,
          doc.id,
        );
      }).where((result) {
        if (fromDate != null && result.analyzedDate.isBefore(fromDate)) {
          return false;
        }
        if (toDate != null && result.analyzedDate.isAfter(toDate)) {
          return false;
        }
        return true;
      }).toList();
    } catch (e) {
      print('Error getting analysis results: $e');
      return [];
    }
  }

  /// Check if a sample has already been uploaded
  Future<bool> isSampleUploaded(int sampleId, String deviceId) async {
    try {
      final snapshot = await _analysisResultsRef
          .where('sampleId', isEqualTo: sampleId)
          .where('deviceId', isEqualTo: deviceId)
          .limit(1)
          .get();

      return snapshot.docs.isNotEmpty;
    } catch (e) {
      print('Error checking upload status: $e');
      return false;
    }
  }

  /// Delete an analysis result
  Future<bool> deleteAnalysisResult(String docId) async {
    try {
      await _analysisResultsRef.doc(docId).delete();
      return true;
    } catch (e) {
      print('Error deleting analysis result: $e');
      return false;
    }
  }

  /// Get analysis result by ID
  Future<AnalysisResult?> getAnalysisResultById(String docId) async {
    try {
      final doc = await _analysisResultsRef.doc(docId).get();
      if (!doc.exists) return null;

      return AnalysisResult.fromFirestore(
        doc.data() as Map<String, dynamic>,
        doc.id,
      );
    } catch (e) {
      print('Error getting analysis result: $e');
      return null;
    }
  }
}
