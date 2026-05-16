// Copia de referencia tomada de lib/services/auth_service.dart
// Sirve para mostrar el patron de trabajo actual con Firebase Auth y Firestore.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:ecoruta/models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<UserCredential> login({
    required String email,
    required String password,
  }) {
    return _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password.trim(),
    );
  }

  Future<UserCredential> register({
    required String fullName,
    required String email,
    required String address,
    required String password,
    required int avatarId,
    required String favoriteActivity,
  }) async {
    final userCredential = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password.trim(),
    );

    final user = userCredential.user;

    if (user == null) {
      throw FirebaseAuthException(
        code: 'user-null',
        message: 'No se pudo crear el usuario',
      );
    }

    await _firestore.collection('users').doc(user.uid).set({
      'uid': user.uid,
      'email': email.trim(),
      'fullName': fullName.trim(),
      'address': address.trim(),
      'avatarId': avatarId,
      'favoriteActivity': favoriteActivity.trim(),
      'completed_routes': 0,
      'km_counter': 0,
      'streak_started_at': null,
      'streak_deadline_at': null,
      'createdAt': FieldValue.serverTimestamp(),
    });

    return userCredential;
  }

  Future<Map<String, dynamic>?> getUserData(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    return doc.data();
  }

  Future<UserModel?> getCurrentUserProfile() async {
    final user = _auth.currentUser;

    if (user == null) return null;

    final doc = await _firestore.collection('users').doc(user.uid).get();

    if (!doc.exists || doc.data() == null) return null;

    final data = Map<String, dynamic>.from(doc.data()!);
    final syncedData = await _resetExpiredStreakIfNeeded(
      uid: user.uid,
      data: data,
    );
    return UserModel.fromMap(syncedData);
  }

  Future<void> updateAvatar(int avatarId) async {
    final user = _auth.currentUser;

    if (user == null) {
      throw FirebaseAuthException(
        code: 'user-null',
        message: 'No hay un usuario autenticado',
      );
    }

    await _firestore.collection('users').doc(user.uid).update({
      'avatarId': avatarId,
    });
  }

  Future<void> updateProfile({
    required String fullName,
    required String address,
    required String favoriteActivity,
  }) async {
    final user = _auth.currentUser;

    if (user == null) {
      throw FirebaseAuthException(
        code: 'user-null',
        message: 'No hay un usuario autenticado',
      );
    }

    await _firestore.collection('users').doc(user.uid).update({
      'fullName': fullName.trim(),
      'address': address.trim(),
      'favoriteActivity': favoriteActivity.trim(),
    });
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final user = _auth.currentUser;

    if (user == null || user.email == null) {
      throw FirebaseAuthException(
        code: 'user-null',
        message: 'No hay un usuario autenticado',
      );
    }

    final credential = EmailAuthProvider.credential(
      email: user.email!,
      password: currentPassword.trim(),
    );

    await user.reauthenticateWithCredential(credential);
    await user.updatePassword(newPassword.trim());
  }

  Future<void> deleteCurrentAccount({required String currentPassword}) async {
    final user = _auth.currentUser;

    if (user == null || user.email == null) {
      throw FirebaseAuthException(
        code: 'user-null',
        message: 'No hay un usuario autenticado',
      );
    }

    final uid = user.uid;
    final normalizedPassword = currentPassword.trim();

    if (normalizedPassword.isEmpty) {
      throw FirebaseAuthException(
        code: 'missing-password',
        message: 'Debes confirmar tu contrasena actual',
      );
    }

    final credential = EmailAuthProvider.credential(
      email: user.email!,
      password: normalizedPassword,
    );
    await user.reauthenticateWithCredential(credential);

    final userDocRef = _firestore.collection('users').doc(uid);
    final userDocSnapshot = await userDocRef.get();
    final backupData = userDocSnapshot.data();

    await userDocRef.delete();

    try {
      await user.delete();
    } catch (e) {
      if (backupData != null) {
        await userDocRef.set(backupData);
      }
      rethrow;
    }
  }

  Future<UserModel?> registerWeeklyRouteCompletion() async {
    final user = _auth.currentUser;

    if (user == null) {
      throw FirebaseAuthException(
        code: 'user-null',
        message: 'No hay un usuario autenticado',
      );
    }

    final userDoc = _firestore.collection('users').doc(user.uid);
    final snapshot = await userDoc.get();
    final data = Map<String, dynamic>.from(snapshot.data() ?? {});
    final now = DateTime.now();

    final startedAt = _readDate(data['streak_started_at']);
    final deadlineAt = _readDate(data['streak_deadline_at']);
    final hasActiveStreak = deadlineAt != null && !deadlineAt.isBefore(now);
    final nextDeadline = now.add(const Duration(days: 7));

    await userDoc.set({
      'streak_started_at': hasActiveStreak ? startedAt ?? now : now,
      'streak_deadline_at': nextDeadline,
    }, SetOptions(merge: true));

    final refreshed = await userDoc.get();
    if (!refreshed.exists || refreshed.data() == null) return null;
    return UserModel.fromMap(refreshed.data()!);
  }

  Future<Map<String, dynamic>> _resetExpiredStreakIfNeeded({
    required String uid,
    required Map<String, dynamic> data,
  }) async {
    final deadlineAt = _readDate(data['streak_deadline_at']);
    if (deadlineAt == null || !deadlineAt.isBefore(DateTime.now())) {
      return data;
    }

    await _firestore.collection('users').doc(uid).set({
      'streak_started_at': null,
      'streak_deadline_at': null,
    }, SetOptions(merge: true));

    final normalized = Map<String, dynamic>.from(data);
    normalized['streak_started_at'] = null;
    normalized['streak_deadline_at'] = null;
    return normalized;
  }

  DateTime? _readDate(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  Future<void> logout() async {
    await _auth.signOut();
  }
}
