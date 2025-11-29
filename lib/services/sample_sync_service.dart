import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'dart:io';
import '../data/models.dart';
import '../data/dao/sample_dao.dart';
import '../data/dao/order_dao.dart';
import '../data/dao/taxon_dao.dart';

/// Service to sync samples, orders, and taxonomies with Firebase
class SampleSyncService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final SampleDao _sampleDao = SampleDao();
  final OrderDao _orderDao = OrderDao();
  final TaxonDao _taxonDao = TaxonDao();

  /// Get reference to samples collection
  CollectionReference get _samplesRef {
    return _firestore.collection('samples');
  }

  /// Get reference to orders collection
  CollectionReference get _ordersRef {
    return _firestore.collection('orders');
  }

  /// Get current device ID
  Future<String> _getDeviceId() async {
    try {
      final deviceInfo = DeviceInfoPlugin();
      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        return androidInfo.id; // Android ID
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        return iosInfo.identifierForVendor ?? 'unknown_ios';
      } else if (Platform.isWindows) {
        final windowsInfo = await deviceInfo.windowsInfo;
        return windowsInfo.deviceId;
      } else {
        return 'unknown_device';
      }
    } catch (e) {
      print('Error getting device ID: $e');
      return 'unknown_device';
    }
  }

  /// Generate unique Reference ID for a sample
  /// Format: BM/00001/25 (Macrobenthos), BZ/00001/25 (Zooplankton), BP/00001/25 (Phytoplankton)
  Future<String> _generateReferenceId(String specimenType) async {
    // Get prefix based on specimen type
    String prefix;
    switch (specimenType) {
      case 'Macrobenthos':
        prefix = 'BM/';
        break;
      case 'Zooplankton':
        prefix = 'BZ/';
        break;
      case 'Phytoplankton':
        prefix = 'BP/';
        break;
      default:
        prefix = 'XX/';
    }

    // Get current year's last 2 digits
    final year = DateTime.now().year % 100;
    final yearStr = year.toString().padLeft(2, '0');

    try {
      // Query all existing Reference IDs for this specimen type
      final snapshot = await _samplesRef
          .where('sampleType', isEqualTo: specimenType)
          .get();

      int maxSequence = 0;

      // Parse existing Reference IDs to find the highest sequence number
      for (final doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final referenceId = data['receiveId'] as String?;

        if (referenceId != null && referenceId.startsWith(prefix)) {
          // Extract the 5-digit sequence number
          // Format: BM/00001/25 -> extract "00001"
          final parts = referenceId.split('/');
          if (parts.length >= 3) {
            final sequenceStr = parts[1];
            final sequence = int.tryParse(sequenceStr);
            if (sequence != null && sequence > maxSequence) {
              maxSequence = sequence;
            }
          }
        }
      }

      // Increment sequence number
      final nextSequence = maxSequence + 1;
      final sequenceStr = nextSequence.toString().padLeft(5, '0');

      // Format: BM/00001/25
      return '$prefix$sequenceStr/$yearStr';
    } catch (e) {
      print('Error generating Reference ID: $e');
      // Fallback to 00001 if there's an error
      return '$prefix${'1'.padLeft(5, '0')}/$yearStr';
    }
  }

  /// Upload an order to Firebase
  Future<String?> uploadOrder(OrderInfo order) async {
    try {
      final deviceId = await _getDeviceId();

      final orderData = order.toFirestore();
      orderData['deviceId'] = deviceId;

      final docRef = await _ordersRef.add(orderData);

      print('Order uploaded successfully: ${docRef.id}');

      // Update local database with Firebase ID
      if (order.id != null) {
        final updatedOrder = OrderInfo(
          id: order.id,
          firebaseId: docRef.id,
          clientName: order.clientName,
          clientAddress: order.clientAddress,
          specimenType: order.specimenType,
          numberOfSamples: order.numberOfSamples,
          numberOfReplicates: order.numberOfReplicates,
          dateReceived: order.dateReceived,
          dateAnalysis: order.dateAnalysis,
          gearUsed: order.gearUsed,
          areaOfGrab: order.areaOfGrab,
          sieveSize: order.sieveSize,
          netDiameter: order.netDiameter,
          netMesh: order.netMesh,
          towType: order.towType,
          filteredVolume: order.filteredVolume,
          methodAnalysis: order.methodAnalysis,
          reportNo: order.reportNo,
          referenceId: order.referenceId,
          comments: order.comments,
          sammNo: order.sammNo,
          authorizedBy: order.authorizedBy,
          institution: order.institution,
          sampleDescription: order.sampleDescription,
          towDistance: order.towDistance,
          sampleVolume: order.sampleVolume,
          srCellVolume: order.srCellVolume,
          srCellsCounted: order.srCellsCounted,
          deviceId: deviceId,
          createdAt: order.createdAt,
          updatedAt: DateTime.now(),
          synced: true,
        );
        await _orderDao.updateOrder(updatedOrder);
      }

      return docRef.id;
    } catch (e) {
      print('Error uploading order: $e');
      return null;
    }
  }

  /// Upload a sample to Firebase and auto-generate Reference ID
  Future<String?> uploadSample(Sample sample) async {
    try {
      final deviceId = await _getDeviceId();

      // Auto-generate Reference ID if not already set
      String referenceId = sample.receiveId ?? '';
      if (referenceId.isEmpty) {
        referenceId = await _generateReferenceId(sample.sampleType);
        print('Generated Reference ID: $referenceId');
      }

      final sampleData = sample.toFirestore();
      sampleData['deviceId'] = deviceId;
      sampleData['receiveId'] = referenceId; // Set auto-generated Reference ID

      // CRITICAL FIX: Convert local orderId to Firebase document ID
      // The web admin queries samples by Firebase document ID, not local SQLite ID
      if (sample.orderId != null) {
        final order = await _orderDao.getOrderById(sample.orderId!);
        if (order != null && order.firebaseId != null) {
          // Use Firebase document ID instead of local ID
          sampleData['orderId'] = order.firebaseId;
          print('Converted orderId from ${sample.orderId} to ${order.firebaseId}');
        } else {
          print('Warning: Order ${sample.orderId} not found or has no Firebase ID');
          // Keep the local ID as fallback, but this may cause sync issues
          sampleData['orderId'] = sample.orderId.toString();
        }
      }

      final docRef = await _samplesRef.add(sampleData);

      print('Sample uploaded successfully: ${docRef.id}');

      // Update local database with Firebase ID and Reference ID
      if (sample.id != null) {
        final updatedSample = Sample(
          id: sample.id,
          firebaseId: docRef.id,
          orderId: sample.orderId,
          stationId: sample.stationId,
          date: sample.date,
          lat: sample.lat,
          lon: sample.lon,
          habitat: sample.habitat,
          client: sample.client,
          biologistId: sample.biologistId,
          remarks: sample.remarks,
          completed: sample.completed,
          sampleType: sample.sampleType,
          sampleMarking: sample.sampleMarking,
          receiveId: referenceId, // Update with auto-generated Reference ID
          analyzedDate: sample.analyzedDate,
          deviceId: deviceId,
          createdAt: sample.createdAt,
          updatedAt: DateTime.now(),
          synced: true,
        );
        await _sampleDao.updateSample(updatedSample);
      }

      return docRef.id;
    } catch (e) {
      print('Error uploading sample: $e');
      return null;
    }
  }

  /// Helper method to resolve Firebase orderId to local orderId
  /// Firebase orderIds can be either integers (from mobile) or Firebase document IDs (from web)
  Future<int?> _resolveOrderId(dynamic firebaseOrderId) async {
    if (firebaseOrderId == null) return null;

    // If it's already an integer, return it
    if (firebaseOrderId is int) return firebaseOrderId;

    // If it's a string that can be parsed as integer, return the integer
    if (firebaseOrderId is String) {
      final intValue = int.tryParse(firebaseOrderId);
      if (intValue != null) return intValue;

      // It's a Firebase document ID string - find the local order with this firebaseId
      final allOrders = await _orderDao.getAllOrders();
      final matchingOrder = allOrders.where((o) => o.firebaseId == firebaseOrderId).firstOrNull;
      if (matchingOrder != null) {
        print('Resolved Firebase orderId $firebaseOrderId to local orderId ${matchingOrder.id}');
        return matchingOrder.id;
      } else {
        print('Warning: Could not find local order for Firebase orderId: $firebaseOrderId');
        return null;
      }
    }

    return null;
  }

  /// Get all samples from Firebase for a specimen type
  /// Returns samples with raw Firebase data for orderId resolution
  Future<List<Map<String, dynamic>>> _getSamplesRawFromFirebase({String? specimenType}) async {
    try {
      Query query = _samplesRef;

      if (specimenType != null) {
        query = query.where('sampleType', isEqualTo: specimenType);
      }

      final snapshot = await query.orderBy('createdAt', descending: true).get();

      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['_firebaseDocId'] = doc.id; // Store document ID
        return data;
      }).toList();
    } catch (e) {
      print('Error getting samples from Firebase: $e');
      return [];
    }
  }

  /// Get all samples from Firebase for a specimen type
  Future<List<Sample>> getSamplesFromFirebase({String? specimenType}) async {
    try {
      Query query = _samplesRef;

      if (specimenType != null) {
        query = query.where('sampleType', isEqualTo: specimenType);
      }

      final snapshot = await query.orderBy('createdAt', descending: true).get();

      return snapshot.docs.map((doc) {
        return Sample.fromFirestore(
          doc.data() as Map<String, dynamic>,
          doc.id,
        );
      }).toList();
    } catch (e) {
      print('Error getting samples from Firebase: $e');
      return [];
    }
  }

  /// Get all orders from Firebase
  Future<List<OrderInfo>> getOrdersFromFirebase({String? specimenType}) async {
    try {
      Query query = _ordersRef;

      if (specimenType != null) {
        query = query.where('specimenType', isEqualTo: specimenType);
      }

      final snapshot = await query.orderBy('createdAt', descending: true).get();

      return snapshot.docs.map((doc) {
        return OrderInfo.fromFirestore(
          doc.data() as Map<String, dynamic>,
          doc.id,
        );
      }).toList();
    } catch (e) {
      print('Error getting orders from Firebase: $e');
      return [];
    }
  }

  /// Sync all samples from Firebase to local database
  Future<int> syncSamplesToLocal({String? specimenType}) async {
    try {
      final rawSamples = await _getSamplesRawFromFirebase(specimenType: specimenType);
      int syncedCount = 0;

      for (final rawData in rawSamples) {
        final firebaseDocId = rawData['_firebaseDocId'] as String;

        // Parse sample from Firestore
        final sample = Sample.fromFirestore(rawData, firebaseDocId);

        // Check if sample already exists locally by Firebase ID
        final existingSamples = await _sampleDao.getAllSamples();
        var existing = existingSamples.where((s) => s.firebaseId == sample.firebaseId).firstOrNull;

        // CRITICAL FIX: If not found by firebaseId, also check by sample marking + type
        // This handles cases where local sample hasn't been assigned firebaseId yet
        if (existing == null) {
          existing = existingSamples.where((s) {
            return s.sampleMarking == sample.sampleMarking &&
                   s.sampleType == sample.sampleType &&
                   s.firebaseId == null; // Only match if it doesn't have a firebaseId yet
          }).firstOrNull;

          if (existing != null) {
            print('Found local sample without firebaseId, linking: ${sample.sampleMarking}');
          }
        }

        // CRITICAL FIX: Resolve Firebase orderId to local orderId
        // Web-created samples have orderId as Firebase document ID string
        // We need to find the matching local order and use its local ID
        final firebaseOrderId = rawData['orderId'];
        final localOrderId = await _resolveOrderId(firebaseOrderId);

        // CRITICAL: Skip orphaned samples (samples with orderId that doesn't exist in local orders)
        // Firebase is the master - if a sample references an order that doesn't exist locally, it's orphaned
        if (localOrderId == null && firebaseOrderId != null) {
          print('Skipping orphaned sample ${sample.sampleMarking} (${sample.firebaseId}) - references non-existent order ${firebaseOrderId}');
          continue; // Skip this sample, don't sync it
        }

        if (existing == null) {
          // Insert new sample only if it's truly not in local database
          final newSample = Sample(
            firebaseId: sample.firebaseId,
            orderId: localOrderId,
            stationId: sample.stationId,
            date: sample.date,
            lat: sample.lat,
            lon: sample.lon,
            habitat: sample.habitat,
            client: sample.client,
            biologistId: sample.biologistId,
            remarks: sample.remarks,
            completed: sample.completed,
            sampleType: sample.sampleType,
            sampleMarking: sample.sampleMarking,
            receiveId: sample.receiveId,
            analyzedDate: sample.analyzedDate,
            deviceId: sample.deviceId,
            createdAt: sample.createdAt,
            updatedAt: sample.updatedAt,
            synced: true,
          );
          await _sampleDao.insertSample(newSample);
          syncedCount++;
        } else {
          // If existing sample doesn't have firebaseId, always update to link it
          final needsFirebaseIdLink = existing.firebaseId == null;

          // Update existing sample if it needs Firebase ID link OR if Firebase version is newer
          bool shouldUpdate = needsFirebaseIdLink;
          if (!shouldUpdate && sample.updatedAt != null && existing.updatedAt != null) {
            shouldUpdate = sample.updatedAt!.isAfter(existing.updatedAt!);
          }

          if (shouldUpdate) {
            final updatedSample = Sample(
              id: existing.id, // Keep local ID
              firebaseId: sample.firebaseId,
              orderId: localOrderId, // Use resolved local orderId
              stationId: sample.stationId,
              date: sample.date,
              lat: sample.lat,
              lon: sample.lon,
              habitat: sample.habitat,
              client: sample.client,
              biologistId: sample.biologistId,
              remarks: sample.remarks,
              completed: sample.completed,
              sampleType: sample.sampleType,
              sampleMarking: sample.sampleMarking,
              receiveId: sample.receiveId,
              analyzedDate: sample.analyzedDate,
              deviceId: sample.deviceId,
              createdAt: sample.createdAt,
              updatedAt: sample.updatedAt,
              synced: true,
            );
            await _sampleDao.updateSample(updatedSample);
            syncedCount++;
          }
        }
      }

      print('Synced $syncedCount samples from Firebase to local database');
      return syncedCount;
    } catch (e) {
      print('Error syncing samples to local: $e');
      return 0;
    }
  }

  /// Sync all orders from Firebase to local database
  Future<int> syncOrdersToLocal({String? specimenType}) async {
    try {
      final firebaseOrders = await getOrdersFromFirebase(specimenType: specimenType);
      int syncedCount = 0;

      for (final order in firebaseOrders) {
        // Check if order already exists locally by Firebase ID
        final existingOrders = await _orderDao.getAllOrders();
        var existing = existingOrders.where((o) => o.firebaseId == order.firebaseId).firstOrNull;

        // CRITICAL FIX: If not found by firebaseId, also check by client name + specimen type
        // This handles cases where local order hasn't been assigned firebaseId yet
        if (existing == null) {
          existing = existingOrders.where((o) {
            return o.clientName == order.clientName &&
                   o.specimenType == order.specimenType &&
                   o.firebaseId == null; // Only match if it doesn't have a firebaseId yet
          }).firstOrNull;

          if (existing != null) {
            print('Found local order without firebaseId, linking: ${order.clientName}');
          }
        }

        if (existing == null) {
          // Insert new order only if it's truly not in local database
          await _orderDao.insertOrder(order);
          syncedCount++;
        } else {
          // If existing order doesn't have firebaseId, always update to link it
          final needsFirebaseIdLink = existing.firebaseId == null;

          // Update existing order if it needs Firebase ID link OR if Firebase version is newer
          bool shouldUpdate = needsFirebaseIdLink;
          if (!shouldUpdate && order.updatedAt != null && existing.updatedAt != null) {
            shouldUpdate = order.updatedAt!.isAfter(existing.updatedAt!);
          }

          if (shouldUpdate) {
            // Merge strategy: Preserve local values if Firebase values are null/empty
            final updatedOrder = OrderInfo(
              id: existing.id, // Keep local ID
              firebaseId: order.firebaseId,
              clientName: order.clientName,
              clientAddress: order.clientAddress ?? existing.clientAddress,
              specimenType: order.specimenType,
              numberOfSamples: order.numberOfSamples ?? existing.numberOfSamples,
              numberOfReplicates: order.numberOfReplicates ?? existing.numberOfReplicates,
              dateReceived: order.dateReceived ?? existing.dateReceived,
              dateAnalysis: order.dateAnalysis ?? existing.dateAnalysis,
              gearUsed: order.gearUsed ?? existing.gearUsed,
              areaOfGrab: order.areaOfGrab ?? existing.areaOfGrab, // Preserve local value
              sieveSize: order.sieveSize ?? existing.sieveSize,
              netDiameter: order.netDiameter ?? existing.netDiameter,
              netMesh: order.netMesh ?? existing.netMesh,
              towType: order.towType ?? existing.towType,
              filteredVolume: order.filteredVolume ?? existing.filteredVolume, // Preserve local value
              methodAnalysis: order.methodAnalysis ?? existing.methodAnalysis,
              reportNo: order.reportNo ?? existing.reportNo,
              referenceId: order.referenceId ?? existing.referenceId,
              comments: order.comments ?? existing.comments,
              sammNo: order.sammNo ?? existing.sammNo,
              authorizedBy: order.authorizedBy ?? existing.authorizedBy,
              institution: order.institution ?? existing.institution,
              sampleDescription: order.sampleDescription ?? existing.sampleDescription,
              towDistance: order.towDistance ?? existing.towDistance,
              sampleVolume: order.sampleVolume ?? existing.sampleVolume,
              srCellVolume: order.srCellVolume ?? existing.srCellVolume,
              srCellsCounted: order.srCellsCounted ?? existing.srCellsCounted,
              deviceId: order.deviceId ?? existing.deviceId,
              createdAt: order.createdAt ?? existing.createdAt,
              updatedAt: order.updatedAt ?? existing.updatedAt,
              synced: true,
            );
            await _orderDao.updateOrder(updatedOrder);
            syncedCount++;
          }
        }
      }

      print('Synced $syncedCount orders from Firebase to local database');
      return syncedCount;
    } catch (e) {
      print('Error syncing orders to local: $e');
      return 0;
    }
  }

  /// Get real-time stream of samples from Firebase
  /// Returns a Stream that emits updated sample lists whenever changes occur in Firestore
  Stream<List<Sample>> getSamplesStream({String? specimenType}) {
    try {
      Query query = _samplesRef;

      if (specimenType != null) {
        query = query.where('sampleType', isEqualTo: specimenType);
      }

      return query.orderBy('createdAt', descending: true).snapshots().map((snapshot) {
        return snapshot.docs.map((doc) {
          return Sample.fromFirestore(
            doc.data() as Map<String, dynamic>,
            doc.id,
          );
        }).toList();
      });
    } catch (e) {
      print('Error creating samples stream: $e');
      return Stream.value([]); // Return empty stream on error
    }
  }

  /// Get real-time stream of orders from Firebase
  /// Returns a Stream that emits updated order lists whenever changes occur in Firestore
  Stream<List<OrderInfo>> getOrdersStream({String? specimenType}) {
    try {
      Query query = _ordersRef;

      if (specimenType != null) {
        query = query.where('specimenType', isEqualTo: specimenType);
      }

      return query.orderBy('createdAt', descending: true).snapshots().map((snapshot) {
        return snapshot.docs.map((doc) {
          return OrderInfo.fromFirestore(
            doc.data() as Map<String, dynamic>,
            doc.id,
          );
        }).toList();
      });
    } catch (e) {
      print('Error creating orders stream: $e');
      return Stream.value([]); // Return empty stream on error
    }
  }

  /// Process incoming sample update from real-time stream
  /// Merges Firebase data with local database using timestamp-based conflict resolution
  /// NOTE: Real-time updates may have unresolved orderIds (null) if created from web.
  /// Full sync (syncSamplesToLocal) will resolve these properly. Real-time stream is
  /// primarily for triggering UI updates.
  Future<bool> handleSampleUpdate(Sample sample) async {
    try {
      final existingSamples = await _sampleDao.getAllSamples();
      final existing = existingSamples.where((s) => s.firebaseId == sample.firebaseId).firstOrNull;

      if (existing == null) {
        // CRITICAL FIX: Check if this sample was just created by this device
        // to prevent race condition duplicates
        final now = DateTime.now();

        // Look for recently created local samples (within last 10 seconds) with matching marking/type
        final recentLocal = existingSamples.where((s) {
          if (s.sampleMarking != sample.sampleMarking || s.sampleType != sample.sampleType) {
            return false;
          }
          if (s.createdAt == null) return false;
          final age = now.difference(s.createdAt!);
          return age.inSeconds < 10 && s.firebaseId == null;
        }).firstOrNull;

        if (recentLocal != null) {
          // This is likely the same sample just uploaded - update it instead of inserting
          final updatedSample = Sample(
            id: recentLocal.id, // Keep local ID
            firebaseId: sample.firebaseId, // Set Firebase ID
            orderId: sample.orderId ?? recentLocal.orderId,
            stationId: sample.stationId,
            date: sample.date,
            lat: sample.lat,
            lon: sample.lon,
            habitat: sample.habitat,
            client: sample.client,
            biologistId: sample.biologistId,
            remarks: sample.remarks,
            completed: sample.completed,
            sampleType: sample.sampleType,
            sampleMarking: sample.sampleMarking,
            receiveId: sample.receiveId,
            analyzedDate: sample.analyzedDate,
            deviceId: sample.deviceId,
            createdAt: sample.createdAt,
            updatedAt: sample.updatedAt,
            synced: true,
          );
          await _sampleDao.updateSample(updatedSample);
          print('Linked local sample to Firebase ID for: ${sample.sampleMarking}');
          return true;
        }

        // CRITICAL: Validate that sample has a valid orderId before inserting
        // Skip orphaned samples (samples without an order)
        if (sample.orderId == null) {
          print('Skipping orphaned sample ${sample.sampleMarking} from real-time stream - no orderId');
          return false;
        }

        // Insert new sample only if it's truly from another source
        await _sampleDao.insertSample(sample);
        print('Inserted new sample from Firebase: ${sample.stationId}');
        return true;
      } else {
        // Update if Firebase version is newer
        if (sample.updatedAt != null && existing.updatedAt != null) {
          if (sample.updatedAt!.isAfter(existing.updatedAt!)) {
            final updatedSample = Sample(
              id: existing.id, // Keep local ID
              firebaseId: sample.firebaseId,
              orderId: sample.orderId ?? existing.orderId, // Preserve existing orderId if new one is null
              stationId: sample.stationId,
              date: sample.date,
              lat: sample.lat,
              lon: sample.lon,
              habitat: sample.habitat,
              client: sample.client,
              biologistId: sample.biologistId,
              remarks: sample.remarks,
              completed: sample.completed,
              sampleType: sample.sampleType,
              sampleMarking: sample.sampleMarking,
              receiveId: sample.receiveId,
              analyzedDate: sample.analyzedDate,
              deviceId: sample.deviceId,
              createdAt: sample.createdAt,
              updatedAt: sample.updatedAt,
              synced: true,
            );
            await _sampleDao.updateSample(updatedSample);
            print('Updated sample from Firebase: ${sample.stationId}');
            return true;
          }
        }
      }
      return false;
    } catch (e) {
      print('Error handling sample update: $e');
      return false;
    }
  }

  /// Process incoming order update from real-time stream
  /// Merges Firebase data with local database using timestamp-based conflict resolution
  Future<bool> handleOrderUpdate(OrderInfo order) async {
    try {
      final existingOrders = await _orderDao.getAllOrders();
      final existing = existingOrders.where((o) => o.firebaseId == order.firebaseId).firstOrNull;

      if (existing == null) {
        // CRITICAL FIX: Check if this order was just created by this device
        // to prevent race condition duplicates
        final deviceId = await _getDeviceId();
        final now = DateTime.now();

        // Look for recently created local orders (within last 10 seconds) with matching client/type
        final recentLocal = existingOrders.where((o) {
          if (o.clientName != order.clientName || o.specimenType != order.specimenType) {
            return false;
          }
          if (o.createdAt == null) return false;
          final age = now.difference(o.createdAt!);
          return age.inSeconds < 10 && o.firebaseId == null;
        }).firstOrNull;

        if (recentLocal != null) {
          // This is likely the same order just uploaded - update it instead of inserting
          // Merge strategy: Preserve local values if Firebase values are null/empty
          final updatedOrder = OrderInfo(
            id: recentLocal.id, // Keep local ID
            firebaseId: order.firebaseId, // Set Firebase ID
            clientName: order.clientName,
            clientAddress: order.clientAddress ?? recentLocal.clientAddress,
            specimenType: order.specimenType,
            numberOfSamples: order.numberOfSamples ?? recentLocal.numberOfSamples,
            numberOfReplicates: order.numberOfReplicates ?? recentLocal.numberOfReplicates,
            dateReceived: order.dateReceived ?? recentLocal.dateReceived,
            dateAnalysis: order.dateAnalysis ?? recentLocal.dateAnalysis,
            gearUsed: order.gearUsed ?? recentLocal.gearUsed,
            areaOfGrab: order.areaOfGrab ?? recentLocal.areaOfGrab, // Preserve local value
            sieveSize: order.sieveSize ?? recentLocal.sieveSize,
            netDiameter: order.netDiameter ?? recentLocal.netDiameter,
            netMesh: order.netMesh ?? recentLocal.netMesh,
            towType: order.towType ?? recentLocal.towType,
            filteredVolume: order.filteredVolume ?? recentLocal.filteredVolume, // Preserve local value
            methodAnalysis: order.methodAnalysis ?? recentLocal.methodAnalysis,
            reportNo: order.reportNo ?? recentLocal.reportNo,
            referenceId: order.referenceId ?? recentLocal.referenceId,
            comments: order.comments ?? recentLocal.comments,
            sammNo: order.sammNo ?? recentLocal.sammNo,
            authorizedBy: order.authorizedBy ?? recentLocal.authorizedBy,
            institution: order.institution ?? recentLocal.institution,
            sampleDescription: order.sampleDescription ?? recentLocal.sampleDescription,
            towDistance: order.towDistance ?? recentLocal.towDistance,
            sampleVolume: order.sampleVolume ?? recentLocal.sampleVolume,
            srCellVolume: order.srCellVolume ?? recentLocal.srCellVolume,
            srCellsCounted: order.srCellsCounted ?? recentLocal.srCellsCounted,
            deviceId: order.deviceId ?? recentLocal.deviceId,
            createdAt: order.createdAt ?? recentLocal.createdAt,
            updatedAt: order.updatedAt ?? recentLocal.updatedAt,
            synced: true,
          );
          await _orderDao.updateOrder(updatedOrder);
          print('Linked local order to Firebase ID for: ${order.clientName}');
          return true;
        }

        // Insert new order only if it's truly from another source
        await _orderDao.insertOrder(order);
        print('Inserted new order from Firebase: ${order.clientName}');
        return true;
      } else {
        // Update if Firebase version is newer
        if (order.updatedAt != null && existing.updatedAt != null) {
          if (order.updatedAt!.isAfter(existing.updatedAt!)) {
            // Merge strategy: Preserve local values if Firebase values are null/empty
            final updatedOrder = OrderInfo(
              id: existing.id, // Keep local ID
              firebaseId: order.firebaseId,
              clientName: order.clientName,
              clientAddress: order.clientAddress ?? existing.clientAddress,
              specimenType: order.specimenType,
              numberOfSamples: order.numberOfSamples ?? existing.numberOfSamples,
              numberOfReplicates: order.numberOfReplicates ?? existing.numberOfReplicates,
              dateReceived: order.dateReceived ?? existing.dateReceived,
              dateAnalysis: order.dateAnalysis ?? existing.dateAnalysis,
              gearUsed: order.gearUsed ?? existing.gearUsed,
              areaOfGrab: order.areaOfGrab ?? existing.areaOfGrab, // Preserve local value
              sieveSize: order.sieveSize ?? existing.sieveSize,
              netDiameter: order.netDiameter ?? existing.netDiameter,
              netMesh: order.netMesh ?? existing.netMesh,
              towType: order.towType ?? existing.towType,
              filteredVolume: order.filteredVolume ?? existing.filteredVolume, // Preserve local value
              methodAnalysis: order.methodAnalysis ?? existing.methodAnalysis,
              reportNo: order.reportNo ?? existing.reportNo,
              referenceId: order.referenceId ?? existing.referenceId,
              comments: order.comments ?? existing.comments,
              sammNo: order.sammNo ?? existing.sammNo,
              authorizedBy: order.authorizedBy ?? existing.authorizedBy,
              institution: order.institution ?? existing.institution,
              sampleDescription: order.sampleDescription ?? existing.sampleDescription,
              towDistance: order.towDistance ?? existing.towDistance,
              sampleVolume: order.sampleVolume ?? existing.sampleVolume,
              srCellVolume: order.srCellVolume ?? existing.srCellVolume,
              srCellsCounted: order.srCellsCounted ?? existing.srCellsCounted,
              deviceId: order.deviceId ?? existing.deviceId,
              createdAt: order.createdAt,
              updatedAt: order.updatedAt,
              synced: true,
            );
            await _orderDao.updateOrder(updatedOrder);
            print('Updated order from Firebase: ${order.clientName}');
            return true;
          }
        }
      }
      return false;
    } catch (e) {
      print('Error handling order update: $e');
      return false;
    }
  }

  /// Detect and delete local samples that were deleted in Firebase
  /// Firebase is the master - if a sample exists locally with firebaseId but is not in Firebase, delete it
  Future<void> detectAndDeleteRemovedSamples(List<Sample> firebaseSamples, {String? specimenType}) async {
    try {
      // Get all local samples for this specimen type that have firebaseId
      final localSamples = await _sampleDao.getAllSamples();
      final localSamplesWithFirebaseId = localSamples.where((s) {
        if (s.firebaseId == null) return false;
        if (specimenType != null && s.sampleType != specimenType) return false;
        return true;
      }).toList();

      // Create a set of Firebase IDs from the Firebase snapshot
      final firebaseIds = firebaseSamples.map((s) => s.firebaseId).whereType<String>().toSet();

      // Find local samples that are not in Firebase anymore
      final samplesToDelete = localSamplesWithFirebaseId.where((local) {
        return !firebaseIds.contains(local.firebaseId);
      }).toList();

      // Delete them from local database
      for (final sample in samplesToDelete) {
        if (sample.id != null) {
          await _sampleDao.deleteSample(sample.id!);
          print('Deleted local sample ${sample.sampleMarking} (ID: ${sample.id}) - removed from Firebase');
        }
      }

      if (samplesToDelete.isNotEmpty) {
        print('Deleted ${samplesToDelete.length} samples that were removed from Firebase');
      }
    } catch (e) {
      print('Error detecting and deleting removed samples: $e');
    }
  }

  /// Detect and delete local orders that were deleted in Firebase
  /// Firebase is the master - if an order exists locally with firebaseId but is not in Firebase, delete it
  /// Also cascade delete all samples associated with the deleted order
  Future<void> detectAndDeleteRemovedOrders(List<OrderInfo> firebaseOrders, {String? specimenType}) async {
    try {
      // Get all local orders for this specimen type that have firebaseId
      final localOrders = await _orderDao.getAllOrders();
      final localOrdersWithFirebaseId = localOrders.where((o) {
        if (o.firebaseId == null) return false;
        if (specimenType != null && o.specimenType != specimenType) return false;
        return true;
      }).toList();

      // Create a set of Firebase IDs from the Firebase snapshot
      final firebaseIds = firebaseOrders.map((o) => o.firebaseId).whereType<String>().toSet();

      // Find local orders that are not in Firebase anymore
      final ordersToDelete = localOrdersWithFirebaseId.where((local) {
        return !firebaseIds.contains(local.firebaseId);
      }).toList();

      // Delete them from local database along with their samples (cascade)
      for (final order in ordersToDelete) {
        if (order.id != null) {
          // First, delete all samples associated with this order
          final allSamples = await _sampleDao.getAllSamples();
          final samplesOfOrder = allSamples.where((s) => s.orderId == order.id).toList();

          for (final sample in samplesOfOrder) {
            if (sample.id != null) {
              await _sampleDao.deleteSample(sample.id!);
              print('Deleted sample ${sample.sampleMarking} (cascade from order deletion)');
            }
          }

          // Then delete the order
          await _orderDao.deleteOrder(order.id!);
          print('Deleted local order ${order.clientName} (ID: ${order.id}) - removed from Firebase');
        }
      }

      if (ordersToDelete.isNotEmpty) {
        print('Deleted ${ordersToDelete.length} orders that were removed from Firebase');
      }
    } catch (e) {
      print('Error detecting and deleting removed orders: $e');
    }
  }

  // ========== TAXONOMY SYNC METHODS ==========

  /// Get real-time stream of taxonomies from Firebase for a specimen type
  Stream<List<Taxon>> getTaxonomiesStream({String? specimenType}) {
    if (specimenType == null) {
      // Return empty stream if no specimen type specified
      return Stream.value([]);
    }

    return _firestore
        .collection('taxonomies')
        .doc(specimenType)
        .collection('taxa')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
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

  /// Get all taxonomies from Firebase for a specimen type
  Future<List<Taxon>> getTaxonomiesFromFirebase({String? specimenType}) async {
    try {
      if (specimenType == null) {
        print('No specimen type specified for taxonomy sync');
        return [];
      }

      final snapshot = await _firestore
          .collection('taxonomies')
          .doc(specimenType)
          .collection('taxa')
          .get();

      final taxa = snapshot.docs.map((doc) {
        final data = doc.data();
        return Taxon(
          id: int.tryParse(doc.id),
          parentId: data['parentId'] as int?,
          name: data['name'] as String,
          rank: data['rank'] as String?,
          notes: data['notes'] as String?,
          specimenType: data['specimenType'] as String?,
        );
      }).toList();

      print('Fetched ${taxa.length} taxa from Firebase for $specimenType');
      return taxa;
    } catch (e) {
      print('Error getting taxonomies from Firebase: $e');
      return [];
    }
  }

  /// Sync taxonomies from Firebase to local database
  Future<int> syncTaxonomiesToLocal({String? specimenType}) async {
    try {
      if (specimenType == null) {
        print('No specimen type specified for taxonomy sync');
        return 0;
      }

      print('Syncing taxonomies for $specimenType from Firebase to local...');

      // Get all taxonomies from Firebase
      final firebaseTaxa = await getTaxonomiesFromFirebase(specimenType: specimenType);

      // Clear existing local taxa for this specimen type
      await _taxonDao.deleteAllTaxaByType(specimenType);
      print('Cleared local taxa for $specimenType');

      // Insert all taxa from Firebase
      for (final taxon in firebaseTaxa) {
        await _taxonDao.insertTaxon(taxon);
      }

      print('Synced ${firebaseTaxa.length} taxa for $specimenType to local database');
      return firebaseTaxa.length;
    } catch (e) {
      print('Error syncing taxonomies to local: $e');
      return 0;
    }
  }

  /// Handle taxonomy update from real-time stream
  Future<void> handleTaxonomyUpdate(Taxon taxon) async {
    try {
      // Check if taxon exists locally
      final existing = await _taxonDao.getTaxonById(taxon.id!);

      if (existing == null) {
        // Insert new taxon
        await _taxonDao.insertTaxon(taxon);
        print('Inserted new taxon from Firebase: ${taxon.name}');
      } else {
        // Update existing taxon
        await _taxonDao.updateTaxon(taxon);
        print('Updated taxon from Firebase: ${taxon.name}');
      }
    } catch (e) {
      print('Error handling taxonomy update: $e');
    }
  }

  /// Sync all taxonomies for all specimen types
  Future<int> syncAllTaxonomies() async {
    int totalCount = 0;
    final specimenTypes = ['Macrobenthos', 'Zooplankton', 'Phytoplankton'];

    for (final specimenType in specimenTypes) {
      try {
        final count = await syncTaxonomiesToLocal(specimenType: specimenType);
        totalCount += count;
      } catch (e) {
        print('Error syncing $specimenType taxonomy: $e');
      }
    }

    return totalCount;
  }

  /// Recalculate and update numberOfSamples for all orders based on actual sample count
  /// This ensures the order's numberOfSamples field matches the actual count in local database
  Future<void> recalculateSampleCounts() async {
    try {
      final allOrders = await _orderDao.getAllOrders();
      final allSamples = await _sampleDao.getAllSamples();

      for (final order in allOrders) {
        if (order.id == null) continue;

        // Count samples for this order
        final samplesForOrder = allSamples.where((s) => s.orderId == order.id).length;

        // Update order if count doesn't match
        if (order.numberOfSamples != samplesForOrder) {
          print('Updating numberOfSamples for order ${order.clientName}: ${order.numberOfSamples} -> $samplesForOrder');

          final updatedOrder = OrderInfo(
            id: order.id,
            firebaseId: order.firebaseId,
            clientName: order.clientName,
            clientAddress: order.clientAddress,
            specimenType: order.specimenType,
            numberOfSamples: samplesForOrder, // Update with actual count
            numberOfReplicates: order.numberOfReplicates,
            dateReceived: order.dateReceived,
            dateAnalysis: order.dateAnalysis,
            gearUsed: order.gearUsed,
            areaOfGrab: order.areaOfGrab,
            sieveSize: order.sieveSize,
            netDiameter: order.netDiameter,
            netMesh: order.netMesh,
            towType: order.towType,
            filteredVolume: order.filteredVolume,
            methodAnalysis: order.methodAnalysis,
            reportNo: order.reportNo,
            referenceId: order.referenceId,
            comments: order.comments,
            sammNo: order.sammNo,
            authorizedBy: order.authorizedBy,
            institution: order.institution,
            sampleDescription: order.sampleDescription,
            towDistance: order.towDistance,
            sampleVolume: order.sampleVolume,
            srCellVolume: order.srCellVolume,
            srCellsCounted: order.srCellsCounted,
            deviceId: order.deviceId,
            createdAt: order.createdAt,
            updatedAt: DateTime.now(),
            synced: order.synced,
          );
          await _orderDao.updateOrder(updatedOrder);
        }
      }

      print('Sample count recalculation complete');
    } catch (e) {
      print('Error recalculating sample counts: $e');
    }
  }
}
