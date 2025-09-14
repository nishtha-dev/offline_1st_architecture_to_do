import 'package:equatable/equatable.dart';

/// Base class for all failures
abstract class Failure extends Equatable {
  const Failure();

  @override
  List<Object> get props => [];
}

/// General failures
class ServerFailure extends Failure {}

class CacheFailure extends Failure {}

class NetworkFailure extends Failure {}

class SyncFailure extends Failure {
  final String message;

  const SyncFailure(this.message);

  @override
  List<Object> get props => [message];
}

class ConflictFailure extends Failure {
  final String message;

  const ConflictFailure(this.message);

  @override
  List<Object> get props => [message];
}

class ValidationFailure extends Failure {
  final String message;

  const ValidationFailure(this.message);

  @override
  List<Object> get props => [message];
}
