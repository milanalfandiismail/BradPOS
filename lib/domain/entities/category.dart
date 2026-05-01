import 'package:equatable/equatable.dart';

class Category extends Equatable {
  final String id;
  final String ownerId;
  final String name;
  final String? description;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Category({
    required this.id,
    required this.ownerId,
    required this.name,
    this.description,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'owner_id': ownerId,
      'name': name,
      'description': description,
    };
  }

  Category copyWith({
    String? id,
    String? ownerId,
    String? name,
    String? description,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Category(
      id: id ?? this.id,
      ownerId: ownerId ?? this.ownerId,
      name: name ?? this.name,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [id, ownerId, name, description, createdAt, updatedAt];
}
