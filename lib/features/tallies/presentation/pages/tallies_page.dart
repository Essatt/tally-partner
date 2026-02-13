import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/tally_provider.dart';
import '../widgets/add_event_dialog.dart';
import '../../../../models/tally_event.dart';
import '../../../../models/person.dart';
import '../../../../services/tally_repository.dart';
import '../../../../utils/icon_mapper.dart';
import '../../../../utils/color_extensions.dart';

class TalliesPage extends ConsumerWidget {
  const TalliesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventsAsync = ref.watch(tallyEventsProvider);
    final peopleAsync = ref.watch(peopleProvider);
    final service = ref.read(tallyServiceProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Tallies'),
        elevation: 0,
      ),
      body: eventsAsync.when(
        data: (events) {
          if (events.isEmpty) {
            return _buildEmptyState(context, ref);
          }
          final people = peopleAsync.valueOrNull ?? [];
          final useSections = people.length >= 2;

          return RefreshIndicator(
            onRefresh: () async {
              ref.refreshAfterEventChange();
            },
            child: useSections
                ? _buildSectionedList(context, ref, service, events, people)
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: events.length,
                    itemBuilder: (context, index) {
                      final event = events[index];
                      return _buildTallyCard(context, ref, service, event);
                    },
                  ),
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

  Widget _buildSectionedList(BuildContext context, WidgetRef ref,
      TallyRepository service, List<TallyEvent> events, List<Person> people) {
    final favorites = events.where((e) => e.isFavorite).toList();
    final general =
        events.where((e) => e.personId == null && !e.isFavorite).toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Favorites section
        if (favorites.isNotEmpty)
          _TallySection(
            title: 'Favorites',
            icon: Icons.star,
            iconColor: Colors.amber.shade600,
            children: favorites
                .map((e) => _buildTallyCard(context, ref, service, e,
                    showFavoriteStar: true))
                .toList(),
          ),

        // General section
        if (general.isNotEmpty)
          _TallySection(
            title: 'General',
            icon: Icons.tag,
            children: general
                .map((e) => _buildTallyCard(context, ref, service, e))
                .toList(),
          ),

        // Per-person sections
        ...people.map((person) {
          final personEvents = events
              .where((e) => e.personId == person.id && !e.isFavorite)
              .toList();
          if (personEvents.isEmpty) return const SizedBox.shrink();
          return _TallySection(
            title: person.name,
            icon: Icons.person,
            children: personEvents
                .map((e) => _buildTallyCard(context, ref, service, e))
                .toList(),
          );
        }),
        const SizedBox(height: 80),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context, WidgetRef ref) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .primaryContainer
                    .withValues(alpha: 0.3),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.touch_app_rounded,
                size: 48,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Start counting',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Track habits, actions, or anything you want to count. Create your first tally to get started.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: () => _showAddDialog(context, ref),
              icon: const Icon(Icons.add),
              label: const Text('Create First Tally'),
              style: FilledButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTallyCard(BuildContext context, WidgetRef ref,
      TallyRepository service, TallyEvent event,
      {bool showFavoriteStar = false}) {
    return _TallyCard(
      key: ValueKey(event.id),
      event: event,
      showFavoriteStar: showFavoriteStar,
      onIncrement: () async {
        try {
          HapticFeedback.lightImpact();
          await service.incrementTally(event.id);
          ref.refreshAfterTallyUpdate();
        } catch (e) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content: Text('Unable to update tally. Please try again.')),
            );
          }
        }
      },
      onDecrement: () async {
        try {
          HapticFeedback.lightImpact();
          await service.decrementTally(event.id);
          ref.refreshAfterTallyUpdate();
        } catch (e) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content: Text('Unable to update tally. Please try again.')),
            );
          }
        }
      },
      onUndo: () async {
        try {
          final lastLog = service.getLastLogForEvent(event.id);
          if (lastLog != null) {
            HapticFeedback.mediumImpact();
            await service.deleteLog(lastLog.id);
            ref.refreshAfterTallyUpdate();
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Last action undone')),
              );
            }
          } else {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Nothing to undo')),
              );
            }
          }
        } catch (e) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content: Text('Unable to undo. Please try again.')),
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
              const SnackBar(
                  content: Text('Unable to delete tally. Please try again.')),
            );
          }
        }
      },
      onEdit: () => _showEditDialog(context, ref, event),
      onToggleFavorite: () async {
        try {
          HapticFeedback.selectionClick();
          await service.toggleFavorite(event.id);
          ref.refreshAfterEventChange();
        } catch (e) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Unable to toggle favorite.')),
            );
          }
        }
      },
    );
  }

  void _showAddDialog(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => AddEventDialog(
        onSave: (name, icon, color, type, value,
            {String? personId,
            List<String>? assignedBudgetIds,
            List<String>? additionalPersonIds}) async {
          try {
            final service = ref.read(tallyServiceProvider);
            final event = TallyEvent(
              id: '',
              name: name,
              icon: icon,
              color: color,
              createdAt: DateTime.now(),
              type: type,
              value: value,
              personId: personId,
              assignedBudgetIds: assignedBudgetIds ?? [],
            );
            await service.addEvent(event);

            // Clone for additional people
            if (additionalPersonIds != null && additionalPersonIds.isNotEmpty) {
              for (final pid in additionalPersonIds) {
                // Get budgets for this person to assign
                final personBudgets = service.getBudgetsForPerson(pid);
                final budgetIds = personBudgets.map((b) => b.id).toList();
                final clone = TallyEvent(
                  id: '',
                  name: name,
                  icon: icon,
                  color: color,
                  createdAt: DateTime.now(),
                  type: type,
                  value: value,
                  personId: pid,
                  assignedBudgetIds: budgetIds,
                );
                await service.addEvent(clone);
              }
            }

            ref.refreshAfterEventChange();
          } catch (e) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('Unable to create tally. Please try again.')),
              );
            }
          }
        },
      ),
    );
  }

  void _showEditDialog(BuildContext context, WidgetRef ref, TallyEvent event) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => AddEventDialog(
        existingEvent: event,
        onSave: (name, icon, color, type, value,
            {String? personId,
            List<String>? assignedBudgetIds,
            List<String>? additionalPersonIds}) async {
          try {
            final service = ref.read(tallyServiceProvider);
            final updated = event.copyWith(
              name: name,
              icon: icon,
              color: color,
              type: type,
              value: value,
              personId: personId ?? event.personId,
              assignedBudgetIds: assignedBudgetIds ?? event.assignedBudgetIds,
            );
            await service.updateEvent(updated);
            ref.refreshAfterEventChange();
          } catch (e) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('Unable to update tally. Please try again.')),
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
  final VoidCallback onDecrement;
  final VoidCallback onUndo;
  final VoidCallback onDelete;
  final VoidCallback onEdit;
  final VoidCallback? onToggleFavorite;
  final bool showFavoriteStar;

  const _TallyCard({
    super.key,
    required this.event,
    required this.onIncrement,
    required this.onDecrement,
    required this.onUndo,
    required this.onDelete,
    required this.onEdit,
    this.onToggleFavorite,
    this.showFavoriteStar = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final count = ref.watch(tallyCountProvider(event.id));
    final color =
        parseHexColor(event.color, Theme.of(context).colorScheme.primary);
    final isPartner = event.type != TallyType.standard;

    return Dismissible(
      key: key!,
      direction: DismissDirection.endToStart,
      background: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.errorContainer,
          borderRadius: BorderRadius.circular(20),
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
                content:
                    Text('Are you sure you want to delete "${event.name}"?'),
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
            ) ??
            false;
      },
      onDismissed: (_) => onDelete(),
      child: GestureDetector(
        onTap: onEdit,
        onLongPress: onToggleFavorite,
        child: Card(
          margin: const EdgeInsets.only(bottom: 12),
          color: Color.lerp(
            Theme.of(context).colorScheme.surface,
            color,
            0.04,
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Icon(
                            getIconData(event.icon),
                            color: color,
                            size: 28,
                          ),
                        ),
                        if (showFavoriteStar && event.isFavorite)
                          Positioned(
                            top: -4,
                            right: -4,
                            child: Container(
                              padding: const EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.surface,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.star,
                                size: 14,
                                color: Colors.amber.shade600,
                              ),
                            ),
                          ),
                      ],
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
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              _buildTypeChip(context, event.type),
                              if (isPartner) ...[
                                const SizedBox(width: 8),
                                Text(
                                  '\$${event.value.toStringAsFixed(0)}',
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelMedium
                                      ?.copyWith(
                                        color: color,
                                        fontWeight: FontWeight.w600,
                                      ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                    _AnimatedCountText(
                      count: count,
                      color: color,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _SpringIncrementButton(
                      onPressed: onDecrement,
                      color: Theme.of(context).colorScheme.error,
                      label: isPartner
                          ? '-\$${event.value.toStringAsFixed(0)}'
                          : '-1',
                    ),
                    const SizedBox(width: 8),
                    _SpringIncrementButton(
                      onPressed: onIncrement,
                      color: color,
                      label: isPartner
                          ? (event.type == TallyType.partnerPositive
                              ? '+\$${event.value.toStringAsFixed(0)}'
                              : '-\$${event.value.toStringAsFixed(0)}')
                          : '+1',
                    ),
                    const Spacer(),
                    IconButton.outlined(
                      onPressed: onUndo,
                      icon: const Icon(Icons.undo, size: 18),
                      tooltip: 'Undo last',
                      style: IconButton.styleFrom(
                        padding: const EdgeInsets.all(8),
                        minimumSize: const Size(36, 36),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTypeChip(BuildContext context, TallyType type) {
    String label;
    Color bgColor;
    Color textColor;
    IconData? chipIcon;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    switch (type) {
      case TallyType.standard:
        label = 'Standard';
        bgColor = Colors.blue.withValues(alpha: 0.1);
        textColor = isDark ? Colors.blue.shade300 : Colors.blue.shade700;
        break;
      case TallyType.partnerPositive:
        label = 'Partner +';
        bgColor = Colors.green.withValues(alpha: 0.1);
        textColor = isDark ? Colors.green.shade300 : Colors.green.shade700;
        chipIcon = Icons.arrow_upward;
        break;
      case TallyType.partnerNegative:
        label = 'Partner -';
        bgColor = Colors.red.withValues(alpha: 0.1);
        textColor = isDark ? Colors.red.shade300 : Colors.red.shade700;
        chipIcon = Icons.arrow_downward;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (chipIcon != null) ...[
            Icon(chipIcon, size: 12, color: textColor),
            const SizedBox(width: 2),
          ],
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: textColor,
                  fontWeight: FontWeight.w500,
                ),
          ),
        ],
      ),
    );
  }
}

class _AnimatedCountText extends StatelessWidget {
  final int count;
  final Color color;

  const _AnimatedCountText({required this.count, required this.color});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<int>(
      tween: IntTween(begin: count, end: count),
      duration: const Duration(milliseconds: 300),
      builder: (context, value, child) {
        return TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 1.0, end: 1.0),
          duration: const Duration(milliseconds: 150),
          builder: (context, scale, child) {
            return Transform.scale(
              scale: scale,
              child: Text(
                value.toString(),
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: color,
                    ),
              ),
            );
          },
        );
      },
    );
  }
}

