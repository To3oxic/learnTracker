import 'dart:convert';
import 'package:flutter/material.dart';
import 'task.dart';

class Module {
  final String id;
  String title;
  String description;
  final DateTime endDate;
  final List<Task> tasks;
  Color color;
  bool _isDeleted = false;

  Module({
    required this.id,
    required this.title,
    required this.description,
    required this.endDate,
    required this.color,
    List<Task>? tasks,
  }) : tasks = tasks ?? [];

  bool get isDeleted => _isDeleted;

  void markAsDeleted() {
    _isDeleted = true;
  }

  double get progress {
    if (tasks.isEmpty) return 0.0;
    final completedTasks = tasks.where((task) => task.isCompleted).length;
    return completedTasks / tasks.length;
  }

  bool get isCompleted => progress >= 1.0;

  bool get isOverdue => !isCompleted && endDate.isBefore(DateTime.now());

  void addTask(Task task) {
    tasks.add(task);
  }

  void removeTask(String taskId) {
    tasks.removeWhere((task) => task.id == taskId);
  }

  void updateCompletionStatus() {
    // This method is called when a task's completion status changes
    // It ensures the module's completion status is up to date
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'endDate': endDate.toIso8601String(),
      'tasks': tasks.map((task) => task.toJson()).toList(),
      'color': color.value,
      'isDeleted': _isDeleted,
    };
  }

  factory Module.fromJson(Map<String, dynamic> json) {
    return Module(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      endDate: DateTime.parse(json['endDate'] as String),
      color: Color(json['color'] as int),
      tasks: (json['tasks'] as List<dynamic>)
          .map((taskJson) => Task.fromJson(taskJson as Map<String, dynamic>))
          .toList(),
    ).._isDeleted = json['isDeleted'] as bool? ?? false;
  }
}

// Helper functions for encoding/decoding lists of modules
String encodeModules(List<Module> modules) => json.encode(
      modules.map<Map<String, dynamic>>((module) => module.toJson()).toList(),
    );

List<Module> decodeModules(String modulesString) =>
    (json.decode(modulesString) as List<dynamic>)
        .map<Module>((item) => Module.fromJson(item as Map<String, dynamic>))
        .toList(); 