/// Define el tipo de actividad para filtrar y calcular rutas compatibles.
enum RouteProfile {
  hiking,
  cycling,
  running;

  /// Valor persistible que se usa en consultas y documentos.
  String get label {
    switch (this) {
      case RouteProfile.hiking:
        return 'hiking';
      case RouteProfile.cycling:
        return 'cycling';
      case RouteProfile.running:
        return 'running';
    }
  }

  /// Valores de `route=*` aceptados para el perfil en Overpass.
  List<String> get routeValues {
    switch (this) {
      case RouteProfile.hiking:
        return const ['hiking', 'foot'];
      case RouteProfile.cycling:
        return const ['bicycle', 'mtb'];
      case RouteProfile.running:
        return const ['running', 'foot', 'jogging'];
    }
  }

  /// Tipos de `highway=*` permitidos para construir el grafo.
  List<String> get highwayValues {
    switch (this) {
      case RouteProfile.hiking:
        return const [
          'path',
          'footway',
          'track',
          'steps',
          'pedestrian',
          'living_street',
          'service',
          'residential',
          'unclassified',
        ];
      case RouteProfile.cycling:
        return const [
          'cycleway',
          'path',
          'track',
          'service',
          'residential',
          'living_street',
          'unclassified',
          'tertiary',
          'secondary',
        ];
      case RouteProfile.running:
        return const [
          'path',
          'footway',
          'track',
          'pedestrian',
          'living_street',
          'service',
          'residential',
          'unclassified',
        ];
    }
  }

  /// Distancia recomendada en línea recta antes de advertir al usuario.
  double get maxRecommendedDistanceKm {
    switch (this) {
      case RouteProfile.hiking:
        return 20;
      case RouteProfile.cycling:
        return 60;
      case RouteProfile.running:
        return 15;
    }
  }
}
