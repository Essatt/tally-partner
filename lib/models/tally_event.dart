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

  @HiveField(6)
  final double value;

  @HiveField(7)
  final String? personId;

  @HiveField(8)
  final List<String> assignedBudgetIds;

  @HiveField(9)
  final bool isFavorite;

  TallyEvent({
    required this.id,
    required this.name,
    this.icon,
    this.color,
    required this.createdAt,
    required this.type,
    this.value = 1.0,
    this.personId,
    this.assignedBudgetIds = const [],
    this.isFavorite = false,
  });

  TallyEvent copyWith({
    String? id,
    String? name,
    String? icon,
    String? color,
    DateTime? createdAt,
    TallyType? type,
    double? value,
    String? personId,
    List<String>? assignedBudgetIds,
    bool? isFavorite,
  }) {
    return TallyEvent(
      id: id ?? this.id,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      createdAt: createdAt ?? this.createdAt,
      type: type ?? this.type,
      value: value ?? this.value,
      personId: personId ?? this.personId,
      assignedBudgetIds: assignedBudgetIds ?? this.assignedBudgetIds,
      isFavorite: isFavorite ?? this.isFavorite,
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
