import '../../domain/entities/todo.dart';

class TodoModel extends Todo {
  const TodoModel({
    required super.id,
    required super.title,
    super.description,
    required super.isCompleted,
    required super.createdAt,
    required super.updatedAt,
    required super.userId,
    required super.version,
    super.deleted = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'is_completed': isCompleted,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
        'user_id': userId,
        'version': version,
        'deleted': deleted,
      };

  factory TodoModel.fromJson(Map<String, dynamic> json) => TodoModel(
        id: json['id'] as String,
        title: json['title'] as String,
        description: json['description'] as String?,
        isCompleted: json['is_completed'] as bool,
        createdAt: DateTime.parse(json['created_at'] as String),
        updatedAt: DateTime.parse(json['updated_at'] as String),
        userId: json['user_id'] as String,
        version: json['version'] as int,
        deleted: json['deleted'] as bool? ?? false,
      );

  factory TodoModel.fromMap(Map<String, dynamic> map) {
    return TodoModel(
      id: map['id'] as String,
      title: map['title'] as String,
      description: map['description'] as String?,
      isCompleted: (map['is_completed'] as int) == 1,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
      userId: map['user_id'] as String,
      version: map['version'] as int,
      deleted: (map['deleted'] as int) == 1,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'is_completed': isCompleted ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'user_id': userId,
      'version': version,
      'deleted': deleted ? 1 : 0,
    };
  }

  factory TodoModel.fromEntity(Todo todo) {
    return TodoModel(
      id: todo.id,
      title: todo.title,
      description: todo.description,
      isCompleted: todo.isCompleted,
      createdAt: todo.createdAt,
      updatedAt: todo.updatedAt,
      userId: todo.userId,
      version: todo.version,
      deleted: todo.deleted,
    );
  }

  TodoModel copyWith({
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
    return TodoModel(
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
}
