import 'package:equatable/equatable.dart';

enum KaryawanRole { owner, cashier, staff }

/// Entitas utama Karyawan.
/// Merepresentasikan data seorang karyawan/staf toko dalam sistem BradPOS.
class Karyawan extends Equatable {
  final String id;
  final String ownerId;
  final String name;
  final String password;
  final bool isActive;
  final DateTime createdAt;

  final String? remoteImage;
  final String? localImage;

  const Karyawan({
    required this.id,
    required this.ownerId,
    required this.name,
    required this.password,
    required this.isActive,
    required this.createdAt,
    this.remoteImage,
    this.localImage,
  });

  Map<String, dynamic> toMap() {
    return {
      'owner_id': ownerId,
      'full_name': name,
      'is_active': isActive,
      'remote_image': remoteImage,
      'local_image': localImage,
      'created_at': createdAt.toIso8601String(),
    };
  }

  Karyawan copyWith({
    String? id,
    String? ownerId,
    String? name,
    String? password,
    bool? isActive,
    DateTime? createdAt,
    String? remoteImage,
    String? localImage,
  }) {
    return Karyawan(
      id: id ?? this.id,
      ownerId: ownerId ?? this.ownerId,
      name: name ?? this.name,
      password: password ?? this.password,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      remoteImage: remoteImage ?? this.remoteImage,
      localImage: localImage ?? this.localImage,
    );
  }

  @override
  List<Object?> get props => [
    id,
    ownerId,
    name,
    password,
    isActive,
    createdAt,
    remoteImage,
    localImage,
  ];
}
