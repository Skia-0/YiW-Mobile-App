import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:yiw_field_report/models/user.dart' as app_user;
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';

/// Raised when a profile change is rejected, with a message safe to show the
/// user directly.
class ProfileUpdateException implements Exception {
  final String message;
  ProfileUpdateException(this.message);
  @override
  String toString() => message;
}

class AuthService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  User? _user;
  app_user.User? _appUser;
  bool _isLoading = false;

  User? get user => _user;
  app_user.User? get appUser => _appUser;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _user != null;

  AuthService() {
    _auth.authStateChanges().listen(_onAuthStateChanged);
  }

  void _onAuthStateChanged(User? user) {
    _user = user;
    if (user != null) {
      _loadUserData(user.uid);
    } else {
      _appUser = null;
    }
    notifyListeners();
  }

  Future<void> _loadUserData(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        _appUser = app_user.User.fromJson(doc.data()!);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading user data: $e');
    }
  }

  Future<bool> isAuthenticatedAsync() async {
    return _auth.currentUser != null;
  }

  Future<UserCredential?> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      _isLoading = true;
      notifyListeners();
      
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      _user = credential.user;
      await _loadUserData(_user!.uid);
      
      _isLoading = false;
      notifyListeners();
      
      return credential;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<UserCredential?> createUserWithEmailAndPassword({
    required String email,
    required String password,
    required String fullName,
    required String phoneNumber,
    required String zone,
    required String role,
  }) async {
    try {
      _isLoading = true;
      notifyListeners();
      
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      _user = credential.user;
      
      // Create user document in Firestore
      final appUser = app_user.User(
        id: _user!.uid,
        email: email,
        fullName: fullName,
        phoneNumber: phoneNumber,
        zone: zone,
        role: role,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      await _firestore.collection('users').doc(_user!.uid).set(appUser.toJson());
      _appUser = appUser;
      
      _isLoading = false;
      notifyListeners();
      
      return credential;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> signOut() async {
    try {
      await _auth.signOut();
      _user = null;
      _appUser = null;
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      rethrow;
    }
  }

  /// Updates the signed-in user's profile.
  ///
  /// Everything except the display name can be changed freely. Changing
  /// [fullName] is limited to once every [app_user.User.nameChangeCooldown]
  /// (30 days) and throws [ProfileUpdateException] if attempted early.
  ///
  /// Note: timestamps are written as ISO strings rather than
  /// FieldValue.serverTimestamp(). The original code used serverTimestamp(),
  /// but User.fromJson calls DateTime.parse() on the value - a Firestore
  /// Timestamp is not a String, so every reload after an update threw and the
  /// error was swallowed by _loadUserData's try/catch.
  Future<void> updateProfile({
    String? fullName,
    String? phoneNumber,
    String? zone,
    String? photoUrl,
  }) async {
    if (_user == null) {
      throw ProfileUpdateException('You are not signed in.');
    }

    try {
      final now = DateTime.now();
      final updates = <String, dynamic>{
        'updatedAt': now.toIso8601String(),
      };

      final trimmedName = fullName?.trim();
      final isRealNameChange = trimmedName != null &&
          trimmedName.isNotEmpty &&
          trimmedName != _appUser?.fullName;

      if (isRealNameChange) {
        final current = _appUser;
        if (current != null && !current.canChangeName) {
          throw ProfileUpdateException(
            'You can change your name again in '
            '${current.daysUntilNameChange} day(s).',
          );
        }
        updates['fullName'] = trimmedName;
        updates['nameLastChangedAt'] = now.toIso8601String();
      }

      if (phoneNumber != null) updates['phoneNumber'] = phoneNumber.trim();
      if (zone != null) updates['zone'] = zone;
      if (photoUrl != null) updates['photoUrl'] = photoUrl;

      // Nothing but the timestamp - no point writing.
      if (updates.length == 1) return;

      await _firestore.collection('users').doc(_user!.uid).update(updates);

      if (isRealNameChange) {
        // Keep the Firebase Auth display name in step with Firestore.
        try {
          await _user!.updateDisplayName(trimmedName);
        } catch (e) {
          debugPrint('Could not update auth display name: $e');
        }
      }

      await _loadUserData(_user!.uid);
      notifyListeners();
    } on ProfileUpdateException {
      rethrow;
    } catch (e) {
      throw ProfileUpdateException('Could not save your profile: $e');
    }
  }

  /// Uploads a profile picture and returns its download URL.
  ///
  /// Stored at `profile_photos/<uid>.jpg` so each user has exactly one,
  /// overwritten on change rather than accumulating.
  Future<String> uploadProfilePhoto(String localPath) async {
    if (_user == null) {
      throw ProfileUpdateException('You are not signed in.');
    }
    final file = File(localPath);
    if (!await file.exists()) {
      throw ProfileUpdateException('That image could not be found.');
    }
    try {
      final ref =
          FirebaseStorage.instance.ref().child('profile_photos/${_user!.uid}.jpg');
      final task = await ref.putFile(
        file,
        SettableMetadata(contentType: 'image/jpeg'),
      );
      return await task.ref.getDownloadURL();
    } catch (e) {
      throw ProfileUpdateException(
        'Photo upload failed. Cloud storage may not be set up yet. ($e)',
      );
    }
  }

  Future<String?> getRegistrationOfficerEmail(String zone) async {
    try {
      final query = await _firestore
          .collection('users')
          .where('zone', isEqualTo: zone)
          .where('role', isEqualTo: 'registration_officer')
          .limit(1)
          .get();
      
      if (query.docs.isNotEmpty) {
        return query.docs.first.data()['email'] as String?;
      }
      return null;
    } catch (e) {
      debugPrint('Error getting registration officer email: $e');
      return null;
    }
  }
}