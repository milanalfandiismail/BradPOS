import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bradpos/domain/entities/category.dart';
import 'package:bradpos/domain/repositories/category_repository.dart';
import 'package:bradpos/core/sync/sync_service.dart';
import 'package:bradpos/presentation/blocs/category_event.dart';
import 'package:bradpos/presentation/blocs/category_state.dart';

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
    final result = await repository.updateCategory(
      Category(
        id: event.id,
        ownerId: '',
        name: event.newName,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );
    await result.fold(
      (failure) async => emit(CategoryError(failure)),
      (_) async {
        emit(CategoryOperationSuccess("Kategori berhasil diperbarui"));
        add(LoadCategoriesEvent());
        syncService.syncAll();
      },
    );
  }

  Future<void> _onDeleteCategory(
    DeleteCategoryEvent event,
    Emitter<CategoryState> emit,
  ) async {
    final result = await repository.deleteCategory(event.id, event.name);
    await result.fold(
      (failure) async => emit(CategoryError(failure)),
      (_) async {
        emit(CategoryOperationSuccess("Kategori berhasil dihapus"));
        add(LoadCategoriesEvent());
        syncService.syncAll();
      },
    );
  }
}