import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/app_state.dart';
import '../../core/routing.dart';
import '../../data/models.dart';
import '../widgets/app_scaffold.dart';

class SampleListPage extends StatefulWidget {
  const SampleListPage({super.key});

  @override
  State<SampleListPage> createState() => _SampleListPageState();
}

class _SampleListPageState extends State<SampleListPage> {
  String? selectedClient;

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final clients = appState.samples
        .map((s) => s.client)
        .where((c) => c != null && c.isNotEmpty)
        .cast<String>()
        .toSet()
        .toList()
      ..sort();

    return AppScaffold(
      title: AppPageTitles.sampleList,
      body: appState.samples.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.list, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'No samples yet',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Create your first sample in Sample Info',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: selectedClient,
                          items: [
                            const DropdownMenuItem<String>(value: '', child: Text('All Clients')),
                            ...clients.map((c) => DropdownMenuItem<String>(value: c, child: Text(c))),
                          ],
                          onChanged: (v) => setState(() => selectedClient = v),
                          decoration: const InputDecoration(
                            labelText: 'Filter by Client ID',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(child: _buildGroupedList(context, appState)),
              ],
            ),
    );
  }

  Widget _buildGroupedList(BuildContext context, AppState appState) {
    final theme = Theme.of(context);
    final grouped = <String, List<Sample>>{};
    for (final s in appState.samples.where((s) => selectedClient == null || selectedClient == '' || s.client == selectedClient)) {
      final key = (s.client == null || s.client!.isEmpty) ? 'Unknown Client' : s.client!;
      grouped.putIfAbsent(key, () => []);
      grouped[key]!.add(s);
    }
    final keys = grouped.keys.toList()..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    final children = <Widget>[];
    for (final key in keys) {
      final items = grouped[key]!;
      children.add(Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        color: theme.colorScheme.surfaceContainerHighest,
        child: Row(
          children: [
            const Icon(Icons.badge),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                key,
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text('${items.length} samples', style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.primary)),
            ),
          ],
        ),
      ));
      for (final sample in items) {
        children.add(_buildSampleCardWithCount(context, sample, appState));
      }
    }
    return ListView(children: children);
  }

  Widget _buildSampleCardWithCount(BuildContext context, Sample sample, AppState appState) {
    return FutureBuilder<int>(
      future: appState.getTotalCountForSample(sample.id ?? 0),
      builder: (context, snapshot) {
        final totalCount = snapshot.data ?? 0;
        return _buildSampleCard(context, sample, totalCount, appState);
      },
    );
  }

  Widget _buildSampleCard(BuildContext context, Sample sample, int totalCount, AppState appState) {
    final theme = Theme.of(context);
    final isActive = appState.activeSample?.id == sample.id;
    final isCompleted = sample.completed;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: isActive 
                ? theme.colorScheme.primary.withValues(alpha: 0.1)
                : theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Icon(
                isActive ? Icons.play_arrow : Icons.description,
                color: isActive ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant,
              ),
              if (isCompleted)
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Icon(Icons.check_circle, color: Colors.green, size: 18),
                ),
            ],
          ),
        ),
        title: Text(
          sample.stationId,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(_formatDate(sample.date)),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    sample.sampleType,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSecondaryContainer,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            if (sample.habitat != null) Text(sample.habitat!),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'Total: $totalCount',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  isCompleted ? Icons.check_circle : Icons.hourglass_bottom,
                  size: 16,
                  color: isCompleted ? Colors.green : theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
                const SizedBox(width: 4),
                Text(
                  isCompleted ? 'Completed' : 'Pending',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: isCompleted ? Colors.green : theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.visibility),
              onPressed: () => _viewSample(context, sample, appState),
              tooltip: 'View/Continue',
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => _deleteSample(context, sample, appState),
              tooltip: 'Delete',
            ),
          ],
        ),
        onTap: () => _viewSample(context, sample, appState),
        onLongPress: () => _showSampleOptions(context, sample, appState),
      ),
    );
  }

  void _viewSample(BuildContext context, Sample sample, AppState appState) {
    appState.setActiveSample(sample);
    Navigator.pushNamed(context, AppRoutes.analysis);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Switched to sample: ${sample.stationId}')),
    );
  }

  void _deleteSample(BuildContext context, Sample sample, AppState appState) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Sample'),
        content: Text('Are you sure you want to delete sample "${sample.stationId}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              appState.deleteSample(sample.id!);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Deleted sample: ${sample.stationId}')),
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

  void _showSampleOptions(BuildContext context, Sample sample, AppState appState) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.play_arrow),
            title: const Text('Set as Active'),
            onTap: () {
              appState.setActiveSample(sample);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Set as active: ${sample.stationId}')),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.analytics),
            title: const Text('Continue Counting'),
            onTap: () {
              appState.setActiveSample(sample);
              Navigator.pop(context);
              Navigator.pushNamed(context, AppRoutes.analysis);
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete, color: Colors.red),
            title: const Text('Delete Sample'),
            onTap: () {
              Navigator.pop(context);
              _deleteSample(context, sample, appState);
            },
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}
