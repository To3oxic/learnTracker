import 'package:flutter/material.dart';
import '../models/module.dart';
import '../screens/view_module_page.dart'; // Import ViewModulePage
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class ModuleListItem extends StatelessWidget {
  final Module module;
  final VoidCallback onModuleUpdated; // Callback to notify HomePage to refresh

  const ModuleListItem({super.key, required this.module, required this.onModuleUpdated});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    int completedTasks = module.tasks.where((task) => task.isCompleted).length;
    int totalTasks = module.tasks.length;
    double progress = totalTasks > 0 ? completedTasks / totalTasks : 0.0;
    String percentage = (progress * 100).toStringAsFixed(0);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      elevation: 2.0,
      child: InkWell(
        onTap: () async {
          // Navigate to ViewModulePage and wait for a potential update
          final result = await Navigator.push<bool>(
            context,
            MaterialPageRoute(
              builder: (context) => ViewModulePage(module: module),
            ),
          );
          // If ViewModulePage indicated changes were made, call the callback
          if (result == true) {
            onModuleUpdated();
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(module.name, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text('${l10n.priority}: ${module.priority}', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 8),
              if (totalTasks > 0)
                Row(
                  children: [
                    Expanded(
                      child: LinearProgressIndicator(
                        value: progress,
                        backgroundColor: Colors.grey[300],
                        valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).colorScheme.primary),
                        minHeight: 6,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text('$percentage%', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                  ],
                )
              else
                Text('${l10n.noTasks}', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey)),
              const SizedBox(height: 4),
              Text('${l10n.completedTasks}: $completedTasks ${l10n.of} $totalTasks ${l10n.taskCompleted}', style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
      ),
    );
  }
} 