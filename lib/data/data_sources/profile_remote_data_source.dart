import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;
import 'package:supabase_flutter/supabase_flutter.dart';

abstract class ProfileRemoteDataSource {
  Future<Map<String, dynamic>?> getProfile(
    String effectiveUserId, {
    String? localUpdatedAt,
  });
  Future<void> upsertProfile(Map<String, dynamic> data);
  Future<String?> uploadProfileImage(String localPath, String userId);
  Future<void> deleteProfileImage(String imageUrl);
}

class ProfileRemoteDataSourceImpl implements ProfileRemoteDataSource {
  final SupabaseClient supabase;

  ProfileRemoteDataSourceImpl({required this.supabase});

  @override
  Future<Map<String, dynamic>?> getProfile(
    String effectiveUserId, {
    String? localUpdatedAt,
  }) async {
    var query = supabase
        .from('profiles')
        .select('shop_name, shop_id, full_name, address, phone, remote_image, local_image, updated_at')
        .eq('id', effectiveUserId);

    if (localUpdatedAt != null) {
      query = query.gt('updated_at', localUpdatedAt);
    }

    try {
      final response = await query.maybeSingle();
      return response;
    } catch (e) {
      debugPrint("ProfileRemoteDataSource: getProfile failed: $e");
      return null;
    }
  }

  @override
  Future<void> upsertProfile(Map<String, dynamic> data) async {
    await supabase.from('profiles').upsert(data);
  }

  @override
  Future<String?> uploadProfileImage(String localPath, String userId) async {
    try {
      final file = File(localPath);
      if (!await file.exists()) return null;

      final extension = path.extension(localPath).toLowerCase();
      String contentType = 'image/jpeg';
      if (extension == '.png') contentType = 'image/png';
      if (extension == '.webp') contentType = 'image/webp';

      final fileName =
          'profile_${userId}_${DateTime.now().millisecondsSinceEpoch}$extension';
      final filePath = '$userId/$fileName';

      await supabase.storage
          .from('profile_images')
          .upload(
            filePath,
            file,
            fileOptions: FileOptions(upsert: true, contentType: contentType),
          );

      return supabase.storage.from('profile_images').getPublicUrl(filePath);
    } catch (e) {
      debugPrint("ProfileRemoteDataSource: Upload image gagal: $e");
      return null;
    }
  }

  @override
  Future<void> deleteProfileImage(String imageUrl) async {
    try {
      const bucket = 'profile_images';
      if (!imageUrl.contains(bucket)) return;

      final parts = imageUrl.split('$bucket/');
      if (parts.length < 2) return;

      String filePath = parts[1];
      if (filePath.contains('?')) filePath = filePath.split('?')[0];

      await supabase.storage.from(bucket).remove([
        Uri.decodeComponent(filePath),
      ]);
    } catch (e) {
      debugPrint("ProfileRemoteDataSource: Hapus image lama gagal: $e");
    }
  }
}
