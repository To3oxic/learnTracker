import 'dart:convert';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/module.dart';
import '../models/task.dart';

class PersistenceService {
  static const String _modulesKey = 'modules';
  static const String _settingsKey = 'settings';
  static const String _backupFolderName = 'studyflow-backup';
  static const String _backupFileName = 'app_backup.json';

  Future<bool> _requestStoragePermission() async {
    if (await Permission.storage.request().isGranted) {
      return true;
    }
    
    // If storage permission is denied, try requesting manage external storage
    if (await Permission.manageExternalStorage.request().isGranted) {
      return true;
    }
    
    return false;
  }

  Future<Directory> _getBackupDirectory() async {
    // Request storage permission
    final hasPermission = await _requestStoragePermission();
    if (!hasPermission) {
      throw Exception('Storage permission denied');
    }

    // Get the external storage directory
    final externalDir = await getExternalStorageDirectory();
    if (externalDir == null) {
      throw Exception('Could not access external storage');
    }

    // Navigate up to the root storage directory
    // The path is typically like: /storage/emulated/0/Android/data/com.example.app/files
    // We want to go up to: /storage/emulated/0/
    final rootPath = externalDir.path.split('Android')[0];
    final backupDir = Directory('$rootPath$_backupFolderName');

    // Create the directory if it doesn't exist
    if (!await backupDir.exists()) {
      await backupDir.create(recursive: true);
    }

    return backupDir;
  }

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

  Future<String> exportData() async {
    try {
      // Get all data from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final allData = prefs.getKeys().fold<Map<String, dynamic>>({}, (map, key) {
        map[key] = prefs.get(key);
        return map;
      });

      // Add export timestamp
      allData['exportTimestamp'] = DateTime.now().toIso8601String();

      // Convert to JSON
      final jsonData = jsonEncode(allData);

      // Get the backup directory
      final backupDir = await _getBackupDirectory();
      final file = File('${backupDir.path}/$_backupFileName');

      // Write to file
      await file.writeAsString(jsonData);
      
      // Return the backup file path
      return file.path;
    } catch (e) {
      print('Error exporting data: $e');
      rethrow;
    }
  }

  Future<void> importData() async {
    try {
      // Get the backup directory
      final backupDir = await _getBackupDirectory();
      final file = File('${backupDir.path}/$_backupFileName');

      // Check if file exists
      if (!await file.exists()) {
        throw Exception('No backup file found in $_backupFolderName folder');
      }

      // Read the file
      final jsonData = await file.readAsString();
      final Map<String, dynamic> allData = jsonDecode(jsonData);

      // Save all data back to SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      for (var entry in allData.entries) {
        if (entry.key == 'exportTimestamp') continue; // Skip the timestamp
        
        if (entry.value is String) {
          await prefs.setString(entry.key, entry.value as String);
        } else if (entry.value is bool) {
          await prefs.setBool(entry.key, entry.value as bool);
        } else if (entry.value is int) {
          await prefs.setInt(entry.key, entry.value as int);
        } else if (entry.value is double) {
          await prefs.setDouble(entry.key, entry.value as double);
        }
      }
    } catch (e) {
      print('Error importing data: $e');
      rethrow;
    }
  }
} 