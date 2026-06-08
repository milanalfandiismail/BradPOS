import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:path/path.dart' as path;

abstract class KaryawanRemoteDataSource {
  Future<List<Map<String, dynamic>>> getKaryawans(String ownerId);
  Future<Map<String, dynamic>> createKaryawan(Map<String, dynamic> data);
  Future<void> updateKaryawan(String id, Map<String, dynamic> data);
  Future<void> deleteKaryawan(String id);
  Future<String?> uploadImage(String localPath, String id);
  Future<void> deleteImage(String imageUrl);
}

class KaryawanRemoteDataSourceImpl implements KaryawanRemoteDataSource {
  final SupabaseClient supabase;

  KaryawanRemoteDataSourceImpl({required this.supabase});

  @override
  Future<List<Map<String, dynamic>>> getKaryawans(String ownerId) async {
    final response = await supabase
        .from('karyawan')
        .select('*')
        .eq('owner_id', ownerId)
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }

  @override
  Future<Map<String, dynamic>> createKaryawan(Map<String, dynamic> data) async {
    final response = await supabase
        .from('karyawan')
        .insert(data)
        .select()
        .single();
    return response;
  }

  @override
  Future<void> updateKaryawan(String id, Map<String, dynamic> data) async {
    await supabase.from('karyawan').update(data).eq('id', id);
  }

  @override
  Future<void> deleteKaryawan(String id) async {
    await supabase.from('karyawan').delete().eq('id', id);
  }

  @override
  Future<String?> uploadImage(String localPath, String id) async {
    try {
      final file = File(localPath);
      if (!await file.exists()) return null;

      final extension = path.extension(localPath).toLowerCase();
      String contentType = 'image/jpeg';
      if (extension == '.png') contentType = 'image/png';
      if (extension == '.webp') contentType = 'image/webp';

      final fileName = 'staff_${id}_${DateTime.now().millisecondsSinceEpoch}$extension';
      final filePath = 'staff/$fileName';

      await supabase.storage.from('profile_images').upload(
            filePath,
            file,
            fileOptions: FileOptions(upsert: true, contentType: contentType),
          );

      return supabase.storage.from('profile_images').getPublicUrl(filePath);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<void> deleteImage(String imageUrl) async {
    try {
      const bucket = 'profile_images';
      if (!imageUrl.contains(bucket)) return;

      final parts = imageUrl.split('$bucket/');
      if (parts.length < 2) return;

      String filePath = parts[1];
      if (filePath.contains('?')) filePath = filePath.split('?')[0];

      await supabase.storage.from(bucket).remove([Uri.decodeComponent(filePath)]);
    } catch (_) {}
  }
}
