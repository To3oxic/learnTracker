import 'package:flutter/material.dart';
import '../models/module.dart';
import 'module_detail_page.dart';
import 'statistics_page.dart';
import 'package:learn_progress_tracker/l10n/app_localizations.dart';

class ModulesListPage extends StatefulWidget {
  final List<Module> modules;
  final VoidCallback onModuleUpdated;
  final Function(Module) onModuleDeleted;

  const ModulesListPage({
    super.key,
    required this.modules,
    required this.onModuleUpdated,
    required this.onModuleDeleted,
  });

  @override
  State<ModulesListPage> createState() => _ModulesListPageState();
}

class _ModulesListPageState extends State<ModulesListPage> {
  String _searchQuery = '';
  String _sortBy = 'name';
  bool _showCompletedModules = false;

  List<Module> get _filteredModules {
    var filtered = widget.modules.where((module) {
      final matchesSearch = module.title.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesSearch && !module.isCompleted;
    }).toList();

    switch (_sortBy) {
      case 'name':
        filtered.sort((a, b) => a.title.compareTo(b.title));
        break;
      case 'date':
        filtered.sort((a, b) => a.endDate.compareTo(b.endDate));
        break;
    }

    return filtered;
  }

  List<Module> get _completedModules {
    var completed = widget.modules.where((module) {
      final matchesSearch = module.title.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesSearch && module.isCompleted;
    }).toList();

    switch (_sortBy) {
      case 'name':
        completed.sort((a, b) => a.title.compareTo(b.title));
        break;
      case 'date':
        completed.sort((a, b) => a.endDate.compareTo(b.endDate));
        break;
    }

    return completed;
  }

  Color _getModuleColor(String id) {
    final colors = [
      Colors.blue,
      Colors.green,
      Colors.purple,
      Colors.orange,
      Colors.teal,
      Colors.pink,
      Colors.indigo,
      Colors.amber,
    ];
    final index = id.hashCode.abs() % colors.length;
    return colors[index];
  }

  void _showDeleteConfirmation(Module module) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.deleteModule),
        content: Text('${l10n.areYouSureYouWantToDelete} "${module.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () {
              widget.onModuleDeleted(module);
              Navigator.pop(context);
            },
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
  }

  Widget _buildModuleCard(Module module) {
    final l10n = AppLocalizations.of(context)!;
    final color = _getModuleColor(module.id);
    return Card(
      color: color,
      child: ListTile(
        title: Text(
          module.title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${l10n.due}: ${module.endDate.toString().split(' ')[0]}',
              style: const TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Expanded(
                  child: LinearProgressIndicator(
                    value: module.progress,
                    backgroundColor: Colors.white24,
                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${(module.progress * 100).toStringAsFixed(0)}%',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
        onTap: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ModuleDetailPage(
                module: module,
                onModuleUpdated: widget.onModuleUpdated,
                onModuleDeleted: widget.onModuleDeleted,
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    hintText: l10n.searchModules,
                    prefixIcon: const Icon(Icons.search),
                    border: const OutlineInputBorder(),
                  ),
                  onChanged: (value) => setState(() => _searchQuery = value),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.sort),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: Text(l10n.sortBy),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ListTile(
                            title: Text(l10n.name),
                            onTap: () {
                              setState(() => _sortBy = 'name');
                              Navigator.pop(context);
                            },
                          ),
                          ListTile(
                            title: Text(l10n.date),
                            onTap: () {
                              setState(() => _sortBy = 'date');
                              Navigator.pop(context);
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.show_chart),
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                    ),
                    builder: (context) => DraggableScrollableSheet(
                      initialChildSize: 0.9,
                      maxChildSize: 0.9,
                      minChildSize: 0.5,
                      expand: false,
                      builder: (context, scrollController) => SingleChildScrollView(
                        controller: scrollController,
                        child: StatisticsPage(modules: widget.modules),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            children: [
              if (_filteredModules.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    l10n.activeModules,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                ..._filteredModules.map(_buildModuleCard),
              ],
              if (_completedModules.isNotEmpty) ...[
                const SizedBox(height: 16),
                Card(
                  margin: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: ExpansionTile(
                    title: Row(
                      children: [
                        Text(
                          l10n.completedModules,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            _completedModules.length.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    initiallyExpanded: _showCompletedModules,
                    onExpansionChanged: (expanded) {
                      setState(() {
                        _showCompletedModules = expanded;
                      });
                    },
                    children: _completedModules.map(_buildModuleCard).toList(),
                  ),
                ),
              ],
              if (_filteredModules.isEmpty && _completedModules.isEmpty)
                Center(child: Text(l10n.noModulesFound)),
            ],
          ),
        ),
      ],
    );
  }
} 