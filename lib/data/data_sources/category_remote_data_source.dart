import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:bradpos/data/models/category_model.dart';

abstract class CategoryRemoteDataSource {
  Future<List<CategoryModel>> getCategories(String userId, {String? lastSync});
  Future<void> pushCreatedCategory(Map<String, dynamic> categoryMap);
  Future<void> pushUpdatedCategory(Map<String, dynamic> categoryMap);
  Future<void> pushDeletedCategory(String id, String userId);
  Future<void> updateProductsCategoryToNull(String categoryId, String userId);
}

class CategoryRemoteDataSourceImpl implements CategoryRemoteDataSource {
  final SupabaseClient supabase;

  CategoryRemoteDataSourceImpl({required this.supabase});

  @override
  Future<List<CategoryModel>> getCategories(
    String userId, {
    String? lastSync,
  }) async {
    dynamic query = supabase
        .from("categories")
        .select("*")
        .eq("owner_id", userId);

    if (lastSync != null && lastSync.isNotEmpty) {
      query = query.gt('updated_at', lastSync);
    }

    final response = await query.order('name', ascending: true);
    final data = response as List<dynamic>;
    return data
        .map((row) => CategoryModel.fromMap(row as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<void> pushCreatedCategory(Map<String, dynamic> categoryMap) async {
    final payload = Map<String, dynamic>.from(categoryMap);
    payload.remove('sync_status');
    payload.remove('updated_at');

    await supabase.from("categories").upsert(payload);
  }

  @override
  Future<void> pushUpdatedCategory(Map<String, dynamic> categoryMap) async {
    final payload = Map<String, dynamic>.from(categoryMap);
    payload.remove('sync_status');
    payload.remove('updated_at');

    await supabase.from("categories").upsert(payload);
  }

  @override
  Future<void> pushDeletedCategory(String id, String userId) async {
    await supabase
        .from("categories")
        .delete()
        .eq("id", id)
        .eq("owner_id", userId);
  }

  @override
  Future<void> updateProductsCategoryToNull(
    String categoryId,
    String userId,
  ) async {
    await supabase
        .from("produk")
        .update({'category_id': null, 'category': 'Tanpa Kategori'})
        .eq('category_id', categoryId)
        .eq('owner_id', userId);
  }
}
