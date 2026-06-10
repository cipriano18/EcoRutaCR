import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ecoruta/features/routes/models/geo_node.dart';
import 'package:ecoruta/features/routes/models/guided_saved_route.dart';
import 'package:ecoruta/features/routes/models/route_profile.dart';
import 'package:ecoruta/features/routes/models/stored_route.dart';
import 'package:ecoruta/features/routes/services/routing/a_star_router.dart';
import 'package:ecoruta/features/routes/services/routing/route_result.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:latlong2/latlong.dart';

/// Servicio de persistencia para rutas creadas, guardadas y completadas.
class SavedRoutesService {
  SavedRoutesService({FirebaseFirestore? firestore, FirebaseAuth? auth})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  /// UID del usuario autenticado, si existe.
  String? get currentUserId => _auth.currentUser?.uid;

  CollectionReference<Map<String, dynamic>> get _routes =>
      _firestore.collection('routes');

  CollectionReference<Map<String, dynamic>> get _savedPublicRoutes =>
      _firestore.collection('saved_public_routes');
  CollectionReference<Map<String, dynamic>> get _routeCompletionSessions =>
      _firestore.collection('route_completion_sessions');

  /// Observa las rutas creadas por el usuario autenticado.
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

  /// Observa referencias personales a rutas públicas guardadas.
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

  /// Observa el catálogo público de rutas compartidas.
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

  /// Obtiene una captura puntual de rutas públicas.
  Future<List<StoredRoute>> fetchPublicRoutes() async {
    _requireUserId();

    final snapshot = await _routes
        .where('visibility', isEqualTo: StoredRouteVisibility.public.name)
        .orderBy('createdAt', descending: true)
        .get();

    return snapshot.docs.map(StoredRoute.fromDocument).toList(growable: false);
  }

  /// Retorna los IDs de rutas públicas que el usuario ya guardó.
  Future<Set<String>> fetchSavedPublicSourceRouteIds() async {
    final uid = _requireUserId();

    final snapshot = await _savedPublicRoutes
        .where('savedByUserId', isEqualTo: uid)
        .get();

    return snapshot.docs
        .map((doc) => (doc.data()['sourceRouteId'] as String?)?.trim() ?? '')
        .where((routeId) => routeId.isNotEmpty)
        .toSet();
  }

  /// Obtiene nombres públicos para mostrar autores de rutas compartidas.
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
          // Un perfil público ausente no debe bloquear la carga del catálogo.
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

  /// Guarda una ruta generada o registrada por el usuario.
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

    // La ruta se guarda con geometría comprimida y bounds para mantener
    // documentos livianos y acelerar previsualizaciones.
    final payload = {
      'ownerId': uid,
      'title': title.trim(),
      'description': description.trim(),
      'visibility': visibility.name,
      'activityProfile': activityProfile.name,
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

  /// Guarda una referencia personal a una ruta pública creada por otro usuario.
  Future<String> savePublicRouteReference({
    required StoredRoute route,
    required String creatorName,
  }) async {
    final uid = _requireUserId();

    if (!route.isPublic) {
      throw const SavedRouteException(
        'Solo puedes guardar rutas públicas desde este flujo.',
      );
    }

    if (route.ownerId == uid) {
      throw const SavedRouteException(
        'Esa ruta ya forma parte de tus creaciones.',
      );
    }

    final docId = '${uid}_${route.id}';
    final docRef = _savedPublicRoutes.doc(docId);

    try {
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
        'activityProfile': route.activityProfile.name,
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
    } on FirebaseException catch (e) {
      if (e.code == 'already-exists') {
        throw const SavedRouteException('Ya guardaste esta ruta pública.');
      }

      rethrow;
    }
  }

  /// Registra una ejecución completada de una ruta guiada.
  Future<String> saveRouteCompletionSession({
    required GuidedSavedRoute sourceRoute,
    required DateTime startedAt,
    required DateTime finishedAt,
    required double completionDistanceMeters,
    required int completionDurationSeconds,
    required double elevationGainMeters,
    required List<LatLng> recordedPath,
  }) async {
    final uid = _requireUserId();
    if (recordedPath.isEmpty) {
      throw const SavedRouteException(
        'No se pudo guardar la sesión porque no hay recorrido registrado.',
      );
    }

    final path = recordedPath
        .asMap()
        .entries
        .map(
          (entry) => GeoNode(
            id: entry.key,
            latitude: entry.value.latitude,
            longitude: entry.value.longitude,
          ),
        )
        .toList(growable: false);
    final polyline = StoredRoute.encodePath(path);

    // Las sesiones completadas se guardan aparte para no duplicar ni mutar la
    // ruta fuente que sirvió como guía.
    final payload = {
      'userId': uid,
      'sourceRouteId': sourceRoute.routeId,
      'sourceRouteTitle': sourceRoute.title,
      'activityProfile': sourceRoute.activityProfile.name,
      'startedNearStart': true,
      'finishedNearEnd': true,
      'startedAt': Timestamp.fromDate(startedAt),
      'finishedAt': Timestamp.fromDate(finishedAt),
      'completionDistanceMeters': completionDistanceMeters,
      'completionDurationSeconds': completionDurationSeconds,
      'elevationGainMeters': elevationGainMeters,
      'recordedPolyline': polyline,
      'pointCount': recordedPath.length,
      'createdAt': FieldValue.serverTimestamp(),
    };

    final doc = await _routeCompletionSessions.add(payload);
    return doc.id;
  }

  /// Elimina una ruta creada por el usuario autenticado.
  Future<void> deleteRoute(String routeId) async {
    await _assertOwnership(routeId);
    await _routes.doc(routeId).delete();
  }

  /// Elimina una referencia guardada de una ruta pública.
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

  /// Actualiza la visibilidad de una ruta propia.
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

  /// Actualiza datos editables de una ruta privada.
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
        'Las rutas públicas no se pueden editar.',
      );
    }

    await _routes.doc(routeId).update({
      'title': title.trim(),
      'description': description.trim(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Calcula el bounding box mínimo que contiene todos los puntos de [path].
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

  /// Exige una sesión autenticada y retorna su UID.
  String _requireUserId() {
    final user = _auth.currentUser;

    if (user == null) {
      throw const SavedRouteException(
        'Debes iniciar sesión para guardar rutas.',
      );
    }

    return user.uid;
  }

  /// Verifica que la ruta exista y pertenezca al usuario autenticado.
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

/// Error de dominio para operaciones de rutas guardadas.
class SavedRouteException implements Exception {
  const SavedRouteException(this.message);

  final String message;

  @override
  String toString() => 'SavedRouteException: $message';
}
