import 'package:flutter/material.dart';
import '../data/models.dart';
import '../data/dao/taxon_dao.dart';
import '../data/dao/sample_dao.dart';
import '../data/dao/count_dao.dart';
import '../data/dao/project_dao.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'dart:io';

class AppState with ChangeNotifier {
  final TaxonDao _taxonDao = TaxonDao();
  final SampleDao _sampleDao = SampleDao();
  final CountDao _countDao = CountDao();
  final ProjectDao _projectDao = ProjectDao();

  // Current state
  Sample? _activeSample;
  List<Taxon> _taxa = [];
  Map<int, int> _currentCounts = {}; // taxonId -> count
  List<Taxon> _currentTaxonPath = [];
  List<Sample> _samples = [];
  ProjectInfo? _currentProject;

  // Getters
  Sample? get activeSample => _activeSample;
  List<Taxon> get taxa => _taxa;
  Map<int, int> get currentCounts => _currentCounts;
  List<Taxon> get currentTaxonPath => _currentTaxonPath;
  List<Sample> get samples => _samples;
  ProjectInfo? get currentProject => _currentProject;

  // Initialize app state
  Future<void> initialize() async {
    await _loadTaxa();
    await _loadSamples();
    await _loadMostRecentProject();
    
    // Try to load the last active sample
    if (_samples.isNotEmpty) {
      _activeSample = _samples.first;
      await _loadCurrentCounts();
    }
    
    notifyListeners();
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
    await _taxonDao.insertTaxon(taxon);
    await _loadTaxa();
  }

  Future<void> updateTaxon(Taxon taxon) async {
    await _taxonDao.updateTaxon(taxon);
    await _loadTaxa();
  }

  Future<void> deleteTaxon(int taxonId) async {
    await _taxonDao.deleteTaxon(taxonId);
    await _loadTaxa();
  }

  // Sample management
  Future<void> _loadSamples() async {
    try {
      _samples = await _sampleDao.getAllSamples();
      print('Loaded ${_samples.length} samples from database');
      for (final sample in _samples) {
        print('Sample: ${sample.stationId}, ID: ${sample.id}, Client: ${sample.client}');
      }
      notifyListeners();
    } catch (e) {
      print('Error loading samples: $e');
      rethrow;
    }
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
      print('Creating sample without activate: ${sample.stationId}, client: ${sample.client}');
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
      children = _taxa.where((taxon) => taxon.parentId == currentTaxon.id).toList();
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
    deduped.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
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
    await _sampleDao.markSampleCompleted(_activeSample!.id!, true);
    _activeSample = Sample(
      id: _activeSample!.id,
      stationId: _activeSample!.stationId,
      date: _activeSample!.date,
      lat: _activeSample!.lat,
      lon: _activeSample!.lon,
      habitat: _activeSample!.habitat,
      client: _activeSample!.client,
      remarks: _activeSample!.remarks,
      completed: true,
    );
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
      final dirs = await getExternalStorageDirectories(type: StorageDirectory.documents);
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

  Future<List<String>> exportCsvForClientDateRange({required String client, required DateTime start, required DateTime end, required String specimenType}) async {
    final exportDir = await _getExportDirectory();

    final samplesAll = await _sampleDao.getAllSamples();
    final samples = samplesAll.where((s) {
      final withinDate = !s.date.isBefore(start) && !s.date.isAfter(end);
      final matchesClient = (s.client ?? _currentProject?.client) == client;
      final matchesType = s.sampleType == specimenType;
      return withinDate && matchesClient && matchesType;
    }).toList();

    final lines = <String>[
      'StationId,Date,ClientID,Location,Phylum,Class,Order,Family,Genus,Species,Count'
    ];

    for (final s in samples) {
      final counts = await _countDao.getCountsWithTaxa(s.id!);
      for (final row in counts) {
        final taxonId = row['taxonId'] as int;
        final path = await _taxonDao.getTaxonAncestry(taxonId);
        String? phylum;
        String? clazz;
        String? order;
        String? family;
        String? genus;
        String? species;
        for (final t in path) {
          final r = (t.rank ?? '').toLowerCase();
          if (r == 'phylum') phylum = t.name;
          if (r == 'class') clazz = t.name;
          if (r == 'order') order = t.name;
          if (r == 'family') family = t.name;
          if (r == 'genus') genus = t.name;
          if (r == 'species') species = t.name;
        }
        final line = [
          s.stationId,
          '${s.date.year}-${s.date.month.toString().padLeft(2,'0')}-${s.date.day.toString().padLeft(2,'0')}',
          client,
          s.habitat ?? '',
          phylum ?? '',
          clazz ?? '',
          order ?? '',
          family ?? '',
          genus ?? '',
          species ?? '',
          row['count'].toString(),
        ].map((v) => _csvEscape(v.toString())).join(',');
        lines.add(line);
      }
    }

    final filename = '${specimenType}_Results_${client}_${_fmtDate(start)}-${_fmtDate(end)}.csv';
    final outPath = p.join(exportDir.path, filename);
    final file = File(outPath);
    await file.writeAsString(lines.join('\n'));
    return [outPath];
  }

  Future<String> exportCsvForSampleIds({required String client, required List<int> sampleIds, required String specimenType}) async {
    final exportDir = await _getExportDirectory();
    final lines = <String>[
      'StationId,Date,ClientID,Location,Phylum,Class,Order,Family,Genus,Species,Count'
    ];
    final samplesAll = await _sampleDao.getAllSamples();
    final samples = samplesAll.where((s) => sampleIds.contains(s.id) && s.sampleType == specimenType).toList();
    for (final s in samples) {
      final counts = await _countDao.getCountsWithTaxa(s.id!);
      for (final row in counts) {
        final taxonId = row['taxonId'] as int;
        final path = await _taxonDao.getTaxonAncestry(taxonId);
        String? phylum;
        String? clazz;
        String? order;
        String? family;
        String? genus;
        String? species;
        for (final t in path) {
          final r = (t.rank ?? '').toLowerCase();
          if (r == 'phylum') phylum = t.name;
          if (r == 'class') clazz = t.name;
          if (r == 'order') order = t.name;
          if (r == 'family') family = t.name;
          if (r == 'genus') genus = t.name;
          if (r == 'species') species = t.name;
        }
        final line = [
          s.stationId,
          '${s.date.year}-${s.date.month.toString().padLeft(2,'0')}-${s.date.day.toString().padLeft(2,'0')}',
          client,
          s.habitat ?? '',
          phylum ?? '',
          clazz ?? '',
          order ?? '',
          family ?? '',
          genus ?? '',
          species ?? '',
          row['count'].toString(),
        ].map((v) => _csvEscape(v.toString())).join(',');
        lines.add(line);
      }
    }
    final filename = '${specimenType}_Results_${client}_${_fmtDate(DateTime.now())}.csv';
    final outPath = p.join(exportDir.path, filename);
    final file = File(outPath);
    await file.writeAsString(lines.join('\n'));
    return outPath;
  }

  String _fmtDate(DateTime d) => '${d.year}${d.month.toString().padLeft(2,'0')}${d.day.toString().padLeft(2,'0')}';

  String _csvEscape(String input) {
    final needsQuotes = input.contains(',') || input.contains('"') || input.contains('\n');
    var escaped = input.replaceAll('"', '""');
    return needsQuotes ? '"$escaped"' : escaped;
  }
}
