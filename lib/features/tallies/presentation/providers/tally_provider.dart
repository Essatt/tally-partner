import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../services/tally_repository.dart';
import '../../../../services/tally_service.dart';
import '../../../../models/tally_event.dart';
import '../../../../models/tally_log.dart';
import '../../../../models/partner_config.dart';

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

// Partner Config Provider
final partnerConfigProvider = FutureProvider<PartnerConfig?>((ref) async {
  final service = ref.watch(tallyServiceProvider);
  return service.getPartnerConfig();
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
  }

  /// Refresh after an event was created or deleted.
  void refreshAfterEventChange() {
    invalidate(tallyEventsProvider);
    invalidate(tallyLogsProvider);
  }

  /// Refresh after a partner budget action (affects config, events, and logs).
  void refreshAfterPartnerAction() {
    invalidate(partnerConfigProvider);
    invalidate(tallyEventsProvider);
    invalidate(tallyLogsProvider);
  }

  /// Refresh after partner config was set up or updated.
  void refreshAfterConfigChange() {
    invalidate(partnerConfigProvider);
  }

  /// Refresh everything (e.g. pull-to-refresh).
  void refreshAll() {
    invalidate(tallyEventsProvider);
    invalidate(tallyLogsProvider);
    invalidate(partnerConfigProvider);
  }
}
