import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../tallies/presentation/providers/tally_provider.dart';
import '../widgets/add_action_dialog.dart';
import '../widgets/setup_budget_dialog.dart';
import '../../../../models/partner_config.dart';
import '../../../../models/tally_log.dart';
import '../../../../models/tally_event.dart';

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
              ref.invalidate(partnerConfigProvider);
              ref.invalidate(tallyLogsProvider);
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
                          final log = logs.reversed.toList()[index];
                          return _LogItem(log: log);
                        },
                      );
                    },
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (error, stack) => Center(
                      child: Text('Error: $error'),
                    ),
                  ),
                ),
              ],
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
        label: const Text('Log Action'),
        icon: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildSetupPrompt(BuildContext context, WidgetRef ref, dynamic service) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.account_balance_wallet,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 24),
            Text(
              'Partner Budget Not Set Up',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.grey[700],
                  ),
            ),
            const SizedBox(height: 12),
            Text(
              'Set up your partner budget to start tracking relationship balance',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.grey[500],
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
    final balanceColor = isPositive ? Colors.green : Colors.red;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            balanceColor.withOpacity(0.1),
            balanceColor.withOpacity(0.2),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: balanceColor.withOpacity(0.3), width: 2),
      ),
      child: Column(
        children: [
          Text(
            'Current Balance',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.grey[700],
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
                  color: Colors.grey[600],
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200, width: 1),
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
                      color: Colors.grey[700],
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
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation<Color>(
                isPositive ? Colors.green : Colors.red,
              ),
              minHeight: 12,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${percentage.toStringAsFixed(1)}% of budget used',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
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
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No actions logged yet',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
        ],
      ),
    );
  }

  void _showSetupDialog(BuildContext context, WidgetRef ref, dynamic service) {
    showDialog(
      context: context,
      builder: (context) => SetupBudgetDialog(
        onSave: (budget, name) async {
          await service.initPartnerConfig(
            budgetLimit: budget,
            partnerName: name,
          );
          ref.invalidate(partnerConfigProvider);
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
                _showSetupDialog(context, ref, ref.read(tallyServiceProvider));
              });
              return const SizedBox.shrink();
            }
            
            return AddActionDialog(
              onSave: (name, value, type) async {
                final tallyService = ref.read(tallyServiceProvider);
                final event = TallyEvent(
                  id: '',
                  name: name,
                  icon: type == 'positive' ? 'thumb_up' : 'thumb_down',
                  color: type == 'positive' ? '#4CD964' : '#FF3B30',
                  createdAt: DateTime.now(),
                  type: type == 'positive'
                      ? TallyType.partnerPositive
                      : TallyType.partnerNegative,
                );
                await tallyService.addEvent(event);

                final newBalance = config.currentBalance + value;
                await tallyService.updatePartnerConfig(
                  config.copyWith(currentBalance: newBalance),
                );

                ref.invalidate(partnerConfigProvider);
                ref.invalidate(tallyEventsProvider);
                ref.invalidate(tallyLogsProvider);
              },
            );
          },
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
        );
      },
    );
  }
}

class _LogItem extends ConsumerWidget {
  final TallyLog log;

  const _LogItem({required this.log});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isPositive = log.valueAdjustment >= 0;
    final color = isPositive ? Colors.green : Colors.red;
    final icon = isPositive ? Icons.arrow_upward : Icons.arrow_downward;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200, width: 1),
      ),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color),
        ),
        title: Text(isPositive ? 'Positive Action' : 'Negative Action'),
        subtitle: Text(
          _formatDate(log.timestamp),
          style: TextStyle(color: Colors.grey[600]),
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
