import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/admin_model.dart';

const _bootstrapAdminProfiles = {
  'admin@ecoruta.com': (name: 'Administrador General', role: 'super_admin'),
  'admin.20260530@ecorutacr.com': (
    name: 'Administrador EcoRuta',
    role: 'admin',
  ),
};

class AdminAuthService {
  AdminAuthService({FirebaseAuth? auth, FirebaseFirestore? firestore})
    : _auth = auth ?? FirebaseAuth.instance,
      _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  User? get currentUser => _auth.currentUser;

  Stream<User?> authStateChanges() => _auth.authStateChanges();

  Future<UserCredential> login({
    required String email,
    required String password,
  }) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password.trim(),
    );

    final user = credential.user;
    if (user == null) {
      throw FirebaseAuthException(
        code: 'user-null',
        message: 'No se pudo iniciar sesion.',
      );
    }

    final adminDoc = await _firestore.collection('admins').doc(user.uid).get();
    if (!adminDoc.exists) {
      final bootstrapProfile = _bootstrapProfileFor(user.email);
      if (bootstrapProfile == null) {
        await _auth.signOut();
        throw FirebaseAuthException(
          code: 'admin-not-found',
          message: 'La cuenta no tiene permisos administrativos.',
        );
      }
    }

    return credential;
  }

  Future<UserCredential> registerAdmin({
    required String name,
    required String email,
    required String password,
    String role = 'admin',
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password.trim(),
    );

    final user = credential.user;
    if (user == null) {
      throw FirebaseAuthException(
        code: 'user-null',
        message: 'No se pudo crear el admin.',
      );
    }

    await _upsertAdminDocument(
      uid: user.uid,
      name: name,
      email: email,
      role: role,
    );

    return credential;
  }

  Future<AdminModel?> getCurrentAdminProfile() async {
    final user = _auth.currentUser;
    if (user == null) {
      return null;
    }

    final doc = await _firestore.collection('admins').doc(user.uid).get();
    if (!doc.exists || doc.data() == null) {
      return _buildBootstrapAdmin(user);
    }

    return AdminModel.fromMap(doc.data()!);
  }

  Future<void> logout() => _auth.signOut();

  Future<void> _upsertAdminDocument({
    required String uid,
    required String name,
    required String email,
    required String role,
  }) async {
    await _firestore.collection('admins').doc(uid).set({
      'uid': uid,
      'name': name.trim(),
      'email': email.trim(),
      'role': role,
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  AdminModel? _buildBootstrapAdmin(User user) {
    final bootstrapProfile = _bootstrapProfileFor(user.email);
    if (bootstrapProfile == null || user.email == null) {
      return null;
    }

    return AdminModel(
      uid: user.uid,
      name: bootstrapProfile.name,
      email: user.email!,
      role: bootstrapProfile.role,
      createdAt: null,
    );
  }

  ({String name, String role})? _bootstrapProfileFor(String? email) {
    if (email == null) return null;
    return _bootstrapAdminProfiles[email.trim().toLowerCase()];
  }
}
