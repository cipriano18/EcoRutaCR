import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../screens/dashboard/shared/dashboard_mock_ui.dart';

class DashboardHomeSnapshot {
  const DashboardHomeSnapshot({
    required this.totalSponsors,
    required this.totalClients,
    required this.totalAdmins,
    required this.totalAds,
    required this.totalPublicRoutes,
    required this.operationCards,
    required this.highlights,
    required this.recentActivity,
  });

  final int totalSponsors;
  final int totalClients;
  final int totalAdmins;
  final int totalAds;
  final int totalPublicRoutes;
  final List<DashboardOperationalCardData> operationCards;
  final List<(String, String)> highlights;
  final List<DashboardActivityItem> recentActivity;
}

class DashboardOperationalCardData {
  const DashboardOperationalCardData({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.accentColor,
  });

  final String title;
  final String value;
  final String subtitle;
  final Color accentColor;
}

class DashboardHomeService {
  DashboardHomeService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  Future<DashboardHomeSnapshot> loadSnapshot() async {
    debugPrint(
      'DashboardHomeService.loadSnapshot: leyendo colecciones users, admins y routes.',
    );

    final usersCollection = _firestore.collection('users');
    final adminsCollection = _firestore.collection('admins');
    final routesCollection = _firestore.collection('routes');

    try {
      final totalClientsFuture = usersCollection.count().get();
      final totalAdminsFuture = adminsCollection.count().get();
      final recentUsersFuture = _loadRecentDocuments(usersCollection, 'users');
      final recentAdminsFuture = _loadRecentDocuments(adminsCollection, 'admins');
      final routesFuture = routesCollection.get();
      final recentRoutesFuture = _loadRecentDocuments(routesCollection, 'routes');

      final results = await Future.wait([
        totalClientsFuture,
        totalAdminsFuture,
        recentUsersFuture,
        recentAdminsFuture,
        routesFuture,
        recentRoutesFuture,
      ]);

      final totalClients = (results[0] as AggregateQuerySnapshot).count ?? 0;
      final totalAdmins = (results[1] as AggregateQuerySnapshot).count ?? 0;
      final recentUsers =
          results[2] as List<QueryDocumentSnapshot<Map<String, dynamic>>>;
      final recentAdmins =
          results[3] as List<QueryDocumentSnapshot<Map<String, dynamic>>>;
      final routesSnapshot = results[4] as QuerySnapshot<Map<String, dynamic>>;
      final recentRoutes =
          results[5] as List<QueryDocumentSnapshot<Map<String, dynamic>>>;

      final totalPublicRoutes = routesSnapshot.docs
          .where((doc) => _isPublicRoute(doc.data()))
          .length;

      debugPrint(
        'DashboardHomeService.loadSnapshot: totals -> users=$totalClients, admins=$totalAdmins, publicRoutes=$totalPublicRoutes, allRoutes=${routesSnapshot.docs.length}',
      );

      final favoriteActivity = _mostCommonFavoriteActivity(recentUsers);
      final latestUserName = recentUsers.isNotEmpty
          ? _readFirstString(recentUsers.first.data(), ['fullName', 'name'])
          : null;
      final latestAdminName = recentAdmins.isNotEmpty
          ? _readFirstString(recentAdmins.first.data(), ['name', 'fullName'])
          : null;
      final latestRouteName = _findLatestPublicRouteName(recentRoutes);

      final operationCards = [
        DashboardOperationalCardData(
          title: 'Clientes en plataforma',
          value: '$totalClients',
          subtitle: latestUserName != null
              ? 'Ultimo registro detectado: $latestUserName.'
              : 'Conteo real de la coleccion users.',
          accentColor: dashboardSoftGreen,
        ),
        DashboardOperationalCardData(
          title: 'Rutas públicas registradas',
          value: '$totalPublicRoutes',
          subtitle: latestRouteName != null
              ? 'Ultima ruta publica observada: $latestRouteName.'
              : 'Conteo real de rutas públicas en la coleccion routes.',
          accentColor: dashboardAccentOrange,
        ),
      ];

      final highlights = [
        (
          'Actividad favorita detectada',
          favoriteActivity ?? 'Sin datos suficientes',
        ),
        ('Administrador mas reciente', latestAdminName ?? 'Sin datos recientes'),
        ('Ultima ruta publica', latestRouteName ?? 'Sin nombre disponible'),
      ];

      final recentActivity = _buildRecentActivity(
        latestUserName: latestUserName,
        latestAdminName: latestAdminName,
        latestRouteName: latestRouteName,
        favoriteActivity: favoriteActivity,
      );

      return DashboardHomeSnapshot(
        totalSponsors: 0,
        totalClients: totalClients,
        totalAdmins: totalAdmins,
        totalAds: 0,
        totalPublicRoutes: totalPublicRoutes,
        operationCards: operationCards,
        highlights: highlights,
        recentActivity: recentActivity,
      );
    } catch (error, stackTrace) {
      debugPrint('DashboardHomeService.loadSnapshot error: $error');
      debugPrint('$stackTrace');
      rethrow;
    }
  }

  Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>> _loadRecentDocuments(
    CollectionReference<Map<String, dynamic>> collection,
    String collectionName,
  ) async {
    try {
      final query = await collection
          .orderBy('createdAt', descending: true)
          .limit(5)
          .get();
      return query.docs;
    } catch (error, stackTrace) {
      debugPrint(
        'DashboardHomeService._loadRecentDocuments: fallo orderBy(createdAt) en $collectionName -> $error',
      );
      debugPrint('$stackTrace');
      final fallback = await collection.limit(5).get();
      return fallback.docs;
    }
  }

