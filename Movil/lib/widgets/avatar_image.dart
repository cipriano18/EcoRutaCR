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

  final int id;
  final String assetPath;
  final String category;
  final String label;
  final num requiredKm;

  bool get isUnlockable => requiredKm > 0;
}

/// Renderiza el avatar actual o una opción específica del catálogo.
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

  static const int avatarCount = 10;
  static int get totalAvatarCount => options.length;

  static AvatarOption optionFor(int avatarId) {
    return options.firstWhere(
      (option) => option.id == avatarId,
      orElse: () => options.first,
    );
  }

  static String assetPathFor(int avatarId) {
    return optionFor(avatarId).assetPath;
  }

  static bool isValidAvatarId(int avatarId) {
    return options.any((option) => option.id == avatarId);
  }

  static bool isUnlockedForKm(int avatarId, num totalKilometers) {
    return totalKilometers >= optionFor(avatarId).requiredKm;
  }

  final int avatarId;
  final double size;
  final Color backgroundColor;
  final Color iconColor;
  final bool useOvalClip;
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
