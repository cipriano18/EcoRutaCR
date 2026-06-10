import 'package:flutter/material.dart';

/// Describe un avatar disponible y el progreso requerido para desbloquearlo.
class AvatarOption {
  const AvatarOption({
    required this.id,
    required this.assetPath,
    required this.category,
    this.label = '',
    this.requiredKm = 0,
  });

  /// Identificador persistido en el perfil del usuario.
  final int id;

  /// Ruta local del asset que representa el avatar.
  final String assetPath;

  /// Grupo visual usado para ordenar o filtrar avatares.
  final String category;

  /// Nombre visible opcional, usado especialmente en avatares de rango.
  final String label;

  /// Kilómetros requeridos para desbloquear el avatar.
  final num requiredKm;

  /// Indica si el avatar depende de kilómetros acumulados para desbloquearse.
  bool get isUnlockable => requiredKm > 0;
}

/// Renderiza el avatar actual o una opción específica del catálogo.
///
/// Centraliza el catálogo usado por el perfil y por los selectores de avatar
/// para mantener una sola fuente de rutas de assets y requisitos de progreso.
class AvatarImage extends StatelessWidget {
  const AvatarImage({
    super.key,
    required this.avatarId,
    this.size = 48,
    this.backgroundColor = const Color(0xFFEDEEEF),
    this.iconColor = const Color(0xFF012D1D),
    this.useOvalClip = true,
    this.fit,
  });

  /// Catálogo completo de avatares disponibles en la aplicación.
  static const List<AvatarOption> options = [
    AvatarOption(
      id: 0,
      assetPath: 'assets/images/avatars/icon1.png',
      category: 'Deportistas',
    ),
    AvatarOption(
      id: 1,
      assetPath: 'assets/images/avatars/icon2.png',
      category: 'Deportistas',
    ),
    AvatarOption(
      id: 2,
      assetPath: 'assets/images/avatars/icon3.png',
      category: 'Deportistas',
    ),
    AvatarOption(
      id: 3,
      assetPath: 'assets/images/avatars/icon4.png',
      category: 'Deportistas',
    ),
    AvatarOption(
      id: 4,
      assetPath: 'assets/images/avatars/icon5.png',
      category: 'Deportistas',
    ),
    AvatarOption(
      id: 5,
      assetPath: 'assets/images/avatars/icon6.png',
      category: 'Deportistas',
    ),
    AvatarOption(
      id: 6,
      assetPath: 'assets/images/avatars/icon7.png',
      category: 'Deportistas',
    ),
    AvatarOption(
      id: 7,
      assetPath: 'assets/images/avatars/icon8.png',
      category: 'Mascotas',
    ),
    AvatarOption(
      id: 8,
      assetPath: 'assets/images/avatars/icon9.png',
      category: 'Mascotas',
    ),
    AvatarOption(
      id: 9,
      assetPath: 'assets/images/avatars/icon10.png',
      category: 'Mascotas',
    ),
    AvatarOption(
      id: 10,
      assetPath: 'assets/images/Chonetes/Caminante.png',
      label: 'Caminante',
      category: 'Iconos de rango',
      requiredKm: 100,
    ),
    AvatarOption(
      id: 11,
      assetPath: 'assets/images/Chonetes/Travesia.png',
      label: 'Travesia',
      category: 'Iconos de rango',
      requiredKm: 750,
    ),
    AvatarOption(
      id: 12,
      assetPath: 'assets/images/Chonetes/Vanguardista.png',
      label: 'Vanguardista',
      category: 'Iconos de rango',
      requiredKm: 2200,
    ),
    AvatarOption(
      id: 13,
      assetPath: 'assets/images/Chonetes/Titan.gif',
      label: 'Titan',
      category: 'Iconos de rango',
      requiredKm: 4500,
    ),
    AvatarOption(
      id: 14,
      assetPath: 'assets/images/Chonetes/Supremo.gif',
      label: 'Supremo',
      category: 'Iconos de rango',
      requiredKm: 7500,
    ),
    AvatarOption(
      id: 15,
      assetPath: 'assets/images/Chonetes/Legend.gif',
      label: 'Legend',
      category: 'Iconos de rango',
      requiredKm: 10000,
    ),
  ];

  /// Cantidad de avatares base que no dependen del rango del usuario.
  static const int avatarCount = 10;

  /// Cantidad total de avatares registrados, incluidos los desbloqueables.
  static int get totalAvatarCount => options.length;

  /// Busca la opción asociada a [avatarId].
  ///
  /// Si el identificador no existe, retorna el primer avatar para evitar
  /// fallos visuales en perfiles con datos antiguos o incompletos.
  static AvatarOption optionFor(int avatarId) {
    return options.firstWhere(
      (option) => option.id == avatarId,
      orElse: () => options.first,
    );
  }

  /// Retorna la ruta del asset correspondiente a [avatarId].
  static String assetPathFor(int avatarId) {
    return optionFor(avatarId).assetPath;
  }

  /// Valida si [avatarId] pertenece al catálogo actual.
  static bool isValidAvatarId(int avatarId) {
    return options.any((option) => option.id == avatarId);
  }

  /// Indica si [totalKilometers] desbloquea el avatar indicado por [avatarId].
  static bool isUnlockedForKm(int avatarId, num totalKilometers) {
    return totalKilometers >= optionFor(avatarId).requiredKm;
  }

  /// Identificador del avatar que se debe renderizar.
  final int avatarId;

  /// Tamaño cuadrado del contenedor visual del avatar.
  final double size;

  /// Color de fondo usado detrás del asset.
  final Color backgroundColor;

  /// Color del ícono de respaldo cuando el asset no carga.
  final Color iconColor;

  /// Define si el avatar se recorta con forma ovalada.
  final bool useOvalClip;

  /// Ajuste opcional de imagen; si no se define, se elige según el recorte.
  final BoxFit? fit;

  @override
  Widget build(BuildContext context) {
    final image = Container(
      width: size,
      height: size,
      color: backgroundColor,
      child: Image.asset(
        assetPathFor(avatarId),
        fit: fit ?? (useOvalClip ? BoxFit.cover : BoxFit.contain),
        errorBuilder: (context, error, stackTrace) {
          return Icon(
            Icons.person_rounded,
            size: size * 0.52,
            color: iconColor,
          );
        },
      ),
    );

    if (!useOvalClip) return image;

    return ClipOval(child: image);
  }
}
