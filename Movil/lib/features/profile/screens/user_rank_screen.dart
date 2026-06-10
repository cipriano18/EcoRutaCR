import 'package:flutter/material.dart';
import 'package:ecoruta/features/profile/widgets/rank_timeline_card.dart';

/// Describe un rango desbloqueable según kilómetros acumulados.
class UserRank {
  const UserRank({required this.title, required this.minKm});

  final String title;
  final int minKm;
}

const List<UserRank> userRanks = [
  UserRank(title: 'Iniciado', minKm: 0),
  UserRank(title: 'Explorador', minKm: 10),
  UserRank(title: 'Aventurero', minKm: 25),
  UserRank(title: 'Descubridor', minKm: 50),
  UserRank(title: 'Caminante', minKm: 100),
  UserRank(title: 'Navegante', minKm: 200),
  UserRank(title: 'Senderista', minKm: 350),
  UserRank(title: 'Rider', minKm: 500),
  UserRank(title: 'Travesía', minKm: 750),
  UserRank(title: 'Cartógrafo', minKm: 1000),
  UserRank(title: 'Eco Rider', minKm: 1300),
  UserRank(title: 'Maestro', minKm: 1700),
  UserRank(title: 'Vanguardista', minKm: 2200),
  UserRank(title: 'Elite', minKm: 2800),
  UserRank(title: 'Guardian', minKm: 3500),
  UserRank(title: 'Titan', minKm: 4500),
  UserRank(title: 'Conquistador', minKm: 6000),
  UserRank(title: 'Supremo', minKm: 7500),
  UserRank(title: 'Leyenda Verde', minKm: 9000),
  UserRank(title: 'EcoRuta Legend', minKm: 10000),
];

UserRank getUserRank(num kmCounter) {
  UserRank current = userRanks.first;
  for (final rank in userRanks) {
    if (kmCounter >= rank.minKm) {
      current = rank;
    } else {
      break;
    }
  }
  return current;
}

UserRankPalette getUserRankPalette(num kmCounter) {
  final currentRank = getUserRank(kmCounter);
  final currentIndex = userRanks.indexWhere(
    (rank) => rank.title == currentRank.title,
  );
  final safeIndex = currentIndex < 0 ? 0 : currentIndex;
  final importance = safeIndex / (userRanks.length - 1);

  if (importance >= 0.92) {
    return const UserRankPalette(
      backgroundColor: Color(0xFFFFF2C7),
      borderColor: Color(0xFFD3A300),
      iconColor: Color(0xFF8A6300),
      textColor: Color(0xFF8A6300),
    );
  }
  if (importance >= 0.8) {
    return const UserRankPalette(
      backgroundColor: Color(0xFFFFE1CC),
      borderColor: Color(0xFFDD7A2A),
      iconColor: Color(0xFFA14E0B),
      textColor: Color(0xFFA14E0B),
    );
  }
  if (importance >= 0.65) {
    return const UserRankPalette(
      backgroundColor: Color(0xFFFFD9DE),
      borderColor: Color(0xFFD35A72),
      iconColor: Color(0xFF9E2441),
      textColor: Color(0xFF9E2441),
    );
  }
  if (importance >= 0.45) {
    return const UserRankPalette(
      backgroundColor: Color(0xFFDDF0E9),
      borderColor: Color(0xFF3B8A67),
      iconColor: Color(0xFF1F5C41),
      textColor: Color(0xFF1F5C41),
    );
  }
  if (importance >= 0.25) {
    return const UserRankPalette(
      backgroundColor: Color(0xFFE5EEF7),
      borderColor: Color(0xFF5D86B2),
      iconColor: Color(0xFF36597F),
      textColor: Color(0xFF36597F),
    );
  }
  return const UserRankPalette(
    backgroundColor: Color(0xFFF1F3F4),
    borderColor: Color(0xFFC8CED2),
    iconColor: Color(0xFF6A747A),
    textColor: Color(0xFF6A747A),
  );
}

/// Pantalla que muestra la progresión completa de rangos del usuario.
class UserRankScreen extends StatefulWidget {
  const UserRankScreen({super.key, required this.kmCounter});

  final num kmCounter;

  @override
  State<UserRankScreen> createState() => _UserRankScreenState();
}

class _UserRankScreenState extends State<UserRankScreen> {
  static const _primary = Color(0xFF012D1D);
  static const _surface = Color(0xFFF8F9FA);
  static const _lineColor = Color(0xFFD6DBD8);
  static const _itemExtent = 122.0;

  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    final currentRank = getUserRank(widget.kmCounter);
    final reversedRanks = userRanks.reversed.toList();
    final currentIndex = reversedRanks.indexWhere(
      (rank) => rank.title == currentRank.title,
    );
    final initialOffset = currentIndex <= 0
        ? 0.0
        : (currentIndex * _itemExtent) - 120;
    _scrollController = ScrollController(
      initialScrollOffset: initialOffset < 0 ? 0 : initialOffset,
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentRank = getUserRank(widget.kmCounter);
    final currentPalette = getUserRankPalette(widget.kmCounter);
    final reversedRanks = userRanks.reversed.toList();

    return Scaffold(
      backgroundColor: _surface,
      appBar: AppBar(
        backgroundColor: _surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        foregroundColor: _primary,
        title: const Text(
          'Rangos',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Tu progreso en EcoRuta',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: _primary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Tu titulo actual es ${currentRank.title}. Los rangos más altos están arriba y se desbloquean al sumar más kilómetros.',
                style: const TextStyle(
                  fontSize: 14,
                  height: 1.4,
                  color: Colors.black54,
                ),
              ),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: currentPalette.backgroundColor,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.42),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        Icons.military_tech_rounded,
                        color: currentPalette.iconColor,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            currentRank.title,
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              color: currentPalette.textColor,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${_formatKm(widget.kmCounter)} km acumulados',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: currentPalette.textColor.withValues(
                                alpha: 0.78,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  itemCount: reversedRanks.length,
                  itemExtent: _itemExtent,
                  itemBuilder: (context, index) {
                    final rank = reversedRanks[index];
                    final isCurrent = rank.title == currentRank.title;
                    final isUnlocked = widget.kmCounter >= rank.minKm;
                    final importance = 1 - (index / (reversedRanks.length - 1));

                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SizedBox(
                          width: 42,
                          child: Column(
                            children: [
                              Expanded(
                                child: Container(
                                  width: 3,
                                  color: index == 0
                                      ? Colors.transparent
                                      : _lineColor,
                                ),
                              ),
                              Container(
                                width: 18,
                                height: 18,
                                decoration: BoxDecoration(
                                  color: isCurrent
                                      ? _primary
                                      : isUnlocked
                                      ? const Color(0xFF86AF99)
                                      : Colors.white,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: isCurrent || isUnlocked
                                        ? Colors.transparent
                                        : _lineColor,
                                    width: 2,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Container(
                                  width: 3,
                                  color: index == reversedRanks.length - 1
                                      ? Colors.transparent
                                      : _lineColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: RankTimelineCard(
                            title: rank.title,
                            minKm: rank.minKm,
                            isCurrent: isCurrent,
                            isUnlocked: isUnlocked,
                            importance: importance,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatKm(num value) {
    if (value % 1 == 0) {
      return value.toInt().toString();
    }
    return value.toStringAsFixed(1);
  }
}

/// Agrupa colores e íconos usados para representar un rango.
class UserRankPalette {
  const UserRankPalette({
    required this.backgroundColor,
    required this.borderColor,
    required this.iconColor,
    required this.textColor,
  });

  final Color backgroundColor;
  final Color borderColor;
  final Color iconColor;
  final Color textColor;
}
