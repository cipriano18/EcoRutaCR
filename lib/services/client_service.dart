import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/client_model.dart';

class ClientService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<List<ClientModel>> getClients() {
    return _firestore
        .collection('users')
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return ClientModel.fromMap(doc.data());
          }).toList();
        });
  }

 Future<void> updateClient({
  required String uid,
  required String fullName,
  required String email,
  required String favoriteActivity,
}) async {
  await _firestore.collection('users').doc(uid).update({
    'fullName': fullName.trim(),
    'email': email.trim(),
    'favoriteActivity': favoriteActivity.trim(),
    'updatedAt': FieldValue.serverTimestamp(),
  });
}

  Future<void> deleteClient(String uid) async {
    await _firestore.collection('users').doc(uid).delete();
  }
  
}