import 'package:equatable/equatable.dart';

/// Todo entity representing the core business object
class Todo extends Equatable {
  final String id;
  final String title;
  final String? description;
  final bool isCompleted;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String userId;
  final int version;
  final bool deleted;

  const Todo({
    required this.id,
    required this.title,
    this.description,
    required this.isCompleted,
    required this.createdAt,
    required this.updatedAt,
    required this.userId,
    required this.version,
    this.deleted = false,
  });

  Todo copyWith({
    String? id,
    String? title,
    String? description,
    bool? isCompleted,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? userId,
    int? version,
    bool? deleted,
  }) {
    return Todo(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      userId: userId ?? this.userId,
      version: version ?? this.version,
      deleted: deleted ?? this.deleted,
    );
  }

  @override
  List<Object?> get props => [
        id,
        title,
        description,
        isCompleted,
        createdAt,
        updatedAt,
        userId,
        version,
        deleted,
      ];
}
