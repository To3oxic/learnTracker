import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/module.dart';
import '../models/task.dart';

class PersistenceService {
  static const String _modulesKey = 'modules';
  static const String _settingsKey = 'settings';

  Future<List<Module>> loadModules() async {
    final prefs = await SharedPreferences.getInstance();
    final modulesData = prefs.getString(_modulesKey);
    
    if (modulesData == null) {
      return [];
    }

    try {
      final List<dynamic> modulesList = jsonDecode(modulesData);
      return modulesList.map((json) {
        try {
          return Module.fromJson(json as Map<String, dynamic>);
        } catch (e) {
          print('Error parsing module: $e');
          return null;
        }
      }).whereType<Module>().toList();
    } catch (e) {
      print('Error loading modules: $e');
      return [];
    }
  }

  Future<void> saveModules(List<Module> modules) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final modulesJson = jsonEncode(modules.map((module) => module.toJson()).toList());
      await prefs.setString(_modulesKey, modulesJson);
    } catch (e) {
      print('Error saving modules: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final settingsJson = prefs.getString(_settingsKey);
    if (settingsJson == null) {
      return {
        'language': 'en',
        'theme': 'light',
      };
    }
    return jsonDecode(settingsJson);
  }

  Future<void> saveSettings(Map<String, dynamic> settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_settingsKey, jsonEncode(settings));
  }

  Future<void> exportData() async {
    final modules = await loadModules();
    final settings = await loadSettings();
    
    final exportData = {
      'modules': modules.map((m) => m.toJson()).toList(),
      'settings': settings,
    };
    
    // TODO: Implement actual file export
    // For now, we'll just save to SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('export_data', jsonEncode(exportData));
  }

  Future<void> importData() async {
    final prefs = await SharedPreferences.getInstance();
    final exportDataJson = prefs.getString('export_data');
    
    if (exportDataJson == null) {
      throw Exception('No export data found');
    }
    
    final exportData = jsonDecode(exportDataJson);
    if (exportData is! Map<String, dynamic>) {
      throw Exception('Invalid export data format');
    }
    
    final modules = (exportData['modules'] as List)
        .map((json) => Module.fromJson(json as Map<String, dynamic>))
        .toList();
    
    await saveModules(modules);
    await saveSettings(exportData['settings'] as Map<String, dynamic>);
  }
} 