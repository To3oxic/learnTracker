import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:learn_progress_tracker/l10n/app_localizations.dart';
import '../models/module.dart';

class StatisticsPage extends StatelessWidget {
  final List<Module>? modules;

  const StatisticsPage({super.key, this.modules});

  @override
  Widget build(BuildContext context) {   
    final l10n = AppLocalizations.of(context)!;
    if (modules == null || modules!.isEmpty) {
      return Center(child: Text(l10n.noModules));
    }

    final completedModules = modules!.where((m) => m.isCompleted).length;
    final totalModules = modules!.length;
    final completionRate = totalModules > 0 ? completedModules / totalModules : 0.0;

    // Calculate total tasks across all modules
    final totalTasks = modules!.fold<int>(0, (sum, module) => sum + module.tasks.length);
    
    // Calculate total progress for each module
    final moduleProgressSections = modules!.map((module) {
      // Calculate average task completion for this module
      final taskCount = module.tasks.length;
      if (taskCount == 0) return null;
      
      final totalTaskProgress = module.tasks.fold<double>(
        0,
        (sum, task) => sum + (task.isCompleted ? 1.0 : 0.0),
      );
      final moduleProgress = (totalTaskProgress / taskCount) * 100;  // This is the module's actual progress percentage
      
      return moduleProgress;  // Return just the progress for now
    }).where((progress) => progress != null).cast<double>().toList();

    // Calculate total progress across all modules
    final totalProgress = moduleProgressSections.fold<double>(0, (sum, progress) => sum + progress);

    // Now create the pie chart sections with progress relative to total progress
    final pieChartSections = modules!.asMap().entries.map((entry) {
      final module = entry.value;
      final taskCount = module.tasks.length;
      if (taskCount == 0) return null;
      
      final totalTaskProgress = module.tasks.fold<double>(
        0,
        (sum, task) => sum + (task.isCompleted ? 1.0 : 0.0),
      );
      final moduleProgress = (totalTaskProgress / taskCount) * 100;
      final relativeProgress = (moduleProgress / totalProgress) * 100;  // Calculate relative to total progress
      
      return PieChartSectionData(
        value: relativeProgress,
        title: '${module.title}\n${moduleProgress.toStringAsFixed(1)}%',
        color: _getModuleColor(module.id),
        radius: 80,
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }).where((section) => section != null).cast<PieChartSectionData>().toList();

    // Generate daily progress data (last 7 days)
    final now = DateTime.now();
    final dailyProgress = List.generate(7, (index) {
      final date = now.subtract(Duration(days: 6 - index));
      final dayProgress = modules!.fold<double>(0, (sum, module) {
        // This is a simplified calculation - you might want to track actual daily progress
        return sum + (module.progress / 7);
      });
      return FlSpot(index.toDouble(), dayProgress);
    });

    // Calculate module progress for vertical lines
    final moduleProgressLines = modules!.asMap().entries.map((entry) {
      final module = entry.value;
      final taskCount = module.tasks.length;
      if (taskCount == 0) return null;
      
      final totalTaskProgress = module.tasks.fold<double>(
        0,
        (sum, task) => sum + (task.isCompleted ? 1.0 : 0.0),
      );
      final moduleProgress = (totalTaskProgress / taskCount) * 100;
      
      // Calculate x position based on module index
      final xPosition = entry.key / (modules!.length - 1);  // Distribute modules evenly across x-axis
      
      return LineChartBarData(
        spots: [
          FlSpot(xPosition, 0),  // Start at bottom (0%)
          FlSpot(xPosition, moduleProgress),  // End at module's progress percentage
        ],
        isCurved: false,
        color: _getModuleColor(module.id),
        barWidth: 3,
        isStrokeCapRound: true,
        dotData: FlDotData(show: true),
        belowBarData: BarAreaData(show: false),
      );
    }).where((line) => line != null).cast<LineChartBarData>().toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.moduleProgressComparison,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 300,
                    child: PieChart(
                      PieChartData(
                        sections: pieChartSections,
                        sectionsSpace: 2,
                        centerSpaceRadius: 40,
                        startDegreeOffset: -90,
                        borderData: FlBorderData(show: false),
                        centerSpaceColor: Theme.of(context).scaffoldBackgroundColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.moduleProgressLines,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 300,
                    child: LineChart(
                      LineChartData(
                        gridData: FlGridData(show: true),
                        titlesData: FlTitlesData(
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 40,
                              getTitlesWidget: (value, meta) {
                                return Text('${value.toInt()}%');
                              },
                            ),
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (value, meta) {
                                final index = (value * (modules!.length - 1)).round();
                                if (index >= 0 && index < modules!.length) {
                                  return Text(modules![index].title);
                                }
                                return const Text('');
                              },
                            ),
                          ),
                          topTitles: AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          rightTitles: AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                        ),
                        borderData: FlBorderData(show: true),
                        lineBarsData: moduleProgressLines,
                        minY: 0,  // Set minimum Y to 0%
                        maxY: 100,  // Set maximum Y to 100%
                        minX: 0,  // Set minimum X to 0
                        maxX: 1,  // Set maximum X to 1
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${l10n.dailyProgress}',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 300,
                    child: LineChart(
                      LineChartData(
                        gridData: FlGridData(show: true),
                        titlesData: FlTitlesData(
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 40,
                              getTitlesWidget: (value, meta) {
                                return Text('${value.toInt()}%');
                              },
                            ),
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (value, meta) {
                                final date = now.subtract(Duration(days: 6 - value.toInt()));
                                return Text('${date.day}/${date.month}');
                              },
                            ),
                          ),
                          topTitles: AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          rightTitles: AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                        ),
                        borderData: FlBorderData(show: true),
                        lineBarsData: [
                          LineChartBarData(
                            spots: dailyProgress,
                            isCurved: true,
                            color: Theme.of(context).colorScheme.primary,
                            barWidth: 3,
                            isStrokeCapRound: true,
                            dotData: FlDotData(show: true),
                            belowBarData: BarAreaData(
                              show: true,
                              color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${l10n.summary}',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  _buildSummaryItem(
                    context,
                    '${l10n.totalModules}',
                    totalModules.toString(),
                    Icons.list_alt,
                  ),
                  _buildSummaryItem(
                    context,
                    '${l10n.completedModules}',
                    completedModules.toString(),
                    Icons.check_circle,
                    Colors.green,
                  ),
                  _buildSummaryItem(
                    context,
                    '${l10n.overdueModules}',
                    modules!.where((m) => m.isOverdue).length.toString(),
                    Icons.warning,
                    Colors.red,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getModuleColor(String id) {
    final colors = [
      Colors.blue,
      Colors.green,
      Colors.purple,
      Colors.orange,
      Colors.teal,
      Colors.pink,
      Colors.indigo,
      Colors.amber,
    ];
    final index = id.hashCode.abs() % colors.length;
    return colors[index];
  }

  Widget _buildSummaryItem(
    BuildContext context,
    String title,
    String value,
    IconData icon, [
    Color? color,
  ]) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 16),
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const Spacer(),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
          ),
        ],
      ),
    );
  }
} 