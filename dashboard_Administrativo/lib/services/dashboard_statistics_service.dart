import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../screens/dashboard/shared/dashboard_mock_ui.dart';

class DashboardStatisticsSnapshot {
  const DashboardStatisticsSnapshot({
    required this.metrics,
    required this.barData,
    required this.lineData,
    required this.pieData,
    required this.highlights,
  });

  final List<DashboardMetricData> metrics;
  final List<DashboardBarDatum> barData;
  final List<DashboardLineDatum> lineData;
  final List<DashboardPieDatum> pieData;
  final List<DashboardStatisticsHighlight> highlights;
}

class DashboardStatisticsHighlight {
  const DashboardStatisticsHighlight({
    required this.title,
    required this.value,
    required this.badge,
    required this.color,
  });

  final String title;
  final String value;
  final String badge;
  final Color color;
}

class DashboardStatisticsService {
  DashboardStatisticsService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  Future<DashboardStatisticsSnapshot> loadSnapshot() async {
    debugPrint(
      'DashboardStatisticsService.loadSnapshot: leyendo colecciones users, admins y routes.',
    );

    try {
      final results = await Future.wait<QuerySnapshot<Map<String, dynamic>>>([
        _firestore.collection('users').get(),
        _firestore.collection('admins').get(),
        _firestore.collection('routes').get(),
      ]);

      final usersSnapshot = results[0];
      final adminsSnapshot = results[1];
      final routesSnapshot = results[2];

      final totalClients = usersSnapshot.docs.length;
      final totalAdmins = adminsSnapshot.docs.length;
      final publicRoutes = routesSnapshot.docs
          .where((doc) => _isPublicRoute(doc.data()))
          .toList();
      final totalPublicRoutes = publicRoutes.length;

      final activityCounts = _buildActivityCounts(publicRoutes);
      final topActivity = _topActivity(activityCounts);
      final latestRouteName = _latestRouteName(publicRoutes);
      final latestUserName = _latestDocumentName(
        usersSnapshot.docs,
        const ['fullName', 'name'],
      );
      final latestAdminName = _latestDocumentName(
        adminsSnapshot.docs,
        const ['fullName', 'name'],
      );
      final monthlyTrend = _buildMonthlyTrend(
        routes: routesSnapshot.docs,
      );

      debugPrint(
        'DashboardStatisticsService.loadSnapshot: totals -> users=$totalClients, admins=$totalAdmins, publicRoutes=$totalPublicRoutes, allRoutes=${routesSnapshot.docs.length}',
      );

      return DashboardStatisticsSnapshot(
        metrics: [
          DashboardMetricData(
            title: 'Total de patrocinadores',
            value: '0',
            changeLabel: 'Sin coleccion disponible',
            icon: Icons.handshake_outlined,
            accentColor: dashboardSoftGreen,
          ),
          DashboardMetricData(
            title: 'Total de clientes',
            value: '$totalClients',
            changeLabel: latestUserName != null
                ? 'Ultimo visible: $latestUserName'
                : 'Coleccion users',
            icon: Icons.groups_2_outlined,
            accentColor: dashboardBrandGreen,
          ),
          DashboardMetricData(
            title: 'Total de administradores',
            value: '$totalAdmins',
            changeLabel: latestAdminName != null
                ? 'Ultimo visible: $latestAdminName'
                : 'Coleccion admins',
            icon: Icons.admin_panel_settings_outlined,
            accentColor: dashboardSupportGreen,
          ),
          DashboardMetricData(
            title: 'Publicidades activas',
            value: '0',
            changeLabel: 'Sin coleccion disponible',
            icon: Icons.campaign_outlined,
            accentColor: dashboardAccentOrange,
          ),
          DashboardMetricData(
            title: 'Rutas públicas',
            value: '$totalPublicRoutes',
            changeLabel: latestRouteName != null
                ? 'Ultima visible: $latestRouteName'
                : 'Coleccion routes',
            icon: Icons.route_outlined,
            accentColor: dashboardSoftGreen,
          ),
        ],
        barData: [
          const DashboardBarDatum(
            label: 'Patroc.',
            value: 0,
            color: dashboardBrandGreen,
          ),
          DashboardBarDatum(
            label: 'Clientes',
            value: totalClients.toDouble(),
            color: dashboardSoftGreen,
          ),
          DashboardBarDatum(
            label: 'Admins',
            value: totalAdmins.toDouble(),
            color: dashboardSupportGreen,
          ),
          const DashboardBarDatum(
            label: 'Ads',
            value: 0,
            color: dashboardAccentOrange,
          ),
          DashboardBarDatum(
            label: 'Rutas',
            value: totalPublicRoutes.toDouble(),
            color: dashboardLightGreen,
          ),
        ],
        lineData: monthlyTrend,
        pieData: _buildPieData(activityCounts),
        highlights: [
          DashboardStatisticsHighlight(
            title: 'Actividad con mas rutas',
            value: topActivity.$1,
            badge: topActivity.$2,
            color: dashboardSoftGreen,
          ),
          DashboardStatisticsHighlight(
            title: 'Ruta publica mas reciente',
            value: latestRouteName ?? 'Sin nombre visible',
            badge: totalPublicRoutes > 0
                ? '$totalPublicRoutes rutas públicas'
                : 'Sin rutas públicas',
            color: dashboardAccentOrange,
          ),
          DashboardStatisticsHighlight(
            title: 'Lectura operativa actual',
            value: _buildOperationalInsight(
              totalClients: totalClients,
              totalAdmins: totalAdmins,
              totalPublicRoutes: totalPublicRoutes,
            ),
            badge: _buildOperationalBadge(
              totalClients: totalClients,
              totalAdmins: totalAdmins,
              totalPublicRoutes: totalPublicRoutes,
            ),
            color: dashboardBrandGreen,
          ),
        ],
      );
    } catch (error, stackTrace) {
      debugPrint('DashboardStatisticsService.loadSnapshot error: $error');
      debugPrint('$stackTrace');
      rethrow;
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
          normalized == 'p\u00fablica';
    }

    return false;
  }

