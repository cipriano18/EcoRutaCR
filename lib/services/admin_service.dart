import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

import '../firebase_options.dart';
import '../models/admin_model.dart';

class AdminService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Stream<List<AdminModel>> getAdmins() {
    return _firestore
        .collection('admins')
        .where('role', whereIn: ['admin', 'super_admin'])
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return AdminModel.fromMap(doc.data());
          }).toList();
        });
  }

  Future<void> createAdmin({
    required String name,
    required String email,
    required String password,
    required String role,
  }) async {
    final secondaryApp = await Firebase.initializeApp(
      name: 'SecondaryAdminApp',
      options: DefaultFirebaseOptions.currentPlatform,
    );

    try {
      final secondaryAuth = FirebaseAuth.instanceFor(app: secondaryApp);

      final credential = await secondaryAuth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );

      final uid = credential.user!.uid;

      await credential.user!.updateDisplayName(name.trim());

      await _firestore.collection('admins').doc(uid).set({
        'uid': uid,
        'name': name.trim(),
        'email': email.trim(),
        'role': role,
        'createdAt': FieldValue.serverTimestamp(),
      });

      await secondaryAuth.signOut();
    } finally {
      await secondaryApp.delete();
    }
  }

  Future<void> deleteAdmin(String uid) async {
    await _firestore.collection('admins').doc(uid).delete();
  }

  // Para editar OTROS admins desde la lista.
  // Solo actualiza Firestore: nombre y correo.
  Future<void> updateAdmin({
    required String uid,
    required String name,
    required String email,
  }) async {
    await _firestore.collection('admins').doc(uid).update({
      'name': name.trim(),
      'email': email.trim(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // Para editar EL ADMIN LOGUEADO desde el sidebar.
  // Puede cambiar nombre, correo y contraseña.
  Future<void> updateCurrentAdminProfile({
    required String name,
    required String email,
    required String currentPassword,
    required String newPassword,
  }) async {
    final user = _auth.currentUser;

    if (user == null || user.email == null) {
      throw FirebaseAuthException(
        code: 'user-null',
        message: 'No hay un administrador autenticado',
      );
    }

    final credential = EmailAuthProvider.credential(
      email: user.email!,
      password: currentPassword.trim(),
    );

    await user.reauthenticateWithCredential(credential);

    await user.updateDisplayName(name.trim());

    if (newPassword.trim().isNotEmpty) {
      await user.updatePassword(newPassword.trim());
    }

    if (email.trim() != user.email) {
      await user.verifyBeforeUpdateEmail(email.trim());
    }

    await _firestore.collection('admins').doc(user.uid).update({
      'name': name.trim(),
      'email': email.trim(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}