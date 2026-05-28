import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:ecoruta/models/geo_node.dart';
import 'package:ecoruta/models/route_profile.dart';
import 'package:ecoruta/models/stored_route.dart';
import 'package:ecoruta/services/routing/a_star_router.dart';
import 'package:ecoruta/services/routing/route_result.dart';

/// Administra el guardado y la lectura de rutas persistidas en Firestore.
class SavedRoutesService {
  SavedRoutesService({FirebaseFirestore? firestore, FirebaseAuth? auth})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  String? get currentUserId => _auth.currentUser?.uid;

  /// Referencia principal a la colección donde viven las rutas guardadas.
  CollectionReference<Map<String, dynamic>> get _routes =>
      _firestore.collection('routes');

  CollectionReference<Map<String, dynamic>> get _savedPublicRoutes =>
      _firestore.collection('saved_public_routes');

  /// Observa en tiempo real las rutas del usuario autenticado.
  Stream<List<StoredRoute>> watchUserRoutes() {
    final uid = _requireUserId();

    return _routes
        .where('ownerId', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(StoredRoute.fromDocument)
              .toList(growable: false),
        );
  }

  Stream<List<StoredRoute>> watchSavedPublicRoutes() {
    final uid = _requireUserId();

    return _savedPublicRoutes
        .where('savedByUserId', isEqualTo: uid)
        .orderBy('savedAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(StoredRoute.fromDocument)
              .toList(growable: false),
        );
  }

