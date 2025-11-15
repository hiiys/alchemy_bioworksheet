import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/app_state.dart';
import '../../core/routing.dart';
import '../../data/models.dart';
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

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final pending = appState.samples.where((s) => !s.completed).toList();
    final completed = appState.samples.where((s) => s.completed).toList();

    return AppScaffold(
      title: AppPageTitles.home,
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
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _selectedSampleIds.isEmpty
                        ? null
                        : () {
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Delete Sample'),
                                content: const Text(
                                  'Are you sure you want to delete selected samples?',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text('Cancel'),
                                  ),
                                  TextButton(
                                    onPressed: () async {
                                      final appState = Provider.of<AppState>(
                                        context,
                                        listen: false,
                                      );
                                      for (final id
                                          in _selectedSampleIds.toList()) {
                                        await appState.deleteSample(id);
                                      }
                                      setState(() {
                                        _selectedSampleIds.clear();
                                        _selectAll = false;
                                      });
                                      // ignore: use_build_context_synchronously
                                      Navigator.pop(context);
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'Selected samples deleted',
                                          ),
                                        ),
                                      );
                                    },
                                    child: const Text('OK'),
                                  ),
                                ],
                              ),
                            );
                          },
                    icon: const Icon(Icons.delete),
                    label: const Text('Delete'),
                  ),
                ),
              ],
            ),
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
        case 1:
          cmp = a.date.compareTo(b.date);
          break;
        case 2:
          cmp = (a.sampleType).toLowerCase().compareTo(
            (b.sampleType).toLowerCase(),
          );
          break;
        case 3:
          cmp = (a.client ?? '').toLowerCase().compareTo(
            (b.client ?? '').toLowerCase(),
          );
          break;
        case 4:
          cmp = a.stationId.toLowerCase().compareTo(b.stationId.toLowerCase());
          break;
        case 5:
          cmp = (a.completed ? 1 : 0).compareTo(b.completed ? 1 : 0);
          break;
        default:
          cmp = a.date.compareTo(b.date);
      }
      return _sortAscending ? cmp : -cmp;
    });

    final columns = [
      DataColumn(
        label: Checkbox(
          value: _selectAll,
          onChanged: (v) {
            setState(() {
              _selectAll = v ?? false;
              _selectedSampleIds.clear();
              if (_selectAll) {
                for (final s in items) {
                  if (s.id != null) _selectedSampleIds.add(s.id!);
                }
              }
            });
          },
        ),
      ),
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
    ];

    final rows = items.map((s) {
      return DataRow(
        selected: s.id != null && _selectedSampleIds.contains(s.id!),
        cells: [
          DataCell(
            Checkbox(
              value: s.id != null && _selectedSampleIds.contains(s.id!),
              onChanged: (v) {
                setState(() {
                  if (s.id != null) {
                    if (v == true) {
                      _selectedSampleIds.add(s.id!);
                    } else {
                      _selectedSampleIds.remove(s.id!);
                    }
                    _selectAll =
                        _selectedSampleIds.length ==
                        items.where((e) => e.id != null).length;
                  }
                });
              },
            ),
          ),
          DataCell(
            InkWell(
              onTap: () {
                appState.setActiveSample(s);
                Navigator.pushNamed(context, AppRoutes.analysis);
              },
              child: Text(_formatDate(s.date)),
            ),
          ),
          DataCell(
            Text(s.sampleType),
            onTap: () {
              appState.setActiveSample(s);
              Navigator.pushNamed(context, AppRoutes.analysis);
            },
          ),
          DataCell(
            Text(s.client ?? ''),
            onTap: () {
              appState.setActiveSample(s);
              Navigator.pushNamed(context, AppRoutes.analysis);
            },
          ),
          DataCell(
            Text(s.stationId),
            onTap: () {
              appState.setActiveSample(s);
              Navigator.pushNamed(context, AppRoutes.analysis);
            },
          ),
          DataCell(
            Text(s.completed ? 'Completed' : 'Pending'),
            onTap: () {
              appState.setActiveSample(s);
              Navigator.pushNamed(context, AppRoutes.analysis);
            },
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

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}
