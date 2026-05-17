import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../screens/dashboard/shared/dashboard_mock_ui.dart';

class DashboardLiveReportPayload {
  const DashboardLiveReportPayload({
    required this.metrics,
    required this.rows,
    required this.timeline,
    required this.highlights,
  });

  final List<DashboardMetricData> metrics;
  final List<DashboardLiveReportRow> rows;
  final List<DashboardActivityItem> timeline;
  final List<DashboardLiveReportHighlight> highlights;
}

class DashboardLiveReportRow {
  const DashboardLiveReportRow({
    required this.primary,
    required this.secondary,
    required this.detail,
    required this.status,
    required this.activity,
    required this.actionLabel,
  });

  final String primary;
  final String secondary;
  final String detail;
  final String status;
  final String activity;
  final String actionLabel;
}

class DashboardLiveReportHighlight {
  const DashboardLiveReportHighlight({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;
}

class DashboardReportsService {
  DashboardReportsService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  Future<DashboardLiveReportPayload> loadUsersReport() async {
    debugPrint(
      'DashboardReportsService.loadUsersReport: leyendo coleccion users.',
    );

    try {
      final snapshot = await _firestore.collection('users').get();
      final docs = snapshot.docs;
      final now = DateTime.now();

      final totalUsers = docs.length;
      final recentUsers = docs
          .where((doc) => _isWithinDays(_readDate(doc.data(), 'createdAt'), 7, now))
          .length;

      final currentMonth = docs
          .where((doc) => _isSameMonth(_readDate(doc.data(), 'createdAt'), now))
          .length;
      final previousMonthDate = DateTime(now.year, now.month - 1, 1);
      final previousMonth = docs
          .where(
            (doc) => _isSameMonth(
              _readDate(doc.data(), 'createdAt'),
              previousMonthDate,
            ),
          )
          .length;

      final growth = _formatGrowth(currentMonth, previousMonth);
      final sortedDocs = [...docs]..sort((a, b) => _compareByCreatedAt(a.data(), b.data()));
      final rows = sortedDocs
          .map((doc) => _buildUserRow(doc, now))
          .toList();

      final favoriteActivity = _mostCommonValue(
        docs.map(
          (doc) => _readFirstString(doc.data(), const ['favoriteActivity']),
        ),
      );
      final region = _mostCommonRegion(docs);
      final latestName = rows.isNotEmpty ? rows.first.primary : 'Sin registros';

      debugPrint(
        'DashboardReportsService.loadUsersReport: total=$totalUsers recent7d=$recentUsers currentMonth=$currentMonth previousMonth=$previousMonth',
      );

      return DashboardLiveReportPayload(
        metrics: [
          DashboardMetricData(
            title: 'Total de registros',
            value: '$totalUsers',
            icon: Icons.people_alt_outlined,
            accentColor: dashboardBrandGreen,
          ),
          DashboardMetricData(
            title: 'Usuarios activos',
            value: '-',
            changeLabel: 'Pendiente definir criterio real',
            icon: Icons.person_search_outlined,
            accentColor: dashboardSoftGreen,
          ),
          DashboardMetricData(
            title: 'Crecimiento mensual',
            value: growth,
            changeLabel: '$currentMonth altas este mes',
            icon: Icons.trending_up_rounded,
            accentColor: dashboardAccentOrange,
          ),
          DashboardMetricData(
            title: 'Ultimos registros',
            value: '$recentUsers',
            changeLabel: 'Ultimos 7 dias',
            icon: Icons.schedule_outlined,
            accentColor: dashboardSupportGreen,
          ),
        ],
        rows: rows,
        timeline: _buildUsersTimeline(rows, favoriteActivity),
        highlights: [
          DashboardLiveReportHighlight(
            label: 'Region mas activa',
            value: region ?? 'Sin direccion visible',
            color: dashboardSoftGreen,
          ),
          DashboardLiveReportHighlight(
            label: 'Perfil mas comun',
            value: favoriteActivity ?? 'Sin actividad favorita',
            color: dashboardBrandGreen,
          ),
          DashboardLiveReportHighlight(
            label: 'Registro mas reciente',
            value: latestName,
            color: dashboardAccentOrange,
          ),
        ],
      );
    } catch (error, stackTrace) {
      debugPrint('DashboardReportsService.loadUsersReport error: $error');
      debugPrint('$stackTrace');
      rethrow;
    }
  }

  Future<DashboardLiveReportPayload> loadPublicRoutesReport() async {
    debugPrint(
      'DashboardReportsService.loadPublicRoutesReport: leyendo coleccion routes.',
    );

    try {
      final snapshot = await _firestore.collection('routes').get();
      final publicDocs = snapshot.docs
          .where((doc) => _isPublicRoute(doc.data()))
          .toList()
        ..sort((a, b) => _compareByCreatedAt(a.data(), b.data()));

      final rows = publicDocs.map((doc) => _buildRouteRow(doc)).toList();
      final totalRoutes = publicDocs.length;
      final cyclingRoutes = publicDocs
          .where((doc) => _routeActivityLabel(doc.data()) == 'Ciclismo')
          .length;
      final hikingRoutes = publicDocs
          .where((doc) => _routeActivityLabel(doc.data()) == 'Senderismo')
          .length;
      final runningRoutes = publicDocs
          .where((doc) => _routeActivityLabel(doc.data()) == 'Running')
          .length;
      final longestRoute = _longestRouteName(publicDocs);
      final averageCoverage = _averageDistance(publicDocs);

      debugPrint(
        'DashboardReportsService.loadPublicRoutesReport: total=$totalRoutes cycling=$cyclingRoutes hiking=$hikingRoutes running=$runningRoutes',
      );

      return DashboardLiveReportPayload(
        metrics: [
          DashboardMetricData(
            title: 'Rutas registradas',
            value: '$totalRoutes',
            icon: Icons.route_outlined,
            accentColor: dashboardBrandGreen,
          ),
          DashboardMetricData(
            title: 'Ciclismo',
            value: '$cyclingRoutes',
            icon: Icons.directions_bike_outlined,
            accentColor: dashboardSoftGreen,
          ),
          DashboardMetricData(
            title: 'Senderismo',
            value: '$hikingRoutes',
            icon: Icons.hiking_outlined,
            accentColor: dashboardAccentOrange,
          ),
          DashboardMetricData(
            title: 'Running',
            value: '$runningRoutes',
            icon: Icons.directions_run_rounded,
            accentColor: dashboardSupportGreen,
          ),
        ],
        rows: rows,
        timeline: _buildRoutesTimeline(rows),
        highlights: [
          DashboardLiveReportHighlight(
            label: 'Ruta con mas km',
            value: longestRoute ?? 'Sin distancias visibles',
            color: dashboardSoftGreen,
          ),
          DashboardLiveReportHighlight(
            label: 'Cobertura media',
            value: averageCoverage,
            color: dashboardBrandGreen,
          ),
        ],
      );
    } catch (error, stackTrace) {
      debugPrint('DashboardReportsService.loadPublicRoutesReport error: $error');
      debugPrint('$stackTrace');
      rethrow;
    }
  }

  DashboardLiveReportRow _buildUserRow(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
    DateTime now,
  ) {
    final data = doc.data();
    final createdAt = _readDate(data, 'createdAt');
    final name = _readFirstString(data, const ['fullName', 'name']) ?? 'Usuario sin nombre';
    final email = _readFirstString(data, const ['email']) ?? 'Correo no disponible';
    final favoriteActivity =
        _readFirstString(data, const ['favoriteActivity']) ?? 'Sin actividad favorita';

    return DashboardLiveReportRow(
      primary: name,
      secondary: email,
      detail: favoriteActivity,
      status: '',
      activity: _relativeTime(createdAt, now),
      actionLabel: 'Ver perfil',
    );
  }

  DashboardLiveReportRow _buildRouteRow(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    final createdAt = _readDate(data, 'createdAt');
    final title =
        _readFirstString(data, const ['title', 'name', 'routeName']) ??
        'Ruta sin titulo';
    final zone = _routeZoneLabel(data);
    final detail = _routeActivityLabel(data);

    return DashboardLiveReportRow(
      primary: title,
      secondary: zone,
      detail: detail,
      status: '',
      activity: _relativeTime(createdAt, DateTime.now()),
      actionLabel: 'Ver detalle',
    );
  }

  List<DashboardActivityItem> _buildUsersTimeline(
    List<DashboardLiveReportRow> rows,
    String? favoriteActivity,
  ) {
    final items = <DashboardActivityItem>[];

    if (rows.isNotEmpty) {
      items.add(
        DashboardActivityItem(
          title: 'Usuario reciente detectado',
          detail: '${rows.first.primary} aparece como registro reciente en users.',
          timeLabel: rows.first.activity,
          icon: Icons.person_add_alt_1_outlined,
          accentColor: dashboardSoftGreen,
        ),
      );
    }

    items.add(
      DashboardActivityItem(
        title: 'Lectura de preferencia',
        detail: favoriteActivity != null
            ? 'La actividad favorita mas visible es $favoriteActivity.'
            : 'Aun no hay actividad favorita consistente en users.',
        timeLabel: 'Coleccion users',
        icon: Icons.query_stats_outlined,
        accentColor: dashboardBrandGreen,
      ),
    );

    return items;
  }

  List<DashboardActivityItem> _buildRoutesTimeline(
    List<DashboardLiveReportRow> rows,
  ) {
    if (rows.isEmpty) {
      return const [
        DashboardActivityItem(
          title: 'Sin rutas públicas recientes',
          detail: 'Aun no hay actividad reciente visible para este reporte.',
          timeLabel: 'Sin datos',
          icon: Icons.route_outlined,
          accentColor: dashboardSupportGreen,
        ),
      ];
    }

    return [
      DashboardActivityItem(
        title: 'Ruta publica reciente',
        detail:
            '${rows.first.primary} figura entre las rutas públicas mas recientes.',
        timeLabel: rows.first.activity,
        icon: Icons.location_on_outlined,
        accentColor: dashboardSoftGreen,
      ),
    ];
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

  String _routeActivityLabel(Map<String, dynamic> data) {
    final raw = _readFirstString(
      data,
      const ['activityProfile', 'activityType', 'activity', 'type'],
    );

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
        normalized.contains('correr') ||
        normalized.contains('carrera') ||
        normalized.contains('corr')) {
      return 'Running';
    }
    return 'Otros';
  }

  String _routeZoneLabel(Map<String, dynamic> data) {
    final start = _readNestedLabel(data['start']);
    final end = _readNestedLabel(data['end']);

    if (start != null && end != null) {
      return '$start -> $end';
    }
    return start ?? end ?? 'Zona no disponible';
  }

  String? _longestRouteName(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    if (docs.isEmpty) {
      return null;
    }

    final sorted = [...docs]
      ..sort(
        (a, b) => (_readNum(b.data()['totalDistanceMeters']) ?? 0).compareTo(
          _readNum(a.data()['totalDistanceMeters']) ?? 0,
        ),
      );

    return _readFirstString(
      sorted.first.data(),
      const ['title', 'name', 'routeName'],
    );
  }

  String _averageDistance(List<QueryDocumentSnapshot<Map<String, dynamic>>> docs) {
    if (docs.isEmpty) {
      return '0.0 km';
    }
    final totalMeters = docs.fold<num>(
      0,
      (runningMeters, doc) =>
          runningMeters + (_readNum(doc.data()['totalDistanceMeters']) ?? 0),
    );
    final averageMeters = totalMeters / docs.length;
    return _formatDistance(averageMeters);
  }

  int _compareByCreatedAt(
    Map<String, dynamic> left,
    Map<String, dynamic> right,
  ) {
    final leftDate = _readDate(left, 'createdAt');
    final rightDate = _readDate(right, 'createdAt');

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

  bool _isWithinDays(DateTime? date, int days, DateTime now) {
    if (date == null) {
      return false;
    }
    return now.difference(date).inDays <= days;
  }

  bool _isSameMonth(DateTime? date, DateTime reference) {
    if (date == null) {
      return false;
    }
    return date.year == reference.year && date.month == reference.month;
  }

  String _formatGrowth(int currentMonth, int previousMonth) {
    if (currentMonth == 0 && previousMonth == 0) {
      return '0%';
    }
    if (previousMonth == 0) {
      return currentMonth > 0 ? '100%' : '0%';
    }
    final growth = ((currentMonth - previousMonth) / previousMonth) * 100;
    return '${growth.toStringAsFixed(1)}%';
  }

  String _relativeTime(DateTime? date, DateTime now) {
    if (date == null) {
      return 'Sin fecha';
    }

    final difference = now.difference(date);
    if (difference.inMinutes < 1) {
      return 'Hace instantes';
    }
    if (difference.inMinutes < 60) {
      return 'Hace ${difference.inMinutes} min';
    }
    if (difference.inHours < 24) {
      return 'Hace ${difference.inHours} h';
    }
    return 'Hace ${difference.inDays} dias';
  }

  String _formatDistance(num meters) {
    final km = meters / 1000;
    return '${km.toStringAsFixed(1)} km';
  }

  String? _mostCommonRegion(List<QueryDocumentSnapshot<Map<String, dynamic>>> docs) {
    final values = docs.map((doc) {
      final address = _readFirstString(doc.data(), const ['address']);
      if (address == null || address.trim().isEmpty) {
        return null;
      }
      return address.split(',').first.trim();
    });
    return _mostCommonValue(values);
  }

  String? _mostCommonValue(Iterable<String?> values) {
    final frequency = <String, int>{};

    for (final value in values) {
      if (value == null || value.trim().isEmpty) {
        continue;
      }
      final trimmed = value.trim();
      frequency.update(trimmed, (currentValue) => currentValue + 1, ifAbsent: () => 1);
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

  String? _readNestedLabel(dynamic value) {
    if (value is Map<String, dynamic>) {
      final label = value['label'];
      if (label is String && label.trim().isNotEmpty) {
        return label.trim();
      }
    }
    return null;
  }

  num? _readNum(dynamic value) {
    if (value is num) {
      return value;
    }
    return null;
  }

  DateTime? _readDate(Map<String, dynamic> data, String key) {
    final value = data[key];
    if (value is Timestamp) {
      return value.toDate();
    }
    if (value is DateTime) {
      return value;
    }
    if (value is String) {
      return DateTime.tryParse(value);
    }
    return null;
  }
}
