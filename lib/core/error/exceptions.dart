class ServerException implements Exception {
  final String message;

  ServerException([this.message = 'Server error occurred']);

  @override
  String toString() => message;
}

class CacheException implements Exception {
  final String message;

  CacheException([this.message = 'Cache error occurred']);

  @override
  String toString() => message;
}

class NetworkException implements Exception {
  final String message;

  NetworkException([this.message = 'No internet connection']);

  @override
  String toString() => message;
}

class AuthenticationException implements Exception {
  final String message;

  AuthenticationException([this.message = 'Authentication failed']);

  @override
  String toString() => message;
}

class UploadException implements Exception {
  final String message;

  UploadException([this.message = 'Upload failed']);

  @override
  String toString() => message;
}

class ValidationException implements Exception {
  final String message;

  ValidationException([this.message = 'Validation error']);

  @override
  String toString() => message;
}
