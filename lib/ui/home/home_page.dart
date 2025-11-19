import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/app_state.dart';
import '../../core/routing.dart';
import '../../data/models.dart';
import '../../services/sync_service.dart';
import '../widgets/app_scaffold.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final Set<int> _selectedSampleIds = {};
  int? _sortColumnIndex;
  bool _sortAscending = true;
  bool _selectAll = false;
  bool _isSyncing = false;
  DateTime? _lastSyncTime;
  final SyncService _syncService = SyncService();

  @override
  void initState() {
    super.initState();
    _loadLastSyncTime();
  }

  Future<void> _loadLastSyncTime() async {
    // Load last sync time for any specimen type to show general sync status
    final macroTime = await _syncService.getLastSyncTime('Macrobenthos');
    final zooTime = await _syncService.getLastSyncTime('Zooplankton');
    final phytoTime = await _syncService.getLastSyncTime('Phytoplankton');

    // Use the most recent sync time
    DateTime? latest;
    for (final time in [macroTime, zooTime, phytoTime]) {
      if (time != null && (latest == null || time.isAfter(latest))) {
        latest = time;
      }
    }

    if (mounted) {
      setState(() {
        _lastSyncTime = latest;
      });
    }
  }

  Future<void> _syncTaxonomies() async {
    setState(() {
      _isSyncing = true;
    });

    try {
      final results = await _syncService.syncAllTaxonomies();

      if (!mounted) return;

      // Build result message
      final messages = <String>[];
      int totalSynced = 0;
      bool hasError = false;

      for (final entry in results.entries) {
        if (entry.value.success) {
          if (entry.value.taxaSynced > 0) {
            messages.add('${entry.key}: ${entry.value.taxaSynced} taxa');
            totalSynced += entry.value.taxaSynced;
          } else {
            messages.add('${entry.key}: Up to date');
          }
        } else {
          messages.add('${entry.key}: ${entry.value.message}');
          hasError = true;
        }
      }

      // Show result dialog
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(hasError ? 'Sync Completed with Errors' : 'Sync Completed'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (totalSynced > 0)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    'Total taxa synced: $totalSynced',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ...messages.map((m) => Text(m)),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );

      // Reload last sync time
      await _loadLastSyncTime();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Sync failed: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSyncing = false;
        });
      }
    }
  }

  String _formatSyncTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);

    if (diff.inMinutes < 1) {
      return 'Just now';
    } else if (diff.inHours < 1) {
      return '${diff.inMinutes}m ago';
    } else if (diff.inDays < 1) {
      return '${diff.inHours}h ago';
    } else {
      return '${time.day}/${time.month}/${time.year}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final pending = appState.samples.where((s) => !s.completed).toList();
    final completed = appState.samples.where((s) => s.completed).toList();

    return AppScaffold(
      title: AppPageTitles.home,
      actions: [
        // Sync button
        _isSyncing
            ? const Padding(
                padding: EdgeInsets.all(12),
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                ),
              )
            : IconButton(
                icon: const Icon(Icons.cloud_sync),
                tooltip: _lastSyncTime != null
                    ? 'Sync Taxonomy (Last: ${_formatSyncTime(_lastSyncTime!)})'
                    : 'Sync Taxonomy',
                onPressed: _syncTaxonomies,
              ),
        IconButton(
          icon: const Icon(Icons.delete_forever),
          tooltip: 'Reset Data',
          onPressed: () async {
            final ok = await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Reset All Data'),
                content: const Text(
                  'This will delete all orders, samples, and counts. Proceed?',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('Reset'),
                  ),
                ],
              ),
            );
            if (ok == true) {
              await Provider.of<AppState>(
                context,
                listen: false,
              ).resetAllData();
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('All data reset')));
            }
          },
        ),
      ],
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 320),
                          child: Image.asset(
                            'assets/images/logo.png',
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => Navigator.pushNamed(
                      context,
                      AppRoutes.orderRegistration,
                      arguments: {'specimenType': 'Macrobenthos'},
                    ),
                    icon: const Icon(Icons.add_circle),
                    label: const Text('New Macrobenthos Order'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => Navigator.pushNamed(
                      context,
                      AppRoutes.orderRegistration,
                      arguments: {'specimenType': 'Zooplankton'},
                    ),
                    icon: const Icon(Icons.add_circle),
                    label: const Text('New Zooplankton Order'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => Navigator.pushNamed(
                      context,
                      AppRoutes.orderRegistration,
                      arguments: {'specimenType': 'Phytoplankton'},
                    ),
                    icon: const Icon(Icons.add_circle),
                    label: const Text('New Phytoplankton Order'),
                  ),
                ),
              ],
            ),

            // Dashboard summary
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _summaryTile(
                      context,
                      title: 'Total Samples',
                      value: appState.samples.length.toString(),
                    ),
                    _summaryTile(
                      context,
                      title: 'Completed',
                      value: completed.length.toString(),
                    ),
                    _summaryTile(
                      context,
                      title: 'Pending',
                      value: pending.length.toString(),
                    ),
                  ],
                ),
              ),
            ),

            Expanded(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Sample Status',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: _buildStatusTable(
                          context,
                          appState,
                          appState.samples,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),
            const SizedBox.shrink(),
          ],
        ),
      ),
    );
  }

  Widget _buildSampleInfo(BuildContext context, AppState appState) {
    final sample = appState.activeSample!;
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Station ID: ${sample.stationId}',
          style: theme.textTheme.bodyMedium,
        ),
        Text(
          'Date: ${_formatDate(sample.date)}',
          style: theme.textTheme.bodyMedium,
        ),
        if (sample.habitat != null)
          Text('Habitat: ${sample.habitat}', style: theme.textTheme.bodyMedium),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            'Total Count: ${appState.totalCurrentCount}',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _summaryTile(
    BuildContext context, {
    required String title,
    required String value,
  }) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Text(
          title,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusTable(
    BuildContext context,
    AppState appState,
    List<Sample> samples,
  ) {
    final theme = Theme.of(context);
    if (samples.isEmpty) {
      return Text('No samples', style: theme.textTheme.bodyMedium);
    }
    final items = List<Sample>.from(samples);
    items.sort((a, b) {
      int cmp;
      switch (_sortColumnIndex) {
        case 0:
          cmp = a.date.compareTo(b.date);
          break;
        case 1:
          cmp = (a.sampleType).toLowerCase().compareTo(
            (b.sampleType).toLowerCase(),
          );
          break;
        case 2:
          cmp = (a.client ?? '').toLowerCase().compareTo(
            (b.client ?? '').toLowerCase(),
          );
          break;
        case 3:
          cmp = a.stationId.toLowerCase().compareTo(b.stationId.toLowerCase());
          break;
        case 4:
          cmp = (a.completed ? 1 : 0).compareTo(b.completed ? 1 : 0);
          break;
        case 5:
          cmp = (a.biologistId ?? '').toLowerCase().compareTo(
            (b.biologistId ?? '').toLowerCase(),
          );
          break;
        default:
          cmp = a.date.compareTo(b.date);
      }
      return _sortAscending ? cmp : -cmp;
    });

    final columns = [
      DataColumn(
        label: const Text('Date'),
        onSort: (i, asc) {
          setState(() {
            if (_sortColumnIndex != i) {
              _sortAscending = false;
            } else {
              _sortAscending = !_sortAscending;
            }
            _sortColumnIndex = i;
          });
        },
      ),
      DataColumn(
        label: const Text('Type'),
        onSort: (i, asc) {
          setState(() {
            if (_sortColumnIndex != i) {
              _sortAscending = false;
            } else {
              _sortAscending = !_sortAscending;
            }
            _sortColumnIndex = i;
          });
        },
      ),
      DataColumn(
        label: const Text('Client'),
        onSort: (i, asc) {
          setState(() {
            if (_sortColumnIndex != i) {
              _sortAscending = false;
            } else {
              _sortAscending = !_sortAscending;
            }
            _sortColumnIndex = i;
          });
        },
      ),
      DataColumn(
        label: const Text('Station'),
        onSort: (i, asc) {
          setState(() {
            if (_sortColumnIndex != i) {
              _sortAscending = false;
            } else {
              _sortAscending = !_sortAscending;
            }
            _sortColumnIndex = i;
          });
        },
      ),
      DataColumn(
        label: const Text('Status'),
        onSort: (i, asc) {
          setState(() {
            if (_sortColumnIndex != i) {
              _sortAscending = false;
            } else {
              _sortAscending = !_sortAscending;
            }
            _sortColumnIndex = i;
          });
        },
      ),
      DataColumn(
        label: const Text('Biologist'),
        onSort: (i, asc) {
          setState(() {
            if (_sortColumnIndex != i) {
              _sortAscending = false;
            } else {
              _sortAscending = !_sortAscending;
            }
            _sortColumnIndex = i;
          });
        },
      ),
    ];

    final rows = items.map((s) {
      return DataRow(
        cells: [
          DataCell(
            InkWell(
              onTap: () => _openAnalysisWithBiologistGate(context, s, appState),
              child: Text(_formatDate(s.date)),
            ),
          ),
          DataCell(
            Text(s.sampleType),
            onTap: () => _openAnalysisWithBiologistGate(context, s, appState),
          ),
          DataCell(
            Text(s.client ?? ''),
            onTap: () => _openAnalysisWithBiologistGate(context, s, appState),
          ),
          DataCell(
            Text(s.stationId),
            onTap: () => _openAnalysisWithBiologistGate(context, s, appState),
          ),
          DataCell(
            Text(s.completed ? 'Completed' : 'Pending'),
            onTap: () => _openAnalysisWithBiologistGate(context, s, appState),
          ),
          DataCell(
            Text(s.biologistId ?? ''),
            onTap: () => _openAnalysisWithBiologistGate(context, s, appState),
          ),
        ],
      );
    }).toList();
    final minWidth = MediaQuery.of(context).size.width;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: ConstrainedBox(
          constraints: BoxConstraints(minWidth: minWidth),
          child: DataTable(
            columns: columns,
            rows: rows,
            sortColumnIndex: _sortColumnIndex,
            sortAscending: _sortAscending,
            showCheckboxColumn: false,
          ),
        ),
      ),
    );
  }

  void _openAnalysisWithBiologistGate(
    BuildContext context,
    Sample s,
    AppState appState,
  ) {
    if ((s.biologistId ?? '').isEmpty) {
      final ctrl = TextEditingController();
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Enter Biologist ID'),
          content: TextField(
            controller: ctrl,
            decoration: const InputDecoration(
              labelText: 'Biologist ID',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                final id = ctrl.text.trim();
                if (id.isEmpty) return;
                final updated = Sample(
                  id: s.id,
                  stationId: s.stationId,
                  date: s.date,
                  lat: s.lat,
                  lon: s.lon,
                  habitat: s.habitat,
                  client: s.client,
                  biologistId: id,
                  remarks: s.remarks,
                  completed: s.completed,
                  sampleType: s.sampleType,
                  orderId: s.orderId,
                  sampleMarking: s.sampleMarking,
                  receiveId: s.receiveId,
                  analyzedDate: s.analyzedDate,
                );
                await appState.updateSample(updated);
                // ignore: use_build_context_synchronously
                Navigator.pop(context);
                appState.setActiveSample(updated);
                Navigator.pushNamed(context, AppRoutes.analysis);
              },
              child: const Text('Continue'),
            ),
          ],
        ),
      );
      return;
    }
    appState.setActiveSample(s);
    Navigator.pushNamed(context, AppRoutes.analysis);
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}
