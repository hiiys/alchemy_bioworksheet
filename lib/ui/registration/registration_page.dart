import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/app_state.dart';
import '../../core/routing.dart';
import '../../data/models.dart';
import '../../data/dao/taxon_dao.dart';
import '../../data/db.dart';
import '../widgets/app_scaffold.dart';

class RegistrationPage extends StatefulWidget {
  const RegistrationPage({super.key});

  @override
  State<RegistrationPage> createState() => _RegistrationPageState();
}

class _RegistrationPageState extends State<RegistrationPage> {
  bool _canModify = false;
  DateTime? _lastModified;
  final Set<int> _selectedLeafIds = {};
  bool _selectAll = false;
  String _viewSpecimenType = 'Macrobenthos';

  @override
  void dispose() {
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _loadLastModified();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final appState = Provider.of<AppState>(context, listen: false);
      _viewSpecimenType = appState.activeSample?.sampleType ?? 'Macrobenthos';
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);

    return AppScaffold(
      title: AppPageTitles.registration,
      actions: [
        if (!_canModify)
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: _startModification,
            tooltip: 'Modify',
          ),
        if (_canModify) ...[
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showSpecimenRegistrationDialog,
            tooltip: 'Register Specimen',
          ),
          IconButton(
            icon: const Icon(Icons.upload),
            onPressed: _showImportDialog,
            tooltip: 'Import CSV',
          ),
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: _exportRegistrationCsv,
            tooltip: 'Export CSV',
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: _deleteSelectedRegistrations,
            tooltip: 'Delete Selected',
          ),
          IconButton(
            icon: const Icon(Icons.delete_forever),
            onPressed: _deleteAllRegistrations,
            tooltip: 'Delete All',
          ),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: _cancelModification,
            tooltip: 'Cancel',
          ),
        ],
      ],
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ChoiceChip(
                  label: const Text('Phytoplankton'),
                  selected: _viewSpecimenType == 'Phytoplankton',
                  onSelected: (v) {
                    setState(() {
                      _viewSpecimenType = 'Phytoplankton';
                      _selectedLeafIds.clear();
                      _selectAll = false;
                    });
                  },
                ),
                ChoiceChip(
                  label: const Text('Zooplankton'),
                  selected: _viewSpecimenType == 'Zooplankton',
                  onSelected: (v) {
                    setState(() {
                      _viewSpecimenType = 'Zooplankton';
                      _selectedLeafIds.clear();
                      _selectAll = false;
                    });
                  },
                ),
                ChoiceChip(
                  label: const Text('Macrobenthos'),
                  selected: _viewSpecimenType == 'Macrobenthos',
                  onSelected: (v) {
                    setState(() {
                      _viewSpecimenType = 'Macrobenthos';
                      _selectedLeafIds.clear();
                      _selectAll = false;
                    });
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _buildTaxonomyTable(context, appState),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Icon(Icons.history),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _lastModified == null
                        ? 'Last modified: N/A'
                        : 'Last modified: ${_formatDate(_lastModified!)}',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaxonomyTable(BuildContext context, AppState appState) {
    final ranks = const ['Phylum', 'Class', 'Order', 'Family', 'Genus', 'Species'];
    final taxonDao = TaxonDao();
    return FutureBuilder<List<Taxon>>(
      future: _viewSpecimenType == appState.activeSample?.sampleType
          ? Future.value(appState.taxa)
          : taxonDao.getAllTaxaByType(_viewSpecimenType),
      builder: (context, snapshot) {
        final taxa = snapshot.data ?? [];
        final leaves = taxa.where((t) => !taxa.any((c) => c.parentId == t.id)).toList()
          ..sort((a, b) => (a.name).toLowerCase().compareTo((b.name).toLowerCase()));
        final rankOrder = const ['phylum', 'class', 'order', 'family', 'genus', 'species'];
        final columns = [
          if (_canModify)
            const DataColumn(label: Text('Select')),
          const DataColumn(label: Text('Unique ID')),
          ...ranks.map((r) => DataColumn(label: Text(r))).toList(),
        ];

        List<DataRow> buildRows() {
          final rows = <DataRow>[];
          for (final leaf in leaves) {
            final pathByRankName = <String, String>{};
            final pathByRankTaxon = <String, Taxon>{};
            Taxon? current = leaf;
            while (current != null) {
              final r = (current.rank ?? '').toLowerCase();
              if (r.isNotEmpty) {
                pathByRankName[_capitalize(r)] = current.name;
                pathByRankTaxon[r] = current;
              }
              current = taxa.where((t) => t.id == current!.parentId).cast<Taxon?>().firstWhere((t) => true, orElse: () => null);
            }

            final cells = <DataCell>[];
            if (_canModify) {
              cells.add(
                DataCell(
                  Checkbox(
                    value: leaf.id != null && _selectedLeafIds.contains(leaf.id!),
                    onChanged: (v) {
                      setState(() {
                        if (leaf.id != null) {
                          if (v == true) {
                            _selectedLeafIds.add(leaf.id!);
                          } else {
                            _selectedLeafIds.remove(leaf.id!);
                          }
                          _selectAll = _selectedLeafIds.length == leaves.where((l) => l.id != null).length;
                        }
                      });
                    },
                  ),
                ),
              );
            }
            cells.add(
              DataCell(
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
                  child: Text(leaf.id?.toString() ?? ''),
                ),
              ),
            );
            cells.addAll(ranks.map((rankLabel) {
              final lowerRank = rankLabel.toLowerCase();
              final value = pathByRankName[rankLabel] ?? '';
              return DataCell(
                InkWell(
                  onTap: () async {
                    if (!_canModify) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Tap Modify to enable editing')),
                      );
                      return;
                    }
                    final controller = TextEditingController(text: value);
                    await showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: Text('Edit $rankLabel'),
                        content: TextField(
                          controller: controller,
                          decoration: InputDecoration(
                            labelText: value.isEmpty ? 'Enter $rankLabel' : 'Change $rankLabel',
                            border: const OutlineInputBorder(),
                          ),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Cancel'),
                          ),
                          FilledButton(
                            onPressed: () async {
                              final newVal = controller.text.trim();
                              Navigator.pop(context);
                              if (newVal.isEmpty && value.isEmpty) return;
                              if (value.isEmpty) {
                                await _addRankValueForSpecimen(appState, leaf, lowerRank, newVal, pathByRankTaxon, rankOrder);
                              } else {
                                final taxonToUpdate = pathByRankTaxon[lowerRank];
                                if (taxonToUpdate != null) {
                                  await appState.updateTaxon(Taxon(
                                    id: taxonToUpdate.id,
                                    parentId: taxonToUpdate.parentId,
                                    name: newVal.isEmpty ? taxonToUpdate.name : newVal,
                                    rank: taxonToUpdate.rank,
                                    notes: taxonToUpdate.notes,
                                    specimenType: _viewSpecimenType,
                                  ));
                                  await _setTaxaModifiedNow();
                                }
                              }
                            },
                            child: const Text('Save'),
                          ),
                        ],
                      ),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
                    child: Text(value),
                  ),
                ),
              );
            }).toList());
            rows.add(DataRow(cells: cells));
          }
          return rows;
        }

        return Card(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(columns: columns, rows: buildRows()),
          ),
        );
      },
    );
  }

  Future<void> _startModification() async {
    final controller = TextEditingController();
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Enter Password'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Password'),
          obscureText: true,
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final input = controller.text;
              if (input == 'alC123') {
                setState(() => _canModify = true);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Modification enabled')),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Incorrect password')),
                );
              }
            },
            child: const Text('Unlock'),
          ),
        ],
      ),
    );
  }

  void _cancelModification() {
    setState(() {
      _canModify = false;
      _selectedLeafIds.clear();
      _selectAll = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Modification cancelled')),
    );
  }

  

  void _showAddTaxonDialog(BuildContext context, Taxon? parent) {
      final nameController = TextEditingController();
      final rankController = TextEditingController();
      final notesController = TextEditingController();

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(parent == null ? 'Add Root Taxon' : 'Add Child Taxon to ${parent.name}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Name *',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: rankController,
                decoration: const InputDecoration(
                  labelText: 'Rank (e.g., Family, Genus)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: notesController,
                decoration: const InputDecoration(
                  labelText: 'Notes',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                if (nameController.text.isNotEmpty) {
                  final appState = Provider.of<AppState>(context, listen: false);
                  final taxon = Taxon(
                    parentId: parent?.id,
                    name: nameController.text,
                    rank: rankController.text.isEmpty ? null : rankController.text,
                    notes: notesController.text.isEmpty ? null : notesController.text,
                  );
                  appState.addTaxon(taxon);
                  await _setTaxaModifiedNow();
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Taxon added successfully')),
                  );
                }
              },
              child: const Text('Add'),
            ),
          ],
        ),
      );
  }

  void _showEditTaxonDialog(BuildContext context, Taxon taxon) {
      final nameController = TextEditingController(text: taxon.name);
      final rankController = TextEditingController(text: taxon.rank ?? '');
      final notesController = TextEditingController(text: taxon.notes ?? '');

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Edit Taxon'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Name *',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: rankController,
                decoration: const InputDecoration(
                  labelText: 'Rank',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: notesController,
                decoration: const InputDecoration(
                  labelText: 'Notes',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                if (nameController.text.isNotEmpty) {
                  final appState = Provider.of<AppState>(context, listen: false);
                  final updatedTaxon = Taxon(
                    id: taxon.id,
                    parentId: taxon.parentId,
                    name: nameController.text,
                    rank: rankController.text.isEmpty ? null : rankController.text,
                    notes: notesController.text.isEmpty ? null : notesController.text,
                  );
                  appState.updateTaxon(updatedTaxon);
                  await _setTaxaModifiedNow();
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Taxon updated successfully')),
                  );
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      );
  }

  void _showDeleteTaxonDialog(BuildContext context, Taxon taxon) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Delete Taxon'),
          content: Text('Are you sure you want to delete "${taxon.name}"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                final appState = Provider.of<AppState>(context, listen: false);
                appState.deleteTaxon(taxon.id!);
                await _setTaxaModifiedNow();
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Deleted taxon: ${taxon.name}')),
                );
              },
              child: const Text(
                'Delete',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        ),
      );
  }

  void _showImportDialog() {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Import Taxa from CSV'),
          content: const Text('Select a CSV with header columns: Unique ID, Phylum, Class, Order, Family, Genus, Species. Each row is a specimen registration; leave cells blank if not applicable.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                Navigator.pop(context);
                await _importCsv();
                await _setTaxaModifiedNow();
              },
              child: const Text('Choose File'),
            ),
          ],
        ),
      );
  }

  Future<void> _importCsv() async {
    try {
      final result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['csv']);
      if (result == null || result.files.single.path == null) return;
      final path = result.files.single.path!;
      final file = File(path);
      final content = await file.readAsString();
      final lines = content.split(RegExp(r'\r?\n')).where((l) => l.trim().isNotEmpty).toList();
      if (lines.isEmpty) return;
      final headers = lines.first.split(',').map((h) => h.trim()).toList();
      final lower = headers.map((h) => h.toLowerCase()).toList();
      final rankOrder = ['phylum', 'class', 'order', 'family', 'genus', 'species'];
      if (!lower.contains('phylum')) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('CSV must include Phylum column')));
        return;
      }
      final idxMap = {
        'phylum': lower.indexOf('phylum'),
        'class': lower.indexOf('class'),
        'order': lower.indexOf('order'),
        'family': lower.indexOf('family'),
        'genus': lower.indexOf('genus'),
        'species': lower.indexOf('species'),
      };
      final db = await DatabaseHelper().database;
      await db.delete('count_record');
      await db.delete('taxon');
      final appState = Provider.of<AppState>(context, listen: false);
      final taxonDao = TaxonDao();
      int created = 0;
      for (int i = 1; i < lines.length; i++) {
        final cols = lines[i].split(',').map((c) => c.trim()).toList();
        int? parentId;
        for (final r in rankOrder) {
          final idx = idxMap[r]!;
          if (idx == -1 || idx >= cols.length) continue;
          final val = cols[idx];
          if (val.isEmpty) continue;
          final taxon = await taxonDao.upsertTaxon(parentId, val, rank: _capitalize(r), specimenType: appState.activeSample?.sampleType ?? 'Macrobenthos');
          parentId = taxon.id;
          created++;
        }
      }
      await appState.reloadTaxa();
      await _setTaxaModifiedNow();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Import complete. Created/linked: $created taxa')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Import failed: $e')));
    }
  }
  
  Future<void> _loadLastModified() async {
    final prefs = await SharedPreferences.getInstance();
    final millis = prefs.getInt('taxa_last_modified');
    if (millis != null) {
      setState(() => _lastModified = DateTime.fromMillisecondsSinceEpoch(millis));
    }
  }

  Future<void> _setTaxaModifiedNow() async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    await prefs.setInt('taxa_last_modified', now.millisecondsSinceEpoch);
    setState(() => _lastModified = now);
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
  String _capitalize(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

  Future<void> _showSpecimenRegistrationDialog() async {
    final phylumController = TextEditingController();
    final classController = TextEditingController();
    final orderController = TextEditingController();
    final familyController = TextEditingController();
    final genusController = TextEditingController();
    final speciesController = TextEditingController();
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Specimen Registration'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: phylumController,
                decoration: const InputDecoration(
                  labelText: 'Phylum *',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: classController,
                decoration: const InputDecoration(
                  labelText: 'Class',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: orderController,
                decoration: const InputDecoration(
                  labelText: 'Order',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: familyController,
                decoration: const InputDecoration(
                  labelText: 'Family',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: genusController,
                decoration: const InputDecoration(
                  labelText: 'Genus',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: speciesController,
                decoration: const InputDecoration(
                  labelText: 'Species',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              final phylum = phylumController.text.trim();
              if (phylum.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Phylum is required')),
                );
                return;
              }
              final taxonDao = TaxonDao();
              int? parentId;
              final ranks = [
                {'label': 'phylum', 'value': phylum},
                {'label': 'class', 'value': classController.text.trim()},
                {'label': 'order', 'value': orderController.text.trim()},
                {'label': 'family', 'value': familyController.text.trim()},
                {'label': 'genus', 'value': genusController.text.trim()},
                {'label': 'species', 'value': speciesController.text.trim()},
              ];
              for (final r in ranks) {
                final v = r['value']!;
                if (v.isEmpty) continue;
                final t = await taxonDao.upsertTaxon(parentId, v, rank: _capitalize(r['label']!), specimenType: _viewSpecimenType);
                parentId = t.id;
              }
              final appState = Provider.of<AppState>(context, listen: false);
              await appState.reloadTaxa();
              await _setTaxaModifiedNow();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Specimen registered')),
              );
            },
            child: const Text('Register'),
          ),
        ],
      ),
    );
  }

  Future<void> _exportRegistrationCsv() async {
    try {
      final appState = Provider.of<AppState>(context, listen: false);
      final ranks = ['Phylum', 'Class', 'Order', 'Family', 'Genus', 'Species'];
      final taxonDao = TaxonDao();
      final taxa = _viewSpecimenType == appState.activeSample?.sampleType
          ? appState.taxa
          : await taxonDao.getAllTaxaByType(_viewSpecimenType);
      final leaves = taxa.where((t) => !taxa.any((c) => c.parentId == t.id)).toList()
        ..sort((a, b) => (a.name).toLowerCase().compareTo((b.name).toLowerCase()));
      final lines = <String>[];
      lines.add(['Unique ID', 'SpecimenType', ...ranks].join(','));
      for (final leaf in leaves) {
        final pathByRankName = <String, String>{};
        Taxon? current = leaf;
        while (current != null) {
          final r = (current.rank ?? '').toLowerCase();
          if (r.isNotEmpty) {
            final label = _capitalize(r);
            pathByRankName[label] = current.name;
          }
          current = taxa.where((t) => t.id == current!.parentId).cast<Taxon?>().firstWhere((t) => true, orElse: () => null);
        }
        final row = [leaf.id?.toString() ?? '', _viewSpecimenType, ...ranks.map((r) => pathByRankName[r] ?? '')];
        lines.add(row.map((v) => v.contains(',') ? '"${v.replaceAll('"', '""')}"' : v).join(','));
      }
      final baseDir = await getApplicationDocumentsDirectory();
      final outDir = Directory('${baseDir.path}/Macrobenthos');
      if (!outDir.existsSync()) outDir.createSync(recursive: true);
      final filename = 'Taxonomy_${_fmtDate(DateTime.now())}.csv';
      final outPath = '${outDir.path}/$filename';
      final f = File(outPath);
      await f.writeAsString(lines.join('\n'));
      await Share.shareXFiles([XFile(outPath)], text: 'Specimen registration export');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Export failed: $e')));
    }
  }

  String _fmtDate(DateTime d) => '${d.year}${d.month.toString().padLeft(2,'0')}${d.day.toString().padLeft(2,'0')}';
  Future<void> _addRankValueForSpecimen(
    AppState appState,
    Taxon leaf,
    String lowerRank,
    String newVal,
    Map<String, Taxon> pathByRankTaxon,
    List<String> rankOrder,
  ) async {
    final taxonDao = TaxonDao();
    int? parentId;
    for (int i = rankOrder.indexOf(lowerRank) - 1; i >= 0; i--) {
      final r = rankOrder[i];
      final parentTaxon = pathByRankTaxon[r];
      if (parentTaxon != null) {
        parentId = parentTaxon.id;
        break;
      }
    }
    final newTaxon = Taxon(parentId: parentId, name: newVal, rank: _capitalize(lowerRank), specimenType: appState.activeSample?.sampleType ?? 'Macrobenthos');
    final newId = await taxonDao.insertTaxon(newTaxon);
    Taxon? childToReparent;
    for (int i = rankOrder.indexOf(lowerRank) + 1; i < rankOrder.length; i++) {
      final r = rankOrder[i];
      final t = pathByRankTaxon[r];
      if (t != null) {
        childToReparent = t;
        break;
      }
    }
    childToReparent ??= leaf;
    await appState.updateTaxon(Taxon(
      id: childToReparent.id,
      parentId: newId,
      name: childToReparent.name,
      rank: childToReparent.rank,
      notes: childToReparent.notes,
    ));
    await appState.reloadTaxa();
    await _setTaxaModifiedNow();
  }

  Future<void> _confirmDeleteRegistration(BuildContext context, Taxon leaf) async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Registration'),
        content: Text('Delete specimen registration with Unique ID ${leaf.id}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final appState = Provider.of<AppState>(context, listen: false);
              if (leaf.id != null) {
                await appState.deleteTaxon(leaf.id!);
                await _setTaxaModifiedNow();
              }
              // ignore: use_build_context_synchronously
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Registration deleted')),
              );
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteSelectedRegistrations() async {
    if (!_canModify) return;
    final appState = Provider.of<AppState>(context, listen: false);
    final taxa = appState.taxa;
    final allLeafIds = taxa
        .where((t) => !taxa.any((c) => c.parentId == t.id))
        .map((t) => t.id)
        .whereType<int>()
        .toList();
    final idsToDelete = _selectAll
        ? allLeafIds
        : _selectedLeafIds.toList();
    if (idsToDelete.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No records selected')),
      );
      return;
    }
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Selected'),
        content: Text('Delete ${idsToDelete.length} registration(s)?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('OK')),
        ],
      ),
    );
    if (confirm != true) return;
    int deleted = 0;
    for (final id in idsToDelete) {
      await appState.deleteTaxon(id);
      deleted++;
    }
    await _setTaxaModifiedNow();
    setState(() {
      _selectedLeafIds.clear();
      _selectAll = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Deleted $deleted registration(s)')),
    );
  }

  Future<void> _deleteAllRegistrations() async {
    if (!_canModify) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete All Registrations'),
        content: Text('This will remove all ${_viewSpecimenType} registrations. Proceed?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('OK')),
        ],
      ),
    );
    if (confirm != true) return;
    final appState = Provider.of<AppState>(context, listen: false);
    final db = await DatabaseHelper().database;
    // Delete only taxa for the selected specimen type and their counts
    final ids = await db.rawQuery('SELECT id FROM taxon WHERE specimenType = ?', [_viewSpecimenType]);
    final taxonIds = ids.map((e) => e['id'] as int).toList();
    if (taxonIds.isNotEmpty) {
      final placeholders = List.filled(taxonIds.length, '?').join(',');
      await db.delete('count_record', where: 'taxonId IN ($placeholders)', whereArgs: taxonIds);
    }
    await db.delete('taxon', where: 'specimenType = ?', whereArgs: [_viewSpecimenType]);
    await appState.reloadTaxa();
    await _setTaxaModifiedNow();
    setState(() {
      _selectedLeafIds.clear();
      _selectAll = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('All ${_viewSpecimenType} registrations deleted')),
    );
  }
}
