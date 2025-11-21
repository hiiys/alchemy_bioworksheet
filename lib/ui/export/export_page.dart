import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:device_info_plus/device_info_plus.dart';
import '../../core/app_state.dart';
import '../../core/routing.dart';
import '../../services/analysis_upload_service.dart';
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
                Expanded(
                  child: FilledButton.icon(
                    onPressed:
                        _isExporting ||
                            _selectedClient == null ||
                            _selectedSampleIds.isEmpty
                        ? null
                        : () => _uploadSelectedSamples(appState),
                    icon: const Icon(Icons.cloud_upload),
                    label: const Text('Upload'),
                  ),
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

  Future<void> _uploadSelectedSamples(AppState appState) async {
    if (_selectedSampleIds.isEmpty) return;

    // Get device ID
    String deviceId = 'unknown';
    try {
      final deviceInfo = DeviceInfoPlugin();
      final androidInfo = await deviceInfo.androidInfo;
      deviceId = androidInfo.id;
    } catch (e) {
      print('Error getting device info: $e');
    }

    // Show loading dialog
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text('Uploading ${_selectedSampleIds.length} sample(s)...'),
          ],
        ),
      ),
    );

    try {
      final uploadService = AnalysisUploadService();
      int uploaded = 0;
      int alreadyUploaded = 0;
      int failed = 0;

      for (final sampleId in _selectedSampleIds) {
        try {
          // Check if already uploaded
          final exists = await uploadService.isSampleUploaded(
            sampleId,
            deviceId,
          );

          if (exists) {
            alreadyUploaded++;
            continue;
          }

          // Upload
          final docId = await uploadService.uploadSampleAnalysis(
            sampleId: sampleId,
            deviceId: deviceId,
          );

          if (docId != null) {
            uploaded++;
          } else {
            failed++;
          }
        } catch (e) {
          print('Error uploading sample $sampleId: $e');
          failed++;
        }
      }

      if (!mounted) return;
      Navigator.pop(context); // Close loading

      // Show result
      String message = '';
      Color color = Colors.green;

      if (uploaded > 0) {
        message = 'Successfully uploaded $uploaded sample(s)';
      }
      if (alreadyUploaded > 0) {
        if (message.isNotEmpty) message += '\n';
        message += '$alreadyUploaded sample(s) already uploaded';
        color = Colors.orange;
      }
      if (failed > 0) {
        if (message.isNotEmpty) message += '\n';
        message += '$failed sample(s) failed to upload';
        color = Colors.red;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: color,
          duration: const Duration(seconds: 4),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // Close loading
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

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
