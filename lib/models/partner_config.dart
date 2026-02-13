import 'package:hive/hive.dart';

part 'partner_config.g.dart';

@HiveType(typeId: 3)
class PartnerConfig extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final double budgetLimit;

  @HiveField(2)
  final double currentBalance;

  @HiveField(3)
  final String partnerName;

  @HiveField(4)
  final bool isActive;

  PartnerConfig({
    required this.id,
    required this.budgetLimit,
    required this.currentBalance,
    required this.partnerName,
    required this.isActive,
  });

  PartnerConfig copyWith({
    String? id,
    double? budgetLimit,
    double? currentBalance,
    String? partnerName,
    bool? isActive,
  }) {
    return PartnerConfig(
      id: id ?? this.id,
      budgetLimit: budgetLimit ?? this.budgetLimit,
      currentBalance: currentBalance ?? this.currentBalance,
      partnerName: partnerName ?? this.partnerName,
      isActive: isActive ?? this.isActive,
    );
  }

  @override
  String toString() {
    return 'PartnerConfig(id: $id, isActive: $isActive)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is PartnerConfig &&
        other.id == id &&
        other.budgetLimit == budgetLimit &&
        other.currentBalance == currentBalance &&
        other.partnerName == partnerName &&
        other.isActive == isActive;
  }

  @override
  int get hashCode =>
      id.hashCode ^
      budgetLimit.hashCode ^
      currentBalance.hashCode ^
      partnerName.hashCode ^
      isActive.hashCode;
}
