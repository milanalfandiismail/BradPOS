import 'package:dartz/dartz.dart';
import '../entities/category.dart';

abstract class CategoryRepository {
  Future<Either<String, List<Category>>> getCategories();
  Future<Either<String, Category>> addCategory(Category category);
  Future<Either<String, Category>> updateCategory(Category category);
  Future<Either<String, void>> deleteCategory(String id, String name);
}
