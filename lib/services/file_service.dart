import 'dart:convert';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/module.dart';

class FileService {
  static const String _backupKey = 'app_backup';

  static Future<void> exportData(List<Module> modules) async {
    try {
      final exportData = {
        'modules': modules.map((m) => m.toJson()).toList(),
        'exportDate': DateTime.now().toIso8601String(),
        'version': '1.0',
      };
      final jsonData = jsonEncode(exportData);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_backupKey, jsonData);
    } catch (e) {
      throw Exception('Failed to export data: $e');
    }
  }

  static Future<List<Module>> importDataFromFile() async {
    try {
      // For now, we'll use the local backup
      final prefs = await SharedPreferences.getInstance();
      final jsonData = prefs.getString(_backupKey);
      if (jsonData == null) {
        throw Exception('No backup data found');
      }
      final Map<String, dynamic> importData = jsonDecode(jsonData);
      if (!importData.containsKey('modules')) {
        throw Exception('Invalid backup file format');
      }
      final List<Module> modules = (importData['modules'] as List)
          .map((json) => Module.fromJson(json as Map<String, dynamic>))
          .toList();
      return modules;
    } catch (e) {
      throw Exception('Failed to import data: $e');
    }
  }

  static Future<List<Module>> importData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonData = prefs.getString(_backupKey);
      if (jsonData == null) {
        throw Exception('No backup data found');
      }
      final Map<String, dynamic> importData = jsonDecode(jsonData);
      if (!importData.containsKey('modules')) {
        throw Exception('Invalid backup file format');
      }
      final List<Module> modules = (importData['modules'] as List)
          .map((json) => Module.fromJson(json as Map<String, dynamic>))
          .toList();
      return modules;
    } catch (e) {
      throw Exception('Failed to import data: $e');
    }
  }
} 