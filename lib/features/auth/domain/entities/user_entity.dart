import 'package:equatable/equatable.dart';

/// Representasi pengguna yang sedang login di sistem BradPOS.
/// Digunakan untuk Profile, Session, dan Role-Based Access Control (RBAC).
class UserEntity extends Equatable {
  final String id;
  final String email;
  final String? name;
  
  /// Role pengguna: 
  /// - 'owner': Pemilik toko, memiliki akses penuh ke semua fitur.
  /// - 'karyawan': Staf toko, akses terbatas (tidak bisa kelola karyawan lain).
  final String role; 
  
  /// ID Owner yang menaungi karyawan ini (Hanya diisi jika role adalah 'karyawan').
  final String? ownerId; 

  const UserEntity({
    required this.id,
    required this.email,
    this.name,
    this.role = 'owner',
    this.ownerId,
  });

  /// Helper untuk mengecek apakah user adalah Owner.
  bool get isOwner => role == 'owner';
  
  /// Helper untuk mengecek apakah user adalah Karyawan.
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
