import 'package:flutter/material.dart';
import '../data/models.dart';
import '../data/dao/taxon_dao.dart';
import '../data/dao/sample_dao.dart';
import '../data/dao/count_dao.dart';
import '../data/dao/project_dao.dart';
import '../data/dao/rank_definition_dao.dart';
import '../data/dao/order_dao.dart';
import '../services/sample_sync_service.dart';
import '../services/realtime_sync_service.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'dart:io';

class AppState with ChangeNotifier {
  final TaxonDao _taxonDao = TaxonDao();
  final SampleDao _sampleDao = SampleDao();
  final CountDao _countDao = CountDao();
  final ProjectDao _projectDao = ProjectDao();
  final OrderDao _orderDao = OrderDao();
  final SampleSyncService _syncService = SampleSyncService();
  final RealtimeSyncService _realtimeSyncService = RealtimeSyncService();

  // Current state
  Sample? _activeSample;
  List<Taxon> _taxa = [];
  Map<int, int> _currentCounts = {}; // taxonId -> count
  List<Taxon> _currentTaxonPath = [];
  List<Sample> _samples = [];
  List<OrderInfo> _orders = [];
  ProjectInfo? _currentProject;

  // Sync state
  bool _isOnline = true;
  bool _isSyncing = false;
  String _syncStatus = 'Offline';

  // Getters
  Sample? get activeSample => _activeSample;
  List<Taxon> get taxa => _taxa;
  Map<int, int> get currentCounts => _currentCounts;
  List<Taxon> get currentTaxonPath => _currentTaxonPath;
  List<Sample> get samples => _samples;
  List<OrderInfo> get orders => _orders;
  ProjectInfo? get currentProject => _currentProject;
  bool get isOnline => _isOnline;
  bool get isSyncing => _isSyncing;
  String get syncStatus => _syncStatus;

  // Initialize app state
  Future<void> initialize() async {
    await _loadTaxa();
    await _loadSamples();
    await _loadOrders();
    await _loadMostRecentProject();

    // Try to load the last active sample
    if (_samples.isNotEmpty) {
      _activeSample = _samples.first;
      await _loadCurrentCounts();
    }

    // Initialize real-time sync service
    await _initializeRealtimeSync();

    notifyListeners();
  }

  /// Initialize real-time synchronization
  Future<void> _initializeRealtimeSync() async {
    try {
      // Set up callbacks for real-time updates
      _realtimeSyncService.onSamplesUpdated = (samples) {
        // Reload samples from local database when Firebase updates
        _loadSamples();
      };

      _realtimeSyncService.onOrdersUpdated = (orders) {
        // Reload orders from local database when Firebase updates
        _loadOrders();
      };

      _realtimeSyncService.onConnectionChanged = (isOnline) {
        _isOnline = isOnline;
        notifyListeners();
      };

      _realtimeSyncService.onSyncStatusChanged = (status) {
        _syncStatus = status;
        _isSyncing = status == 'Syncing...';
        notifyListeners();
      };

      // Start real-time sync (will also perform initial sync)
      await _realtimeSyncService.initialize();

      print('Real-time sync initialized successfully');
    } catch (e) {
      print('Error initializing real-time sync: $e');
      // Don't throw - allow app to continue without sync
    }
  }

  // Taxon management
  Future<void> _loadTaxa() async {
    if (_activeSample?.sampleType != null) {
      _taxa = await _taxonDao.getAllTaxaByType(_activeSample!.sampleType);
    } else {
      _taxa = await _taxonDao.getAllTaxa();
    }
    notifyListeners();
  }

  Future<void> reloadTaxa() async {
    await _loadTaxa();
  }

  Future<void> addTaxon(Taxon taxon) async {
    await _taxonDao.insertTaxonWithTracking(taxon);
    await _loadTaxa();
  }

  Future<void> updateTaxon(Taxon taxon) async {
    await _taxonDao.updateTaxonWithTracking(taxon);
    await _loadTaxa();
  }

  Future<void> deleteTaxon(int taxonId) async {
    await _taxonDao.deleteTaxonWithTracking(taxonId);
    await _loadTaxa();
  }

