import 'package:flutter/foundation.dart';
import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:path/path.dart' as path;
import 'package:bradpos/data/models/inventory_item_model.dart';

abstract class InventoryRemoteDataSource {
  Future<List<InventoryItemModel>> getInventory(
    String userId, {
    int? limit,
    int? offset,
    String? searchQuery,
    String? category,
    String? stockStatus,
    String? lastSync,
  });
  Future<int> getInventoryCount(
    String userId, {
    String? searchQuery,
    String? category,
    String? stockStatus,
  });

  // Sync methods (push to server) - return new image_url if uploaded
  Future<String?> pushCreatedItem(Map<String, dynamic> itemMap);
  Future<String?> pushUpdatedItem(Map<String, dynamic> itemMap);
  Future<void> pushDeletedItem(String id, String userId);
}

class InventoryRemoteDataSourceImpl implements InventoryRemoteDataSource {
  final SupabaseClient supabase;

  InventoryRemoteDataSourceImpl({required this.supabase});

  @override
  Future<List<InventoryItemModel>> getInventory(
    String userId, {
    int? limit,
    int? offset,
    String? searchQuery,
    String? category,
    String? stockStatus,
    String? lastSync,
  }) async {
    dynamic query = supabase.from("produk").select("*").eq("owner_id", userId);

    if (lastSync != null && lastSync.isNotEmpty) {
      query = query.gt('updated_at', lastSync);
    }

    // Apply Filters
    if (searchQuery != null && searchQuery.isNotEmpty) {
      query = query.ilike('name', '%$searchQuery%');
    }
    if (category != null && category != 'All') {
      query = query.eq('category', category);
    }
    if (stockStatus != null && stockStatus != 'All') {
      if (stockStatus == 'Low Stock') {
        query = query.gt('stock', 0).lte('stock', 10);
      } else if (stockStatus == 'Out of Stock') {
        query = query.lte('stock', 0);
      }
    }

    query = query.order('created_at', ascending: false);

    if (limit != null && offset != null) {
      query = query.range(offset, offset + limit - 1);
    } else if (limit != null) {
      query = query.limit(limit);
    }

    final List<dynamic> response = await query;
    return response
        .map((row) => InventoryItemModel.fromMap(row as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<int> getInventoryCount(
    String userId, {
    String? searchQuery,
    String? category,
    String? stockStatus,
  }) async {
    dynamic countQuery = supabase
        .from('produk')
        .select('id')
        .eq('owner_id', userId);

    if (searchQuery != null && searchQuery.isNotEmpty) {
      countQuery = countQuery.ilike('name', '%$searchQuery%');
    }
    if (category != null && category != 'All') {
      countQuery = countQuery.eq('category', category);
    }
    if (stockStatus != null && stockStatus != 'All') {
      if (stockStatus == 'Low Stock') {
        countQuery = countQuery.gt('stock', 0).lte('stock', 10);
      } else if (stockStatus == 'Out of Stock') {
        countQuery = countQuery.lte('stock', 0);
      }
    }

    final response = await countQuery;
    // Cara paling aman di berbagai versi SDK: Ambil list ID dan hitung length-nya
    if (response is List) {
      return response.length;
    }
    return 0;
  }

  Future<void> _deleteOldImageByUrl(String? imageUrl) async {
    if (imageUrl == null ||
        imageUrl.isEmpty ||
        !imageUrl.contains('produk_images')) {
      return;
    }

    try {
      debugPrint("Storage: Analisis URL untuk dihapus -> $imageUrl");

      // Cara yang lebih mantap: Cari posisi nama bucket
      const bucketName = 'produk_images';
      final bucketPattern = '/$bucketName/';
      final bucketIndex = imageUrl.indexOf(bucketPattern);

      if (bucketIndex != -1) {
        // Ambil semua teks setelah '/produk_images/'
        // Contoh: https://.../produk_images/userId/file.jpg -> userId/file.jpg
        String filePath = imageUrl.substring(
          bucketIndex + bucketPattern.length,
        );

        // Buang query parameter jika ada (seperti ?v=123)
        if (filePath.contains('?')) {
          filePath = filePath.split('?')[0];
        }

        // Decode URL encoding (misal %20 jadi spasi)
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

  Future<String?> _uploadImage(
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

      // Gunakan timestamp dari updatedAt (STABIL) bukan DateTime.now() (BERUBAH-UBAH)
      // Ini memastikan jika ada pemanggilan ganda untuk data yang sama, nama filenya tetap sama.
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

  @override
  Future<String?> pushCreatedItem(Map<String, dynamic> itemMap) async {
    final payload = Map<String, dynamic>.from(itemMap);
    String? finalRemoteUrl;

    // Upload gambar jika path-nya lokal
    final String? imageUrl = payload['image_url'];
    final String id = payload['id'];

    if (imageUrl != null &&
        imageUrl.isNotEmpty &&
        !imageUrl.startsWith('http')) {
      finalRemoteUrl = await _uploadImage(
        imageUrl,
        payload['owner_id'],
        id,
        DateTime.parse(itemMap['updated_at']),
      );
      if (finalRemoteUrl != null) {
        payload['image_url'] = finalRemoteUrl;
      } else {
        debugPrint(
          "RemoteDataSource: Upload image gagal, tetap sync produk tanpa image",
        );
        payload['image_url'] = null;
      }
    }

    payload.remove('sync_status');
    payload.remove('updated_at');
    payload.remove('price'); // Legacy SQLite column
    payload['is_active'] = payload['is_active'] == 1;

    // Proteksi: Pastikan category_id valid UUID atau null (jangan String kosong)
    if (payload['category_id'] != null &&
        (payload['category_id'] as String).isEmpty) {
      payload['category_id'] = null;
    }

    try {
      debugPrint(
        "RemoteDataSource: Upserting produk ${payload['id']} to Supabase...",
      );
      await supabase.from("produk").upsert(payload);
      debugPrint("RemoteDataSource: Upsert produk success!");
    } catch (e) {
      debugPrint("RemoteDataSource ERROR (upsert produk): $e");
      rethrow;
    }
    return finalRemoteUrl;
  }

  @override
  Future<String?> pushUpdatedItem(Map<String, dynamic> itemMap) async {
    final payload = Map<String, dynamic>.from(itemMap);
    String? finalRemoteUrl;

    // Upload gambar jika path-nya lokal
    final String? imageUrl = payload['image_url'];
    final String id = payload['id'];

    if (imageUrl != null &&
        imageUrl.isNotEmpty &&
        !imageUrl.startsWith('http')) {
      // 1. Ambil data lama untuk menghapus fotonya dari storage
      final oldData = await supabase
          .from('produk')
          .select('image_url')
          .eq('id', id)
          .maybeSingle();
      final oldImageUrl = oldData?['image_url'] as String?;

      // 2. Hapus file lama jika ada
      await _deleteOldImageByUrl(oldImageUrl);

      // 3. Upload file baru dengan nama unik (berdasarkan jam update barang)
      finalRemoteUrl = await _uploadImage(
        imageUrl,
        payload['owner_id'],
        id,
        DateTime.parse(itemMap['updated_at']),
      );
      if (finalRemoteUrl != null) {
        payload['image_url'] = finalRemoteUrl;
      } else {
        debugPrint(
          "RemoteDataSource: Upload image gagal, tetap sync produk tanpa image",
        );
        payload['image_url'] = null;
      }
    }

    payload.remove('sync_status');
    payload.remove('updated_at');
    payload.remove('price'); // Legacy SQLite column
    payload['is_active'] = payload['is_active'] == 1;

    // Proteksi: Pastikan category_id valid UUID atau null
    if (payload['category_id'] != null &&
        (payload['category_id'] as String).isEmpty) {
      payload['category_id'] = null;
    }

    try {
      debugPrint(
        "RemoteDataSource: Updating (upsert) produk $id to Supabase...",
      );
      await supabase.from("produk").upsert(payload);
      debugPrint("RemoteDataSource: Update produk success!");
    } catch (e) {
      debugPrint("RemoteDataSource ERROR (update produk): $e");
      rethrow;
    }

    return finalRemoteUrl;
  }

  @override
  Future<void> pushDeletedItem(String id, String userId) async {
    try {
      // 1. Ambil data lama untuk hapus gambarnya
      final oldData = await supabase
          .from('produk')
          .select('image_url')
          .eq('id', id)
          .maybeSingle();
      final oldImageUrl = oldData?['image_url'] as String?;

      // 2. Hapus gambar dari storage
      await _deleteOldImageByUrl(oldImageUrl);
    } catch (e) {
      debugPrint("PushDeletedItem Warning (Storage): $e");
    }

    // 3. Hapus data dari tabel
    debugPrint(
      "PushDeletedItem: Deleting produk id=$id where owner_id=$userId",
    );

    // Coba hapus dengan owner_id
    final result = await supabase
        .from("produk")
        .delete()
        .eq("id", id)
        .eq("owner_id", userId)
        .select();

    // Kalau tidak ada yang terhapus, coba tanpa owner_id filter (atau log saja)
    if (result.isEmpty) {
      debugPrint(
        "PushDeletedItem: Tidak ada data yang terhapus dengan filter owner_id=$userId",
      );
    } else {
      debugPrint("PushDeletedItem: Berhasil hapus ${result.length} baris");
    }
  }

}
