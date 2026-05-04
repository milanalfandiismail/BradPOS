import 'package:equatable/equatable.dart';

enum KaryawanRole { owner, cashier, staff }

/// Entitas utama Karyawan.
/// Merepresentasikan data seorang karyawan/staf toko dalam sistem BradPOS.
class Karyawan extends Equatable {
  final String id;
  final String ownerId;
  final String name;
  final String email;
  final String password;
  final bool isActive;
  final DateTime createdAt;

  const Karyawan({
    required this.id,
    required this.ownerId,
    required this.name,
    required this.email,
    required this.password,
    required this.isActive,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'owner_id': ownerId,
      'full_name': name,
      'email': email,
      'is_active': isActive,
      // created_at is usually handled by DB, but we'll include it for updates
      'created_at': createdAt.toIso8601String(),
    };
  }

  Karyawan copyWith({
    String? id,
    String? ownerId,
    String? name,
    String? email,
    String? password,
    bool? isActive,
    DateTime? createdAt,
  }) {
    return Karyawan(
      id: id ?? this.id,
      ownerId: ownerId ?? this.ownerId,
      name: name ?? this.name,
      email: email ?? this.email,
      password: password ?? this.password,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
    id,
    ownerId,
    name,
    email,
    password,
    isActive,
    createdAt,
  ];
}
