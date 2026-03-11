import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class UserProfile {
  final String id;
  final String email;
  final String? displayName;
  final String role;
  final DateTime createdAt;
  final DateTime? lastLoginAt;

  UserProfile({
    required this.id,
    required this.email,
    this.displayName,
    this.role = 'user',
    required this.createdAt,
    this.lastLoginAt,
  });

  factory UserProfile.fromFirestore(String id, Map<String, dynamic> data) {
    return UserProfile(
      id: id,
      email: data['email'] as String? ?? '',
      displayName: data['displayName'] as String?,
      role: (data['role'] ?? 'user') as String,
      createdAt:
          DateTime.tryParse((data['createdAt'] ?? '') as String) ??
          DateTime.now(),
      lastLoginAt: DateTime.tryParse((data['lastLoginAt'] ?? '') as String),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'displayName': displayName,
      'role': role,
      'createdAt': createdAt.toIso8601String(),
      'lastLoginAt': lastLoginAt?.toIso8601String(),
    };
  }
}

class UserService {
  static final UserService instance = UserService._();

  final CollectionReference _usersCollection = FirebaseFirestore.instance
      .collection('users');

  UserService._();

  Future<UserProfile?> getUserProfile(String userId) async {
    try {
      final doc = await _usersCollection.doc(userId).get();
      if (!doc.exists) return null;
      return UserProfile.fromFirestore(
        doc.id,
        doc.data() as Map<String, dynamic>,
      );
    } catch (e) {
      debugPrint('Error loading user profile: $e');
      return null;
    }
  }

  Future<void> upsertUserProfile({
    required String userId,
    required String email,
    String? displayName,
    String role = 'user',
  }) async {
    try {
      final existing = await getUserProfile(userId);
      if (existing != null) {
        await updateLastLogin(userId);
        return;
      }

      await _usersCollection.doc(userId).set({
        'email': email,
        'displayName': displayName ?? email.split('@').first,
        'role': role,
        'createdAt': DateTime.now().toIso8601String(),
        'lastLoginAt': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('Error creating user profile: $e');
    }
  }

  Future<void> updateUserProfile({
    required String userId,
    String? displayName,
    String? role,
  }) async {
    try {
      final updates = <String, dynamic>{};
      if (displayName != null) updates['displayName'] = displayName;
      if (role != null) updates['role'] = role;
      if (updates.isNotEmpty) {
        await _usersCollection.doc(userId).update(updates);
      }
    } catch (e) {
      debugPrint('Error updating user profile: $e');
    }
  }

  Future<void> updateLastLogin(String userId) async {
    try {
      await _usersCollection.doc(userId).update({
        'lastLoginAt': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('Error updating last login: $e');
    }
  }
}
