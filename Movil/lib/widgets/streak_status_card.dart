import 'package:flutter/material.dart';

/// Tarjeta que comunica el estado actual de la racha semanal.
class StreakStatusCard extends StatelessWidget {
  const StreakStatusCard({super.key, required this.streakWeeks});

  final int streakWeeks;

  @override
  Widget build(BuildContext context) {
    final palette = getStreakPalette(streakWeeks);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: palette.backgroundColor,
        borderRadius: BorderRadius.circular(32),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: SizedBox(
              width: 144,
              height: 144,
              child: Image.asset(
                getStreakFrogAsset(streakWeeks),
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'SEMANAS EN RACHA',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: palette.textColor.withValues(alpha: 0.76),
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.42),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.local_fire_department_rounded,
                  size: 17,
                  color: palette.iconColor,
                ),
                const SizedBox(width: 6),
                Text(
                  streakWeeks.toString(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: palette.textColor,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Para mantener la racha debes completar una ruta a la semana.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: palette.textColor.withValues(alpha: 0.86),
              fontSize: 12,
              height: 1.4,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// Devuelve el recurso visual que representa la racha actual.
String getStreakFrogAsset(int streakWeeks) {
  if (streakWeeks > 0 && streakWeeks <= 20) {
    return 'assets/images/Frogs/frog1.gif';
  }
  if (streakWeeks > 20 && streakWeeks < 50) {
    return 'assets/images/Frogs/frog2.gif';
  }
  if (streakWeeks >= 50) {
    return 'assets/images/Frogs/frog3.gif';
  }
  return 'assets/images/Frogs/frog0.png';
}

StreakPalette getStreakPalette(int streakWeeks) {
  if (streakWeeks > 50) {
    return const StreakPalette(
      backgroundColor: Color(0xFFD7F5F2),
      iconColor: Color(0xFF0F8A83),
      textColor: Color(0xFF0B6F69),
    );
  }
  if (streakWeeks > 20) {
    return const StreakPalette(
      backgroundColor: Color(0xFFFFE2D1),
      iconColor: Color(0xFFCC5A17),
      textColor: Color(0xFF9D3D00),
    );
  }
  if (streakWeeks > 0) {
    return const StreakPalette(
      backgroundColor: Color(0xFFFFF2C7),
      iconColor: Color(0xFFC28A00),
      textColor: Color(0xFF8C6500),
    );
  }
  return const StreakPalette(
    backgroundColor: Color(0xFFF3F4F5),
    iconColor: Colors.grey,
    textColor: Colors.grey,
  );
}

/// Define la paleta asociada a cada tramo de racha semanal.
class StreakPalette {
  const StreakPalette({
    required this.backgroundColor,
    required this.iconColor,
    required this.textColor,
  });

  final Color backgroundColor;
  final Color iconColor;
  final Color textColor;
}
