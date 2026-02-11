import 'package:hive/hive.dart';

part 'tally_log.g.dart';

@HiveType(typeId: 4)
class TallyLog extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String eventId;

  @HiveField(2)
  final DateTime timestamp;

  @HiveField(3)
  final double valueAdjustment;

  TallyLog({
    required this.id,
    required this.eventId,
    required this.timestamp,
    this.valueAdjustment = 1.0,
  });

  TallyLog copyWith({
    String? id,
    String? eventId,
    DateTime? timestamp,
    double? valueAdjustment,
  }) {
    return TallyLog(
      id: id ?? this.id,
      eventId: eventId ?? this.eventId,
      timestamp: timestamp ?? this.timestamp,
      valueAdjustment: valueAdjustment ?? this.valueAdjustment,
    );
  }
}
