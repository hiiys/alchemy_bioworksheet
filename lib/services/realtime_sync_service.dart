import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import '../data/models.dart';
import 'sample_sync_service.dart';

/// Service to manage real-time synchronization of Orders and Samples
/// Handles automatic sync when app opens and keeps all devices synchronized
class RealtimeSyncService {
  final SampleSyncService _sampleSyncService = SampleSyncService();
  final Connectivity _connectivity = Connectivity();

  // Stream subscriptions
  StreamSubscription<List<Sample>>? _samplesSubscription;
  StreamSubscription<List<OrderInfo>>? _ordersSubscription;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  // Callbacks for notifying about data changes
  Function(List<Sample>)? onSamplesUpdated;
  Function(List<OrderInfo>)? onOrdersUpdated;
  Function(bool)? onConnectionChanged;
  Function(String)? onSyncStatusChanged;

  // Sync state
  bool _isOnline = true;
  bool _isSyncing = false;
  String? _currentSpecimenType;

  bool get isOnline => _isOnline;
  bool get isSyncing => _isSyncing;

  /// Initialize real-time sync service
  /// Should be called when app starts
  Future<void> initialize({String? specimenType}) async {
    _currentSpecimenType = specimenType;

    // Check initial connectivity
    final connectivityResult = await _connectivity.checkConnectivity();
    _isOnline = connectivityResult.isNotEmpty &&
                !connectivityResult.contains(ConnectivityResult.none);

    print('RealtimeSyncService initialized. Online: $_isOnline');

    // Start monitoring connectivity
    _startConnectivityMonitoring();

    // Start real-time sync if online
    if (_isOnline) {
      await startRealtimeSync(specimenType: specimenType);
    }
  }

  /// Start monitoring network connectivity
  void _startConnectivityMonitoring() {
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen((result) {
      final wasOnline = _isOnline;
      _isOnline = result.isNotEmpty && !result.contains(ConnectivityResult.none);

      print('Connectivity changed. Online: $_isOnline');
      onConnectionChanged?.call(_isOnline);

      // If we just came online, start sync
      if (!wasOnline && _isOnline) {
        print('Device came online, starting real-time sync...');
        startRealtimeSync(specimenType: _currentSpecimenType);
      }

      // If we went offline, stop sync
      if (wasOnline && !_isOnline) {
        print('Device went offline, stopping real-time sync...');
        stopRealtimeSync();
      }
    });
  }

  /// Start real-time synchronization with Firebase
  Future<void> startRealtimeSync({String? specimenType}) async {
    if (_isSyncing) {
      print('Real-time sync already running');
      return;
    }

    if (!_isOnline) {
      print('Cannot start real-time sync: device is offline');
      return;
    }

    try {
      _isSyncing = true;
      _currentSpecimenType = specimenType;
      onSyncStatusChanged?.call('Syncing...');

      print('Starting real-time sync for specimen type: ${specimenType ?? "all"}');

      // Step 1: Perform initial one-time sync to get all existing data
      await _performInitialSync(specimenType: specimenType);

      // Step 2: Subscribe to real-time streams for ongoing updates
      _subscribeToSamplesStream(specimenType: specimenType);
      _subscribeToOrdersStream(specimenType: specimenType);

      onSyncStatusChanged?.call('Synced');
      print('Real-time sync started successfully');
    } catch (e) {
      print('Error starting real-time sync: $e');
      _isSyncing = false;
      onSyncStatusChanged?.call('Sync error');
      rethrow;
    }
  }

  /// Perform initial sync to download all existing data from Firebase
  Future<void> _performInitialSync({String? specimenType}) async {
    try {
      print('Performing initial sync...');

      // Sync orders first
      final orderCount = await _sampleSyncService.syncOrdersToLocal(
        specimenType: specimenType,
      );
      print('Initial sync: $orderCount orders synced');

      // Then sync samples
      final sampleCount = await _sampleSyncService.syncSamplesToLocal(
        specimenType: specimenType,
      );
      print('Initial sync: $sampleCount samples synced');

      print('Initial sync completed');
    } catch (e) {
      print('Error during initial sync: $e');
      rethrow;
    }
  }

