import 'package:ecoruta/providers/explore_provider.dart';
import 'package:ecoruta/widgets/app_header.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'tabs/generate_tab.dart';
import 'tabs/search_tab.dart';

/// Pantalla contenedora de búsqueda y generación de rutas.
class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late final ExploreProvider _exploreProvider;

  static const _primaryColor = Color(0xFF012D1D);
  static const _surfaceHigh = Color(0xFFE7E8E9);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _exploreProvider = ExploreProvider();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _exploreProvider.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<ExploreProvider>.value(
      value: _exploreProvider,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F9FA),
        appBar: AppHeader(
          backgroundColor: const Color(0xFFF8F9FA),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(60),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: _surfaceHigh,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicator: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.06),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  indicatorSize: TabBarIndicatorSize.tab,
                  dividerColor: Colors.transparent,
                  labelColor: _primaryColor,
                  unselectedLabelColor: Colors.grey,
                  labelStyle: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                  unselectedLabelStyle: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                  tabs: const [
                    Tab(text: 'Búsqueda'),
                    Tab(text: 'Generar ruta'),
                  ],
                ),
              ),
            ),
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: const [SearchTab(), GenerateTab()],
        ),
      ),
    );
  }
}