  // Sample management
  Future<void> _loadSamples() async {
    try {
      _samples = await _sampleDao.getAllSamples();
      print('Loaded ${_samples.length} samples from database');
      for (final sample in _samples) {
        print(
          'Sample: ${sample.stationId}, ID: ${sample.id}, Client: ${sample.client}',
        );
      }
      notifyListeners();
    } catch (e) {
      print('Error loading samples: $e');
      rethrow;
    }
  }

  Future<void> _loadOrders() async {
    try {
      final combined = <OrderInfo>[];
      combined.addAll(await _orderDao.getOrdersByType('Macrobenthos'));
      combined.addAll(await _orderDao.getOrdersByType('Zooplankton'));
      combined.addAll(await _orderDao.getOrdersByType('Phytoplankton'));

      // Deduplicate using a combination of firebaseId (if available) and local id
      final seen = <String>{};
      final deduped = <OrderInfo>[];

      for (final o in combined) {
        // Create unique key: prefer firebaseId, fallback to local id
        final key = o.firebaseId ?? 'local_${o.id}';
        if (!seen.contains(key)) {
          seen.add(key);
          deduped.add(o);
        }
      }

      _orders = deduped..sort((a, b) => (b.id ?? 0).compareTo(a.id ?? 0));
      notifyListeners();
    } catch (e) {
      print('Error loading orders: $e');
    }
  }

  Future<void> saveOrder(OrderInfo order) async {
    final dao = _orderDao;
    if (order.id == null) {
      // Create new order with timestamps
      final newOrder = OrderInfo(
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
        createdAt: DateTime.now(),
      );
      final orderId = await dao.insertOrder(newOrder);

      // Upload to Firebase
      final savedOrder = await dao.getOrderById(orderId);
      if (savedOrder != null) {
        try {
          await _syncService.uploadOrder(savedOrder);
          print('Order uploaded to Firebase');
        } catch (e) {
          print('Error uploading order to Firebase: $e');
        }
      }
    } else {
      await dao.updateOrder(order);
    }
    await _loadOrders();
    notifyListeners();
  }

  Future<int> getTotalCountForSample(int sampleId) async {
    return await _sampleDao.getTotalCountForSample(sampleId);
  }

  Future<void> setActiveSample(Sample sample) async {
    _activeSample = sample;
    await _loadTaxa();
    await _loadCurrentCounts();
    notifyListeners();
  }

  Future<void> createSample(Sample sample) async {
    final sampleId = await _sampleDao.insertSample(sample);
    sample = Sample(
      id: sampleId,
      stationId: sample.stationId,
      date: sample.date,
      lat: sample.lat,
      lon: sample.lon,
      habitat: sample.habitat,
      client: sample.client,
      remarks: sample.remarks,
      completed: false,
      sampleType: sample.sampleType,
    );
    _activeSample = sample;
    await _loadSamples();
    await _loadTaxa();
    await _loadCurrentCounts();
    notifyListeners();
  }

  Future<void> createSampleWithoutActivate(Sample sample) async {
    try {
      print(
        'Creating sample without activate: ${sample.stationId}, client: ${sample.client}',
      );
      final sampleId = await _sampleDao.insertSample(sample);
      print('Sample inserted with ID: $sampleId');
      await _loadSamples();
      print('Samples reloaded, total count: ${_samples.length}');
      notifyListeners();
    } catch (e) {
      print('Error creating sample: $e');
      rethrow;
    }
  }

  Future<int> createOrderAndGenerateSamples({
    required OrderInfo order,
    required String markingBase,
  }) async {
    // Create order with timestamps
    final newOrder = OrderInfo(
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
      createdAt: DateTime.now(),
    );

    final id = await _orderDao.insertOrder(newOrder);

    // Upload to Firebase
    final savedOrder = await _orderDao.getOrderById(id);
    if (savedOrder != null) {
      try {
        await _syncService.uploadOrder(savedOrder);
        print('Order uploaded to Firebase');
      } catch (e) {
        print('Error uploading order to Firebase: $e');
      }
    }

    await _loadOrders();
    notifyListeners();
    return id;
  }