  /// Observa rutas públicas para futuros listados compartidos.
  Stream<List<StoredRoute>> watchPublicRoutes() {
    return _routes
        .where('visibility', isEqualTo: StoredRouteVisibility.public.name)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(StoredRoute.fromDocument)
              .toList(growable: false),
        );
  }

  /// Obtiene una instantánea puntual de las rutas públicas disponibles.
  Future<List<StoredRoute>> fetchPublicRoutes() async {
    _requireUserId();

    final snapshot = await _routes
        .where('visibility', isEqualTo: StoredRouteVisibility.public.name)
        .orderBy('createdAt', descending: true)
        .get();

    return snapshot.docs.map(StoredRoute.fromDocument).toList(growable: false);
  }

  /// Resuelve nombres visibles de usuarios para enriquecer listados de rutas.
  Future<Map<String, String>> fetchUserDisplayNames(
    Iterable<String> userIds,
  ) async {
    _requireUserId();

    final uniqueIds = userIds
        .map((id) => id.trim())
        .where((id) => id.isNotEmpty)
        .toSet();
    final entries = await Future.wait(
      uniqueIds.map((userId) async {
        try {
          final snapshot = await _firestore
              .collection('public_user_profiles')
              .doc(userId)
              .get();
          final data = snapshot.data();
          final fullName = (data?['fullName'] as String?)?.trim();
          return MapEntry(
            userId,
            fullName == null || fullName.isEmpty
                ? 'usuario desconocido'
                : fullName,
          );
        } catch (_) {
          return const MapEntry('', '');
        }
      }),
    );

    return {
      for (final entry in entries)
        if (entry.key.isNotEmpty)
          entry.key: entry.value.isEmpty ? 'usuario desconocido' : entry.value,
    };
  }

  /// Persiste una ruta calculada junto con su geometría comprimida.
  Future<String> saveRoute({
    required String title,
    String description = '',
    required StoredRouteVisibility visibility,
    required RouteProfile activityProfile,
    required RoutingPreference routingPreference,
    required String startLabel,
    required String endLabel,
    required RouteResult route,
  }) async {
    final uid = _requireUserId();
    final path = route.path;
    if (path.isEmpty) {
      throw const SavedRouteException('No hay puntos para guardar la ruta.');
    }

    final startNode = path.first;
    final endNode = path.last;
    final polyline = StoredRoute.encodePath(path);
    final bounds = _calculateBounds(path);

    final payload = {
      'ownerId': uid,
      'title': title.trim(),
      'description': description.trim(),
      'visibility': visibility.name,
      'activityProfile': activityProfile.label,
      'routingPreference': routingPreference.name,
      'start': {
        'label': startLabel.trim(),
        'lat': startNode.latitude,
        'lon': startNode.longitude,
      },
      'end': {
        'label': endLabel.trim(),
        'lat': endNode.latitude,
        'lon': endNode.longitude,
      },
      'polyline': polyline,
      'pointCount': path.length,
      'totalDistanceMeters': route.totalDistanceMeters,
      'estimatedDurationSeconds': route.estimatedDurationSeconds,
      'elevationGainMeters': route.elevationGainMeters,
      'boundingBox': bounds,
      'preview': {
        'centerLat': (bounds['south']! + bounds['north']!) / 2,
        'centerLon': (bounds['west']! + bounds['east']!) / 2,
      },
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };

    final doc = await _routes.add(payload);
    return doc.id;
  }

  Future<String> savePublicRouteReference({
    required StoredRoute route,
    required String creatorName,
  }) async {
    final uid = _requireUserId();

    if (!route.isPublic) {
      throw const SavedRouteException(
        'Solo puedes guardar rutas publicas desde este flujo.',
      );
    }

    if (route.ownerId == uid) {
      throw const SavedRouteException(
        'Esa ruta ya forma parte de tus creaciones.',
      );
    }

    final docId = '${uid}_${route.id}';
    final docRef = _savedPublicRoutes.doc(docId);
    final existing = await docRef.get();
    if (existing.exists) {
      throw const SavedRouteException('Ya guardaste esta ruta publica.');
    }

    await docRef.set({
      'savedByUserId': uid,
      'sourceRouteId': route.id,
      'sourceOwnerId': route.ownerId,
      'sourceOwnerName': creatorName.trim().isEmpty
          ? 'usuario desconocido'
          : creatorName.trim(),
      'title': route.title,
      'description': route.description,
      'visibility': StoredRouteVisibility.public.name,
      'activityProfile': route.activityProfile.label,
      'routingPreference': route.routingPreference.name,
      'start': {
        'label': route.startLabel,
        'lat': route.startLat,
        'lon': route.startLon,
      },
      'end': {
        'label': route.endLabel,
        'lat': route.endLat,
        'lon': route.endLon,
      },
      'polyline': route.polyline,
      'pointCount': route.pointCount,
      'totalDistanceMeters': route.totalDistanceMeters,
      'estimatedDurationSeconds': route.estimatedDurationSeconds,
      'elevationGainMeters': route.elevationGainMeters,
      'boundingBox': {
        'south': route.south,
        'west': route.west,
        'north': route.north,
        'east': route.east,
      },
      'preview': {
        'centerLat': route.previewCenterLat,
        'centerLon': route.previewCenterLon,
      },
      'sourceRouteCreatedAt': route.createdAt == null
          ? null
          : Timestamp.fromDate(route.createdAt!),
      'sourceRouteUpdatedAt': route.updatedAt == null
          ? null
          : Timestamp.fromDate(route.updatedAt!),
      'savedAt': FieldValue.serverTimestamp(),
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    return docId;
  }

  /// Elimina una ruta guardada después de validar ownership.
  Future<void> deleteRoute(String routeId) async {
    await _assertOwnership(routeId);
    await _routes.doc(routeId).delete();
  }

  Future<void> deleteSavedPublicRoute(String savedRouteId) async {
    final uid = _requireUserId();
    final snapshot = await _savedPublicRoutes.doc(savedRouteId).get();
    if (!snapshot.exists) {
      throw const SavedRouteException('La ruta guardada ya no existe.');
    }

    final savedByUserId = snapshot.data()?['savedByUserId'] as String?;
    if (savedByUserId != uid) {
      throw const SavedRouteException(
        'No tienes permisos para eliminar esta ruta guardada.',
      );
    }

    await _savedPublicRoutes.doc(savedRouteId).delete();
  }

  /// Cambia la visibilidad de una ruta sin reescribir el resto del documento.
  Future<void> updateVisibility({
    required String routeId,
    required StoredRouteVisibility visibility,
  }) async {
    await _assertOwnership(routeId);
    await _routes.doc(routeId).update({
      'visibility': visibility.name,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Actualiza metadatos editables de una ruta privada del usuario.
  Future<void> updateRouteDetails({
    required String routeId,
    required String title,
    String description = '',
  }) async {
    await _assertOwnership(routeId);

    final snapshot = await _routes.doc(routeId).get();
    final data = snapshot.data();
    final visibility = data?['visibility'] as String?;

    if (visibility == StoredRouteVisibility.public.name) {
      throw const SavedRouteException(
        'Las rutas publicas no se pueden editar.',
      );
    }

    await _routes.doc(routeId).update({
      'title': title.trim(),
      'description': description.trim(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Map<String, double> _calculateBounds(List<GeoNode> path) {
    var south = path.first.latitude;
    var north = path.first.latitude;
    var west = path.first.longitude;
    var east = path.first.longitude;

    for (final node in path.skip(1)) {
      if (node.latitude < south) south = node.latitude;
      if (node.latitude > north) north = node.latitude;
      if (node.longitude < west) west = node.longitude;
      if (node.longitude > east) east = node.longitude;
    }

    return {'south': south, 'west': west, 'north': north, 'east': east};
  }

  String _requireUserId() {
    final user = _auth.currentUser;
    if (user == null) {
      throw const SavedRouteException(
        'Debes iniciar sesion para guardar rutas.',
      );
    }
    return user.uid;
  }

  Future<void> _assertOwnership(String routeId) async {
    final uid = _requireUserId();
    final snapshot = await _routes.doc(routeId).get();
    if (!snapshot.exists) {
      throw const SavedRouteException('La ruta no existe.');
    }

    final ownerId = snapshot.data()?['ownerId'] as String?;
    if (ownerId != uid) {
      throw const SavedRouteException(
        'No tienes permisos para modificar esta ruta.',
      );
    }
  }
}

/// Error de dominio para operaciones de guardado de rutas.
class SavedRouteException implements Exception {
  const SavedRouteException(this.message);

  final String message;

  @override
  String toString() => 'SavedRouteException: $message';
}
