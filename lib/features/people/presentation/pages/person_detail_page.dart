import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../tallies/presentation/providers/tally_provider.dart';
import '../../../../models/budget.dart';
import '../../../../models/tally_log.dart';
import '../widgets/add_budget_dialog.dart';

class PersonDetailPage extends ConsumerWidget {
  final String personId;
  final bool showBackButton;
  final VoidCallback? onAddPerson;

  const PersonDetailPage({
    super.key,
    required this.personId,
    this.showBackButton = true,
    this.onAddPerson,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final person = ref.watch(personProvider(personId));
    final budgetsAsync = ref.watch(budgetsForPersonProvider(personId));
    final logsAsync = ref.watch(tallyLogsProvider);
    final eventsAsync = ref.watch(tallyEventsProvider);

    if (person == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Person')),
        body: const Center(child: Text('Person not found')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(person.name),
        elevation: 0,
        automaticallyImplyLeading: showBackButton,
        actions: [
          if (onAddPerson != null)
            IconButton(
              onPressed: onAddPerson,
              icon: const Icon(Icons.person_add),
              tooltip: 'Add another person',
            ),
          IconButton(
            onPressed: () => _showAddBudgetDialog(context, ref),
            icon: const Icon(Icons.add_card),
            tooltip: 'Add budget',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.refreshAfterPartnerAction();
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Person info
            _buildPersonHeader(context, person.name, person.label),
            const SizedBox(height: 16),

            // Budgets section
            budgetsAsync.when(
              data: (budgets) {
                if (budgets.isEmpty) {
                  return _buildNoBudgets(context, ref);
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 4, bottom: 8),
                      child: Text(
                        'Budgets',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                      ),
                    ),
                    ...budgets.map((budget) => _BudgetCard(
                          key: ValueKey(budget.id),
                          budget: budget,
                          onDelete: () async {
                            final service = ref.read(tallyServiceProvider);
                            await service.deleteBudget(budget.id);
                            ref.refreshAfterBudgetChange();
                          },
                          onEdit: () =>
                              _showEditBudgetDialog(context, ref, budget),
                        )),
                  ],
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => const Text('Error loading budgets'),
            ),

            const SizedBox(height: 24),

            // Timeline section
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 8),
              child: Text(
                'Timeline',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
            logsAsync.when(
              data: (logs) {
                return eventsAsync.when(
                  data: (events) {
                    final personEventIds = events
                        .where((e) => e.personId == personId)
                        .map((e) => e.id)
                        .toSet();
                    final personLogs = logs
                        .where((log) => personEventIds.contains(log.eventId))
                        .toList()
                      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

                    if (personLogs.isEmpty) {
                      return _buildEmptyTimeline(context);
                    }
                    return Column(
                      children: personLogs.map((log) {
                        final event = events
                            .where((e) => e.id == log.eventId)
                            .firstOrNull;
                        return _TimelineItem(
                          key: ValueKey(log.id),
                          log: log,
                          eventName: event?.name,
                        );
                      }).toList(),
                    );
                  },
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => const Text('Error loading timeline'),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildPersonHeader(BuildContext context, String name, String label) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context)
                .colorScheme
                .primaryContainer
                .withValues(alpha: 0.3),
            Theme.of(context)
                .colorScheme
                .primaryContainer
                .withValues(alpha: 0.5),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Text(
                name.isNotEmpty ? name[0].toUpperCase() : '?',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .colorScheme
                      .tertiaryContainer
                      .withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  label[0].toUpperCase() + label.substring(1),
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color:
                            Theme.of(context).colorScheme.onTertiaryContainer,
                        fontWeight: FontWeight.w500,
                      ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNoBudgets(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context)
            .colorScheme
            .surfaceContainerHighest
            .withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(
            Icons.account_balance_wallet_outlined,
            size: 40,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 12),
          Text(
            'No budgets yet',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            'Add a budget to start tracking',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 16),
          FilledButton.tonal(
            onPressed: () => _showAddBudgetDialog(context, ref),
            child: const Text('Add Budget'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyTimeline(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Center(
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildTimelineDot(context, 0.2),
                Container(
                    width: 24,
                    height: 2,
                    color: Theme.of(context).colorScheme.outlineVariant),
                _buildTimelineDot(context, 0.4),
                Container(
                    width: 24,
                    height: 2,
                    color: Theme.of(context).colorScheme.outlineVariant),
                _buildTimelineDot(context, 0.6),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'No actions logged yet',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimelineDot(BuildContext context, double opacity) {
    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Theme.of(context).colorScheme.primary.withValues(alpha: opacity),
      ),
    );
  }

  void _showAddBudgetDialog(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => AddBudgetDialog(
        onSave: (name, limit) async {
          final service = ref.read(tallyServiceProvider);
          final budget = Budget(
            id: '',
            personId: personId,
            name: name,
            budgetLimit: limit,
            currentBalance: 0,
            createdAt: DateTime.now(),
          );
          await service.addBudget(budget);
          ref.refreshAfterBudgetChange();
        },
      ),
    );
  }

  void _showEditBudgetDialog(
      BuildContext context, WidgetRef ref, Budget budget) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => AddBudgetDialog(
        existingBudget: budget,
        onSave: (name, limit) async {
          final service = ref.read(tallyServiceProvider);
          await service.updateBudget(budget.copyWith(
            name: name,
            budgetLimit: limit,
          ));
          ref.refreshAfterBudgetChange();
        },
      ),
    );
  }
}

class _BudgetCard extends StatelessWidget {
  final Budget budget;
  final VoidCallback onDelete;
  final VoidCallback onEdit;

  const _BudgetCard({
    super.key,
    required this.budget,
    required this.onDelete,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final balance = budget.currentBalance;
    final limit = budget.budgetLimit;
    final percentage =
        limit > 0 ? (balance.abs() / limit * 100).clamp(0.0, 100.0) : 0.0;
    final isPositive = balance >= 0;
    final barColor = isPositive
        ? Theme.of(context).colorScheme.tertiary
        : Theme.of(context).colorScheme.error;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Dismissible(
        key: ValueKey('dismiss_${budget.id}'),
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
          ),
        ),
        confirmDismiss: (_) async {
          return await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Delete Budget'),
                  content: Text('Delete "${budget.name}" budget?'),
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
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Theme.of(context)
                    .colorScheme
                    .outlineVariant
                    .withValues(alpha: 0.3),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      budget.name,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    Text(
                      '\$${balance.toStringAsFixed(2)}',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: barColor,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: percentage / 100,
                    backgroundColor:
                        Theme.of(context).colorScheme.surfaceContainerHighest,
                    valueColor: AlwaysStoppedAnimation<Color>(barColor),
                    minHeight: 8,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${percentage.toStringAsFixed(1)}% of limit',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                    Text(
                      'Limit: \$${limit.toStringAsFixed(2)}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
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
}

class _TimelineItem extends StatelessWidget {
  final TallyLog log;
  final String? eventName;

  const _TimelineItem({super.key, required this.log, this.eventName});

  @override
  Widget build(BuildContext context) {
    final isPositive = log.valueAdjustment >= 0;
    final color = isPositive
        ? Theme.of(context).colorScheme.tertiary
        : Theme.of(context).colorScheme.error;
    final icon = isPositive ? Icons.arrow_upward : Icons.arrow_downward;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 48,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  eventName ??
                      (isPositive ? 'Positive Action' : 'Negative Action'),
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                Text(
                  _formatDate(log.timestamp),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ),
          Text(
            '${isPositive ? '+' : ''}\$${log.valueAdjustment.toStringAsFixed(2)}',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 1) return 'Just now';
    if (difference.inHours < 1) return '${difference.inMinutes}m ago';
    if (difference.inDays < 1) return '${difference.inHours}h ago';
    if (difference.inDays == 1) return 'Yesterday';
    return '${date.day}/${date.month}/${date.year}';
  }
}