  Future<List<Sample>> getSamplesByOrder(int orderId) async {
    return await _sampleDao.getSamplesByOrder(orderId);
  }

  Future<void> deleteOrder(int orderId) async {
    final samples = await _sampleDao.getSamplesByOrder(orderId);
    for (final s in samples) {
      if (s.id != null) {
        await _sampleDao.deleteSample(s.id!);
      }
    }
    await _orderDao.deleteOrder(orderId);
    await _loadOrders();
    await _loadSamples();
    notifyListeners();
  }

  Future<void> updateClientForOrder(int orderId, String? clientName) async {
    final samples = await _sampleDao.getSamplesByOrder(orderId);
    for (final s in samples) {
      final updated = Sample(
        id: s.id,
        stationId: s.stationId,
        date: s.date,
        lat: s.lat,
        lon: s.lon,
        habitat: s.habitat,
        client: (clientName == null || clientName.isEmpty) ? null : clientName,
        biologistId: s.biologistId,
        remarks: s.remarks,
        completed: s.completed,
        sampleType: s.sampleType,
        orderId: s.orderId,
        sampleMarking: s.sampleMarking,
        receiveId: s.receiveId,
        analyzedDate: s.analyzedDate,
      );
      await _sampleDao.updateSample(updated);
    }
    await _loadSamples();
    notifyListeners();
  }

  Future<void> resetAllData() async {
    try {
      await _countDao.clearAll();
      await _sampleDao.clearAll();
      await _orderDao.clearAll();
      _activeSample = null;
      _currentCounts.clear();
      _samples = [];
      _orders = [];
      await _loadSamples();
      await _loadOrders();
      notifyListeners();
    } catch (e) {
      print('Error resetting data: $e');
    }
  }

  Future<int> addSampleMarking({
    required int orderId,
    required String specimenType,
    required String clientName,
    required String sampleMarking,
    String? receiveId, // Ignored - Reference ID is auto-generated by Firebase
    DateTime? dateAnalysis,
  }) async {
    // Create sample without Reference ID (will be auto-generated by Firebase)
    final sample = Sample(
      orderId: orderId,
      stationId: sampleMarking,
      sampleMarking: sampleMarking,
      receiveId: null, // Will be auto-generated by Firebase
      date: dateAnalysis ?? DateTime.now(),
      habitat: null,
      client: clientName,
      biologistId: null,
      remarks: null,
      completed: false,
      sampleType: specimenType,
      createdAt: DateTime.now(),
    );

    // Save locally first
    final id = await _sampleDao.insertSample(sample);

    // Get the saved sample with local ID
    final savedSample = await _sampleDao.getSampleById(id);
    if (savedSample != null) {
      // Upload to Firebase - this will auto-generate Reference ID and sync back
      try {
        await _syncService.uploadSample(savedSample);
        print('Sample uploaded to Firebase with auto-generated Reference ID');
      } catch (e) {
        print('Error uploading sample to Firebase: $e');
        // Continue even if Firebase upload fails - sample is saved locally
      }
    }

    await _loadSamples();
    notifyListeners();
    return id;
  }

  Future<void> updateSample(Sample sample) async {
    await _sampleDao.updateSample(sample);
    if (_activeSample?.id == sample.id) {
      _activeSample = sample;
    }
    await _loadSamples();
    await _loadTaxa();
    notifyListeners();
  }

  Future<void> deleteSample(int sampleId) async {
    await _sampleDao.deleteSample(sampleId);
    if (_activeSample?.id == sampleId) {
      _activeSample = null;
      _currentCounts.clear();
    }
    await _loadSamples();
    notifyListeners();
  }

  // Count management
  Future<void> _loadCurrentCounts() async {
    if (_activeSample == null) {
      _currentCounts.clear();
      return;
    }

    final counts = await _countDao.getCountsWithTaxa(_activeSample!.id!);
    _currentCounts.clear();
    for (final countData in counts) {
      final taxonId = countData['taxonId'] as int;
      final count = countData['count'] as int;
      _currentCounts[taxonId] = (_currentCounts[taxonId] ?? 0) + count;
    }
    notifyListeners();
  }

