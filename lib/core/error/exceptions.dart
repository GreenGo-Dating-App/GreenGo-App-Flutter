class ServerException implements Exception {

  ServerException([this.message = 'Server error occurred']);
  final String message;

  @override
  String toString() => message;
}

class CacheException implements Exception {

  CacheException([this.message = 'Cache error occurred']);
  final String message;

  @override
  String toString() => message;
}

class NetworkException implements Exception {

  NetworkException([this.message = 'No internet connection']);
  final String message;

  @override
  String toString() => message;
}

class AuthenticationException implements Exception {

  AuthenticationException([this.message = 'Authentication failed']);
  final String message;

  @override
  String toString() => message;
}

class UploadException implements Exception {

  UploadException([this.message = 'Upload failed']);
  final String message;

  @override
  String toString() => message;
}

class ValidationException implements Exception {

  ValidationException([this.message = 'Validation error']);
  final String message;

  @override
  String toString() => message;
}