  Map<String, int> _buildActivityCounts(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> routes,
  ) {
    final counts = <String, int>{
      'Senderismo': 0,
      'Ciclismo': 0,
      'Running': 0,
    };

    for (final route in routes) {
      final rawActivity = _readRouteActivity(route.data());
      final activity = _normalizeActivity(rawActivity);
      debugPrint(
        'DashboardStatisticsService._buildActivityCounts: route=${route.id} rawActivity=$rawActivity normalized=$activity',
      );
      counts.update(activity, (value) => value + 1);
    }

    return counts;
  }

  String? _readRouteActivity(Map<String, dynamic> data) {
    final directValue = _readFirstString(
      data,
      const [
        'activityProfile',
        'activityType',
        'activity',
        'type',
        'sport',
        'category',
      ],
    );
    if (directValue != null) {
      return directValue;
    }

    final activityProfile = data['activityProfile'];
    if (activityProfile is Map<String, dynamic>) {
      return _readFirstString(
        activityProfile,
        const ['label', 'name', 'type', 'value'],
      );
    }

    return null;
  }

  String _normalizeActivity(String? raw) {
    if (raw == null || raw.trim().isEmpty) {
      return 'Otros';
    }

    final normalized = raw.trim().toLowerCase();
    if (normalized.contains('sender') ||
        normalized.contains('hiking') ||
        normalized.contains('hike')) {
      return 'Senderismo';
    }
    if (normalized.contains('cicl') ||
        normalized.contains('cycling') ||
        normalized.contains('bike') ||
        normalized.contains('bicicleta')) {
      return 'Ciclismo';
    }
    if (normalized.contains('run') ||
        normalized.contains('running') ||
        normalized.contains('correr') ||
        normalized.contains('carrera') ||
        normalized.contains('corr')) {
      return 'Running';
    }
    return 'Otros';
  }

  List<DashboardPieDatum> _buildPieData(Map<String, int> activityCounts) {
    final total = activityCounts.values.fold<int>(
      0,
      (runningTotal, value) => runningTotal + value,
    );
    final safeTotal = total == 0 ? 1 : total;

    return [
      DashboardPieDatum(
        label: 'Senderismo',
        value: _percentage(activityCounts['Senderismo'] ?? 0, safeTotal),
        color: dashboardBrandGreen,
      ),
      DashboardPieDatum(
        label: 'Ciclismo',
        value: _percentage(activityCounts['Ciclismo'] ?? 0, safeTotal),
        color: dashboardSoftGreen,
      ),
      DashboardPieDatum(
        label: 'Running',
        value: _percentage(activityCounts['Running'] ?? 0, safeTotal),
        color: dashboardAccentOrange,
      ),
    ];
  }

  (String, String) _topActivity(Map<String, int> activityCounts) {
    final sorted = activityCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final top = sorted.first;
    return (top.key, '${top.value} rutas');
  }

