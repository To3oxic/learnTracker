import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import '../models/module.dart';
import '../models/task.dart';
import '../models/priority.dart';
import 'module_detail_page.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../providers/theme_provider.dart';
import '../providers/locale_provider.dart';

class CalendarPage extends StatefulWidget {
  final List<Module>? modules;

  const CalendarPage({super.key, this.modules});

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Map<DateTime, List<Module>> _events = {};

  @override
  void initState() {
    super.initState();
    print('CalendarPage initialized with ${widget.modules?.length ?? 0} modules');
    _updateEvents();
  }

  void _updateEvents() {
    if (widget.modules == null) {
      print('No modules provided to CalendarPage');
      return;
    }

    print('Updating events for ${widget.modules!.length} modules');
    final events = <DateTime, List<Module>>{};
    for (final module in widget.modules!) {
      // Normalize the date to remove time component
      final endDate = DateTime(
        module.endDate.year,
        module.endDate.month,
        module.endDate.day,
      );

      print('Adding event for module ${module.title} on ${endDate.toString()}');

      // Add end date event
      if (events[endDate] == null) {
        events[endDate] = [];
      }
      events[endDate]!.add(module);
    }
    setState(() {
      _events = events;
    });
    print('Total events created: ${_events.length}');
  }

  List<Module> _getEventsForDay(DateTime day) {
    // Normalize the input day to remove time component
    final normalizedDay = DateTime(day.year, day.month, day.day);
    final events = _events[normalizedDay] ?? [];
    print('Getting events for ${normalizedDay.toString()}: ${events.length} events found');
    return events;
  }

  List<Map<String, dynamic>> _getUpcomingEvents() {
    if (widget.modules == null) {
      print('No modules available for upcoming events');
      return [];
    }

    final now = DateTime.now();
    final upcomingEvents = <Map<String, dynamic>>[];

    print('Getting upcoming events from ${widget.modules!.length} modules');

    // Add module end dates
    for (final module in widget.modules!) {
      if (module.endDate.isAfter(now)) {
        upcomingEvents.add({
          'title': '${module.title} - Module End',
          'date': module.endDate,
          'type': 'module',
          'color': Colors.blue,
          'module': module,  // Add reference to the module
        });
        print('Added module end date: ${module.title} on ${module.endDate}');
      }
    }

    // Add upcoming tasks
    for (final module in widget.modules!) {
      for (final task in module.tasks) {
        if (!task.isCompleted && task.endDate != null && task.endDate!.isAfter(now)) {
          upcomingEvents.add({
            'title': '${task.title} - ${module.title}',
            'date': task.endDate!,
            'type': 'task',
            'color': _getTaskColor(task.priority),
            'module': module,  // Add reference to the module
          });
          print('Added task: ${task.title} on ${task.endDate}');
        }
      }
    }

    // Sort by date
    upcomingEvents.sort((a, b) => a['date'].compareTo(b['date']));
    print('Total upcoming events: ${upcomingEvents.length}');
    return upcomingEvents;
  }

  Color _getTaskColor(Priority priority) {
    switch (priority) {
      case Priority.high:
        return Colors.red;
      case Priority.medium:
        return Colors.orange;
      case Priority.low:
        return Colors.green;
    }
  }

  @override
  Widget build(BuildContext context) {  
    final l10n = AppLocalizations.of(context)!;


    final upcomingEvents = _getUpcomingEvents();
    print('Building calendar with ${_events.length} events and ${upcomingEvents.length} upcoming events');

    return Column(
      children: [
        TableCalendar(
          firstDay: DateTime.utc(2020, 1, 1),
          lastDay: DateTime.utc(2030, 12, 31),
          focusedDay: _focusedDay,
          calendarFormat: _calendarFormat,
          selectedDayPredicate: (day) {
            return isSameDay(_selectedDay, day);
          },
          onDaySelected: (selectedDay, focusedDay) {
            setState(() {
              _selectedDay = selectedDay;
              _focusedDay = focusedDay;
            });
          },
          onFormatChanged: (format) {
            setState(() {
              _calendarFormat = format;
            });
          },
          eventLoader: _getEventsForDay,
          calendarStyle: CalendarStyle(
            markersMaxCount: 3,
            markerDecoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              shape: BoxShape.circle,
            ),
          ),
          calendarBuilders: CalendarBuilders(
            markerBuilder: (context, date, events) {
              if (events.isEmpty) return null;
              
              // Check if any of the events are module end dates
              final hasModuleEnd = events.any((event) => event is Module);
              
              return Positioned(
                bottom: 1,
                child: Container(
                  width: 40,
                  height: 3,
                  decoration: BoxDecoration(
                    color: hasModuleEnd 
                        ? Colors.red.withOpacity(0.7)  // Red line for module end dates
                        : Theme.of(context).colorScheme.primary.withOpacity(0.7),  // Blue line for tasks
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        if (_selectedDay != null) ...[
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              '${l10n.eventsOn} ${_selectedDay!.toString().split(' ')[0]}',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _getEventsForDay(_selectedDay!).length,
              itemBuilder: (context, index) {
                final module = _getEventsForDay(_selectedDay!)[index];
                return Card(
                  child: ListTile(
                    title: Text(module.title),
                    subtitle: Text(l10n.moduleEndDate),
                    trailing: const Icon(
                      Icons.flag,
                      color: Colors.red,
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ModuleDetailPage(
                            module: module,
                            onModuleUpdated: () {
                              setState(() {});  // Refresh the calendar view
                            },
                            onModuleDeleted: (module) {
                              setState(() {});  // Refresh the calendar view
                            },
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ] else ...[
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              '${l10n.upcomingEvents}',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: upcomingEvents.length,
              itemBuilder: (context, index) {
                final event = upcomingEvents[index];
                return Card(
                  child: ListTile(
                    title: Text(event['title']),
                    subtitle: Text(
                      '${l10n.taskDueDate} ${event['date'].toString().split(' ')[0]}',
                    ),
                    leading: Icon(
                      event['type'] == 'module' ? Icons.flag : Icons.task,
                      color: event['color'],
                    ),
                    onTap: () {
                      final module = event['module'] as Module;
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ModuleDetailPage(
                            module: module,
                            onModuleUpdated: () {
                              setState(() {});  // Refresh the calendar view
                            },
                            onModuleDeleted: (module) {
                              setState(() {});  // Refresh the calendar view
                            },
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ],
    );
  }
} 