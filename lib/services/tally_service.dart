import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/tally_event.dart';
import '../models/tally_log.dart';
import '../models/partner_config.dart';
import '../models/person.dart';
import '../models/budget.dart';
import 'tally_repository.dart';

class TallyService implements TallyRepository {
  // Constants for box names
  static const String _eventsBoxName = 'tally_events';
  static const String _logsBoxName = 'tally_logs';
  static const String _configBoxName = 'partner_config';
  static const String _peopleBoxName = 'people';
  static const String _budgetsBoxName = 'budgets';
  static const String _configKey = 'active_config';

  // Box references
  late final Box<TallyEvent> _eventsBox;
  late final Box<TallyLog> _logsBox;
  late final Box<PartnerConfig> _configBox;
  late final Box<Person> _peopleBox;
  late final Box<Budget> _budgetsBox;

  // Singleton pattern
  TallyService._internal();
  static final TallyService _instance = TallyService._internal();
  factory TallyService() => _instance;

  @override
  Future<void> init() async {
    _eventsBox = await _openBoxSafe<TallyEvent>(_eventsBoxName);
    _logsBox = await _openBoxSafe<TallyLog>(_logsBoxName);
    _configBox = await _openBoxSafe<PartnerConfig>(_configBoxName);
    _peopleBox = await _openBoxSafe<Person>(_peopleBoxName);
    _budgetsBox = await _openBoxSafe<Budget>(_budgetsBoxName);
  }

  Future<Box<T>> _openBoxSafe<T>(String name) async {
    for (var attempt = 0; attempt < 3; attempt++) {
      try {
        return await Hive.openBox<T>(name);
      } on HiveError catch (e) {
        if (e.message.contains('corrupted') ||
            e.message.contains('invalid') ||
            attempt == 2) {
          await Hive.deleteBoxFromDisk(name);
          return await Hive.openBox<T>(name);
        }
        await Future.delayed(Duration(milliseconds: 100 * (attempt + 1)));
      } catch (_) {
        if (attempt == 2) {
          await Hive.deleteBoxFromDisk(name);
          return await Hive.openBox<T>(name);
        }
        await Future.delayed(Duration(milliseconds: 100 * (attempt + 1)));
      }
    }
    // Fallback - should not reach here
    return await Hive.openBox<T>(name);
  }

  static const _uuid = Uuid();

  String _generateId() {
    return _uuid.v4();
  }

  // --- People Operations ---

  @override
  Future<void> addPerson(Person person) async {
    final id = person.id.isEmpty ? _generateId() : person.id;
    final personWithId = person.copyWith(id: id);
    await _peopleBox.put(id, personWithId);
  }

  @override
  Future<void> updatePerson(Person person) async {
    await _peopleBox.put(person.id, person);
  }

  @override
  List<Person> getPeople() {
    return _peopleBox.values.toList();
  }

  @override
  Person? getPerson(String id) {
    return _peopleBox.get(id);
  }

  @override
  Future<void> deletePerson(String id) async {
    await _peopleBox.delete(id);
    // Clean up budgets for this person
    final budgetsToDelete = _budgetsBox.values
        .where((b) => b.personId == id)
        .map((b) => b.id)
        .toList();
    for (final budgetId in budgetsToDelete) {
      await _budgetsBox.delete(budgetId);
    }
    // Clean up events assigned to this person
    final events = _eventsBox.values.where((e) => e.personId == id).toList();
    for (final event in events) {
      await _eventsBox.put(
          event.id, event.copyWith(personId: null, assignedBudgetIds: []));
    }
  }

  // --- Budget Operations ---

  @override
  Future<void> addBudget(Budget budget) async {
    final id = budget.id.isEmpty ? _generateId() : budget.id;
    final budgetWithId = budget.copyWith(id: id);
    await _budgetsBox.put(id, budgetWithId);
  }

  @override
  Future<void> updateBudget(Budget budget) async {
    await _budgetsBox.put(budget.id, budget);
  }

  @override
  List<Budget> getBudgets() {
    return _budgetsBox.values.toList();
  }

  @override
  List<Budget> getBudgetsForPerson(String personId) {
    return _budgetsBox.values.where((b) => b.personId == personId).toList();
  }

  @override
  Budget? getBudget(String id) {
    return _budgetsBox.get(id);
  }

  @override
  Future<void> deleteBudget(String id) async {
    await _budgetsBox.delete(id);
  }

  @override
  Future<void> adjustBudgetBalance(String budgetId, double amount) async {
    final budget = _budgetsBox.get(budgetId);
    if (budget == null) return;
    final newBalance = budget.currentBalance + amount;
    await _budgetsBox.put(
        budgetId, budget.copyWith(currentBalance: newBalance));
  }

  // --- Legacy Partner Config (for migration) ---

  @override
  PartnerConfig? getPartnerConfig() {
    return _configBox.get(_configKey);
  }

  // --- Event Operations ---

  @override
  Future<void> addEvent(TallyEvent event) async {
    final id = event.id.isEmpty ? _generateId() : event.id;
    final eventWithId = event.copyWith(id: id);
    await _eventsBox.put(id, eventWithId);
  }

  @override
  Future<void> updateEvent(TallyEvent event) async {
    await _eventsBox.put(event.id, event);
  }

  @override
  List<TallyEvent> getEvents() {
    return _eventsBox.values.toList();
  }

  @override
  TallyEvent? getEvent(String id) {
    return _eventsBox.get(id);
  }

