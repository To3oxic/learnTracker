import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../models/module.dart';
import '../models/task.dart';
import '../models/priority.dart';

class ModuleDetailPage extends StatefulWidget {
  final Module module;
  final VoidCallback onModuleUpdated;
  final Function(Module) onModuleDeleted;

  const ModuleDetailPage({
    super.key,
    required this.module,
    required this.onModuleUpdated,
    required this.onModuleDeleted,
  });

  @override
  State<ModuleDetailPage> createState() => _ModuleDetailPageState();
}

class _ModuleDetailPageState extends State<ModuleDetailPage> with TickerProviderStateMixin {
  bool _showCompletedTasks = false;
  bool _isTaskFormExpanded = false;
  String _sortBy = 'name';
  late AnimationController _animationController;
  late Animation<double> _animation;
  String? _editingTaskId;
  final _editTitleController = TextEditingController();
  final _editDescriptionController = TextEditingController();
  Map<String, AnimationController> _taskCompletionAnimations = {};
  List<Task> _currentTasks = [];

  // Task creation form controllers
  final _taskTitleController = TextEditingController();
  final _taskDescriptionController = TextEditingController();
  DateTime? _taskStartDate;
  DateTime? _taskEndDate;
  Priority _taskPriority = Priority.medium;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _currentTasks = List.from(widget.module.tasks);
  }

  @override
  void didUpdateWidget(ModuleDetailPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.module != widget.module) {
      _currentTasks = List.from(widget.module.tasks);
    }
  }

  @override
  void dispose() {
    _taskTitleController.dispose();
    _taskDescriptionController.dispose();
    _editTitleController.dispose();
    _editDescriptionController.dispose();
    _animationController.dispose();
    for (var controller in _taskCompletionAnimations.values) {
      controller.dispose();
    }
    super.dispose();
  }

  AnimationController _getTaskAnimationController(String taskId) {
    if (!_taskCompletionAnimations.containsKey(taskId)) {
      _taskCompletionAnimations[taskId] = AnimationController(
        duration: const Duration(milliseconds: 500),
        vsync: this,
      );
    }
    return _taskCompletionAnimations[taskId]!;
  }

  void _toggleTaskCompletion(Task task) {
    final controller = _getTaskAnimationController(task.id);
    controller.forward().then((_) {
      setState(() {
        task.toggleCompletion();
        widget.module.updateCompletionStatus();
        // Update the task in _currentTasks
        final index = _currentTasks.indexWhere((t) => t.id == task.id);
        if (index != -1) {
          _currentTasks[index] = task;
        }
      });
      widget.onModuleUpdated();
      controller.reset();
    });
  }

  void _toggleTaskForm() {
    setState(() {
      _isTaskFormExpanded = !_isTaskFormExpanded;
      if (_isTaskFormExpanded) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }

  Future<void> _selectTaskDate(BuildContext context, bool isStartDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _taskStartDate = picked;
        } else {
          _taskEndDate = picked;
        }
      });
    }
  }

  void _createTask() {
    final l10n = AppLocalizations.of(context)!;
    if (_taskTitleController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.pleaseEnterTaskTitle)),
      );
      return;
    }

    if (_taskEndDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.pleaseSelectEndDate)),
      );
      return;
    }

    final task = Task(
      id: const Uuid().v4(),
      title: _taskTitleController.text,
      description: _taskDescriptionController.text,
      startDate: _taskStartDate,
      endDate: _taskEndDate,
      priority: _taskPriority,
    );

    setState(() {
      widget.module.addTask(task);
      _currentTasks.add(task); // Add to _currentTasks
      _taskTitleController.clear();
      _taskDescriptionController.clear();
      _taskStartDate = null;
      _taskEndDate = null;
      _taskPriority = Priority.medium;
      _isTaskFormExpanded = false;
      _animationController.reverse();
    });
    widget.onModuleUpdated();
  }

  void _showDeleteTaskConfirmation(Task task) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.deleteTask),
        content: Text('${l10n.areYouSureYouWantToDelete} "${task.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                widget.module.removeTask(task.id);
                _currentTasks.removeWhere((t) => t.id == task.id); // Remove from _currentTasks
                if (_editingTaskId == task.id) {
                  _editingTaskId = null;
                }
              });
              widget.onModuleUpdated();
              Navigator.pop(context);
            },
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
  }

  void _startEditingTask(Task task) {
    setState(() {
      _editingTaskId = task.id;
      _editTitleController.text = task.title;
      _editDescriptionController.text = task.description ?? '';
    });
  }

  void _saveTaskEdits(Task task) {
    setState(() {
      task.title = _editTitleController.text;
      task.description = _editDescriptionController.text;
      // Update the task in _currentTasks
      final index = _currentTasks.indexWhere((t) => t.id == task.id);
      if (index != -1) {
        _currentTasks[index] = task;
      }
      _editingTaskId = null;
    });
    widget.onModuleUpdated();
  }

  String _getTimeRemaining() {
    final now = DateTime.now();
    final difference = widget.module.endDate.difference(now);
    
    if (difference.isNegative) {
      return 'Overdue by ${difference.inDays.abs()} days';
    }
    
    if (difference.inDays > 0) {
      return '${difference.inDays} days remaining';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hours remaining';
    } else {
      return '${difference.inMinutes} minutes remaining';
    }
  }

  List<Task> get _activeTasks {
    var tasks = _currentTasks.where((task) => !task.isCompleted).toList();

    switch (_sortBy) {
      case 'name':
        tasks.sort((a, b) => a.title.compareTo(b.title));
        break;
      case 'date':
        tasks.sort((a, b) => (a.endDate ?? DateTime.now()).compareTo(b.endDate ?? DateTime.now()));
        break;
      case 'priority':
        tasks.sort((a, b) => b.priority.index.compareTo(a.priority.index));
        break;
    }

    return tasks;
  }

  List<Task> get _completedTasks {
    var tasks = _currentTasks.where((task) => task.isCompleted).toList();

    switch (_sortBy) {
      case 'name':
        tasks.sort((a, b) => a.title.compareTo(b.title));
        break;
      case 'date':
        tasks.sort((a, b) => (a.endDate ?? DateTime.now()).compareTo(b.endDate ?? DateTime.now()));
        break;
      case 'priority':
        tasks.sort((a, b) => b.priority.index.compareTo(a.priority.index));
        break;
    }

    return tasks;
  }

  Color _getTaskColor(Priority priority) {
    switch (priority) {
      case Priority.high:
        return Colors.red.shade900;
      case Priority.medium:
        return Colors.orange.shade900;
      case Priority.low:
        return Colors.green.shade900;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.module.title),
        actions: [
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
                      ListTile(
                        title: Text(l10n.priority),
                        onTap: () {
                          setState(() => _sortBy = 'priority');
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
            icon: const Icon(Icons.delete),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text(l10n.deleteModule),
                  content: Text('${l10n.areYouSureYouWantToDelete} "${widget.module.title}"?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(l10n.cancel),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.pop(context);
                        widget.module.markAsDeleted();
                        widget.onModuleDeleted(widget.module);
                      },
                      child: Text(l10n.delete),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Card(
            margin: const EdgeInsets.all(8.0),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.timeRemaining,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _getTimeRemaining(),
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: widget.module.isOverdue ? Colors.red : null,
                    ),
                  ),
                  const SizedBox(height: 16),
                  LinearProgressIndicator(
                    value: widget.module.progress,
                    backgroundColor: Colors.grey[200],
                    valueColor: AlwaysStoppedAnimation<Color>(
                      widget.module.isOverdue ? Colors.red : Colors.green,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: ListView(
              children: [
                if (_activeTasks.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      l10n.activeTasks,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  ..._activeTasks.map((task) => _buildTaskCard(task)),
                ],
                if (_completedTasks.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Card(
                    margin: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: ExpansionTile(
                      title: Row(
                        children: [
                          Text(
                            l10n.completedTasks,
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
                              _completedTasks.length.toString(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      initiallyExpanded: _showCompletedTasks,
                      onExpansionChanged: (expanded) {
                        setState(() {
                          _showCompletedTasks = expanded;
                        });
                      },
                      children: _completedTasks.map((task) => _buildTaskCard(task)).toList(),
                    ),
                  ),
                ],
                if (_activeTasks.isEmpty && _completedTasks.isEmpty)
                  Center(child: Text(l10n.noTasks)),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          if (_isTaskFormExpanded)
            SizeTransition(
              sizeFactor: _animation,
              child: Container(
                margin: const EdgeInsets.all(16.0),
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: _taskTitleController,
                      decoration: InputDecoration(
                        labelText: l10n.taskTitle,
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _taskDescriptionController,
                      decoration: InputDecoration(
                        labelText: l10n.description,
                        border: const OutlineInputBorder(),
                      ),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: ListTile(
                            title: Text(l10n.startDate),
                            subtitle: Text(_taskStartDate?.toString().split(' ')[0] ?? l10n.notSet),
                            trailing: const Icon(Icons.calendar_today),
                            onTap: () => _selectTaskDate(context, true),
                          ),
                        ),
                        Expanded(
                          child: ListTile(
                            title: Text(l10n.endDate),
                            subtitle: Text(_taskEndDate?.toString().split(' ')[0] ?? l10n.required),
                            trailing: const Icon(Icons.calendar_today),
                            onTap: () => _selectTaskDate(context, false),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<Priority>(
                      value: _taskPriority,
                      decoration: InputDecoration(
                        labelText: l10n.priority,
                        border: const OutlineInputBorder(),
                      ),
                      items: Priority.values.map((Priority priority) {
                        return DropdownMenuItem<Priority>(
                          value: priority,
                          child: Text(priority.toString().split('.').last),
                        );
                      }).toList(),
                      onChanged: (Priority? newValue) {
                        if (newValue != null) {
                          setState(() {
                            _taskPriority = newValue;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: _toggleTaskForm,
                          child: Text(l10n.cancel),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: _createTask,
                          child: Text(l10n.createTask),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 16),
          FloatingActionButton.extended(
            onPressed: _toggleTaskForm,
            icon: Icon(_isTaskFormExpanded ? Icons.close : Icons.add),
            label: Text(_isTaskFormExpanded ? l10n.cancel : l10n.newTask),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskCard(Task task) {
    final isEditing = _editingTaskId == task.id;
    final isExpanded = isEditing || (task.description?.isNotEmpty ?? false);
    final animationController = _getTaskAnimationController(task.id);
    final starAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: animationController,
        curve: Curves.easeInOut,
      ),
    );

    return Card(
      color: _getTaskColor(task.priority),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        child: Column(
          children: [
            if (!isEditing)
              ListTile(
                title: Text(
                  task.title,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    decoration: task.isCompleted ? TextDecoration.lineThrough : TextDecoration.none,
                  ),
                ),
                subtitle: isExpanded
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (task.description?.isNotEmpty ?? false) ...[
                            const SizedBox(height: 8),
                            Text(
                              task.description!,
                              style: const TextStyle(color: Colors.white),
                            ),
                          ],
                          if (task.endDate != null) ...[
                            const SizedBox(height: 8),
                            Text(
                              'Due: ${task.endDate!.toString().split(' ')[0]}',
                              style: const TextStyle(color: Colors.white70),
                            ),
                          ],
                        ],
                      )
                    : null,
                onTap: () => _startEditingTask(task),
              )
            else
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.white),
                          onPressed: () => _showDeleteTaskConfirmation(task),
                        ),
                      ],
                    ),
                    TextField(
                      controller: _editTitleController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: 'Task Title',
                        labelStyle: TextStyle(color: Colors.white70),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.white30),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.white),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _editDescriptionController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: 'Description (optional)',
                        labelStyle: TextStyle(color: Colors.white70),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.white30),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.white),
                        ),
                      ),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: ListTile(
                            title: const Text(
                              'Start Date',
                              style: TextStyle(color: Colors.white70),
                            ),
                            subtitle: Text(
                              task.startDate?.toString().split(' ')[0] ?? 'Not set',
                              style: const TextStyle(color: Colors.white),
                            ),
                            trailing: const Icon(Icons.calendar_today, color: Colors.white70),
                            onTap: () => _selectTaskDate(context, true),
                          ),
                        ),
                        Expanded(
                          child: ListTile(
                            title: const Text(
                              'End Date',
                              style: TextStyle(color: Colors.white70),
                            ),
                            subtitle: Text(
                              task.endDate?.toString().split(' ')[0] ?? 'Required',
                              style: const TextStyle(color: Colors.white),
                            ),
                            trailing: const Icon(Icons.calendar_today, color: Colors.white70),
                            onTap: () => _selectTaskDate(context, false),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<Priority>(
                      value: task.priority,
                      dropdownColor: _getTaskColor(task.priority),
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: 'Priority',
                        labelStyle: TextStyle(color: Colors.white70),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.white30),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.white),
                        ),
                      ),
                      items: Priority.values.map((Priority priority) {
                        return DropdownMenuItem<Priority>(
                          value: priority,
                          child: Text(
                            priority.toString().split('.').last,
                            style: const TextStyle(color: Colors.white),
                          ),
                        );
                      }).toList(),
                      onChanged: (Priority? newValue) {
                        if (newValue != null) {
                          setState(() {
                            task.priority = newValue;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () {
                            setState(() {
                              _editingTaskId = null;
                            });
                          },
                          child: const Text(
                            'Cancel',
                            style: TextStyle(color: Colors.white70),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () => _saveTaskEdits(task),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: _getTaskColor(task.priority),
                          ),
                          child: const Text('Save Changes'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            Align(
              alignment: Alignment.bottomRight,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: AnimatedBuilder(
                  animation: starAnimation,
                  builder: (context, child) {
                    return GestureDetector(
                      onTap: () => _toggleTaskCompletion(task),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.2),
                        ),
                        child: Center(
                          child: Icon(
                            Icons.star,
                            color: task.isCompleted
                                ? Colors.amber
                                : Colors.white.withOpacity(0.5),
                            size: 24 * (1 + starAnimation.value * 0.2),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 