import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/app_state.dart';
import '../../core/routing.dart';
import '../../data/models.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/bubble_chip.dart';
import '../widgets/counter_bar.dart';

class AnalysisPage extends StatefulWidget {
  const AnalysisPage({super.key});

  @override
  State<AnalysisPage> createState() => _AnalysisPageState();
}

class _AnalysisPageState extends State<AnalysisPage> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  Taxon? _selectedTaxon;
  List<Taxon> _searchResults = [];
  bool _isSearchExpanded = false;
  final FocusNode _searchFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _checkActiveSample();
  }

  void _checkActiveSample() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final appState = Provider.of<AppState>(context, listen: false);
      if (!appState.hasActiveSample) {
        _showNoActiveSampleDialog(context);
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);

    if (!appState.hasActiveSample) {
      return AppScaffold(
        title: AppPageTitles.analysis,
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.warning, size: 64, color: Colors.orange),
              SizedBox(height: 16),
              Text(
                'No Active Sample',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                'Please create a sample in Sample Info first',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    final currentChildren = appState.taxa.where((t) => !appState.taxa.any((c) => c.parentId == t.id)).toList();
    final currentCount = _selectedTaxon != null 
        ? appState.currentCounts[_selectedTaxon!.id] ?? 0
        : 0;

    return AppScaffold(
      title: AppPageTitles.analysis,
      actions: [
        IconButton(
          icon: const Icon(Icons.check_circle),
          onPressed: () async {
            await appState.markActiveSampleCompleted();
            // ignore: use_build_context_synchronously
            Navigator.pushNamed(context, AppRoutes.sampleList);
          },
          tooltip: 'Complete',
        ),
      ],
      body: Column(
        children: [
          
          
          // Search results overlay (when search is active and has query)
          if (_isSearchExpanded && _searchQuery.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              height: 200, // Fixed height for search results
              child: _buildSearchResults(context, _searchResults, appState),
            ),
          
          // Taxon grid (or empty when search overlay is active)
          Expanded(
            child: !_isSearchExpanded || _searchQuery.isEmpty
                ? _buildTaxonGrid(context, currentChildren, appState)
                : const SizedBox.shrink(),
          ),

          // Counter bar and search
          Column(
            children: [
              // Search bar (expanded when icon is tapped)
              if (_isSearchExpanded)
                Container(
                  padding: const EdgeInsets.all(16),
                  child: TextField(
                    controller: _searchController,
                    focusNode: _searchFocusNode,
                    decoration: InputDecoration(
                      labelText: 'Search taxa',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          _hideSearch();
                        },
                      ),
                      border: const OutlineInputBorder(),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                        if (value.isNotEmpty) {
                          final seen = <String>{};
                          final results = appState.taxa
                              .where((taxon) => taxon.name.toLowerCase().contains(value.toLowerCase()))
                              .toList()
                              ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
                          _searchResults = [];
                          for (final t in results) {
                            final key = t.name.toLowerCase();
                            if (!seen.contains(key)) {
                              seen.add(key);
                              _searchResults.add(t);
                            }
                          }
                        } else {
                          _searchResults.clear();
                        }
                      });
                    },
                    onSubmitted: (value) {
                      _hideSearch();
                    },
                  ),
                ),
              
              CounterBar(
                selectedTaxon: _selectedTaxon,
                count: currentCount,
                onIncrement: () => _incrementCount(appState),
                onDecrement: () => _decrementCount(appState),
                totalCount: appState.totalCurrentCount,
                onSearchTap: () {
                  setState(() {
                    _isSearchExpanded = !_isSearchExpanded;
                    if (_isSearchExpanded) {
                      _searchFocusNode.requestFocus();
                    } else {
                      _hideSearch();
                    }
                  });
                },
              ),
              
              // bottom-most counter bar only; no extra bar below
            ],
          ),
        ],
      ),
    );
  }

  

  Widget _buildTaxonGrid(BuildContext context, List<Taxon> taxa, AppState appState) {
    if (taxa.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.assignment, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No taxa available',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            SizedBox(height: 8),
            Text(
              'Add taxa in the Registration section',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    final items = List<Taxon>.from(taxa);
    int weight(String? rank) {
      final r = (rank ?? '').toLowerCase();
      if (r == 'phylum') return 0;
      if (r == 'class') return 1;
      if (r == 'order') return 2;
      if (r == 'family') return 3;
      if (r == 'genus') return 4;
      if (r == 'species') return 5;
      return 6;
    }
    items.sort((a, b) {
      final wa = weight(a.rank);
      final wb = weight(b.rank);
      if (wa != wb) return wa.compareTo(wb);
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });

    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        children: [
          for (final taxon in items)
            Builder(builder: (context) {
              final count = appState.currentCounts[taxon.id] ?? 0;
              final hasChildren = appState.taxa.any((t) => t.parentId == taxon.id);
              final isSelected = _selectedTaxon?.id == taxon.id;
              return BubbleChip(
                taxon: taxon,
                count: count,
                isSelected: isSelected,
                onTap: () {
                  if (hasChildren) {
                    appState.navigateToTaxon(taxon);
                    setState(() {
                      _selectedTaxon = null;
                    });
                  } else {
                    setState(() {
                      _selectedTaxon = taxon;
                    });
                  }
                },
              );
            }),
        ],
      ),
    );
  }

  Widget _buildSearchResults(BuildContext context, List<Taxon> results, AppState appState) {
    if (results.isEmpty) {
      return const Center(
        child: Text('No taxa found'),
      );
    }

    final items = List<Taxon>.from(results);
    int weight(String? rank) {
      final r = (rank ?? '').toLowerCase();
      if (r == 'phylum') return 0;
      if (r == 'class') return 1;
      if (r == 'order') return 2;
      if (r == 'family') return 3;
      if (r == 'genus') return 4;
      if (r == 'species') return 5;
      return 6;
    }
    items.sort((a, b) {
      final wa = weight(a.rank);
      final wb = weight(b.rank);
      if (wa != wb) return wa.compareTo(wb);
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });

    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        children: [
          for (final taxon in items)
            Builder(builder: (context) {
              final count = appState.currentCounts[taxon.id] ?? 0;
              final hasChildren = appState.taxa.any((t) => t.parentId == taxon.id);
              final isSelected = _selectedTaxon?.id == taxon.id;
              return BubbleChip(
                taxon: taxon,
                count: count,
                isSelected: isSelected,
                onTap: () {
                  if (hasChildren) {
                    appState.navigateToTaxon(taxon);
                    setState(() {
                      _selectedTaxon = null;
                    });
                  } else {
                    setState(() {
                      _selectedTaxon = taxon;
                    });
                  }
                  _hideSearch();
                },
              );
            }),
        ],
      ),
    );
  }

  void _incrementCount(AppState appState) {
    if (_selectedTaxon != null) {
      appState.incrementCount(_selectedTaxon!.id!);
    }
  }

  void _decrementCount(AppState appState) {
    if (_selectedTaxon != null) {
      appState.decrementCount(_selectedTaxon!.id!);
    }
  }

  // Note: Undo and Save functionality removed - counts are automatically saved

  void _hideSearch() {
    setState(() {
      _isSearchExpanded = false;
      _searchQuery = '';
      _searchResults.clear();
      _searchController.clear();
      _searchFocusNode.unfocus();
    });
  }

  void _showNoActiveSampleDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('No Active Sample'),
        content: const Text('You need to create a sample before you can start counting.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, AppRoutes.sampleInfo);
            },
            child: const Text('Create Sample'),
          ),
        ],
      ),
    );
  }
}
