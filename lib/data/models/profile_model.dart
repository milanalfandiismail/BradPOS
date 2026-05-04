class ProfileModel {
  final String id;
  final String shopName;
  final String? fullName;
  final String? remoteImage;
  final String? localImage;
  final String? updatedAt;

  const ProfileModel({
    required this.id,
    required this.shopName,
    this.fullName,
    this.remoteImage,
    this.localImage,
    this.updatedAt,
  });

  factory ProfileModel.fromMap(Map<String, dynamic> map) {
    return ProfileModel(
      id: map['id'] as String,
      shopName: map['shop_name'] as String? ?? '',
      fullName: map['full_name'] as String?,
      remoteImage: map['remote_image'] as String?,
      localImage: map['local_image'] as String?,
      updatedAt: map['updated_at'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'shop_name': shopName,
      if (fullName != null) 'full_name': fullName,
      if (remoteImage != null) 'remote_image': remoteImage,
      if (localImage != null) 'local_image': localImage,
      if (updatedAt != null) 'updated_at': updatedAt,
    };
  }
}
