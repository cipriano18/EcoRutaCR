import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Representa una provincia de Costa Rica junto
/// con la lista de cantones y distritos disponibles.
@immutable
class ProvinceLocationData {
  const ProvinceLocationData({
    required this.name,
    required this.cantonDistricts,
  });

  /// Reconstruye una provincia desde un objeto JSON.
  factory ProvinceLocationData.fromJson(Map<String, dynamic> json) {
    return ProvinceLocationData(
      name: json['name'] as String,
      cantonDistricts: (json['cantonDistricts'] as List<dynamic>)
          .map(
            (item) =>
                CantonDistrictOption.fromJson(item as Map<String, dynamic>),
          )
          .toList(growable: false),
    );
  }

  /// Nombre oficial de la provincia.
  final String name;

  /// Lista de cantones y distritos asociados a la provincia.
  final List<CantonDistrictOption> cantonDistricts;
}

/// Representa una combinación válida de cantón y distrito.
@immutable
class CantonDistrictOption {
  const CantonDistrictOption({
    required this.canton,
    required this.district,
  });

  /// Reconstruye una opción de ubicación desde JSON.
  factory CantonDistrictOption.fromJson(Map<String, dynamic> json) {
    return CantonDistrictOption(
      canton: json['canton'] as String,
      district: json['district'] as String,
    );
  }

  /// Nombre del cantón.
  final String canton;

  /// Nombre del distrito.
  final String district;

  /// Etiqueta amigable usada en listas desplegables.
  String get displayLabel => '$canton - $district';

  /// Construye una dirección legible para almacenamiento.
  String toStoredAddress(String province) {
    return '$province, $canton, $district';
  }
}

/// Repositorio singleton encargado de cargar
/// las ubicaciones de Costa Rica desde assets.
class CostaRicaLocationsRepository {
  CostaRicaLocationsRepository._();

  /// Instancia global reutilizable del repositorio.
  static final CostaRicaLocationsRepository instance =
      CostaRicaLocationsRepository._();

  /// Ruta del archivo JSON dentro de assets.
  static const _assetPath = 'assets/data/costa_rica_locations.json';

  /// Datos cargados en memoria.
  List<ProvinceLocationData> _locations = const [];

  /// Future reutilizado para evitar cargas duplicadas.
  Future<void>? _loadingFuture;

  /// Lista de provincias actualmente cargadas.
  List<ProvinceLocationData> get locations => _locations;

  /// Indica si las ubicaciones ya fueron cargadas.
  bool get isLoaded => _locations.isNotEmpty;

  /// Precarga el archivo JSON solo una vez.
  Future<void> preload() {
    return _loadingFuture ??= _load();
  }

  /// Lee y transforma el archivo JSON en entidades tipadas.
  Future<void> _load() async {
    final rawJson = await rootBundle.loadString(_assetPath);

    final decoded = jsonDecode(rawJson) as List<dynamic>;

    _locations = decoded
        .map(
          (item) => ProvinceLocationData.fromJson(
            item as Map<String, dynamic>,
          ),
        )
        .toList(growable: false);
  }
}

/// Acceso rápido global a las ubicaciones precargadas.
List<ProvinceLocationData> get costaRicaLocations =>
    CostaRicaLocationsRepository.instance.locations;