  Future<void> incrementCount(int taxonId) async {
    if (_activeSample == null) return;

    await _countDao.incrementCount(_activeSample!.id!, taxonId);
    _currentCounts[taxonId] = (_currentCounts[taxonId] ?? 0) + 1;
    notifyListeners();
  }

  Future<void> decrementCount(int taxonId) async {
    if (_activeSample == null) return;

    await _countDao.decrementCount(_activeSample!.id!, taxonId);
    final currentCount = _currentCounts[taxonId] ?? 0;
    if (currentCount > 1) {
      _currentCounts[taxonId] = currentCount - 1;
    } else {
      _currentCounts.remove(taxonId);
    }
    notifyListeners();
  }

  Future<void> setCount(int taxonId, int count) async {
    if (_activeSample == null) return;

    await _countDao.setCount(_activeSample!.id!, taxonId, count);
    if (count > 0) {
      _currentCounts[taxonId] = count;
    } else {
      _currentCounts.remove(taxonId);
    }
    notifyListeners();
  }

  // Taxon navigation
  void navigateToTaxon(Taxon taxon) {
    _currentTaxonPath.add(taxon);
    notifyListeners();
  }

  void navigateBack() {
    if (_currentTaxonPath.isNotEmpty) {
      _currentTaxonPath.removeLast();
      notifyListeners();
    }
  }

  void navigateToRoot() {
    _currentTaxonPath.clear();
    notifyListeners();
  }

  Taxon? get currentTaxon {
    if (_currentTaxonPath.isEmpty) return null;
    return _currentTaxonPath.last;
  }

