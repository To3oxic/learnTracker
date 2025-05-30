import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'priority.dart';

class Task {
  final String id;
  String title;
  String? description;
  DateTime? startDate;
  DateTime? endDate;
  bool isCompleted;
  Priority priority;

  Task({
    required this.id,
    required this.title,
    this.description,
    this.startDate,
    this.endDate,
    this.isCompleted = false,
    this.priority = Priority.medium,
  });

  bool get isOverdue => endDate != null && endDate!.isBefore(DateTime.now());

  void toggleCompletion() {
    isCompleted = !isCompleted;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'startDate': startDate?.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'isCompleted': isCompleted,
      'priority': priority.toString(),
    };
  }

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      startDate: json['startDate'] != null ? DateTime.parse(json['startDate'] as String) : null,
      endDate: json['endDate'] != null ? DateTime.parse(json['endDate'] as String) : null,
      isCompleted: json['isCompleted'] as bool? ?? false,
      priority: Priority.values.firstWhere(
        (e) => e.toString() == json['priority'],
        orElse: () => Priority.medium,
      ),
    );
  }
} 