  String? _latestRouteName(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> publicRoutes,
  ) {
    if (publicRoutes.isEmpty) {
      return null;
    }

    final sorted = [...publicRoutes]
      ..sort((a, b) => _compareByCreatedAt(a.data(), b.data()));

    return _readFirstString(
      sorted.first.data(),
      const ['title', 'name', 'routeName'],
    );
  }

  String? _latestDocumentName(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
    List<String> candidateKeys,
  ) {
    if (docs.isEmpty) {
      return null;
    }

    final sorted = [...docs]
      ..sort((a, b) => _compareByCreatedAt(a.data(), b.data()));
    return _readFirstString(sorted.first.data(), candidateKeys);
  }

  int _compareByCreatedAt(
    Map<String, dynamic> left,
    Map<String, dynamic> right,
  ) {
    final leftDate = _readDateTime(left);
    final rightDate = _readDateTime(right);

    if (leftDate == null && rightDate == null) {
      return 0;
    }
    if (leftDate == null) {
      return 1;
    }
    if (rightDate == null) {
      return -1;
    }
    return rightDate.compareTo(leftDate);
  }

  DateTime? _readDateTime(Map<String, dynamic> data) {
    final candidates = [
      data['createdAt'],
      data['updatedAt'],
      data['timestamp'],
      data['date'],
    ];

    for (final value in candidates) {
      if (value is Timestamp) {
        return value.toDate();
      }
      if (value is DateTime) {
        return value;
      }
      if (value is String) {
        final parsed = DateTime.tryParse(value);
        if (parsed != null) {
          return parsed;
        }
      }
    }

    return null;
  }

  List<DashboardLineDatum> _buildMonthlyTrend({
    required List<QueryDocumentSnapshot<Map<String, dynamic>>> routes,
  }) {
    final now = DateTime.now();
    final months = List<DateTime>.generate(
      6,
      (index) => DateTime(now.year, now.month - (5 - index), 1),
    );

    final counts = <String, double>{
      for (final month in months) _monthKey(month): 0,
    };

    void addCounts(Iterable<QueryDocumentSnapshot<Map<String, dynamic>>> docs) {
      for (final doc in docs) {
        final date = _readDateTime(doc.data());
        if (date == null) {
          continue;
        }
        final key = _monthKey(DateTime(date.year, date.month, 1));
        if (counts.containsKey(key)) {
          counts.update(key, (value) => value + 1);
        }
      }
    }

    addCounts(routes);

    final data = months
        .map(
          (month) => DashboardLineDatum(
            label: _monthLabel(month.month),
            value: counts[_monthKey(month)] ?? 0,
          ),
        )
        .toList();

    if (data.every((item) => item.value == 0)) {
      debugPrint(
        'DashboardStatisticsService._buildMonthlyTrend: no se encontraron timestamps utilizables, devolviendo tendencia plana.',
      );
    }

    return data;
  }

  String _monthKey(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}';

  String _monthLabel(int month) {
    const labels = [
      'Ene',
      'Feb',
      'Mar',
      'Abr',
      'May',
      'Jun',
      'Jul',
      'Ago',
      'Sep',
      'Oct',
      'Nov',
      'Dic',
    ];
    return labels[month - 1];
  }

  double _percentage(int count, int total) {
    return double.parse(((count * 100) / total).toStringAsFixed(0));
  }

  String _buildOperationalInsight({
    required int totalClients,
    required int totalAdmins,
    required int totalPublicRoutes,
  }) {
    if (totalClients == 0 && totalAdmins == 0 && totalPublicRoutes == 0) {
      return 'Sin datos visibles para construir una lectura operativa.';
    }

    if (totalPublicRoutes >= totalClients && totalPublicRoutes > 0) {
      return 'El inventario de rutas públicas ya compite con el volumen de clientes visibles.';
    }

    if (totalClients > totalPublicRoutes) {
      return 'La base de clientes supera el catalogo actual de rutas públicas.';
    }

    return 'La operacion muestra distribucion estable entre cuentas y rutas visibles.';
  }

  String _buildOperationalBadge({
    required int totalClients,
    required int totalAdmins,
    required int totalPublicRoutes,
  }) {
    if (totalClients == 0 && totalAdmins == 0 && totalPublicRoutes == 0) {
      return 'Datos parciales';
    }

    if (totalAdmins == 0) {
      return 'Revisar admins';
    }

    return '$totalAdmins admins activos';
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
}
