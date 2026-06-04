import 'package:equatable/equatable.dart';

class User extends Equatable {

  const User({
    required this.id,
    required this.email,
    required this.emailVerified, required this.createdAt, this.displayName,
    this.photoUrl,
    this.lastLoginAt,
  });
  final String id;
  final String email;
  final String? displayName;
  final String? photoUrl;
  final bool emailVerified;
  final DateTime createdAt;
  final DateTime? lastLoginAt;

  // Getter for compatibility with Firebase Auth's uid property
  String get uid => id;

  @override
  List<Object?> get props => [
        id,
        email,
        displayName,
        photoUrl,
        emailVerified,
        createdAt,
        lastLoginAt,
      ];

  User copyWith({
    String? id,
    String? email,
    String? displayName,
    String? photoUrl,
    bool? emailVerified,
    DateTime? createdAt,
    DateTime? lastLoginAt,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      emailVerified: emailVerified ?? this.emailVerified,
      createdAt: createdAt ?? this.createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
    );
  }
}
