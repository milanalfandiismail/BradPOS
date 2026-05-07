import 'package:flutter/foundation.dart' hide Category;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bradpos/domain/entities/category.dart';
import 'package:bradpos/domain/repositories/category_repository.dart';
import 'package:bradpos/core/sync/sync_service.dart';
import 'category_event.dart';
import 'category_state.dart';

class CategoryBloc extends Bloc<CategoryEvent, CategoryState> {
  final CategoryRepository repository;
  final SyncService syncService;

  CategoryBloc({required this.repository, required this.syncService}) : super(CategoryInitial()) {
    on<LoadCategoriesEvent>(_onLoadCategories);
    on<AddCategoryEvent>(_onAddCategory);
    on<UpdateCategoryEvent>(_onUpdateCategory);
    on<DeleteCategoryEvent>(_onDeleteCategory);
  }

  Future<void> _onLoadCategories(
    LoadCategoriesEvent event,
    Emitter<CategoryState> emit,
  ) async {
    emit(CategoryLoading());
    final result = await repository.getCategories();
    result.fold(
      (failure) => emit(CategoryError(failure)),
      (categories) => emit(CategoryLoaded(categories)),
    );
  }

  Future<void> _onAddCategory(
    AddCategoryEvent event,
    Emitter<CategoryState> emit,
  ) async {
    final result = await repository.addCategory(
      Category(
        id: '',
        ownerId: '',
        name: event.name,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );
    result.fold(
      (failure) => emit(CategoryError(failure)),
      (_) {
        emit(CategoryOperationSuccess("Kategori berhasil ditambahkan"));
        add(LoadCategoriesEvent());
        syncService.syncAll();
      },
    );
  }

  Future<void> _onUpdateCategory(
    UpdateCategoryEvent event,
    Emitter<CategoryState> emit,
  ) async {
    debugPrint("DEBUG _onUpdateCategory: START, id=${event.id}, name=${event.newName}");
    try {
      final result = await repository.updateCategory(
        Category(
          id: event.id,
          ownerId: '',
          name: event.newName,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );
      debugPrint("DEBUG update result: $result");
      await result.fold(
        (failure) async {
          debugPrint("DEBUG update failure: $failure");
          emit(CategoryError(failure));
        },
        (_) async {
          emit(CategoryOperationSuccess("Kategori berhasil diperbarui"));
          syncService.syncAll();
          final loadResult = await repository.getCategories();
          debugPrint("DEBUG loadResult: ${loadResult.fold((l)=>l, (r)=>r.length)}");
          loadResult.fold(
            (failure) => emit(CategoryError(failure)),
            (categories) => emit(CategoryLoaded(categories)),
          );
        },
      );
    } catch (e) {
      debugPrint("DEBUG update exception: $e");
      emit(CategoryError("Error: $e"));
    }
  }

  Future<void> _onDeleteCategory(
    DeleteCategoryEvent event,
    Emitter<CategoryState> emit,
  ) async {
    debugPrint("DEBUG _onDeleteCategory: START, id=${event.id}, name=${event.name}");
    final result = await repository.deleteCategory(event.id, event.name);
    debugPrint("DEBUG delete result: $result");
    await result.fold(
      (failure) async {
        debugPrint("DEBUG delete failure: $failure");
        emit(CategoryError(failure));
      },
      (_) async {
        debugPrint("DEBUG emit success");
        emit(CategoryOperationSuccess("Kategori berhasil dihapus"));
        syncService.syncAll();
        final loadResult = await repository.getCategories();
        debugPrint("DEBUG loadResult categories: ${loadResult.getOrElse(() => []).length}");
        emit(CategoryLoaded(loadResult.getOrElse(() => [])));
      },
    );
    debugPrint("DEBUG _onDeleteCategory: DONE");
  }
}