  List<Taxon> get currentChildren {
    List<Taxon> children;
    if (_currentTaxonPath.isEmpty) {
      children = _taxa.where((taxon) => taxon.isRoot).toList();
    } else {
      final currentTaxon = _currentTaxonPath.last;
      children = _taxa
          .where((taxon) => taxon.parentId == currentTaxon.id)
          .toList();
    }
    final seen = <String>{};
    final deduped = <Taxon>[];
    for (final t in children) {
      final key = t.name.toLowerCase();
      if (!seen.contains(key)) {
        seen.add(key);
        deduped.add(t);
      }
    }
    deduped.sort(
      (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
    );
    return deduped;
  }

  // Project management
  Future<void> _loadMostRecentProject() async {
    _currentProject = await _projectDao.getMostRecentProjectInfo();
    notifyListeners();
  }

  Future<void> setCurrentProject(ProjectInfo project) async {
    _currentProject = project;
    notifyListeners();
  }

  Future<void> saveProject(ProjectInfo project) async {
    if (project.id == null) {
      await _projectDao.insertProjectInfo(project);
    } else {
      await _projectDao.updateProjectInfo(project);
    }
    _currentProject = project;
    notifyListeners();
  }

  // Utility methods
  int get totalCurrentCount {
    return _currentCounts.values.fold(0, (sum, count) => sum + count);
  }

  bool get hasActiveSample => _activeSample != null;

  void clearCurrentCounts() {
    _currentCounts.clear();
    notifyListeners();
  }

  Future<void> markActiveSampleCompleted() async {
    if (_activeSample?.id == null) return;
    final now = DateTime.now();
    final s = Sample(
      id: _activeSample!.id,
      stationId: _activeSample!.stationId,
      date: _activeSample!.date,
      lat: _activeSample!.lat,
      lon: _activeSample!.lon,
      habitat: _activeSample!.habitat,
      client: _activeSample!.client,
      biologistId: _activeSample!.biologistId,
      remarks: _activeSample!.remarks,
      completed: true,
      sampleType: _activeSample!.sampleType,
      orderId: _activeSample!.orderId,
      sampleMarking: _activeSample!.sampleMarking,
      receiveId: _activeSample!.receiveId,
      analyzedDate: now,
    );
    await _sampleDao.updateSample(s);
    _activeSample = s;
    await _loadSamples();
    notifyListeners();
  }

  Future<void> markSampleCompleted(int sampleId, bool completed) async {
    await _sampleDao.markSampleCompleted(sampleId, completed);
    await _loadSamples();
    notifyListeners();
  }

  Future<Directory> _getExportDirectory() async {
    Directory? baseDir;
    try {
      final dirs = await getExternalStorageDirectories(
        type: StorageDirectory.documents,
      );
      if (dirs != null && dirs.isNotEmpty) {
        baseDir = dirs.first;
      }
    } catch (_) {}
    baseDir ??= await getApplicationDocumentsDirectory();
    final exportDir = Directory(p.join(baseDir.path, 'Macrobenthos'));
    if (!exportDir.existsSync()) {
      exportDir.createSync(recursive: true);
    }
    return exportDir;
  }

  Future<List<String>> exportCsvForClientDateRange({
    required String client,
    required DateTime start,
    required DateTime end,
    required String specimenType,
  }) async {
    final exportDir = await _getExportDirectory();
    final rankDao = RankDefinitionDao();
    final rankDefs = await rankDao.getRanksByType(specimenType);
    final rankNames = rankDefs.map((r) => r.name).toList();
    final samplesAll = await _sampleDao.getAllSamples();
    final samples = samplesAll.where((s) {
      final withinDate = !s.date.isBefore(start) && !s.date.isAfter(end);
      final matchesClient = (s.client ?? _currentProject?.client) == client;
      final matchesType = s.sampleType == specimenType;
      return withinDate && matchesClient && matchesType;
    }).toList();

    final header = [
      'StationId',
      'Date',
      'ClientID',
      'BiologistID',
      'Location',
      ...rankNames,
      'Count',
    ];
    final lines = <String>[header.join(',')];

    for (final s in samples) {
      final counts = await _countDao.getCountsWithTaxa(s.id!);
      for (final row in counts) {
        final taxonId = row['taxonId'] as int;
        final path = await _taxonDao.getTaxonAncestry(taxonId);
        final pathMap = <String, String>{};
        for (final t in path) {
          final r = (t.rank ?? '').toLowerCase();
          if (r.isNotEmpty) pathMap[r] = t.name;
        }
        final line = [
          s.stationId,
          '${s.date.year}-${s.date.month.toString().padLeft(2, '0')}-${s.date.day.toString().padLeft(2, '0')}',
          client,
          s.biologistId ?? '',
          s.habitat ?? '',
          ...rankNames.map((rn) => pathMap[rn.toLowerCase()] ?? ''),
          row['count'].toString(),
        ].map((v) => _csvEscape(v.toString())).join(',');
        lines.add(line);
      }
    }

    final filename =
        '${specimenType}_Results_${client}_${_fmtDate(start)}-${_fmtDate(end)}.csv';
    final outPath = p.join(exportDir.path, filename);
    final file = File(outPath);
    await file.writeAsString(lines.join('\n'));
    return [outPath];
  }

  Future<String> exportCsvForSampleIds({
    required String client,
    required List<int> sampleIds,
    required String specimenType,
  }) async {
    final exportDir = await _getExportDirectory();
    final rankDao = RankDefinitionDao();
    final rankDefs = await rankDao.getRanksByType(specimenType);
    final rankNames = rankDefs.map((r) => r.name).toList();
    final header = [
      'StationId',
      'Date',
      'ClientID',
      'BiologistID',
      'Location',
      ...rankNames,
      'Count',
    ];
    final lines = <String>[header.join(',')];
    final samplesAll = await _sampleDao.getAllSamples();
    final samples = samplesAll
        .where((s) => sampleIds.contains(s.id) && s.sampleType == specimenType)
        .toList();
    for (final s in samples) {
      final counts = await _countDao.getCountsWithTaxa(s.id!);
      for (final row in counts) {
        final taxonId = row['taxonId'] as int;
        final path = await _taxonDao.getTaxonAncestry(taxonId);
        final pathMap = <String, String>{};
        for (final t in path) {
          final r = (t.rank ?? '').toLowerCase();
          if (r.isNotEmpty) pathMap[r] = t.name;
        }
        final line = [
          s.stationId,
          '${s.date.year}-${s.date.month.toString().padLeft(2, '0')}-${s.date.day.toString().padLeft(2, '0')}',
          client,
          s.biologistId ?? '',
          s.habitat ?? '',
          ...rankNames.map((rn) => pathMap[rn.toLowerCase()] ?? ''),
          row['count'].toString(),
        ].map((v) => _csvEscape(v.toString())).join(',');
        lines.add(line);
      }
    }
    final filename =
        '${specimenType}_Results_${client}_${_fmtDate(DateTime.now())}.csv';
    final outPath = p.join(exportDir.path, filename);
    final file = File(outPath);
    await file.writeAsString(lines.join('\n'));
    return outPath;
  }

  String _fmtDate(DateTime d) =>
      '${d.year}${d.month.toString().padLeft(2, '0')}${d.day.toString().padLeft(2, '0')}';

  String _csvEscape(String input) {
    final needsQuotes =
        input.contains(',') || input.contains('"') || input.contains('\n');
    var escaped = input.replaceAll('"', '""');
    return needsQuotes ? '"$escaped"' : escaped;
  }

  Future<void> updateActiveSampleBiologist(String biologistId) async {
    if (_activeSample == null) return;
    final s = Sample(
      id: _activeSample!.id,
      stationId: _activeSample!.stationId,
      date: _activeSample!.date,
      lat: _activeSample!.lat,
      lon: _activeSample!.lon,
      habitat: _activeSample!.habitat,
      client: _activeSample!.client,
      biologistId: biologistId,
      remarks: _activeSample!.remarks,
      completed: _activeSample!.completed,
      sampleType: _activeSample!.sampleType,
    );
    await _sampleDao.updateSample(s);
    _activeSample = s;
    await _loadSamples();
    notifyListeners();
  }

  /// Sync samples from Firebase to local database
  Future<int> syncSamplesFromFirebase({String? specimenType}) async {
    try {
      final count = await _syncService.syncSamplesToLocal(specimenType: specimenType);
      await _loadSamples();
      notifyListeners();
      print('Synced $count samples from Firebase');
      return count;
    } catch (e) {
      print('Error syncing samples from Firebase: $e');
      return 0;
    }
  }

  /// Sync orders from Firebase to local database
  Future<int> syncOrdersFromFirebase({String? specimenType}) async {
    try {
      final count = await _syncService.syncOrdersToLocal(specimenType: specimenType);
      await _loadOrders();
      notifyListeners();
      print('Synced $count orders from Firebase');
      return count;
    } catch (e) {
      print('Error syncing orders from Firebase: $e');
      return 0;
    }
  }

  /// Sync both orders and samples from Firebase
  Future<Map<String, int>> syncAllFromFirebase({String? specimenType}) async {
    final orderCount = await syncOrdersFromFirebase(specimenType: specimenType);
    final sampleCount = await syncSamplesFromFirebase(specimenType: specimenType);
    return {
      'orders': orderCount,
      'samples': sampleCount,
    };
  }

  /// Force a manual sync with Firebase (triggered by user action)
  Future<void> forceSync({String? specimenType}) async {
    try {
      await _realtimeSyncService.forceSync(specimenType: specimenType);
      await _loadSamples();
      await _loadOrders();
      notifyListeners();
    } catch (e) {
      print('Error during force sync: $e');
      rethrow;
    }
  }

  /// Change specimen type filter and restart sync
  Future<void> changeSpecimenTypeFilter(String? specimenType) async {
    try {
      await _realtimeSyncService.changeSpecimenType(specimenType);
      await _loadSamples();
      await _loadOrders();
      notifyListeners();
    } catch (e) {
      print('Error changing specimen type filter: $e');
    }
  }

  /// Clean up resources when disposing AppState
  @override
  void dispose() {
    _realtimeSyncService.dispose();
    super.dispose();
  }
}
