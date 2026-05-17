import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late VideoPlayerController _videoController;

  static const _primaryColor = Color(0xFF012D1D);
  static const _orangeColor = Color(0xFFFF7043);
  static const _primaryFixed = Color(0xFFC1ECD4);
  static const _primaryFixedDim = Color(0xFFA5D0B9);
  static const _orangeShadow = Color(0x66FF7043);

  @override
  void initState() {
    super.initState();
    _videoController = VideoPlayerController.asset('assets/videos/welcome.mp4')
      ..initialize().then((_) {
        _videoController.setLooping(true);
        _videoController.setVolume(0);
        _videoController.play();
        setState(() {});
      });
  }

  @override
  void dispose() {
    _videoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _primaryColor,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ── Video de fondo ──────────────────────────────────────────
          if (_videoController.value.isInitialized)
            FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: _videoController.value.size.width,
                height: _videoController.value.size.height,
                child: VideoPlayer(_videoController),
              ),
            )
          else
            SizedBox.expand(
              child: Image.asset(
                'assets/images/welcome.png',
                fit: BoxFit.cover,
              ),
            ),
          // ── Contenido ───────────────────────────────────────────────
          SafeArea(
            child: Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 24,
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.terrain, color: _primaryFixed, size: 28),
                      const SizedBox(width: 8),
                      const Text(
                        'EcoRuta',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ],
                  ),
                ),

                const Spacer(),

                // Bloque principal (parte inferior como en el diseño)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Subtítulo pequeño
                      Text(
                        'ÚNETE A LA EXPEDICIÓN',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: const Color.fromARGB(
                            255,
                            231,
                            163,
                            73,
                          ).withOpacity(0.9),
                          letterSpacing: 3,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Título
                      const Text(
                        'Bienvenido a EcoRuta',
                        style: TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          height: 1.15,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Descripción
                      Text(
                        'Conecta con la naturaleza de Costa Rica a través de rutas inteligentes con IA. Crea recorridos personalizados, explora nuevos caminos y comparte tus aventuras con la comunidad.',
                        style: TextStyle(
                          fontSize: 15,
                          color: _primaryFixedDim.withOpacity(0.9),
                          height: 1.6,
                        ),
                      ),
                      const SizedBox(height: 28),

                      // Tarjetas bento
                      Row(
                        children: [
                          Expanded(
                            child: _BentoCard(
                              icon: Icons.psychology_rounded,
                              iconColor: _orangeColor,
                              label: 'IA',
                              title: 'Rutas Inteligentes',
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: _BentoCard(
                              icon: Icons.groups_rounded,
                              iconColor: _primaryFixed,
                              label: 'COMUNIDAD',
                              title: 'Comparte y Descubre',
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 28),

                      // Botón primario — Iniciar sesión
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _orangeColor,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shadowColor: _orangeShadow,
                            shape: const StadiumBorder(),
                          ),
                          onPressed: () =>
                              Navigator.pushNamed(context, '/login'),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Text(
                                'Iniciar Sesión',
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.2,
                                ),
                              ),
                              SizedBox(width: 8),
                              Icon(Icons.arrow_forward_rounded, size: 20),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Botón secundario — Registrarse
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: BorderSide(
                              color: Colors.white.withOpacity(0.3),
                            ),
                            shape: const StadiumBorder(),
                            backgroundColor: Colors.white.withOpacity(0.1),
                          ),
                          onPressed: () =>
                              Navigator.pushNamed(context, '/register'),
                          child: const Text(
                            'Registrarse',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                    ],
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

// ── Widget tarjeta bento ─────────────────────────────────────────────────────
/// Tarjeta decorativa usada para resumir beneficios principales.
class _BentoCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String title;

  const _BentoCard({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor, size: 26),
          const SizedBox(height: 10),
          Text(
            label,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              color: Colors.white.withOpacity(0.55),
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
