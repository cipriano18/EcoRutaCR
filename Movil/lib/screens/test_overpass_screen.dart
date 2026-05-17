import 'package:ecoruta/models/route_profile.dart';
import 'package:ecoruta/providers/explore_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Pantalla de prueba rápida para validar consultas y perfiles de routing.
class TestOverpassRouteScreen extends StatelessWidget {
  const TestOverpassRouteScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ExploreProvider(),
      child: const _TestOverpassRouteView(),
    );
  }
}

/// Representa un punto de prueba fijo usado en la pantalla experimental.
class _Place {
  const _Place(this.name, this.lat, this.lon);

  final String name;
  final double lat;
  final double lon;
}

/// Vista de pruebas que ejecuta consultas y renderiza resultados básicos.
class _TestOverpassRouteView extends StatefulWidget {
  const _TestOverpassRouteView();

  @override
  State<_TestOverpassRouteView> createState() => _TestOverpassRouteViewState();
}

class _TestOverpassRouteViewState extends State<_TestOverpassRouteView> {
  static const primary = Color(0xFF012D1D);
  static const orange = Color(0xFFFF7043);

  final List<_Place> places = const [
    _Place('San José Centro', 9.9325, -84.0796),
    _Place('Heredia Centro', 9.9981, -84.1165),
    _Place('Alajuela Centro', 10.0032, -84.2231),
    _Place('Cartago Centro', 9.8644, -83.9194),
    _Place('Volcán Poás', 10.1986, -84.2308),
    _Place('Tres Ríos', 9.9064, -83.9876),
  ];

  late _Place startPlace;
  late _Place endPlace;
  RouteProfile selectedProfile = RouteProfile.hiking;

  @override
  void initState() {
    super.initState();
    startPlace = places[0];
    endPlace = places[1];
  }

  /// Ejecuta una consulta de rutas con los parámetros de prueba seleccionados.
  Future<void> calculateRoutes() async {
    final provider = context.read<ExploreProvider>();

    final south = _min(startPlace.lat, endPlace.lat) - 0.025;
    final north = _max(startPlace.lat, endPlace.lat) + 0.025;
    final west = _min(startPlace.lon, endPlace.lon) - 0.025;
    final east = _max(startPlace.lon, endPlace.lon) + 0.025;

    await provider.loadRoutesInBoundingBox(
      south: south,
      west: west,
      north: north,
      east: east,
      profile: selectedProfile,
    );
  }

  double _min(double a, double b) => a < b ? a : b;
  double _max(double a, double b) => a > b ? a : b;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ExploreProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('Universo de rutas'),
        backgroundColor: Colors.transparent,
        foregroundColor: primary,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Text(
            'Selecciona inicio, destino y tipo de actividad',
            style: TextStyle(
              fontSize: 25,
              fontWeight: FontWeight.w900,
              color: primary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'La consulta busca caminos reales de OpenStreetMap dentro del área entre ambos puntos.',
            style: TextStyle(color: Colors.black54),
          ),
          const SizedBox(height: 24),

          _placeDropdown(
            title: 'Inicio',
            value: startPlace,
            onChanged: (value) {
              if (value != null) setState(() => startPlace = value);
            },
          ),
          const SizedBox(height: 14),

          _placeDropdown(
            title: 'Destino',
            value: endPlace,
            onChanged: (value) {
              if (value != null) setState(() => endPlace = value);
            },
          ),
          const SizedBox(height: 14),

          _profileSelector(),
          const SizedBox(height: 22),

          SizedBox(
            height: 56,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: orange,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
              onPressed: provider.isLoading ? null : calculateRoutes,
              icon: const Icon(Icons.route),
              label: const Text(
                'Calcular rutas disponibles',
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
          ),

          const SizedBox(height: 24),

          if (provider.isLoading)
            const Center(child: CircularProgressIndicator()),

          if (provider.errorMessage != null)
            _resultCard(
              title: 'Error',
              value: provider.errorMessage!,
              icon: Icons.error_outline,
              color: Colors.red,
            ),

          if (!provider.isLoading && provider.errorMessage == null) ...[
            _resultCard(
              title: 'Perfil',
              value: selectedProfile == RouteProfile.hiking
                  ? 'Senderismo'
                  : 'Ciclismo',
              icon: selectedProfile == RouteProfile.hiking
                  ? Icons.hiking
                  : Icons.directions_bike,
            ),
            _resultCard(
              title: 'Nodos encontrados',
              value: provider.nodes.length.toString(),
              icon: Icons.location_on,
            ),
            _resultCard(
              title: 'Segmentos disponibles',
              value: provider.edges.length.toString(),
              icon: Icons.alt_route,
            ),
            _resultCard(
              title: 'Ways / rutas base recibidas',
              value: provider.rawWays.length.toString(),
              icon: Icons.map,
            ),
          ],

          const SizedBox(height: 20),
          const Text(
            'Rutas disponibles',
            style: TextStyle(
              fontSize: 21,
              fontWeight: FontWeight.w900,
              color: primary,
            ),
          ),
          const SizedBox(height: 12),

          ...provider.rawWays.take(30).map((way) {
            final tags = way['tags'];
            final name = tags is Map && tags['name'] != null
                ? tags['name'].toString()
                : 'Ruta sin nombre';

            final highway = tags is Map && tags['highway'] != null
                ? tags['highway'].toString()
                : 'sin tipo';

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                leading: Icon(
                  selectedProfile == RouteProfile.hiking
                      ? Icons.hiking
                      : Icons.directions_bike,
                  color: primary,
                ),
                title: Text(
                  name,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                subtitle: Text('Tipo: $highway\nWay ID: ${way['id']}'),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _placeDropdown({
    required String title,
    required _Place value,
    required ValueChanged<_Place?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title.toUpperCase(),
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.2,
            color: primary,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<_Place>(
          value: value,
          decoration: InputDecoration(
            filled: true,
            fillColor: const Color(0xFFEDEEEF),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: BorderSide.none,
            ),
          ),
          items: places.map((place) {
            return DropdownMenuItem(value: place, child: Text(place.name));
          }).toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _profileSelector() {
    return Row(
      children: [
        Expanded(
          child: _profileButton(
            text: 'Senderismo',
            icon: Icons.hiking,
            selected: selectedProfile == RouteProfile.hiking,
            onTap: () {
              setState(() => selectedProfile = RouteProfile.hiking);
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _profileButton(
            text: 'Ciclismo',
            icon: Icons.directions_bike,
            selected: selectedProfile == RouteProfile.cycling,
            onTap: () {
              setState(() => selectedProfile = RouteProfile.cycling);
            },
          ),
        ),
      ],
    );
  }

  Widget _profileButton({
    required String text,
    required IconData icon,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: selected ? primary : const Color(0xFFEDEEEF),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          children: [
            Icon(icon, color: selected ? Colors.white : primary),
            const SizedBox(height: 6),
            Text(
              text,
              style: TextStyle(
                color: selected ? Colors.white : primary,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _resultCard({
    required String title,
    required String value,
    required IconData icon,
    Color color = primary,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: Colors.black45,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
