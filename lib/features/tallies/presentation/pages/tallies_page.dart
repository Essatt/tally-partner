import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/tally_provider.dart';
import '../widgets/add_event_dialog.dart';
import '../../../../models/tally_event.dart';

class TalliesPage extends ConsumerWidget {
  const TalliesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventsAsync = ref.watch(tallyEventsProvider);
    final service = ref.read(tallyServiceProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Tallies'),
        elevation: 0,
      ),
      body: eventsAsync.when(
        data: (events) {
          if (events.isEmpty) {
            return _buildEmptyState(context);
          }
          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(tallyEventsProvider);
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: events.length,
              itemBuilder: (context, index) {
                final event = events[index];
                return _TallyCard(
                  key: ValueKey(event.id),
                  event: event,
                  onIncrement: () async {
                    HapticFeedback.lightImpact();
                    await service.incrementTally(event.id);
                    ref.invalidate(tallyEventsProvider);
                    ref.invalidate(tallyLogsProvider);
                  },
                  onDelete: () async {
                    HapticFeedback.mediumImpact();
                    await service.deleteEvent(event.id);
                    ref.invalidate(tallyEventsProvider);
                    ref.invalidate(tallyLogsProvider);
                  },
                );
              },
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Text('Error: $error'),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddDialog(context, ref),
        label: const Text('New Tally'),
        icon: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.event_note,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 24),
          Text(
            'No tallies yet',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap + to create your first tally',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[500],
                ),
          ),
        ],
      ),
    );
  }

  void _showAddDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AddEventDialog(
        onSave: (name, icon, color, type) async {
          final service = ref.read(tallyServiceProvider);
          final event = TallyEvent(
            id: '',
            name: name,
            icon: icon,
            color: color,
            createdAt: DateTime.now(),
            type: type,
          );
          await service.addEvent(event);
          ref.invalidate(tallyEventsProvider);
        },
      ),
    );
  }
}

class _TallyCard extends ConsumerWidget {
  final TallyEvent event;
  final VoidCallback onIncrement;
  final VoidCallback onDelete;

  const _TallyCard({
    super.key,
    required this.event,
    required this.onIncrement,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final count = ref.watch(tallyCountProvider(event.id));
    final color = event.color != null
        ? Color(int.parse(event.color!.replaceFirst('#', '0xFF')))
        : Theme.of(context).colorScheme.primary;

    return Dismissible(
      key: key!,
      direction: DismissDirection.endToStart,
      background: Container(
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        child: const Icon(
          Icons.delete_outline,
          color: Colors.white,
          size: 32,
        ),
      ),
      onDismissed: (_) => onDelete(),
      child: Card(
        elevation: 0,
        margin: const EdgeInsets.only(bottom: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.grey.shade200, width: 1),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _getIconData(event.icon),
                  color: color,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      event.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 4),
                    _buildTypeChip(context, event.type),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    count.toString(),
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                  ),
                  const SizedBox(height: 4),
                  _SpringIncrementButton(
                    onPressed: onIncrement,
                    color: color,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTypeChip(BuildContext context, TallyType type) {
    String label;
    Color bgColor;

    switch (type) {
      case TallyType.standard:
        label = 'Standard';
        bgColor = Colors.blue.withOpacity(0.1);
        break;
      case TallyType.partnerPositive:
        label = 'Partner (+)';
        bgColor = Colors.green.withOpacity(0.1);
        break;
      case TallyType.partnerNegative:
        label = 'Partner (-)';
        bgColor = Colors.red.withOpacity(0.1);
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: bgColor.withOpacity(0.8),
              fontWeight: FontWeight.w500,
            ),
      ),
    );
  }

  IconData _getIconData(String? iconName) {
    // Simple mapping of common icon names to IconData
    const iconMap = {
      'star': Icons.star,
      'favorite': Icons.favorite,
      'thumb_up': Icons.thumb_up,
      'thumb_down': Icons.thumb_down,
      'check': Icons.check_circle,
      'close': Icons.cancel,
      'water_drop': Icons.water_drop,
      'coffee': Icons.coffee,
      'fitness': Icons.fitness_center,
      'book': Icons.book,
      'work': Icons.work,
    };
    return iconMap[iconName] ?? Icons.event;
  }
}

class _SpringIncrementButton extends StatefulWidget {
  final VoidCallback onPressed;
  final Color color;

  const _SpringIncrementButton({required this.onPressed, required this.color});

  @override
  State<_SpringIncrementButton> createState() => _SpringIncrementButtonState();
}

class _SpringIncrementButtonState extends State<_SpringIncrementButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.85).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTapDown() {
    _controller.forward();
  }

  void _handleTapUp() {
    _controller.reverse();
    widget.onPressed();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _handleTapDown(),
      onTapUp: (_) => _handleTapUp(),
      onTapCancel: () => _controller.reverse(),
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: widget.color,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: widget.color.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(
                Icons.add,
                color: Colors.white,
                size: 28,
              ),
            ),
          );
        },
      ),
    );
  }
}
