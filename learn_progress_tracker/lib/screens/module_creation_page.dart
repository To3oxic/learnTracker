import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../models/module.dart';
import 'package:uuid/uuid.dart';

class ModuleCreationPage extends StatefulWidget {
  const ModuleCreationPage({super.key});

  @override
  State<ModuleCreationPage> createState() => _ModuleCreationPageState();
}

class _ModuleCreationPageState extends State<ModuleCreationPage> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  Color _selectedColor = Colors.blue;
  DateTime? _endDate;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _endDate = picked;
      });
    }
  }

  void _createModule() {
    final l10n = AppLocalizations.of(context)!;
    if (_titleController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.pleaseEnterTaskTitle)),
      );
      return;
    }

    if (_endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.pleaseSelectEndDate)),
      );
      return;
    }

    final module = Module(
      id: const Uuid().v4(),
      title: _titleController.text,
      description: _descriptionController.text,
      color: _selectedColor,
      endDate: _endDate!,
    );

    Navigator.pop(context, module);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.createModule),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: l10n.moduleTitle,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _descriptionController,
              decoration: InputDecoration(
                labelText: l10n.moduleDescription,
                border: const OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            ListTile(
              title: Text(l10n.moduleEndDate),
              subtitle: Text(_endDate?.toString().split(' ')[0] ?? l10n.notSet),
              trailing: const Icon(Icons.calendar_today),
              onTap: () => _selectDate(context),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _createModule,
              child: Text(l10n.createModule),
            ),
          ],
        ),
      ),
    );
  }
} 