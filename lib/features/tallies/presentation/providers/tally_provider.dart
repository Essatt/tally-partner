import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../services/tally_repository.dart';
import '../../../../services/tally_service.dart';
import '../../../../models/tally_event.dart';
import '../../../../models/tally_log.dart';
import '../../../../models/person.dart';
import '../../../../models/budget.dart';

// Tally Service Provider — typed as abstract TallyRepository for testability
final tallyServiceProvider = Provider<TallyRepository>((ref) {
  return TallyService();
});

// Tally Events Provider
final tallyEventsProvider = FutureProvider<List<TallyEvent>>((ref) async {
  final service = ref.watch(tallyServiceProvider);
  return service.getEvents();
});

// Tally Logs Provider
final tallyLogsProvider = FutureProvider<List<TallyLog>>((ref) async {
  final service = ref.watch(tallyServiceProvider);
  return service.getLogs();
});

// People Provider
final peopleProvider = FutureProvider<List<Person>>((ref) async {
  final service = ref.watch(tallyServiceProvider);
  return service.getPeople();
});

// Budgets Provider
final budgetsProvider = FutureProvider<List<Budget>>((ref) async {
  final service = ref.watch(tallyServiceProvider);
  return service.getBudgets();
});

// Budgets for a specific person — derived from budgetsProvider for cascading invalidation
final budgetsForPersonProvider =
    Provider.family<AsyncValue<List<Budget>>, String>((ref, personId) {
  final allBudgets = ref.watch(budgetsProvider);
  return allBudgets.whenData(
      (budgets) => budgets.where((b) => b.personId == personId).toList());
});

// Single person lookup — derived from peopleProvider for reactivity
final personProvider = Provider.family<Person?, String>((ref, personId) {
  final people = ref.watch(peopleProvider);
  return people.whenOrNull(
      data: (list) => list.where((p) => p.id == personId).firstOrNull);
});

// Single Tally Count Provider — watches logs so it recomputes on log changes
final tallyCountProvider = Provider.family<int, String>((ref, eventId) {
  final logsAsync = ref.watch(tallyLogsProvider);
  return logsAsync.when(
    data: (logs) => logs
        .where((log) => log.eventId == eventId)
        .fold(0.0, (sum, log) => sum + log.valueAdjustment)
        .round(),
    loading: () => 0,
    error: (_, __) => 0,
  );
});

// --- State Coordination ---
// Centralizes provider invalidation patterns to avoid scattered, inconsistent refreshes.

extension TallyStateCoordinator on WidgetRef {
  /// Refresh after a tally was incremented/decremented (only logs changed).
  void refreshAfterTallyUpdate() {
    invalidate(tallyLogsProvider);
    invalidate(budgetsProvider);
  }

  /// Refresh after an event was created or deleted.
  void refreshAfterEventChange() {
    invalidate(tallyEventsProvider);
    invalidate(tallyLogsProvider);
  }

  /// Refresh after a partner budget action (affects events, logs, and budgets).
  void refreshAfterPartnerAction() {
    invalidate(tallyEventsProvider);
    invalidate(tallyLogsProvider);
    invalidate(budgetsProvider);
  }

  /// Refresh after a person was added, updated, or deleted.
  void refreshAfterPersonChange() {
    invalidate(peopleProvider);
    invalidate(budgetsProvider);
  }

  /// Refresh after a budget was added, updated, or deleted.
  void refreshAfterBudgetChange() {
    invalidate(budgetsProvider);
  }

  /// Refresh everything (e.g. pull-to-refresh).
  void refreshAll() {
    invalidate(tallyEventsProvider);
    invalidate(tallyLogsProvider);
    invalidate(peopleProvider);
    invalidate(budgetsProvider);
  }
}
