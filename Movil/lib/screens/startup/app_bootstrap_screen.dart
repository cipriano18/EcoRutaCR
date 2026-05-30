import 'dart:async';

import 'package:ecoruta/firebase_options.dart';
import 'package:ecoruta/navigation/main_shell.dart';
import 'package:ecoruta/screens/home/home_screen.dart';
import 'package:ecoruta/services/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

class AppBootstrapScreen extends StatefulWidget {
  const AppBootstrapScreen({super.key});

  @override
  State<AppBootstrapScreen> createState() => _AppBootstrapScreenState();
}

class _AppBootstrapScreenState extends State<AppBootstrapScreen>
    with SingleTickerProviderStateMixin {
  late Future<bool> _startupFuture;
  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
    _startupFuture = _bootstrapApp();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<bool> _bootstrapApp() async {
    final startedAt = DateTime.now();

    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    await AuthService().initializeRememberedSession();

    final elapsed = DateTime.now().difference(startedAt);
    const minVisibleDuration = Duration(milliseconds: 1800);
    if (elapsed < minVisibleDuration) {
      await Future<void>.delayed(minVisibleDuration - elapsed);
    }

    return FirebaseAuth.instance.currentUser != null;
  }

  void _retryBootstrap() {
    setState(() {
      _startupFuture = _bootstrapApp();
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _startupFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return _StartupLoadingView(pulseController: _pulseController);
        }

        if (snapshot.hasError) {
          return _StartupErrorView(onRetry: _retryBootstrap);
        }

        if (snapshot.data ?? false) {
          return const MainShell();
        }

        return const HomeScreen();
      },
    );
  }
}

class _StartupLoadingView extends StatelessWidget {
  const _StartupLoadingView({required this.pulseController});

  final AnimationController pulseController;

  static const _primary = Color(0xFF012D1D);
  static const _accent = Color(0xFFC1ECD4);
  static const _textSoft = Color(0xFFA5D0B9);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _primary,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final shortestSide = constraints.biggest.shortestSide;
          final height = constraints.maxHeight;
          final isCompact = shortestSide < 360 || height < 700;
          final horizontalPadding = isCompact ? 22.0 : 28.0;
          final logoSize = isCompact ? 112.0 : 136.0;
          final titleSize = isCompact ? 38.0 : 46.0;
          final subtitleSize = isCompact ? 10.0 : 12.0;
          final subtitleSpacing = isCompact ? 3.0 : 4.2;
          final bottomLabelSize = isCompact ? 10.0 : 11.0;
          final bottomLabelSpacing = isCompact ? 2.6 : 3.2;

          return SafeArea(
            child: Stack(
              children: [
                Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AnimatedBuilder(
                          animation: pulseController,
                          builder: (context, child) {
                            final scale = 0.985 + (pulseController.value * 0.03);
                            final opacity = 0.9 + (pulseController.value * 0.1);
                            return Transform.scale(
                              scale: scale,
                              child: Opacity(opacity: opacity, child: child),
                            );
                          },
                          child: Image.asset(
                            'assets/images/avatars/icon8.png',
                            width: logoSize,
                            height: logoSize,
                            fit: BoxFit.contain,
                          ),
                        ),
                        SizedBox(height: isCompact ? 16 : 22),
                        Text(
                          'EcoRuta',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: titleSize,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -1.8,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: isCompact ? 8 : 10),
                        Text(
                          'EXPLORACION SOSTENIBLE',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: subtitleSize,
                            fontWeight: FontWeight.w700,
                            letterSpacing: subtitleSpacing,
                            color: _textSoft.withValues(alpha: 0.92),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      horizontalPadding,
                      24,
                      horizontalPadding,
                      isCompact ? 28 : 40,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const _SlidingLoadBar(),
                        SizedBox(height: isCompact ? 14 : 18),
                        Text(
                          'INICIANDO EXPEDICION',
                          style: TextStyle(
                            fontSize: bottomLabelSize,
                            fontWeight: FontWeight.w700,
                            letterSpacing: bottomLabelSpacing,
                            color: _accent.withValues(alpha: 0.76),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _SlidingLoadBar extends StatefulWidget {
  const _SlidingLoadBar();

  @override
  State<_SlidingLoadBar> createState() => _SlidingLoadBarState();
}

class _SlidingLoadBarState extends State<_SlidingLoadBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width < 360 ? 132.0 : 150.0;
    final segmentWidth = width * 0.36;

    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: Container(
        width: width,
        height: 4,
        color: Colors.white.withValues(alpha: 0.14),
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            final left =
                -segmentWidth + ((width + segmentWidth) * _controller.value);
            return Stack(
              children: [
                Positioned(
                  left: left,
                  top: 0,
                  bottom: 0,
                  child: Container(
                    width: segmentWidth,
                    decoration: BoxDecoration(
                      color: const Color(0xFFC1ECD4),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _StartupErrorView extends StatelessWidget {
  const _StartupErrorView({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 84,
                  height: 84,
                  decoration: const BoxDecoration(
                    color: Color(0x14012D1D),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.cloud_off_rounded,
                    size: 40,
                    color: Color(0xFF012D1D),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'No pudimos iniciar EcoRuta',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF012D1D),
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Revisa tu conexion e intenta nuevamente para terminar de cargar la aplicacion.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    height: 1.45,
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: onRetry,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF012D1D),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 28,
                      vertical: 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  child: const Text(
                    'Reintentar',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
