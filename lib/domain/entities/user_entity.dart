import 'package:equatable/equatable.dart';

/// Representasi pengguna yang sedang login di sistem BradPOS.
/// Digunakan untuk Profile, Session, dan Role-Based Access Control (RBAC).
class UserEntity extends Equatable {
  final String id;
  final String email;
  final String? name;
  final String? shopName;

  /// Role pengguna:
  /// - 'owner': Pemilik toko, memiliki akses penuh ke semua fitur.
  /// - 'karyawan': Staf toko, akses terbatas (tidak bisa kelola karyawan lain).
  /// - 'guest': Mode offline tanpa akun.
  final String role;

  /// ID Owner yang menaungi karyawan ini (Hanya diisi jika role adalah 'karyawan').
  final String? ownerId;

  final String? remoteImage;
  final String? localImage;
  final String? address;
  final String? phone;

  const UserEntity({
    required this.id,
    required this.email,
    this.name,
    this.shopName,
    this.role = 'owner',
    this.ownerId,
    this.remoteImage,
    this.localImage,
    this.address,
    this.phone,
  });

  /// Helper untuk mengecek apakah user adalah Owner.
  bool get isOwner => role == 'owner';

  /// Helper untuk mengecek apakah user adalah Karyawan.
  bool get isKaryawan => role == 'karyawan';

  /// Helper untuk mengecek apakah user dalam mode Guest.
  bool get isGuest => role == 'guest';

  factory UserEntity.fromMap(Map<String, dynamic> map) {
    return UserEntity(
      id: map['id'],
      email: map['email'],
      name: map['name'] ?? map['full_name'],
      shopName: map['shop_name'],
      role: map['role'] ?? 'owner',
      ownerId: map['owner_id'],
      remoteImage: map['remote_image'],
      localImage: map['local_image'],
      address: map['address'],
      phone: map['phone'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'shop_name': shopName,
      'role': role,
      'owner_id': ownerId,
      'remote_image': remoteImage,
      'local_image': localImage,
      'address': address,
      'phone': phone,
    };
  }

  @override
  List<Object?> get props => [id, email, name, shopName, role, ownerId, remoteImage, localImage, address, phone];
}
