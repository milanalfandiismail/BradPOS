import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:bradpos/data/models/inventory_item_model.dart';
import 'package:bradpos/data/data_sources/inventory_image_uploader.dart';

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

class InventoryRemoteDataSourceImpl
    with InventoryImageUploader
    implements InventoryRemoteDataSource {
  @override
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

  // ── Private helper: cleans up payload + uploads local image ──
  Future<({Map<String, dynamic> payload, String? remoteUrl})> _preparePayload(
    Map<String, dynamic> itemMap, {
    String? oldImageUrl, // Pass existing remote URL for deletion before upload
  }) async {
    final payload = Map<String, dynamic>.from(itemMap);
    String? remoteUrl;

    final String? imageUrl = payload['image_url'];
    final String id = payload['id'];

    if (imageUrl != null &&
        imageUrl.isNotEmpty &&
        !imageUrl.startsWith('http')) {
      if (oldImageUrl != null) await deleteOldImageByUrl(oldImageUrl);
      remoteUrl = await uploadImage(
        imageUrl,
        payload['owner_id'],
        id,
        DateTime.parse(itemMap['updated_at']),
      );
      payload['image_url'] =
          remoteUrl; // null if upload failed → server stores null
    }

    payload.remove('sync_status');
    payload.remove('price'); // Legacy SQLite column
    payload['is_active'] = payload['is_active'] == 1;

    // Guard: empty string category_id → null (avoid FK violation)
    final catId = payload['category_id'];
    if (catId != null && (catId as String).isEmpty) {
      payload['category_id'] = null;
    }

    return (payload: payload, remoteUrl: remoteUrl);
  }

  @override
  Future<String?> pushCreatedItem(Map<String, dynamic> itemMap) async {
    final (:payload, :remoteUrl) = await _preparePayload(itemMap);
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
    return remoteUrl;
  }

  @override
  Future<String?> pushUpdatedItem(Map<String, dynamic> itemMap) async {
    // Fetch current remote image to delete before replacing
    final id = itemMap['id'] as String;
    String? oldImageUrl;
    final imageUrl = itemMap['image_url'] as String?;
    if (imageUrl != null &&
        imageUrl.isNotEmpty &&
        !imageUrl.startsWith('http')) {
      final oldData = await supabase
          .from('produk')
          .select('image_url')
          .eq('id', id)
          .maybeSingle();
      oldImageUrl = oldData?['image_url'] as String?;
    }

    final (:payload, :remoteUrl) = await _preparePayload(
      itemMap,
      oldImageUrl: oldImageUrl,
    );
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
    return remoteUrl;
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
      await deleteOldImageByUrl(oldImageUrl);
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
