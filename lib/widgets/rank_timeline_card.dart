import 'package:flutter/material.dart';

/// Tarjeta que resume la progresión de rangos del usuario.
class RankTimelineCard extends StatelessWidget {
  const RankTimelineCard({
    super.key,
    required this.title,
    required this.minKm,
    required this.isCurrent,
    required this.isUnlocked,
    required this.importance,
  });

  final String title;
  final int minKm;
  final bool isCurrent;
  final bool isUnlocked;
  final double importance;

  static const _primary = Color(0xFF012D1D);

  @override
  Widget build(BuildContext context) {
    final palette = _paletteForImportance(importance);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      margin: const EdgeInsets.symmetric(vertical: 10),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: isCurrent ? palette.highlight : Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isCurrent ? palette.border : Colors.transparent,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04 + (importance * 0.02)),
            blurRadius: 12 + (importance * 8),
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: palette.badge,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              isCurrent
                  ? Icons.near_me_rounded
                  : isUnlocked
                  ? Icons.check_circle_rounded
                  : Icons.military_tech_rounded,
              color: isCurrent ? _primary : palette.badgeIcon,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: _primary,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '$minKm km',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: isCurrent ? _primary : Colors.black54,
                    height: 1.1,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  _RankPalette _paletteForImportance(double importance) {
    if (importance >= 0.92) {
      return const _RankPalette(
        highlight: Color(0xFFFFF2C7),
        border: Color(0xFFD3A300),
        badge: Color(0xFFFFD75E),
        badgeIcon: Color(0xFF8A6300),
      );
    }
    if (importance >= 0.8) {
      return const _RankPalette(
        highlight: Color(0xFFFFE1CC),
        border: Color(0xFFDD7A2A),
        badge: Color(0xFFFFB26B),
        badgeIcon: Color(0xFFA14E0B),
      );
    }
    if (importance >= 0.65) {
      return const _RankPalette(
        highlight: Color(0xFFFFD9DE),
        border: Color(0xFFD35A72),
        badge: Color(0xFFFF9BB0),
        badgeIcon: Color(0xFF9E2441),
      );
    }
    if (importance >= 0.45) {
      return const _RankPalette(
        highlight: Color(0xFFDDF0E9),
        border: Color(0xFF3B8A67),
        badge: Color(0xFFA9DEC6),
        badgeIcon: Color(0xFF1F5C41),
      );
    }
    if (importance >= 0.25) {
      return const _RankPalette(
        highlight: Color(0xFFE5EEF7),
        border: Color(0xFF5D86B2),
        badge: Color(0xFFBED7F2),
        badgeIcon: Color(0xFF36597F),
      );
    }
    return const _RankPalette(
      highlight: Color(0xFFF1F3F4),
      border: Color(0xFFC8CED2),
      badge: Color(0xFFE2E7EA),
      badgeIcon: Color(0xFF6A747A),
    );
  }
}

/// Define la apariencia asociada a un nivel de importancia visual.
class _RankPalette {
  const _RankPalette({
    required this.highlight,
    required this.border,
    required this.badge,
    required this.badgeIcon,
  });

  final Color highlight;
  final Color border;
  final Color badge;
  final Color badgeIcon;
}
