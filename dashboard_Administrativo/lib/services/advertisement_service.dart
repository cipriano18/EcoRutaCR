import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/advertisement_model.dart';

class AdvertisementService {
  AdvertisementService({FirebaseFirestore? firestore, FirebaseAuth? auth})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  CollectionReference<Map<String, dynamic>> get _advertisementsCollection =>
      _firestore.collection('advertisements');

  CollectionReference<Map<String, dynamic>> get _sponsorsCollection =>
      _firestore.collection('sponsors');

  Future<String> createAdvertisement(AdvertisementDraft draft) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      throw FirebaseAuthException(
        code: 'not-authenticated',
        message:
            'Debes iniciar sesion como administrador para guardar publicidades.',
      );
    }

    final now = Timestamp.now();
    final docRef = _advertisementsCollection.doc();
    final payload = <String, dynamic>{
      'id': docRef.id,
      'type': draft.type.name,
      'sponsorId': draft.sponsorId,
      'sponsorName': draft.sponsorName,
      'sponsorLogoUrl': draft.sponsorLogoUrl,
      'status': draft.status,
      'imageUrl': draft.imageUrl,
      'description': draft.description,
      'startDate': draft.startDate == null
          ? null
          : Timestamp.fromDate(draft.startDate!),
      'endDate': draft.endDate == null
          ? null
          : Timestamp.fromDate(draft.endDate!),
      'openingTime': _timeOfDayToString(draft.openingTime),
      'closingTime': _timeOfDayToString(draft.closingTime),
      'latitude': draft.latitude,
      'longitude': draft.longitude,
      'totalClicks': draft.totalClicks,
      'createdByAdminId': currentUser.uid,
      'createdAt': now,
      'updatedAt': now,
    };

    if (draft.sponsorExternalLink != null &&
        draft.sponsorExternalLink!.trim().isNotEmpty) {
      payload['sponsorExternalLink'] = draft.sponsorExternalLink!.trim();
    }

    final batch = _firestore.batch();
    batch.set(docRef, payload);
    batch.update(_sponsorsCollection.doc(draft.sponsorId), {
      'advertisementIds': FieldValue.arrayUnion([docRef.id]),
      'updatedAt': now,
    });

    await batch.commit();
    debugPrint(
      'AdvertisementService.createAdvertisement: publicidad ${docRef.id} guardada para sponsor ${draft.sponsorId}.',
    );
    return docRef.id;
  }

  Stream<List<AdvertisementDraft>> getAdvertisements() {
    return _advertisementsCollection
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => AdvertisementDraft.fromMap(doc.data(), id: doc.id))
              .toList(),
        );
  }

  String? _timeOfDayToString(TimeOfDay? value) {
    if (value == null) return null;
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}
