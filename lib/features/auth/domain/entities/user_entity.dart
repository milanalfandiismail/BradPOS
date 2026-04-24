import 'package:equatable/equatable.dart';

class UserEntity extends Equatable {
  final String id;
  final String email;
  final String? name;
  final String role; // 'owner' atau 'Karyawan'
  final String? ownerId; // ID owner jika role adalah Karyawan

  const UserEntity({
    required this.id,
    required this.email,
    this.name,
    this.role = 'owner',
    this.ownerId,
  });

  bool get isOwner => role == 'owner';
  bool get isKaryawan => role == 'karyawan';

  factory UserEntity.fromMap(Map<String, dynamic> map) {
    return UserEntity(
      id: map['id'],
      email: map['email'],
      name: map['name'],
      role: map['role'] ?? 'owner',
      ownerId: map['owner_id'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'role': role,
      'owner_id': ownerId,
    };
  }

  @override
  List<Object?> get props => [id, email, name, role, ownerId];
}
