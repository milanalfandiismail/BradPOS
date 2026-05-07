import 'package:equatable/equatable.dart';

abstract class CategoryEvent extends Equatable {
  const CategoryEvent();

  @override
  List<Object?> get props => [];
}

class LoadCategoriesEvent extends CategoryEvent {}

class AddCategoryEvent extends CategoryEvent {
  final String name;
  const AddCategoryEvent(this.name);

  @override
  List<Object?> get props => [name];
}

class UpdateCategoryEvent extends CategoryEvent {
  final String id;
  final String newName;
  const UpdateCategoryEvent(this.id, this.newName);

  @override
  List<Object?> get props => [id, newName];
}

class DeleteCategoryEvent extends CategoryEvent {
  final String id;
  final String name;
  const DeleteCategoryEvent(this.id, this.name);

  @override
  List<Object?> get props => [id, name];
}