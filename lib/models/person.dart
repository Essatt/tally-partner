import 'package:hive/hive.dart';

part 'person.g.dart';

@HiveType(typeId: 7)
class Person extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String label;

  @HiveField(3)
  final DateTime createdAt;

  Person({
    required this.id,
    required this.name,
    required this.label,
    required this.createdAt,
  });

  Person copyWith({
    String? id,
    String? name,
    String? label,
    DateTime? createdAt,
  }) {
    return Person(
      id: id ?? this.id,
      name: name ?? this.name,
      label: label ?? this.label,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() => 'Person(id: $id, name: $name, label: $label)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Person &&
        other.id == id &&
        other.name == name &&
        other.label == label &&
        other.createdAt == createdAt;
  }

  @override
  int get hashCode =>
      id.hashCode ^ name.hashCode ^ label.hashCode ^ createdAt.hashCode;
}
