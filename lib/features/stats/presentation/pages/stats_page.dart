import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../tallies/presentation/providers/tally_provider.dart';
import '../../../../models/tally_event.dart';
import '../../../../models/tally_log.dart';
import '../../../../models/tally_stats.dart';
import '../../../../models/person.dart';
import '../../../../utils/icon_mapper.dart';
import '../../../../utils/color_extensions.dart';

class StatsPage extends ConsumerStatefulWidget {
  const StatsPage({super.key});

  @override
  ConsumerState<StatsPage> createState() => _StatsPageState();
}

class _StatsPageState extends ConsumerState<StatsPage> {
  String _timeframe = 'week';
  String? _selectedPersonId; // null means "All"

  @override
  Widget build(BuildContext context) {
    final eventsAsync = ref.watch(tallyEventsProvider);
    final logsAsync = ref.watch(tallyLogsProvider);
    final peopleAsync = ref.watch(peopleProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Statistics'),
        elevation: 0,
      ),
      body: eventsAsync.when(
        data: (events) {
          return logsAsync.when(
            data: (logs) {
              final people = peopleAsync.valueOrNull ?? [];
              final filteredLogs = _filterLogsByTimeframe(logs);
              final stats = _calculateStats(events, filteredLogs, people);

              // Filter events/logs by person if selected
              final displayEvents = _selectedPersonId != null
                  ? events
                      .where((e) => e.personId == _selectedPersonId)
                      .toList()
                  : events;

              final displayStats = _selectedPersonId != null
                  ? _calculateStats(
                      displayEvents,
                      filteredLogs.where((log) {
                        final event = events
                            .where((e) => e.id == log.eventId)
                            .firstOrNull;
                        return event?.personId == _selectedPersonId;
                      }).toList(),
                      people,
                    )
                  : stats;

              return Column(
                children: [
                  _buildTimeframeToggle(),
                  if (people.length >= 2) _buildPersonFilter(people),
                  _buildSummaryCard(displayStats),
                  Expanded(
                    child: _buildEventStats(
                      displayEvents,
                      displayStats,
                      events,
                      people,
                    ),
                  ),
                ],
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) => Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline,
                      size: 48, color: Theme.of(context).colorScheme.error),
                  const SizedBox(height: 16),
                  Text('Something went wrong',
                      style: Theme.of(context).textTheme.titleMedium),
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: SegmentedButton<String>(
        segments: const [
          ButtonSegment(
            value: 'day',
            label: Text('Day'),
          ),
          ButtonSegment(
            value: 'week',
            label: Text('Week'),
          ),
          ButtonSegment(
            value: 'month',
            label: Text('Month'),
          ),
        ],
        selected: {_timeframe},
        onSelectionChanged: (Set<String> newSelection) {
          setState(() {
            _timeframe = newSelection.first;
          });
        },
        style: ButtonStyle(
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ),
    );
  }

  Widget _buildPersonFilter(List<Person> people) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: SizedBox(
        height: 40,
        child: ListView(
          scrollDirection: Axis.horizontal,
          children: [
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: const Text('All'),
                selected: _selectedPersonId == null,
                onSelected: (_) {
                  setState(() => _selectedPersonId = null);
                },
              ),
            ),
            ...people.map((person) {
              final isSelected = _selectedPersonId == person.id;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(person.name),
                  selected: isSelected,
                  onSelected: (_) {
                    setState(() => _selectedPersonId = person.id);
                  },
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(TallyStats stats) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).colorScheme.primary.withValues(alpha: 0.08),
            Theme.of(context).colorScheme.primary.withValues(alpha: 0.15),
            Theme.of(context).colorScheme.primary.withValues(alpha: 0.22),
          ],
          stops: const [0.0, 0.5, 1.0],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'Total Tallies',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 8),
          TweenAnimationBuilder<int>(
            tween: IntTween(begin: 0, end: stats.totalCount),
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeOut,
            builder: (context, value, child) {
              return Text(
                '$value',
                style: Theme.of(context).textTheme.displayMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
              );
            },
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

  Widget _buildEventStats(
    List<TallyEvent> displayEvents,
    TallyStats stats,
    List<TallyEvent> allEvents,
    List<Person> people,
  ) {
    final eventStats = stats.byEvent;

    if (eventStats.isEmpty) {
      return _buildEmptyState();
    }

    // Sort events by count descending for ranking
    final rankedEvents = displayEvents
        .where((e) => (eventStats[e.id] ?? 0) > 0)
        .toList()
      ..sort(
          (a, b) => (eventStats[b.id] ?? 0).compareTo(eventStats[a.id] ?? 0));

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      children: [
        ...rankedEvents.asMap().entries.map((entry) {
          final index = entry.key;
          final event = entry.value;
          final count = eventStats[event.id] ?? 0;

          return _EventStatCard(
            key: ValueKey(event.id),
            event: event,
            count: count,
            rank: index + 1,
            percentage:
                stats.totalCount > 0 ? (count / stats.totalCount * 100) : 0,
          );
        }),

        // "By Tally Name" grouping when viewing All people and 2+ people
        if (_selectedPersonId == null &&
            people.length >= 2 &&
            stats.byNameByPerson.isNotEmpty) ...[
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              'By Tally Name',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
          ...stats.byNameByPerson.entries.map((entry) {
            final tallyName = entry.key;
            final perPerson = entry.value;
            final total = perPerson.values.fold(0, (sum, count) => sum + count);

            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          tallyName,
                          style:
                              Theme.of(context).textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                        ),
                        Text(
                          '$total total',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                  ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ...perPerson.entries.map((personEntry) {
                      final person = people
                          .where((p) => p.id == personEntry.key)
                          .firstOrNull;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          children: [
                            const SizedBox(width: 8),
                            Text(
                              person?.name ?? 'Unknown',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            const Spacer(),
                            Text(
                              '${personEntry.value}',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
            );
          }),
        ],
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Simple bar chart illustration
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _buildBarIllustration(context, 20, 0.15),
                const SizedBox(width: 8),
                _buildBarIllustration(context, 40, 0.25),
                const SizedBox(width: 8),
                _buildBarIllustration(context, 28, 0.2),
                const SizedBox(width: 8),
                _buildBarIllustration(context, 52, 0.35),
                const SizedBox(width: 8),
                _buildBarIllustration(context, 16, 0.12),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              'Nothing to show yet',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Start tracking tallies to see your statistics here',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBarIllustration(
      BuildContext context, double height, double opacity) {
    return Container(
      width: 16,
      height: height,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withValues(alpha: opacity),
        borderRadius: BorderRadius.circular(4),
      ),
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
            (log.timestamp.isAfter(startDate) ||
                log.timestamp.isAtSameMomentAs(startDate)) &&
            log.timestamp.isBefore(now))
        .toList();
  }

  TallyStats _calculateStats(
    List<TallyEvent> events,
    List<TallyLog> logs,
    List<Person> people,
  ) {
    int totalCount = 0;
    Map<String, int> byEvent = {};
    Map<String, int> byPerson = {};
    Map<String, Map<String, int>> byNameByPerson = {};

    // Build event lookup
    final eventMap = {for (final e in events) e.id: e};

    for (final log in logs) {
      final adjustment = log.valueAdjustment.round().abs();
      totalCount += adjustment;
      byEvent[log.eventId] = (byEvent[log.eventId] ?? 0) + adjustment;

      // Per-person stats
      final event = eventMap[log.eventId];
      if (event != null && event.personId != null) {
        byPerson[event.personId!] =
            (byPerson[event.personId!] ?? 0) + adjustment;

        // By-name-by-person grouping
        byNameByPerson.putIfAbsent(event.name, () => {});
        byNameByPerson[event.name]![event.personId!] =
            (byNameByPerson[event.name]![event.personId!] ?? 0) + adjustment;
      }
    }

    return TallyStats(
      totalCount: totalCount,
      byEvent: byEvent,
      byPerson: byPerson,
      byNameByPerson: byNameByPerson,
    );
  }
}

class _EventStatCard extends StatelessWidget {
  final TallyEvent event;
  final int count;
  final int rank;
  final double percentage;

  const _EventStatCard({
    super.key,
    required this.event,
    required this.count,
    required this.rank,
    required this.percentage,
  });

  @override
  Widget build(BuildContext context) {
    final color =
        parseHexColor(event.color, Theme.of(context).colorScheme.primary);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Card(
        margin: EdgeInsets.zero,
        color: Color.lerp(
          Theme.of(context).colorScheme.surface,
          color,
          0.03,
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Rank number
                  SizedBox(
                    width: 24,
                    child: Text(
                      '$rank',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.15),
                          ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      getIconData(event.icon),
                      color: color,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          event.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style:
                              Theme.of(context).textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                        ),
                        Text(
                          '$count ${count == 1 ? 'tally' : 'tallies'}',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                  ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '${percentage.toStringAsFixed(1)}%',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 500),
                  curve: Curves.easeInOut,
                  child: LinearProgressIndicator(
                    value: percentage / 100,
                    backgroundColor:
                        Theme.of(context).colorScheme.surfaceContainerHighest,
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                    minHeight: 8,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
