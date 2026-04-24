import '../../domain/entities/karyawan.dart';

class KaryawanModel extends Karyawan {
  const KaryawanModel({
    required super.id,
    required super.ownerId,
    required super.name,
    required super.email,
    required super.password,
    required super.isActive,
    required super.createdAt,
  });

  factory KaryawanModel.fromJson(Map<String, dynamic> json) {
    return KaryawanModel(
      id: json['id'],
      ownerId: json['owner_id'] ?? '',
      name: json['full_name'] ?? '',
      email: json['email'] ?? '',
      password: json['password_hash'] ?? '',
      isActive: json['is_active'] ?? true,
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  factory KaryawanModel.fromMap(Map<String, dynamic> map) {
    return KaryawanModel(
      id: map['id'] ?? '',
      ownerId: map['owner_id'] ?? '',
      name: map['full_name'] ?? '',
      email: map['email'] ?? '',
      password: map['password_hash'] ?? '',
      isActive: map['is_active'] ?? true,
      createdAt: DateTime.parse(map['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'owner_id': ownerId,
      'full_name': name,
      'email': email,
      'password_hash': password,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory KaryawanModel.fromEntity(Karyawan karyawan) {
    return KaryawanModel(
      id: karyawan.id,
      ownerId: karyawan.ownerId,
      name: karyawan.name,
      email: karyawan.email,
      password: karyawan.password,
      isActive: karyawan.isActive,
      createdAt: karyawan.createdAt,
    );
  }
}
