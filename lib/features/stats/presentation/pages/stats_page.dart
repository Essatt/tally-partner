import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../tallies/presentation/providers/tally_provider.dart';
import '../../../../models/tally_event.dart';
import '../../../../models/tally_log.dart';
import '../../../../models/tally_stats.dart';
import '../../../../utils/icon_mapper.dart';
import '../../../../utils/color_extensions.dart';

class StatsPage extends ConsumerStatefulWidget {
  const StatsPage({super.key});

  @override
  ConsumerState<StatsPage> createState() => _StatsPageState();
}

class _StatsPageState extends ConsumerState<StatsPage> {
  String _timeframe = 'week'; // 'day', 'week', 'month'

  @override
  Widget build(BuildContext context) {
    final eventsAsync = ref.watch(tallyEventsProvider);
    final logsAsync = ref.watch(tallyLogsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Statistics'),
        elevation: 0,
      ),
      body: eventsAsync.when(
        data: (events) {
          return logsAsync.when(
            data: (logs) {
              final filteredLogs = _filterLogsByTimeframe(logs);
              final stats = _calculateStats(events, filteredLogs);

              return Column(
                children: [
                  _buildTimeframeToggle(),
                  _buildSummaryCard(stats),
                  Expanded(
                    child: _buildEventStats(events, stats),
                  ),
                ],
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) => Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 48, color: Theme.of(context).colorScheme.error),
                  const SizedBox(height: 16),
                  Text('Something went wrong', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  FilledButton.icon(
                    onPressed: () {
                      ref.refreshAfterEventChange();
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                  ),
                ],
              ),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Text('Error: $error'),
        ),
      ),
    );
  }

  Widget _buildTimeframeToggle() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: SegmentedButton<String>(
        segments: const [
          ButtonSegment(
            value: 'day',
            label: Text('Day'),
            icon: Icon(Icons.today),
          ),
          ButtonSegment(
            value: 'week',
            label: Text('Week'),
            icon: Icon(Icons.view_week),
          ),
          ButtonSegment(
            value: 'month',
            label: Text('Month'),
            icon: Icon(Icons.calendar_month),
          ),
        ],
        selected: {_timeframe},
        onSelectionChanged: (Set<String> newSelection) {
          setState(() {
            _timeframe = newSelection.first;
          });
        },
      ),
    );
  }

  Widget _buildSummaryCard(TallyStats stats) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).colorScheme.primary.withValues(alpha:0.1),
            Theme.of(context).colorScheme.primary.withValues(alpha:0.2),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withValues(alpha:0.3),
          width: 2,
        ),
      ),
      child: Column(
        children: [
          Text(
            'Total Tallies',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            '${stats.totalCount}',
            style: Theme.of(context).textTheme.displayMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            'this $_timeframe',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventStats(List<TallyEvent> events, TallyStats stats) {
    final eventStats = stats.byEvent;

    if (eventStats.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.bar_chart,
              size: 80,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha:0.38),
            ),
            const SizedBox(height: 16),
            Text(
              'No statistics yet',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Start tracking to see your stats',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha:0.5),
                  ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: events.length,
      itemBuilder: (context, index) {
        final event = events[index];
        final count = eventStats[event.id] ?? 0;
        if (count == 0) return const SizedBox.shrink();

        return _EventStatCard(
          key: ValueKey(event.id),
          event: event,
          count: count,
          percentage: stats.totalCount > 0
              ? (count / stats.totalCount * 100)
              : 0,
        );
      },
    );
  }

  List<TallyLog> _filterLogsByTimeframe(List<TallyLog> logs) {
    final now = DateTime.now();
    DateTime startDate;

    switch (_timeframe) {
      case 'day':
        startDate = DateTime(now.year, now.month, now.day);
        break;
      case 'week':
        startDate = now.subtract(const Duration(days: 7));
        break;
      case 'month':
        startDate = DateTime(now.year, now.month, 1);
        break;
      default:
        startDate = now.subtract(const Duration(days: 7));
    }

    return logs
        .where((log) =>
            (log.timestamp.isAfter(startDate) || log.timestamp.isAtSameMomentAs(startDate)) &&
            log.timestamp.isBefore(now))
        .toList();
  }

  TallyStats _calculateStats(
    List<TallyEvent> events,
    List<TallyLog> logs,
  ) {
    int totalCount = 0;
    Map<String, int> byEvent = {};

    for (final log in logs) {
      final adjustment = log.valueAdjustment.round().abs();
      totalCount += adjustment;
      byEvent[log.eventId] = (byEvent[log.eventId] ?? 0) + adjustment;
    }

    return TallyStats(totalCount: totalCount, byEvent: byEvent);
  }
}

class _EventStatCard extends StatelessWidget {
  final TallyEvent event;
  final int count;
  final double percentage;

  const _EventStatCard({
    super.key,
    required this.event,
    required this.count,
    required this.percentage,
  });

  @override
  Widget build(BuildContext context) {
    final color = parseHexColor(event.color, Theme.of(context).colorScheme.primary);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Theme.of(context).dividerColor, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha:0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    getIconData(event.icon),
                    color: color,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        event.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      Text(
                        '$count tally${count == 1 ? '' : 'ies'}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '${percentage.toStringAsFixed(1)}%',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: percentage / 100,
                backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                valueColor: AlwaysStoppedAnimation<Color>(color),
                minHeight: 8,
              ),
            ),
          ],
        ),
      ),
    );
  }

}
