import 'package:flutter/material.dart';
import '../../data/models.dart';
import '../../services/analysis_upload_service.dart';
import '../widgets/app_scaffold.dart';

class ExportLogsPage extends StatefulWidget {
  const ExportLogsPage({super.key});

  @override
  State<ExportLogsPage> createState() => _ExportLogsPageState();
}

class _ExportLogsPageState extends State<ExportLogsPage> {
  final AnalysisUploadService _uploadService = AnalysisUploadService();
  List<AnalysisResult> _results = [];
  final Set<String> _selectedIds = {};
  bool _isLoading = true;
  bool _selectAll = false;

  @override
  void initState() {
    super.initState();
    _loadResults();
  }

  Future<void> _loadResults() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final results = await _uploadService.getAnalysisResults();
      setState(() {
        _results = results;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading export logs: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _toggleSelectAll(bool? value) {
    setState(() {
      _selectAll = value ?? false;
      if (_selectAll) {
        _selectedIds.clear();
        _selectedIds.addAll(_results.map((r) => r.id!));
      } else {
        _selectedIds.clear();
      }
    });
  }

  void _toggleSelection(String id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
        _selectAll = false;
      } else {
        _selectedIds.add(id);
        if (_selectedIds.length == _results.length) {
          _selectAll = true;
        }
      }
    });
  }

  Future<void> _deleteSelected() async {
    if (_selectedIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No records selected'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: Text(
          'Are you sure you want to delete ${_selectedIds.length} record(s)?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    // Show loading
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    int successCount = 0;
    int failCount = 0;

    for (final id in _selectedIds) {
      final success = await _uploadService.deleteAnalysisResult(id);
      if (success) {
        successCount++;
      } else {
        failCount++;
      }
    }

    if (!mounted) return;
    Navigator.pop(context); // Close loading dialog

    // Clear selection
    setState(() {
      _selectedIds.clear();
      _selectAll = false;
    });

    // Reload results
    await _loadResults();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Deleted $successCount record(s)${failCount > 0 ? ', failed: $failCount' : ''}',
        ),
        backgroundColor: failCount > 0 ? Colors.orange : Colors.green,
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  String _formatDateTime(DateTime date) {
    return '${_formatDate(date)} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Export Logs',
      actions: [
        if (_selectedIds.isNotEmpty)
          IconButton(
            icon: const Icon(Icons.delete),
            tooltip: 'Delete Selected',
            onPressed: _deleteSelected,
          ),
        IconButton(
          icon: const Icon(Icons.refresh),
          tooltip: 'Refresh',
          onPressed: _loadResults,
        ),
      ],
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _results.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.assignment, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'No export logs found',
                        style: TextStyle(fontSize: 18, color: Colors.grey),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Completed analyses will appear here',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    // Select all bar
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surfaceContainerHighest,
                        border: Border(
                          bottom: BorderSide(
                            color: Theme.of(context).dividerColor,
                          ),
                        ),
                      ),
                      child: Row(
                        children: [
                          Checkbox(
                            value: _selectAll,
                            onChanged: _toggleSelectAll,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _selectAll
                                ? 'Deselect All'
                                : 'Select All (${_results.length} records)',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          const Spacer(),
                          if (_selectedIds.isNotEmpty)
                            Text(
                              '${_selectedIds.length} selected',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context).colorScheme.primary,
                                  ),
                            ),
                        ],
                      ),
                    ),

                    // Results table
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: SingleChildScrollView(
                          scrollDirection: Axis.vertical,
                          child: DataTable(
                            columns: const [
                              DataColumn(label: Text('Select')),
                              DataColumn(label: Text('Report No.')),
                              DataColumn(label: Text('Client')),
                              DataColumn(label: Text('Station')),
                              DataColumn(label: Text('Type')),
                              DataColumn(label: Text('Biologist')),
                              DataColumn(label: Text('Analyzed')),
                              DataColumn(label: Text('Uploaded')),
                              DataColumn(label: Text('Taxa Count')),
                            ],
                            rows: _results.map((result) {
                              final isSelected = _selectedIds.contains(result.id);
                              return DataRow(
                                selected: isSelected,
                                cells: [
                                  DataCell(
                                    Checkbox(
                                      value: isSelected,
                                      onChanged: (_) => _toggleSelection(result.id!),
                                    ),
                                  ),
                                  DataCell(Text(result.reportNo ?? 'N/A')),
                                  DataCell(Text(result.clientName)),
                                  DataCell(Text(result.stationId)),
                                  DataCell(Text(result.specimenType)),
                                  DataCell(Text(result.biologistId)),
                                  DataCell(Text(_formatDate(result.analyzedDate))),
                                  DataCell(
                                    Text(
                                      result.uploadedAt != null
                                          ? _formatDateTime(result.uploadedAt!)
                                          : 'N/A',
                                    ),
                                  ),
                                  DataCell(Text(result.counts.length.toString())),
                                ],
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }
}