class _SpringIncrementButton extends StatefulWidget {
  final VoidCallback onPressed;
  final Color color;
  final String label;

  const _SpringIncrementButton({
    required this.onPressed,
    required this.color,
    this.label = '+1',
  });

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
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: widget.color,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: widget.color.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Text(
                  widget.label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _TallySection extends StatefulWidget {
  final String title;
  final IconData icon;
  final Color? iconColor;
  final List<Widget> children;

  const _TallySection({
    required this.title,
    required this.icon,
    this.iconColor,
    required this.children,
  });

  @override
  State<_TallySection> createState() => _TallySectionState();
}

class _TallySectionState extends State<_TallySection> {
  bool _isExpanded = true;

  @override
  Widget build(BuildContext context) {
    final iconColor =
        widget.iconColor ?? Theme.of(context).colorScheme.onSurfaceVariant;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () => setState(() => _isExpanded = !_isExpanded),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                Icon(widget.icon, size: 18, color: iconColor),
                const SizedBox(width: 8),
                Text(
                  widget.title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(width: 4),
                Text(
                  '(${widget.children.length})',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
                const Spacer(),
                AnimatedRotation(
                  turns: _isExpanded ? 0 : -0.25,
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    Icons.expand_more,
                    size: 20,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
        AnimatedCrossFade(
          duration: const Duration(milliseconds: 200),
          crossFadeState: _isExpanded
              ? CrossFadeState.showFirst
              : CrossFadeState.showSecond,
          firstChild: Column(children: widget.children),
          secondChild: const SizedBox.shrink(),
        ),
      ],
    );
  }
}
