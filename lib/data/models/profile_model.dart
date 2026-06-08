class ProfileModel {
  final String id;
  final String? email;
  final String? shopName;
  final String? shopAddress;
  final String? shopPhone;
  final String? shopDescription;
  final String? logoUrl;
  final DateTime? updatedAt;

  ProfileModel({
    required this.id,
    this.email,
    this.shopName,
    this.shopAddress,
    this.shopPhone,
    this.shopDescription,
    this.logoUrl,
    this.updatedAt,
  });

  factory ProfileModel.fromMap(Map<String, dynamic> map) {
    return ProfileModel(
      id: map['id'],
      email: map['email'],
      shopName: map['shop_name'],
      shopAddress: map['shop_address'],
      shopPhone: map['shop_phone'],
      shopDescription: map['shop_description'],
      logoUrl: map['logo_url'],
      updatedAt: map['updated_at'] != null ? DateTime.parse(map['updated_at']) : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'shop_name': shopName,
      'shop_address': shopAddress,
      'shop_phone': shopPhone,
      'shop_description': shopDescription,
      'logo_url': logoUrl,
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}
