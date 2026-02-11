import 'package:hive_flutter/hive_flutter.dart';
import '../models/tally_event.dart';
import '../models/tally_log.dart';
import '../models/partner_config.dart';

class TallyService {
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

  /// Initializes the service by opening Hive boxes.
  /// Note: Hive.initFlutter() and Adapter registration are handled in main.dart.
  Future<void> init() async {
    try {
      _eventsBox = await Hive.openBox<TallyEvent>(_eventsBoxName);
      _logsBox = await Hive.openBox<TallyLog>(_logsBoxName);
      _configBox = await Hive.openBox<PartnerConfig>(_configBoxName);
    } catch (e) {
      rethrow;
    }
  }

  String _generateId() {
    return DateTime.now().microsecondsSinceEpoch.toString();
  }

  // --- Partner Config Operations ---

  /// Initializes the partner configuration if it does not already exist.
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

  /// Retrieves the active partner configuration.
  PartnerConfig? getPartnerConfig() {
    return _configBox.get(_configKey);
  }

  /// Updates the active partner configuration using copyWith for immutability.
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

  // --- Event Operations ---

  Future<void> addEvent(TallyEvent event) async {
    try {
      final id = event.id.isEmpty ? _generateId() : event.id;
      final eventWithId = event.copyWith(id: id);
      await _eventsBox.put(id, eventWithId);
    } catch (e) {
      rethrow;
    }
  }

  List<TallyEvent> getEvents() {
    return _eventsBox.values.toList();
  }

  Future<void> deleteEvent(String id) async {
    try {
      await _eventsBox.delete(id);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> clearEvents() async {
    try {
      await _eventsBox.clear();
    } catch (e) {
      rethrow;
    }
  }

  // --- Log Operations ---

  Future<void> addLog(TallyLog log) async {
    try {
      final id = log.id.isEmpty ? _generateId() : log.id;
      final logWithId = log.copyWith(id: id);
      await _logsBox.put(id, logWithId);
    } catch (e) {
      rethrow;
    }
  }

  List<TallyLog> getLogs() {
    return _logsBox.values.toList();
  }

  Future<void> clearLogs() async {
    try {
      await _logsBox.clear();
    } catch (e) {
      rethrow;
    }
  }

  // --- Tally Operations ---

  /// Increments the tally for a specific event and logs it.
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

  /// Decrements the tally for a specific event and logs it.
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

  /// Gets the count of tallies for a specific event.
  int getTallyCount(String eventId) {
    return _logsBox.values
        .where((log) => log.eventId == eventId)
        .fold(0.0, (sum, log) => sum + log.valueAdjustment)
        .round();
  }

  /// Gets logs for a specific event.
  List<TallyLog> getLogsForEvent(String eventId) {
    return _logsBox.values
        .where((log) => log.eventId == eventId)
        .toList();
  }

  /// Gets logs within a date range.
  List<TallyLog> getLogsByDateRange(DateTime start, DateTime end) {
    return _logsBox.values
        .where((log) => log.timestamp.isAfter(start) && log.timestamp.isBefore(end))
        .toList();
  }
}
