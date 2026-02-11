import 'package:hive/hive.dart';

part 'tally_event.g.dart';

@HiveType(typeId: 5)
class TallyEvent extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String? icon;

  @HiveField(3)
  final String? color;

  @HiveField(4)
  final DateTime createdAt;

  @HiveField(5)
  final TallyType type;

  TallyEvent({
    required this.id,
    required this.name,
    this.icon,
    this.color,
    required this.createdAt,
    required this.type,
  });

  TallyEvent copyWith({
    String? id,
    String? name,
    String? icon,
    String? color,
    DateTime? createdAt,
    TallyType? type,
  }) {
    return TallyEvent(
      id: id ?? this.id,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      createdAt: createdAt ?? this.createdAt,
      type: type ?? this.type,
    );
  }
}

@HiveType(typeId: 6)
enum TallyType {
  @HiveField(0)
  standard,
  @HiveField(1)
  partnerPositive,
  @HiveField(2)
  partnerNegative,
}
