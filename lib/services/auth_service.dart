import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:yiw_field_report/models/user.dart' as app_user;

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

  Future<void> updateProfile({
    String? fullName,
    String? phoneNumber,
    String? zone,
  }) async {
    try {
      if (_user == null) return;
      
      final updates = <String, dynamic>{
        'updatedAt': FieldValue.serverTimestamp(),
      };
      
      if (fullName != null) updates['fullName'] = fullName;
      if (phoneNumber != null) updates['phoneNumber'] = phoneNumber;
      if (zone != null) updates['zone'] = zone;
      
      await _firestore.collection('users').doc(_user!.uid).update(updates);
      
      // Reload user data
      await _loadUserData(_user!.uid);
    } catch (e) {
      rethrow;
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