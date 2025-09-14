/// Custom exceptions for the application
class ServerException implements Exception {}

class CacheException implements Exception {}

class NetworkException implements Exception {}

class ConflictException implements Exception {
  final String message;
  ConflictException(this.message);
}

class ValidationException implements Exception {
  final String message;
  ValidationException(this.message);
}
