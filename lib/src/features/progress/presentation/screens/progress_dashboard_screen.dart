import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';

/// Progress dashboard screen
class ProgressDashboardScreen extends ConsumerWidget {
  const ProgressDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Progress'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Overall Stats
              _buildOverallStats(theme),
              
              const SizedBox(height: 32),
              
              // Progress Chart
              _buildProgressChart(theme),
              
              const SizedBox(height: 32),
              
              // Subject Progress
              _buildSubjectProgress(theme),
              
              const SizedBox(height: 32),
              
              // Weak and Strong Topics
              Row(
                children: [
                  Expanded(child: _buildWeakTopics(theme)),
                  const SizedBox(width: 16),
                  Expanded(child: _buildStrongTopics(theme)),
                ],
              ),
              
              const SizedBox(height: 32),
              
              // Recent Activity
              _buildRecentActivity(theme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOverallStats(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.colorScheme.primary,
            theme.colorScheme.primary.withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your Learning Journey',
            style: theme.textTheme.titleLarge?.copyWith(
              color: theme.colorScheme.onPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  icon: Icons.school,
                  value: '85%',
                  label: 'Overall Score',
                  theme: theme,
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  icon: Icons.timer,
                  value: '12h',
                  label: 'Study Time',
                  theme: theme,
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  icon: Icons.quiz,
                  value: '24',
                  label: 'Quizzes',
                  theme: theme,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String value,
    required String label,
    required ThemeData theme,
  }) {
    return Column(
      children: [
        Icon(
          icon,
          color: theme.colorScheme.onPrimary,
          size: 24,
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: theme.textTheme.titleLarge?.copyWith(
            color: theme.colorScheme.onPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onPrimary.withOpacity(0.8),
          ),
        ),
      ],
    );
  }

  Widget _buildProgressChart(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Weekly Progress',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          height: 200,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainer,
            borderRadius: BorderRadius.circular(16),
          ),
          child: LineChart(
            LineChartData(
              gridData: const FlGridData(show: false),
              titlesData: FlTitlesData(
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                      if (value.toInt() < days.length) {
                        return Text(
                          days[value.toInt()],
                          style: theme.textTheme.bodySmall,
                        );
                      }
                      return const Text('');
                    },
                  ),
                ),
                leftTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
              ),
              borderData: FlBorderData(show: false),
              lineBarsData: [
                LineChartBarData(
                  spots: const [
                    FlSpot(0, 70),
                    FlSpot(1, 75),
                    FlSpot(2, 80),
                    FlSpot(3, 85),
                    FlSpot(4, 82),
                    FlSpot(5, 88),
                    FlSpot(6, 90),
                  ],
                  isCurved: true,
                  color: theme.colorScheme.primary,
                  barWidth: 3,
                  belowBarData: BarAreaData(
                    show: true,
                    color: theme.colorScheme.primary.withOpacity(0.1),
                  ),
                  dotData: FlDotData(
                    show: true,
                    getDotPainter: (spot, percent, barData, index) {
                      return FlDotCirclePainter(
                        radius: 4,
                        color: theme.colorScheme.primary,
                        strokeColor: theme.colorScheme.surface,
                        strokeWidth: 2,
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSubjectProgress(ThemeData theme) {
    final subjects = [
      {'name': 'Mathematics', 'progress': 0.85, 'color': theme.colorScheme.primary},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Subject Progress',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        ...subjects.map((subject) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        subject['name'] as String,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '${((subject['progress'] as double) * 100).round()}%',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: subject['color'] as Color,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: subject['progress'] as double,
                    backgroundColor: theme.colorScheme.outline.withOpacity(0.2),
                    valueColor: AlwaysStoppedAnimation<Color>(subject['color'] as Color),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildWeakTopics(ThemeData theme) {
    final weakTopics = ['Trigonometry', 'Geometry', 'Statistics'];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.error.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.error.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.trending_down,
                color: theme.colorScheme.error,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Needs Practice',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.error,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...weakTopics.map((topic) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 4.0),
              child: Text(
                '• $topic',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildStrongTopics(ThemeData theme) {
    final strongTopics = ['Algebra', 'Linear Equations', 'Polynomials'];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.tertiary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.tertiary.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.trending_up,
                color: theme.colorScheme.tertiary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Strong Areas',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.tertiary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...strongTopics.map((topic) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 4.0),
              child: Text(
                '• $topic',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.tertiary,
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildRecentActivity(ThemeData theme) {
    final activities = [
      {'action': 'Completed Quiz', 'topic': 'Quadratic Equations', 'score': '9/10', 'time': '2 hours ago'},
      {'action': 'Studied Topic', 'topic': 'Linear Equations', 'score': '', 'time': '1 day ago'},
      {'action': 'Completed Quiz', 'topic': 'Polynomials', 'score': '8/10', 'time': '2 days ago'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent Activity',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        ...activities.map((activity) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      activity['action'] == 'Completed Quiz' ? Icons.quiz : Icons.book,
                      color: theme.colorScheme.primary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${activity['action']} - ${activity['topic']}',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          activity['time'] as String,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (activity['score']!.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.tertiary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        activity['score'] as String,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.tertiary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }
}
