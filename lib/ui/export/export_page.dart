import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/app_state.dart';
import '../../core/routing.dart';
import '../widgets/app_scaffold.dart';

class ExportPage extends StatefulWidget {
  const ExportPage({super.key});

  @override
  State<ExportPage> createState() => _ExportPageState();
}

class _ExportPageState extends State<ExportPage> {
  String? _selectedClient;
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 7));
  DateTime _endDate = DateTime.now();
  bool _isExporting = false;
  List<String> _generatedFiles = [];
  final Set<int> _selectedSampleIds = {};
  String _exportType = 'Macrobenthos';

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final clients =
        appState.samples
            .map((s) => s.client)
            .where((c) => c != null && c.isNotEmpty)
            .cast<String>()
            .toSet()
            .toList()
          ..sort();

    final expectedFilename = _selectedClient == null
        ? null
        : '${_exportType}_Results_${_selectedClient}_${_fmt(_startDate)}-${_fmt(_endDate)}.csv';

    return AppScaffold(
      title: AppPageTitles.export,
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _selectedClient,
                    items: clients
                        .map(
                          (c) => DropdownMenuItem<String>(
                            value: c,
                            child: Text(c),
                          ),
                        )
                        .toList(),
                    onChanged: (v) => setState(() => _selectedClient = v),
                    decoration: const InputDecoration(
                      labelText: 'Client',
                      border: OutlineInputBorder(),
                      isDense: false,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 16,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _DateField(
                    label: 'Start Date',
                    date: _startDate,
                    onPick: (d) => setState(() => _startDate = d),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _DateField(
                    label: 'End Date',
                    date: _endDate,
                    onPick: (d) => setState(() => _endDate = d),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              children: [
                ChoiceChip(
                  label: const Text('Phytoplankton'),
                  selected: _exportType == 'Phytoplankton',
                  onSelected: (_) =>
                      setState(() => _exportType = 'Phytoplankton'),
                ),
                ChoiceChip(
                  label: const Text('Zooplankton'),
                  selected: _exportType == 'Zooplankton',
                  onSelected: (_) =>
                      setState(() => _exportType = 'Zooplankton'),
                ),
                ChoiceChip(
                  label: const Text('Macrobenthos'),
                  selected: _exportType == 'Macrobenthos',
                  onSelected: (_) =>
                      setState(() => _exportType = 'Macrobenthos'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (expectedFilename != null)
              Row(
                children: [
                  const Icon(Icons.insert_drive_file_outlined),
                  const SizedBox(width: 8),
                  Expanded(child: Text('Expected file: $expectedFilename')),
                ],
              ),
            const SizedBox(height: 16),
            Row(
              children: [
                FilledButton.icon(
                  onPressed:
                      _isExporting ||
                          _selectedClient == null ||
                          _selectedSampleIds.isEmpty
                      ? null
                      : () async {
                          setState(() {
                            _isExporting = true;
                            _generatedFiles.clear();
                          });
                          try {
                            final file = await appState.exportCsvForSampleIds(
                              client: _selectedClient!,
                              sampleIds: _selectedSampleIds.toList(),
                              specimenType: _exportType,
                            );
                            setState(() {
                              _generatedFiles = [file];
                            });
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Exported: $file')),
                            );
                          } finally {
                            setState(() => _isExporting = false);
                          }
                        },
                  icon: const Icon(Icons.file_download),
                  label: const Text('Export CSV'),
                ),
                const SizedBox(width: 16),
                FilledButton.icon(
                  onPressed: _generatedFiles.isEmpty
                      ? null
                      : () => Share.shareXFiles(
                          _generatedFiles.map((p) => XFile(p)).toList(),
                        ),
                  icon: const Icon(Icons.share),
                  label: const Text('Share Results'),
                ),
                const SizedBox(width: 16),
                if (_isExporting) const CircularProgressIndicator(),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(child: _buildResultsList(appState)),
          ],
        ),
      ),
    );
  }

  String _fmt(DateTime d) =>
      '${d.year}${d.month.toString().padLeft(2, '0')}${d.day.toString().padLeft(2, '0')}';

  Widget _buildResultsList(AppState appState) {
    if (_selectedClient == null) {
      return const Center(child: Text('Select Client ID to list samples'));
    }
    final samples = appState.samples.where((s) {
      final matchesClient = s.client == _selectedClient;
      final withinDate =
          !s.date.isBefore(_startDate) && !s.date.isAfter(_endDate);
      final matchesType = s.sampleType == _exportType;
      return matchesClient && withinDate && matchesType;
    }).toList()..sort((a, b) => b.date.compareTo(a.date));
    if (samples.isEmpty) {
      return const Center(child: Text('No samples in selected range'));
    }
    return ListView.builder(
      itemCount: samples.length,
      itemBuilder: (context, index) {
        final s = samples[index];
        final selected = _selectedSampleIds.contains(s.id);
        return CheckboxListTile(
          value: selected,
          onChanged: (v) {
            setState(() {
              if (v == true) {
                _selectedSampleIds.add(s.id!);
              } else {
                _selectedSampleIds.remove(s.id!);
              }
            });
          },
          title: Text(s.stationId),
          subtitle: Text('${s.client} • ${_fmt(s.date)}'),
          secondary: Icon(
            s.completed ? Icons.check_circle : Icons.hourglass_bottom,
            color: s.completed
                ? Colors.green
                : Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        );
      },
    );
  }
}

class _DateField extends StatelessWidget {
  final String label;
  final DateTime date;
  final ValueChanged<DateTime> onPick;
  const _DateField({
    required this.label,
    required this.date,
    required this.onPick,
  });

  @override
  Widget build(BuildContext context) {
    return InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}',
            ),
          ),
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: date,
                firstDate: DateTime(2000),
                lastDate: DateTime(2100),
              );
              if (picked != null) onPick(picked);
            },
          ),
        ],
      ),
    );
  }
}
