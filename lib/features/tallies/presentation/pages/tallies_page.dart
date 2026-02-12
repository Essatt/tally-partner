import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/tally_provider.dart';
import '../widgets/add_event_dialog.dart';
import '../../../../models/tally_event.dart';
import '../../../../utils/icon_mapper.dart';
import '../../../../utils/color_extensions.dart';

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
              ref.refreshAfterEventChange();
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
                    try {
                      HapticFeedback.lightImpact();
                      await service.incrementTally(event.id);
                      ref.refreshAfterTallyUpdate();
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Unable to update tally. Please try again.')),
                        );
                      }
                    }
                  },
                  onDelete: () async {
                    try {
                      HapticFeedback.mediumImpact();
                      await service.deleteEvent(event.id);
                      ref.refreshAfterEventChange();
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Unable to delete tally. Please try again.')),
                        );
                      }
                    }
                  },
                );
              },
            ),
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
                onPressed: () => ref.refreshAfterEventChange(),
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
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
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha:0.38),
          ),
          const SizedBox(height: 24),
          Text(
            'No tallies yet',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap + to create your first tally',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha:0.5),
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
          try {
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
            ref.refreshAfterEventChange();
          } catch (e) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Unable to create tally. Please try again.')),
              );
            }
          }
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
    final color = parseHexColor(event.color, Theme.of(context).colorScheme.primary);

    return Dismissible(
      key: key!,
      direction: DismissDirection.endToStart,
      background: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.errorContainer,
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        child: Icon(
          Icons.delete_outline,
          color: Theme.of(context).colorScheme.onErrorContainer,
          size: 32,
        ),
      ),
      confirmDismiss: (_) async {
        return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Delete Tally'),
            content: Text('Are you sure you want to delete "${event.name}"?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: FilledButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.error,
                  foregroundColor: Theme.of(context).colorScheme.onError,
                ),
                child: const Text('Delete'),
              ),
            ],
          ),
        ) ?? false;
      },
      onDismissed: (_) => onDelete(),
      child: Card(
        elevation: 0,
        margin: const EdgeInsets.only(bottom: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Theme.of(context).dividerColor, width: 1),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: color.withValues(alpha:0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  getIconData(event.icon),
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
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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
    Color textColor;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    switch (type) {
      case TallyType.standard:
        label = 'Standard';
        bgColor = Colors.blue.withValues(alpha:0.1);
        textColor = isDark ? Colors.blue.shade300 : Colors.blue.shade700;
        break;
      case TallyType.partnerPositive:
        label = 'Partner (+)';
        bgColor = Colors.green.withValues(alpha:0.1);
        textColor = isDark ? Colors.green.shade300 : Colors.green.shade700;
        break;
      case TallyType.partnerNegative:
        label = 'Partner (-)';
        bgColor = Colors.red.withValues(alpha:0.1);
        textColor = isDark ? Colors.red.shade300 : Colors.red.shade700;
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
              color: textColor,
              fontWeight: FontWeight.w500,
            ),
      ),
    );
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
    return Semantics(
      button: true,
      label: 'Increment tally',
      child: GestureDetector(
        excludeFromSemantics: true,
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
                    color: widget.color.withValues(alpha:0.3),
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
      ),
    );
  }
}
