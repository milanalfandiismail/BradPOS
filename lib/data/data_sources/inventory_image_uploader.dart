import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:path/path.dart' as path;

mixin InventoryImageUploader {
  SupabaseClient get supabase;

  Future<void> deleteOldImageByUrl(String? imageUrl) async {
    if (imageUrl == null ||
        imageUrl.isEmpty ||
        !imageUrl.contains('produk_images')) {
      return;
    }

    try {
      debugPrint("Storage: Analisis URL untuk dihapus -> $imageUrl");

      const bucketName = 'produk_images';
      final bucketPattern = '/$bucketName/';
      final bucketIndex = imageUrl.indexOf(bucketPattern);

      if (bucketIndex != -1) {
        String filePath = imageUrl.substring(
          bucketIndex + bucketPattern.length,
        );

        if (filePath.contains('?')) {
          filePath = filePath.split('?')[0];
        }

        filePath = Uri.decodeComponent(filePath);

        debugPrint("Storage: Mencoba hapus file dengan path -> '$filePath'");

        final List<FileObject> response = await supabase.storage
            .from(bucketName)
            .remove([filePath]);

        if (response.isEmpty) {
          debugPrint(
            "Storage Warning: Supabase melaporkan tidak ada file yang dihapus. Cek Path atau Policy!",
          );
        } else {
          debugPrint("Storage Success: File '$filePath' berhasil dihapus");
        }
      } else {
        debugPrint("Storage Error: Tidak menemukan pola /$bucketName/ di URL");
      }
    } catch (e) {
      debugPrint("Storage Exception saat hapus file lama: $e");
    }
  }

  Future<String?> uploadImage(
    String localPath,
    String ownerId,
    String productId,
    DateTime updatedAt,
  ) async {
    if (localPath.isEmpty) return null;

    try {
      debugPrint("Storage: Mencoba upload gambar dari $localPath");
      final file = File(localPath);

      if (!await file.exists()) {
        debugPrint("Storage Error: File tidak ditemukan di path: $localPath");
        return null;
      }

      final extension = path.extension(localPath).toLowerCase();
      String contentType = 'image/jpeg';
      if (extension == '.png') contentType = 'image/png';
      if (extension == '.gif') contentType = 'image/gif';
      if (extension == '.webp') contentType = 'image/webp';

      final timestamp = updatedAt.millisecondsSinceEpoch;
      final targetFileName = 'prod_${productId}_$timestamp$extension';
      final filePath = '$ownerId/$targetFileName';

      debugPrint(
        "Storage: Mengupload ke bucket 'produk_images' | Path: $filePath | Type: $contentType",
      );

      await supabase.storage
          .from('produk_images')
          .upload(
            filePath,
            file,
            fileOptions: FileOptions(upsert: true, contentType: contentType),
          );
      final String publicUrl = supabase.storage
          .from('produk_images')
          .getPublicUrl(filePath);
      debugPrint("Storage Success: URL Public didapat -> $publicUrl");
      return publicUrl;
    } on StorageException catch (e) {
      debugPrint(
        "Storage Exception (Supabase): ${e.message} | Status: ${e.statusCode}",
      );
      return null;
    } catch (e) {
      debugPrint("Storage Exception (General): $e");
      return null;
    }
  }
}
