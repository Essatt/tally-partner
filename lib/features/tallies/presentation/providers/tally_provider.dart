import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../services/tally_service.dart';
import '../../../../models/tally_event.dart';
import '../../../../models/tally_log.dart';
import '../../../../models/partner_config.dart';

// Tally Service Provider
final tallyServiceProvider = Provider<TallyService>((ref) {
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

// Single Tally Count Provider
final tallyCountProvider = Provider.family<int, String>((ref, eventId) {
  final service = ref.watch(tallyServiceProvider);
  return service.getTallyCount(eventId);
});
