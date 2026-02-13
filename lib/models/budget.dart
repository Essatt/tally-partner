import 'package:hive/hive.dart';

part 'budget.g.dart';

@HiveType(typeId: 8)
class Budget extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String personId;

  @HiveField(2)
  final String name;

  @HiveField(3)
  final double budgetLimit;

  @HiveField(4)
  final double currentBalance;

  @HiveField(5)
  final DateTime createdAt;

  Budget({
    required this.id,
    required this.personId,
    required this.name,
    required this.budgetLimit,
    required this.currentBalance,
    required this.createdAt,
  });

  Budget copyWith({
    String? id,
    String? personId,
    String? name,
    double? budgetLimit,
    double? currentBalance,
    DateTime? createdAt,
  }) {
    return Budget(
      id: id ?? this.id,
      personId: personId ?? this.personId,
      name: name ?? this.name,
      budgetLimit: budgetLimit ?? this.budgetLimit,
      currentBalance: currentBalance ?? this.currentBalance,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() =>
      'Budget(id: $id, personId: $personId, name: $name, balance: $currentBalance/$budgetLimit)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Budget &&
        other.id == id &&
        other.personId == personId &&
        other.name == name &&
        other.budgetLimit == budgetLimit &&
        other.currentBalance == currentBalance &&
        other.createdAt == createdAt;
  }

  @override
  int get hashCode =>
      id.hashCode ^
      personId.hashCode ^
      name.hashCode ^
      budgetLimit.hashCode ^
      currentBalance.hashCode ^
      createdAt.hashCode;
}
