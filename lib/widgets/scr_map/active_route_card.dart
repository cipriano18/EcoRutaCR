import 'dart:async';

import 'package:flutter/material.dart';

/// Tarjeta de sesión activa para controlar una ruta en curso.
class ActiveRouteCard extends StatefulWidget {
  final String routeName;
  final VoidCallback? onPause;
  final VoidCallback? onResume;
  final VoidCallback? onCancel;
  final VoidCallback? onFinish;

  const ActiveRouteCard({
    super.key,
    required this.routeName,
    this.onPause,
    this.onResume,
    this.onCancel,
    this.onFinish,
  });

  @override
  State<ActiveRouteCard> createState() => _ActiveRouteCardState();
}

class _ActiveRouteCardState extends State<ActiveRouteCard> {
  static const _primaryColor = Color(0xFF012D1D);

  final Stopwatch _activeStopwatch = Stopwatch();
  Timer? _ticker;
  bool _isPaused = false;
  Duration _elapsed = Duration.zero;

  @override
  void initState() {
    super.initState();
    _activeStopwatch.start();
    _elapsed = _activeStopwatch.elapsed;
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || _isPaused) return;
      setState(() {
        _elapsed = _activeStopwatch.elapsed;
      });
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  /// Alterna el estado de pausa sin reiniciar el tiempo acumulado.
  void _togglePauseResume() {
    setState(() {
      _isPaused = !_isPaused;
      if (_isPaused) {
        _activeStopwatch.stop();
      } else {
        _activeStopwatch.start();
      }
      _elapsed = _activeStopwatch.elapsed;
    });

    if (_isPaused) {
      widget.onPause?.call();
    } else {
      widget.onResume?.call();
    }
  }

  /// Cancela la sesión actual y notifica al contenedor padre.
  void _cancelRoute() {
    _activeStopwatch.stop();
    widget.onCancel?.call();
  }

  /// Finaliza la sesión activa y entrega el tiempo transcurrido.
  void _finishRoute() {
    _activeStopwatch.stop();
    widget.onFinish?.call();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 40,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: _isPaused ? Colors.orange : Colors.green,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                _isPaused ? 'SESIÓN EN PAUSA' : 'SESIÓN EN VIVO',
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  color: _isPaused ? Colors.orange : Colors.green,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            widget.routeName,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: _primaryColor,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: ActiveRouteMetric(
                  icon: Icons.schedule_rounded,
                  value: _formatElapsedTime(),
                  label: 'Tiempo transcurrido',
                  isPaused: _isPaused,
                ),
              ),
              const SizedBox(width: 14),
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  GestureDetector(
                    onTap: _finishRoute,
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.green.shade200),
                      ),
                      child: Icon(
                        Icons.flag_rounded,
                        color: Colors.green.shade700,
                        size: 22,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_isPaused) ...[
                        GestureDetector(
                          onTap: _cancelRoute,
                          child: Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.red.shade200),
                            ),
                            child: Icon(
                              Icons.close_rounded,
                              color: Colors.red.shade700,
                              size: 22,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                      ],
                      GestureDetector(
                        onTap: _togglePauseResume,
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: const BoxDecoration(
                            color: _primaryColor,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            _isPaused
                                ? Icons.play_arrow_rounded
                                : Icons.pause_rounded,
                            color: Colors.white,
                            size: 22,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatElapsedTime() {
    final totalSeconds = _elapsed.inSeconds;
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    final seconds = totalSeconds % 60;

    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}

/// Métrica compacta usada dentro de la tarjeta de ruta activa.
class ActiveRouteMetric extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final bool isPaused;

  const ActiveRouteMetric({
    super.key,
    required this.icon,
    required this.value,
    required this.label,
    required this.isPaused,
  });

  @override
  Widget build(BuildContext context) {
    final accentColor = isPaused
        ? Colors.orange.shade700
        : Colors.green.shade700;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: accentColor.withOpacity(0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: accentColor.withOpacity(0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: accentColor.withOpacity(0.14),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: accentColor, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label.toUpperCase(),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: accentColor,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF191C1D),
                    letterSpacing: -0.8,
                    height: 1,
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
