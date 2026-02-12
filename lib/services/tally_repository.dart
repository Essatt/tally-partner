import '../models/tally_event.dart';
import '../models/tally_log.dart';
import '../models/partner_config.dart';

abstract class TallyRepository {
  // Initialization
  Future<void> init();

  // Partner Config
  Future<void> initPartnerConfig({
    String? id,
    double budgetLimit,
    double currentBalance,
    String partnerName,
    bool isActive,
  });
  PartnerConfig? getPartnerConfig();
  Future<void> updatePartnerConfig(PartnerConfig updates);
  Future<void> adjustBalance(double amount);

  // Events
  Future<void> addEvent(TallyEvent event);
  List<TallyEvent> getEvents();
  Future<void> deleteEvent(String id);
  Future<void> clearEvents();

  // Logs
  Future<void> addLog(TallyLog log);
  List<TallyLog> getLogs();
  Future<void> clearLogs();

  // Tally Operations
  Future<void> incrementTally(String eventId, {double value});
  Future<void> decrementTally(String eventId, {double value});
  int getTallyCount(String eventId);
  List<TallyLog> getLogsForEvent(String eventId);
  List<TallyLog> getLogsByDateRange(DateTime start, DateTime end);

  /// Logs a partner budget action: creates an event and adjusts the balance atomically.
  Future<void> logPartnerAction({
    required String name,
    required double value,
    required String type,
  });
}
