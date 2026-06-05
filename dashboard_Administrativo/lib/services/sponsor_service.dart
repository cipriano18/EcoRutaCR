import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../models/sponsor_model.dart';

class SponsorService {
  SponsorService({FirebaseFirestore? firestore, FirebaseAuth? auth})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  CollectionReference<Map<String, dynamic>> get _sponsorsCollection =>
      _firestore.collection('sponsors');

  Future<String> createSponsor(Sponsor sponsor) async {
    final docRef = _sponsorsCollection.doc();
    final currentUser = _auth.currentUser;
    final now = Timestamp.now();

    if (currentUser == null) {
      throw FirebaseAuthException(
        code: 'not-authenticated',
        message:
            'Debes iniciar sesion como administrador para guardar patrocinadores.',
      );
    }

    final payload = <String, dynamic>{
      'id': docRef.id,
      'name': sponsor.name,
      'logoUrl': sponsor.logoUrl,
      'type': sponsor.type,
      'contactEmail': sponsor.contactEmail,
      'phone': sponsor.phone,
      'startDate': Timestamp.fromDate(sponsor.startDate),
      'endDate': Timestamp.fromDate(sponsor.endDate),
      'status': sponsor.status,
      'paymentType': sponsor.paymentType,
      'isPhysicalBusiness': sponsor.isPhysicalBusiness,
      'category': sponsor.category,
      'description': sponsor.description,
      'advertisementIds': sponsor.advertisementIds,
      'createdByAdminId': currentUser.uid,
      'createdAt': now,
      'updatedAt': now,
    };

    if (sponsor.amountContributed != null) {
      payload['amountContributed'] = sponsor.amountContributed;
    }
    if (sponsor.latitude != null) {
      payload['latitude'] = sponsor.latitude;
    }
    if (sponsor.longitude != null) {
      payload['longitude'] = sponsor.longitude;
    }
    if (sponsor.externalLink != null && sponsor.externalLink!.isNotEmpty) {
      payload['externalLink'] = sponsor.externalLink;
    }
    if (sponsor.priority != null) {
      payload['priority'] = sponsor.priority;
    }

    await docRef.set(payload);

    debugPrint('SponsorService.createSponsor: sponsor ${docRef.id} guardado.');
    return docRef.id;
  }

  Stream<List<Sponsor>> getSponsors() {
    return _sponsorsCollection
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => Sponsor.fromMap(doc.data(), id: doc.id))
              .toList(),
        );
  }
}