  bool _isPublicRoute(Map<String, dynamic> data) {
    final visibility = data['visibility'];
    final isPublic = data['isPublic'];
    final publicValue = data['public'];

    if (isPublic is bool) {
      return isPublic;
    }

    if (publicValue is bool) {
      return publicValue;
    }

    if (visibility is bool) {
      return visibility;
    }

    if (visibility is String) {
      final normalized = visibility.trim().toLowerCase();
      return normalized == 'public' ||
          normalized == 'publica' ||
          normalized == 'pública';
    }

    return false;
  }

  String? _findLatestPublicRouteName(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> routes,
  ) {
    for (final route in routes) {
      final data = route.data();
      if (!_isPublicRoute(data)) {
        continue;
      }

      final routeName = _readFirstString(data, ['name', 'title', 'routeName']);
      if (routeName != null) {
        return routeName;
      }
    }

    return null;
  }

  String? _mostCommonFavoriteActivity(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> users,
  ) {
    final frequency = <String, int>{};

    for (final user in users) {
      final activity = _readFirstString(user.data(), ['favoriteActivity']);
      if (activity == null || activity.trim().isEmpty) {
        continue;
      }
      frequency.update(activity.trim(), (value) => value + 1, ifAbsent: () => 1);
    }

    if (frequency.isEmpty) {
      return null;
    }

    final sorted = frequency.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.first.key;
  }

  String? _readFirstString(Map<String, dynamic> data, List<String> keys) {
    for (final key in keys) {
      final value = data[key];
      if (value is String && value.trim().isNotEmpty) {
        return value.trim();
      }
    }
    return null;
  }

  List<DashboardActivityItem> _buildRecentActivity({
    required String? latestUserName,
    required String? latestAdminName,
    required String? latestRouteName,
    required String? favoriteActivity,
  }) {
    return [
      DashboardActivityItem(
        title: 'Nuevo cliente detectado',
        detail: latestUserName != null
            ? '$latestUserName aparece como registro reciente en users.'
            : 'No fue posible identificar un cliente reciente con nombre visible.',
        timeLabel: 'Coleccion users',
        icon: Icons.people_alt_outlined,
        accentColor: dashboardSoftGreen,
      ),
      DashboardActivityItem(
        title: 'Administrador reciente',
        detail: latestAdminName != null
            ? '$latestAdminName figura dentro de los admins mas recientes.'
            : 'No fue posible identificar un administrador reciente con nombre visible.',
        timeLabel: 'Coleccion admins',
        icon: Icons.admin_panel_settings_outlined,
        accentColor: dashboardBrandGreen,
      ),
      DashboardActivityItem(
        title: 'Ruta publica reciente',
        detail: latestRouteName != null
            ? '$latestRouteName aparece entre los documentos recientes de routes.'
            : 'La coleccion routes no expuso un nombre legible para actividad reciente.',
        timeLabel: 'Coleccion routes',
        icon: Icons.route_outlined,
        accentColor: dashboardAccentOrange,
      ),
      DashboardActivityItem(
        title: 'Actividad favorita observada',
        detail: favoriteActivity != null
            ? 'La preferencia mas visible en users es $favoriteActivity.'
            : 'Aun no hay suficientes datos para inferir una actividad favorita.',
        timeLabel: 'Lectura parcial',
        icon: Icons.insights_outlined,
        accentColor: dashboardSupportGreen,
      ),
    ];
  }
}
