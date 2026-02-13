import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../tallies/presentation/providers/tally_provider.dart';
import '../../../../models/person.dart';
import '../../../../models/budget.dart';
import '../widgets/add_person_dialog.dart';
import 'person_detail_page.dart';

class PeoplePage extends ConsumerWidget {
  const PeoplePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final peopleAsync = ref.watch(peopleProvider);

    return peopleAsync.when(
      data: (people) {
        if (people.isEmpty) {
          return _buildEmptyState(context, ref);
        }
        if (people.length == 1) {
          return PersonDetailPage(
            personId: people.first.id,
            showBackButton: false,
            onAddPerson: () => _showAddPersonDialog(context, ref),
          );
        }
        return _buildPeopleList(context, ref, people);
      },
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (error, stack) => Scaffold(
        appBar: AppBar(title: const Text('People')),
        body: Center(
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
                onPressed: () => ref.refreshAfterPersonChange(),
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('People'), elevation: 0),
      body: Center(
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
                      .tertiaryContainer
                      .withValues(alpha: 0.3),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.people_rounded,
                  size: 48,
                  color: Theme.of(context).colorScheme.tertiary,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Add Your First Person',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Track budgets for your partner, friends, colleagues, or anyone else. Add a person to get started.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 32),
              FilledButton.icon(
                onPressed: () => _showAddPersonDialog(context, ref),
                icon: const Icon(Icons.person_add),
                label: const Text('Add Person'),
                style: FilledButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPeopleList(
      BuildContext context, WidgetRef ref, List<Person> people) {
    return Scaffold(
      appBar: AppBar(title: const Text('People'), elevation: 0),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.refreshAfterPersonChange();
        },
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: people.length,
          itemBuilder: (context, index) {
            final person = people[index];
            return _PersonCard(
              person: person,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => PersonDetailPage(
                      personId: person.id,
                      showBackButton: true,
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddPersonDialog(context, ref),
        label: const Text('Add Person'),
        icon: const Icon(Icons.person_add),
      ),
    );
  }

  void _showAddPersonDialog(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => AddPersonDialog(
        onSave: (name, label, budgetName, budgetLimit) async {
          final service = ref.read(tallyServiceProvider);
          final person = Person(
            id: '',
            name: name,
            label: label,
            createdAt: DateTime.now(),
          );
          await service.addPerson(person);

          // Get the created person (to get the generated ID)
          final people = service.getPeople();
          final createdPerson = people.lastWhere((p) => p.name == name);

          // Create initial budget if provided
          if (budgetName != null && budgetLimit != null) {
            final budget = Budget(
              id: '',
              personId: createdPerson.id,
              name: budgetName,
              budgetLimit: budgetLimit,
              currentBalance: 0,
              createdAt: DateTime.now(),
            );
            await service.addBudget(budget);
          }

          ref.refreshAfterPersonChange();
        },
      ),
    );
  }
}

class _PersonCard extends ConsumerWidget {
  final Person person;
  final VoidCallback onTap;

  const _PersonCard({required this.person, required this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final budgetsAsync = ref.watch(budgetsForPersonProvider(person.id));

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        onTap: onTap,
        child: Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.all(16),
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
                      person.name.isNotEmpty
                          ? person.name[0].toUpperCase()
                          : '?',
                      style:
                          Theme.of(context).textTheme.headlineSmall?.copyWith(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onPrimaryContainer,
                                fontWeight: FontWeight.bold,
                              ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        person.name,
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          _buildLabelChip(context, person.label),
                          const SizedBox(width: 8),
                          budgetsAsync.when(
                            data: (budgets) => Text(
                              '${budgets.length} ${budgets.length == 1 ? 'budget' : 'budgets'}',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                  ),
                            ),
                            loading: () => const SizedBox.shrink(),
                            error: (_, __) => const SizedBox.shrink(),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLabelChip(BuildContext context, String label) {
    return Container(
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
              color: Theme.of(context).colorScheme.onTertiaryContainer,
              fontWeight: FontWeight.w500,
            ),
      ),
    );
  }
}
