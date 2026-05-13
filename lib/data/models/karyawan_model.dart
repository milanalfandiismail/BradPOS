import 'package:bradpos/domain/entities/karyawan.dart';

class KaryawanModel extends Karyawan {
  const KaryawanModel({
    required super.id,
    required super.ownerId,
    required super.name,
    required super.password,
    required super.isActive,
    required super.createdAt,
    super.remoteImage,
    super.localImage,
  });

  factory KaryawanModel.fromMap(Map<String, dynamic> map) {
    return KaryawanModel(
      id: map['id'] ?? '',
      ownerId: map['owner_id'] ?? '',
      name: map['full_name'] ?? map['name'] ?? '',
      password: map['password_hash'] ?? map['password'] ?? '',
      isActive: map['is_active'] == true || map['is_active'] == 1,
      createdAt: DateTime.parse(map['created_at']),
      remoteImage: map['remote_image'],
      localImage: map['local_image'],
    );
  }

  @override
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'owner_id': ownerId,
      'full_name': name,
      'password_hash': password, // Menggunakan password_hash sesuai tabel SQLite
      'is_active': isActive ? 1 : 0,
      'remote_image': remoteImage,
      'local_image': localImage,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory KaryawanModel.fromEntity(Karyawan entity) {
    return KaryawanModel(
      id: entity.id,
      ownerId: entity.ownerId,
      name: entity.name,
      password: entity.password,
      isActive: entity.isActive,
      createdAt: entity.createdAt,
      remoteImage: entity.remoteImage,
      localImage: entity.localImage,
    );
  }

  Karyawan toEntity() {
    return Karyawan(
      id: id,
      ownerId: ownerId,
      name: name,
      password: password,
      isActive: isActive,
      createdAt: createdAt,
      remoteImage: remoteImage,
      localImage: localImage,
    );
  }
}