  /// Subscribe to real-time Samples stream
  void _subscribeToSamplesStream({String? specimenType}) {
    // Cancel existing subscription if any
    _samplesSubscription?.cancel();

    print('Subscribing to samples stream...');

    _samplesSubscription = _sampleSyncService
        .getSamplesStream(specimenType: specimenType)
        .listen(
      (samples) async {
        print('Received ${samples.length} samples from Firebase stream');

        // Process each sample update
        for (final sample in samples) {
          await _sampleSyncService.handleSampleUpdate(sample);
        }

        // CRITICAL: Detect and delete local samples that were deleted in Firebase
        // Firebase is the master - if a sample exists locally with firebaseId but is not in Firebase, delete it
        await _sampleSyncService.detectAndDeleteRemovedSamples(samples, specimenType: specimenType);

        // Notify listeners
        onSamplesUpdated?.call(samples);
      },
      onError: (error) {
        print('Error in samples stream: $error');
        onSyncStatusChanged?.call('Sync error');
      },
    );
  }

  /// Subscribe to real-time Orders stream
  void _subscribeToOrdersStream({String? specimenType}) {
    // Cancel existing subscription if any
    _ordersSubscription?.cancel();

    print('Subscribing to orders stream...');

    _ordersSubscription = _sampleSyncService
        .getOrdersStream(specimenType: specimenType)
        .listen(
      (orders) async {
        print('Received ${orders.length} orders from Firebase stream');

        // Process each order update
        for (final order in orders) {
          await _sampleSyncService.handleOrderUpdate(order);
        }

        // CRITICAL: Detect and delete local orders that were deleted in Firebase
        // Firebase is the master - if an order exists locally with firebaseId but is not in Firebase, delete it
        await _sampleSyncService.detectAndDeleteRemovedOrders(orders, specimenType: specimenType);

        // Notify listeners
        onOrdersUpdated?.call(orders);
      },
      onError: (error) {
        print('Error in orders stream: $error');
        onSyncStatusChanged?.call('Sync error');
      },
    );
  }

  /// Stop real-time synchronization
  void stopRealtimeSync() {
    print('Stopping real-time sync...');

    _samplesSubscription?.cancel();
    _samplesSubscription = null;

    _ordersSubscription?.cancel();
    _ordersSubscription = null;

    _isSyncing = false;
    onSyncStatusChanged?.call('Offline');

    print('Real-time sync stopped');
  }

  /// Change specimen type filter and restart sync
  Future<void> changeSpecimenType(String? specimenType) async {
    if (_currentSpecimenType == specimenType) {
      return; // No change
    }

    print('Changing specimen type to: ${specimenType ?? "all"}');
    _currentSpecimenType = specimenType;

    // Restart sync with new filter
    stopRealtimeSync();
    if (_isOnline) {
      await startRealtimeSync(specimenType: specimenType);
    }
  }

  /// Manually trigger a full sync
  Future<void> forceSync({String? specimenType}) async {
    if (!_isOnline) {
      print('Cannot force sync: device is offline');
      throw Exception('Device is offline');
    }

    try {
      onSyncStatusChanged?.call('Syncing...');
      await _performInitialSync(specimenType: specimenType ?? _currentSpecimenType);
      onSyncStatusChanged?.call('Synced');
    } catch (e) {
      print('Error during force sync: $e');
      onSyncStatusChanged?.call('Sync error');
      rethrow;
    }
  }

  /// Upload local order to Firebase
  Future<String?> uploadOrder(OrderInfo order) async {
    if (!_isOnline) {
      print('Cannot upload order: device is offline');
      return null;
    }

    return await _sampleSyncService.uploadOrder(order);
  }

  /// Upload local sample to Firebase
  Future<String?> uploadSample(Sample sample) async {
    if (!_isOnline) {
      print('Cannot upload sample: device is offline');
      return null;
    }

    return await _sampleSyncService.uploadSample(sample);
  }

  /// Clean up resources
  void dispose() {
    print('Disposing RealtimeSyncService...');
    stopRealtimeSync();
    _connectivitySubscription?.cancel();
    _connectivitySubscription = null;
  }
}