  @override
  Future<void> toggleFavorite(String eventId) async {
    final event = _eventsBox.get(eventId);
    if (event != null) {
      await _eventsBox.put(
          eventId, event.copyWith(isFavorite: !event.isFavorite));
    }
  }

  @override
  Future<void> deleteEvent(String id) async {
    await _eventsBox.delete(id);
    // Clean up orphaned logs for this event
    final logsToDelete = _logsBox.values
        .where((log) => log.eventId == id)
        .map((log) => log.key)
        .toList();
    for (final key in logsToDelete) {
      await _logsBox.delete(key);
    }
  }

  @override
  Future<void> clearEvents() async {
    await _eventsBox.clear();
  }

  // --- Log Operations ---

  @override
  Future<void> addLog(TallyLog log) async {
    final id = log.id.isEmpty ? _generateId() : log.id;
    final logWithId = log.copyWith(id: id);
    await _logsBox.put(id, logWithId);
  }

  @override
  Future<void> deleteLog(String logId) async {
    final log = _logsBox.get(logId);
    if (log == null) return;
    // Reverse budget adjustments
    for (final entry in log.budgetAdjustments.entries) {
      await adjustBudgetBalance(entry.key, -entry.value);
    }
    await _logsBox.delete(logId);
  }

  @override
  TallyLog? getLastLogForEvent(String eventId) {
    final logs = _logsBox.values.where((log) => log.eventId == eventId).toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return logs.isEmpty ? null : logs.first;
  }

  @override
  List<TallyLog> getLogs() {
    return _logsBox.values.toList();
  }

  @override
  Future<void> clearLogs() async {
    await _logsBox.clear();
  }

  // --- Tally Operations ---

  @override
  Future<void> incrementTally(String eventId, {double value = 1.0}) async {
    final event = _eventsBox.get(eventId);
    if (event != null) {
      final adjustmentValue =
          event.type != TallyType.standard ? event.value : value;

      // Build budget adjustments map for partner tallies
      final Map<String, double> budgetAdj = {};
      if (event.type != TallyType.standard) {
        final amount = event.type == TallyType.partnerPositive
            ? adjustmentValue
            : -adjustmentValue;
        for (final budgetId in event.assignedBudgetIds) {
          budgetAdj[budgetId] = amount;
          await adjustBudgetBalance(budgetId, amount);
        }
      }

      final log = TallyLog(
        id: _generateId(),
        eventId: eventId,
        timestamp: DateTime.now(),
        valueAdjustment: adjustmentValue,
        budgetAdjustments: budgetAdj,
      );
      await addLog(log);
    }
  }

  @override
  Future<void> decrementTally(String eventId, {double value = 1.0}) async {
    final event = _eventsBox.get(eventId);
    if (event != null) {
      final adjustmentValue =
          event.type != TallyType.standard ? event.value : value;

      // Build budget adjustments map (reverse of increment)
      final Map<String, double> budgetAdj = {};
      if (event.type != TallyType.standard) {
        final amount = event.type == TallyType.partnerPositive
            ? -adjustmentValue
            : adjustmentValue;
        for (final budgetId in event.assignedBudgetIds) {
          budgetAdj[budgetId] = amount;
          await adjustBudgetBalance(budgetId, amount);
        }
      }

      final log = TallyLog(
        id: _generateId(),
        eventId: eventId,
        timestamp: DateTime.now(),
        valueAdjustment: -adjustmentValue,
        budgetAdjustments: budgetAdj,
      );
      await addLog(log);
    }
  }

  @override
  int getTallyCount(String eventId) {
    return _logsBox.values
        .where((log) => log.eventId == eventId)
        .fold(0.0, (sum, log) => sum + log.valueAdjustment)
        .round();
  }

  @override
  List<TallyLog> getLogsForEvent(String eventId) {
    return _logsBox.values.where((log) => log.eventId == eventId).toList();
  }

  @override
  List<TallyLog> getLogsByDateRange(DateTime start, DateTime end) {
    return _logsBox.values
        .where((log) =>
            log.timestamp.compareTo(start) >= 0 &&
            log.timestamp.compareTo(end) <= 0)
        .toList();
  }

  @override
  Future<void> logPartnerAction({
    required String name,
    required double value,
    required String type,
    required String personId,
    required List<String> budgetIds,
  }) async {
    final isPositive = type == 'positive';
    final absValue = value.abs();
    final eventId = _generateId();
    final event = TallyEvent(
      id: eventId,
      name: name,
      icon: isPositive ? 'thumb_up' : 'thumb_down',
      color: isPositive ? '#4CD964' : '#FF3B30',
      createdAt: DateTime.now(),
      type: isPositive ? TallyType.partnerPositive : TallyType.partnerNegative,
      value: absValue,
      personId: personId,
      assignedBudgetIds: budgetIds,
    );
    await _eventsBox.put(eventId, event);

    // Adjust each assigned budget
    final Map<String, double> budgetAdj = {};
    final adjustAmount = isPositive ? absValue : -absValue;
    for (final budgetId in budgetIds) {
      budgetAdj[budgetId] = adjustAmount;
      await adjustBudgetBalance(budgetId, adjustAmount);
    }

    final log = TallyLog(
      id: _generateId(),
      eventId: eventId,
      timestamp: DateTime.now(),
      valueAdjustment: value,
      budgetAdjustments: budgetAdj,
    );
    await addLog(log);
  }
}
