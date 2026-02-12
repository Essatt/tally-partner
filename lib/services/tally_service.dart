import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/tally_event.dart';
import '../models/tally_log.dart';
import '../models/partner_config.dart';
import 'tally_repository.dart';

class TallyService implements TallyRepository {
  // Constants for box names
  static const String _eventsBoxName = 'tally_events';
  static const String _logsBoxName = 'tally_logs';
  static const String _configBoxName = 'partner_config';
  static const String _configKey = 'active_config';

  // Box references
  late final Box<TallyEvent> _eventsBox;
  late final Box<TallyLog> _logsBox;
  late final Box<PartnerConfig> _configBox;

  // Singleton pattern
  TallyService._internal();
  static final TallyService _instance = TallyService._internal();
  factory TallyService() => _instance;

  @override
  Future<void> init() async {
    _eventsBox = await _openBoxSafe<TallyEvent>(_eventsBoxName);
    _logsBox = await _openBoxSafe<TallyLog>(_logsBoxName);
    _configBox = await _openBoxSafe<PartnerConfig>(_configBoxName);
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

  // --- Partner Config Operations ---

  @override
  Future<void> initPartnerConfig({
    String? id,
    double budgetLimit = 0.0,
    double currentBalance = 0.0,
    String partnerName = 'Partner',
    bool isActive = true,
  }) async {
    if (_configBox.get(_configKey) == null) {
      final config = PartnerConfig(
        id: id ?? _generateId(),
        budgetLimit: budgetLimit,
        currentBalance: currentBalance,
        partnerName: partnerName,
        isActive: isActive,
      );
      await _configBox.put(_configKey, config);
    }
  }

  @override
  PartnerConfig? getPartnerConfig() {
    return _configBox.get(_configKey);
  }

  @override
  Future<void> updatePartnerConfig(PartnerConfig updates) async {
    final current = _configBox.get(_configKey);
    if (current != null) {
      final updatedConfig = current.copyWith(
        budgetLimit: updates.budgetLimit,
        currentBalance: updates.currentBalance,
        partnerName: updates.partnerName,
        isActive: updates.isActive,
      );
      await _configBox.put(_configKey, updatedConfig);
    } else {
      await _configBox.put(_configKey, updates);
    }
  }

  @override
  Future<void> adjustBalance(double amount) async {
    final config = _configBox.get(_configKey);
    if (config == null) return;
    final newBalance = config.currentBalance + amount;
    await _configBox.put(_configKey, config.copyWith(currentBalance: newBalance));
  }

  // --- Event Operations ---

  @override
  Future<void> addEvent(TallyEvent event) async {
    final id = event.id.isEmpty ? _generateId() : event.id;
    final eventWithId = event.copyWith(id: id);
    await _eventsBox.put(id, eventWithId);
  }

  @override
  List<TallyEvent> getEvents() {
    return _eventsBox.values.toList();
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
      final log = TallyLog(
        id: _generateId(),
        eventId: eventId,
        timestamp: DateTime.now(),
        valueAdjustment: value,
      );
      await addLog(log);
    }
  }

  @override
  Future<void> decrementTally(String eventId, {double value = 1.0}) async {
    final event = _eventsBox.get(eventId);
    if (event != null) {
      final log = TallyLog(
        id: _generateId(),
        eventId: eventId,
        timestamp: DateTime.now(),
        valueAdjustment: -value,
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
    return _logsBox.values
        .where((log) => log.eventId == eventId)
        .toList();
  }

  @override
  List<TallyLog> getLogsByDateRange(DateTime start, DateTime end) {
    return _logsBox.values
        .where((log) => log.timestamp.compareTo(start) >= 0 && log.timestamp.compareTo(end) <= 0)
        .toList();
  }

  @override
  Future<void> logPartnerAction({
    required String name,
    required double value,
    required String type,
  }) async {
    final isPositive = type == 'positive';
    final event = TallyEvent(
      id: '',
      name: name,
      icon: isPositive ? 'thumb_up' : 'thumb_down',
      color: isPositive ? '#4CD964' : '#FF3B30',
      createdAt: DateTime.now(),
      type: isPositive ? TallyType.partnerPositive : TallyType.partnerNegative,
    );
    await addEvent(event);
    await adjustBalance(value);
  }
}
