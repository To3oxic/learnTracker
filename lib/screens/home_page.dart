import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../models/module.dart';
import '../services/persistence_service.dart';
import 'module_creation_page.dart';
import 'modules_list_page.dart';
import 'calendar_page.dart';
import 'settings_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  List<Module> _modules = [];
  final PersistenceService _persistenceService = PersistenceService();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadModules();
  }

  Future<void> _loadModules() async {
    try {
      final loadedModules = await _persistenceService.loadModules();
      if (mounted) {
        setState(() {
          _modules = loadedModules;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${AppLocalizations.of(context)!.errorLoadingModules}: $e')),
        );
      }
    }
  }

  Future<void> _saveModules() async {
    try {
      await _persistenceService.saveModules(_modules);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${AppLocalizations.of(context)!.errorSavingModules}: $e')),
        );
      }
    }
  }

  void _refreshModulesList() {
    setState(() {
      // Remove any modules that have been marked for deletion
      _modules.removeWhere((module) => module.isDeleted);
    });
    _saveModules();
  }

  void _deleteModule(Module module) {
    setState(() {
      _modules.remove(module);
    });
    _saveModules();
  }

  List<Widget> get _widgetOptions => <Widget>[
    _isLoading 
        ? const Center(child: CircularProgressIndicator()) 
        : ModulesListPage(
            modules: _modules,
            onModuleUpdated: _refreshModulesList,
            onModuleDeleted: _deleteModule,
          ),
    CalendarPage(modules: _modules),
    const SettingsPage(),
  ];

  void _onItemTapped(int index) {
    if (index < _widgetOptions.length) {
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  void _addModule() async {
    final newModule = await Navigator.push<Module>(
      context,
      MaterialPageRoute(builder: (context) => const ModuleCreationPage()),
    );

    if (newModule != null && mounted) {
      setState(() {
        _modules.add(newModule);
      });
      _saveModules();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(_getTitleForIndex(_selectedIndex, l10n)),
        elevation: 0,
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: _widgetOptions,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: _onItemTapped,
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.list_alt_rounded),
            label: l10n.modules,
          ),
          NavigationDestination(
            icon: const Icon(Icons.calendar_today_rounded),
            label: l10n.calendar,
          ),
          NavigationDestination(
            icon: const Icon(Icons.settings_rounded),
            label: l10n.settings,
          ),
        ],
      ),
      floatingActionButton: _selectedIndex == 0 ? FloatingActionButton(
        onPressed: _addModule,
        tooltip: l10n.addModule,
        child: const Icon(Icons.add),
      ) : null,
    );
  }

  String _getTitleForIndex(int index, AppLocalizations l10n) {
    switch (index) {
      case 0:
        return l10n.modules;
      case 1:
        return l10n.calendar;
      case 2:
        return l10n.settings;
      default:
        return l10n.appTitle;
    }
  }
} 