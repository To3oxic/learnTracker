import 'package:flutter/material.dart';
import '../models/module.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class ViewModulePage extends StatefulWidget {
  final Module module;

  const ViewModulePage({super.key, required this.module});

  @override
  State<ViewModulePage> createState() => _ViewModulePageState();
}

class _ViewModulePageState extends State<ViewModulePage> {
  final _taskNameController = TextEditingController();
  late List<Task> _tasks;
  late String _moduleName;
  late String _priority;

  @override
  void initState() {
    super.initState();
    // Make a mutable copy of tasks to allow for checking/unchecking and adding
    _tasks = List<Task>.from(widget.module.tasks.map((task) => Task(name: task.name, isCompleted: task.isCompleted)));
    _moduleName = widget.module.name;
    _priority = widget.module.priority;
  }

  void _addTask() {
    if (_taskNameController.text.isNotEmpty) {
      setState(() {
        _tasks.add(Task(name: _taskNameController.text));
        _taskNameController.clear();
      });
    }
  }

  void _saveChangesAndExit() {
    // Update the original module's tasks before popping
    widget.module.tasks.clear();
    widget.module.tasks.addAll(_tasks);
    Navigator.pop(context, true); // Indicate that changes were made
  }

  @override
  void dispose() {
    _taskNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(_moduleName),
        actions: [
          IconButton(
            icon: const Icon(Icons.save_alt_outlined),
            tooltip: '${l10n.saveChanges}',
            onPressed: _saveChangesAndExit,
          )
        ],
      ),
      body: WillPopScope( // Ensures changes are prompted to be saved or are saved on back press
        onWillPop: () async {
          _saveChangesAndExit();
          return true; // Allow pop
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: ListView(
            children: <Widget>[
              Card(
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 16),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${l10n.moduleDetails}', style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Theme.of(context).colorScheme.primary)),
                      const SizedBox(height: 12),
                      Text('${l10n.name}: $_moduleName', style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 8),
                      Text('${l10n.priority}: $_priority', style: Theme.of(context).textTheme.titleMedium),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text('${l10n.tasks}', style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Theme.of(context).colorScheme.primary)),
              const Divider(),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _taskNameController,
                      decoration: const InputDecoration(labelText: '${l10n.newTaskName}'),
                      onFieldSubmitted: (_) => _addTask(),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.add_circle_outline, color: Theme.of(context).colorScheme.primary),
                    onPressed: _addTask,
                    tooltip: '${l10n.addTask}',
                  ),
                ],
              ),
              const SizedBox(height: 10),
              _tasks.isEmpty
                  ? const Center(child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 20.0),
                      child: Text('${l10n.noTasksYetAddSome}', style: TextStyle(fontSize: 16, color: Colors.grey)),
                    ))
                  : ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _tasks.length,
                      itemBuilder: (context, index) {
                        final task = _tasks[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 4.0),
                          elevation: 1.5,
                          child: ListTile(
                            title: Text(task.name, style: TextStyle(decoration: task.isCompleted ? TextDecoration.lineThrough : null)),
                            trailing: Checkbox(
                              value: task.isCompleted,
                              activeColor: Theme.of(context).colorScheme.primary,
                              onChanged: (bool? value) {
                                setState(() {
                                  task.isCompleted = value ?? false;
                                });
                              },
                            ),
                            leading: IconButton(
                              icon: const Icon(Icons.remove_circle_outline, color: Colors.redAccent),
                              onPressed: () {
                                setState(() {
                                  _tasks.removeAt(index);
                                });
                              },
                            ),
                          ),
                        );
                      },
                    ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                icon: const Icon(Icons.check_circle_outline),
                label: const Text('${l10n.doneAndSaveChanges}'),
                onPressed: _saveChangesAndExit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 12)
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 