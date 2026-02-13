import '../models/tally_event.dart';
import '../models/tally_log.dart';
import '../models/partner_config.dart';
import '../models/person.dart';
import '../models/budget.dart';

abstract class TallyRepository {
  // Initialization
  Future<void> init();

  // People
  Future<void> addPerson(Person person);
  Future<void> updatePerson(Person person);
  List<Person> getPeople();
  Person? getPerson(String id);
  Future<void> deletePerson(String id);

  // Budgets
  Future<void> addBudget(Budget budget);
  Future<void> updateBudget(Budget budget);
  List<Budget> getBudgets();
  List<Budget> getBudgetsForPerson(String personId);
  Budget? getBudget(String id);
  Future<void> deleteBudget(String id);
  Future<void> adjustBudgetBalance(String budgetId, double amount);

  // Legacy Partner Config (kept for migration)
  PartnerConfig? getPartnerConfig();

  // Events
  Future<void> addEvent(TallyEvent event);
  Future<void> updateEvent(TallyEvent event);
  List<TallyEvent> getEvents();
  TallyEvent? getEvent(String id);
  Future<void> deleteEvent(String id);
  Future<void> toggleFavorite(String eventId);
  Future<void> clearEvents();

  // Logs
  Future<void> addLog(TallyLog log);
  Future<void> deleteLog(String logId);
  TallyLog? getLastLogForEvent(String eventId);
  List<TallyLog> getLogs();
  Future<void> clearLogs();

  // Tally Operations
  Future<void> incrementTally(String eventId, {double value});
  Future<void> decrementTally(String eventId, {double value});
  int getTallyCount(String eventId);
  List<TallyLog> getLogsForEvent(String eventId);
  List<TallyLog> getLogsByDateRange(DateTime start, DateTime end);

  /// Logs a partner budget action: creates an event and adjusts budgets atomically.
  Future<void> logPartnerAction({
    required String name,
    required double value,
    required String type,
    required String personId,
    required List<String> budgetIds,
  });
}
