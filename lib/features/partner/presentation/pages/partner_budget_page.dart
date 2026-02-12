import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../tallies/presentation/providers/tally_provider.dart';
import '../widgets/add_action_dialog.dart';
import '../widgets/setup_budget_dialog.dart';
import '../../../../models/partner_config.dart';
import '../../../../models/tally_log.dart';
import '../../../../services/tally_repository.dart';

class PartnerBudgetPage extends ConsumerWidget {
  const PartnerBudgetPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final configAsync = ref.watch(partnerConfigProvider);
    final logsAsync = ref.watch(tallyLogsProvider);
    final service = ref.read(tallyServiceProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Partner Budget'),
        elevation: 0,
      ),
      body: configAsync.when(
        data: (config) {
          if (config == null) {
            return _buildSetupPrompt(context, ref, service);
          }
          return RefreshIndicator(
            onRefresh: () async {
              ref.refreshAll();
            },
            child: Column(
              children: [
                _buildBalanceCard(context, config),
                _buildProgressCard(context, config),
                Expanded(
                  child: logsAsync.when(
                    data: (logs) {
                      if (logs.isEmpty) {
                        return _buildEmptyLogs(context);
                      }
                      return ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: logs.length,
                        itemBuilder: (context, index) {
                          final log = logs[logs.length - 1 - index];
                          return _LogItem(key: ValueKey(log.id), log: log);
                        },
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
                            onPressed: () => ref.refreshAfterTallyUpdate(),
                            icon: const Icon(Icons.refresh),
                            label: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
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
                onPressed: () => ref.refreshAfterConfigChange(),
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddDialog(context, ref),
        label: const Text('Log Action'),
        icon: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildSetupPrompt(BuildContext context, WidgetRef ref, TallyRepository service) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.account_balance_wallet,
              size: 80,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha:0.38),
            ),
            const SizedBox(height: 24),
            Text(
              'Partner Budget Not Set Up',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 12),
            Text(
              'Set up your partner budget to start tracking relationship balance',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha:0.5),
                  ),
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: () => _showSetupDialog(context, ref, service),
              icon: const Icon(Icons.settings),
              label: const Text('Setup Budget'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBalanceCard(BuildContext context, PartnerConfig config) {
    final balance = config.currentBalance;
    final isPositive = balance >= 0;
    final balanceColor = isPositive
        ? Theme.of(context).colorScheme.tertiary
        : Theme.of(context).colorScheme.error;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            balanceColor.withValues(alpha:0.1),
            balanceColor.withValues(alpha:0.2),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: balanceColor.withValues(alpha:0.3), width: 2),
      ),
      child: Column(
        children: [
          Text(
            'Current Balance',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            '\$${balance.toStringAsFixed(2)}',
            style: Theme.of(context).textTheme.displayMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: balanceColor,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            isPositive ? 'Positive Balance' : 'Negative Balance',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressCard(BuildContext context, PartnerConfig config) {
    final balance = config.currentBalance.abs();
    final limit = config.budgetLimit;
    final percentage = limit > 0 ? (balance / limit * 100).clamp(0, 100) : 0;
    final isPositive = config.currentBalance >= 0;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).dividerColor, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Budget Limit',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
              Text(
                '\$${limit.toStringAsFixed(2)}',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: percentage / 100,
              backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation<Color>(
                isPositive
                    ? Theme.of(context).colorScheme.tertiary
                    : Theme.of(context).colorScheme.error,
              ),
              minHeight: 12,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${percentage.toStringAsFixed(1)}% of budget used',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyLogs(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.history,
            size: 80,
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha:0.38),
          ),
          const SizedBox(height: 16),
          Text(
            'No actions logged yet',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }

  void _showSetupDialog(BuildContext context, WidgetRef ref, TallyRepository service) {
    showDialog(
      context: context,
      builder: (context) => SetupBudgetDialog(
        onSave: (budget, name) async {
          await service.initPartnerConfig(
            budgetLimit: budget,
            partnerName: name,
          );
          ref.refreshAfterConfigChange();
        },
      ),
    );
  }

  void _showAddDialog(BuildContext context, WidgetRef ref) {
    final configAsync = ref.watch(partnerConfigProvider);
    
    showDialog(
      context: context,
      builder: (context) {
        return configAsync.when(
          data: (config) {
            if (config == null) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (context.mounted) {
                  _showSetupDialog(context, ref, ref.read(tallyServiceProvider));
                }
              });
              return const SizedBox.shrink();
            }
            
            return AddActionDialog(
              onSave: (name, value, type) async {
                final tallyService = ref.read(tallyServiceProvider);
                await tallyService.logPartnerAction(
                  name: name,
                  value: value,
                  type: type,
                );
                ref.refreshAfterPartnerAction();
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, __) => AlertDialog(
            title: const Text('Error'),
            content: const Text('Failed to load budget configuration.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _LogItem extends ConsumerWidget {
  final TallyLog log;

  const _LogItem({super.key, required this.log});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isPositive = log.valueAdjustment >= 0;
    final color = isPositive
        ? Theme.of(context).colorScheme.tertiary
        : Theme.of(context).colorScheme.error;
    final icon = isPositive ? Icons.arrow_upward : Icons.arrow_downward;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Theme.of(context).dividerColor, width: 1),
      ),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withValues(alpha:0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color),
        ),
        title: Text(isPositive ? 'Positive Action' : 'Negative Action'),
        subtitle: Text(
          _formatDate(log.timestamp),
          style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),
        trailing: Text(
          '${isPositive ? '+' : ''}\${log.valueAdjustment.toStringAsFixed(2)}',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: color,
            fontSize: 18,
          ),
        ),
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
