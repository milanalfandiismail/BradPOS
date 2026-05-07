import 'package:bradpos/domain/entities/karyawan.dart';

/// Model data Karyawan.
/// Bertugas mengubah data Map/JSON dari Supabase menjadi objek Karyawan,
/// dan sebaliknya (toJson) untuk dikirim ke database.
class KaryawanModel extends Karyawan {
  const KaryawanModel({
    required super.id,
    required super.ownerId,
    required super.name,
    required super.password,
    required super.isActive,
    required super.createdAt,
  });

  factory KaryawanModel.fromJson(Map<String, dynamic> json) {
    return KaryawanModel(
      id: json['id'],
      ownerId: json['owner_id'] ?? '',
      name: json['full_name'] ?? '',
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
      password: karyawan.password,
      isActive: karyawan.isActive,
      createdAt: karyawan.createdAt,
    );
  }
}
