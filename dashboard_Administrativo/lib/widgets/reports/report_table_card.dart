import 'package:flutter/material.dart';

import '../../screens/dashboard/reports/models/report_models.dart';
import '../../screens/dashboard/shared/dashboard_mock_ui.dart';

bool _isDarkMode(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark;

Color _reportSurface(BuildContext context) =>
    _isDarkMode(context) ? const Color(0xFF0F241C) : Colors.white;

Color _reportHeaderSurface(BuildContext context) =>
    _isDarkMode(context) ? const Color(0xFF17352A) : const Color(0xFFF8FAF9);

Color _reportBorder(BuildContext context) =>
    _isDarkMode(context) ? const Color(0xFF1B4332) : dashboardBorder;

Color _reportLabelText(BuildContext context) =>
    _isDarkMode(context) ? dashboardSupportGreen : const Color(0xFF5F746B);

class ReportTableCard extends StatelessWidget {
  static const double _horizontalCellPadding = 36;
  static const double _tableWidthWithStatus =
      210 + 290 + 170 + 150 + 140 + 160 + _horizontalCellPadding;
  static const double _tableWidthWithoutStatus =
      210 + 290 + 170 + 140 + 160 + _horizontalCellPadding;

  const ReportTableCard({
    required this.config,
    required this.searchController,
    required this.selectedFilter,
    required this.sortAscending,
    required this.visibleRows,
    required this.filteredCount,
    required this.currentPage,
    required this.pageCount,
    required this.pageSize,
    required this.onFilterSelected,
    required this.onToggleSort,
    required this.onPreviousPage,
    required this.onNextPage,
    required this.isLoading,
    super.key,
  });

  final DashboardReportConfig config;
  final TextEditingController searchController;
  final String selectedFilter;
  final bool sortAscending;
  final List<DashboardReportRow> visibleRows;
  final int filteredCount;
  final int currentPage;
  final int pageCount;
  final int pageSize;
  final ValueChanged<String> onFilterSelected;
  final VoidCallback onToggleSort;
  final VoidCallback onPreviousPage;
  final VoidCallback onNextPage;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return DashboardSectionCard(
      title: 'Tabla administrativa',
      subtitle:
          'Consulta visual con busqueda, filtros, estados, acciones y paginacion para ${config.shortLabel.toLowerCase()}.',
      child: Column(
        children: [
          _ReportToolbar(
            config: config,
            controller: searchController,
            selectedFilter: selectedFilter,
            onFilterSelected: onFilterSelected,
            sortAscending: sortAscending,
            onToggleSort: onToggleSort,
          ),
          const SizedBox(height: 16),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Container(
                constraints: BoxConstraints(
                  minWidth: config.showStatusColumn
                      ? _tableWidthWithStatus
                      : _tableWidthWithoutStatus,
                ),
                decoration: BoxDecoration(
                  color: _reportSurface(context),
                  border: Border.all(color: _reportBorder(context)),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: _reportHeaderSurface(context),
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(20),
                        ),
                      ),
                      child: Row(
                        children: [
                          _headerCell(context, config.primaryColumnLabel, 210),
                          _headerCell(
                            context,
                            config.secondaryColumnLabel,
                            290,
                          ),
                          _headerCell(context, config.detailColumnLabel, 170),
                          if (config.showStatusColumn)
                            _headerCell(context, 'Estado', 150),
                          _headerCell(context, config.activityColumnLabel, 140),
                          _headerCell(context, 'Accion', 160),
                        ],
                      ),
                    ),
                    if (visibleRows.isEmpty)
                      isLoading
                          ? const _ReportLoadingState()
                          : const _EmptyTableState()
                    else
                      ...visibleRows.map(
                        (row) => _ReportTableRow(
                          row: row,
                          showStatusColumn: config.showStatusColumn,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          _PaginationBar(
            filteredCount: filteredCount,
            visibleCount: visibleRows.length,
            currentPage: currentPage,
            pageCount: pageCount,
            pageSize: pageSize,
            onPreviousPage: onPreviousPage,
            onNextPage: onNextPage,
          ),
        ],
      ),
    );
  }

  Widget _headerCell(BuildContext context, String label, double width) {
    return SizedBox(
      width: width,
      child: Text(
        label,
        style: Theme.of(
          context,
        ).textTheme.labelLarge?.copyWith(color: _reportLabelText(context)),
      ),
    );
  }
}

class _ReportToolbar extends StatelessWidget {
  const _ReportToolbar({
    required this.config,
    required this.controller,
    required this.selectedFilter,
    required this.onFilterSelected,
    required this.sortAscending,
    required this.onToggleSort,
  });

  final DashboardReportConfig config;
  final TextEditingController controller;
  final String selectedFilter;
  final ValueChanged<String> onFilterSelected;
  final bool sortAscending;
  final VoidCallback onToggleSort;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 760;
        final search = Expanded(
          child: TextField(
            controller: controller,
            decoration: const InputDecoration(
              hintText: 'Buscar registros',
              prefixIcon: Icon(Icons.search_rounded),
            ),
          ),
        );

        final filter = SizedBox(
          width: compact ? double.infinity : 220,
          child: DropdownButtonFormField<String>(
            initialValue: selectedFilter,
            decoration: const InputDecoration(
              labelText: 'Filtro',
              prefixIcon: Icon(Icons.filter_alt_outlined),
            ),
            items: config.filters
                .map(
                  (filter) => DropdownMenuItem<String>(
                    value: filter.label,
                    child: Text(filter.label),
                  ),
                )
                .toList(),
            onChanged: (value) {
              if (value != null) {
                onFilterSelected(value);
              }
            },
          ),
        );

        final actions = Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            DashboardActionGhostButton(
              label: sortAscending ? 'Orden A-Z' : 'Orden Z-A',
              icon: Icons.sort_by_alpha_rounded,
              onTap: onToggleSort,
            ),
          ],
        );

        if (compact) {
          return Column(
            children: [
              Row(children: [search]),
              const SizedBox(height: 12),
              Row(children: [Expanded(child: filter)]),
              const SizedBox(height: 12),
              Row(children: [Expanded(child: actions)]),
            ],
          );
        }

        return Row(
          children: [
            search,
            const SizedBox(width: 12),
            filter,
            const SizedBox(width: 12),
            actions,
          ],
        );
      },
    );
  }
}

class _ReportTableRow extends StatelessWidget {
  const _ReportTableRow({required this.row, required this.showStatusColumn});

  final DashboardReportRow row;
  final bool showStatusColumn;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: _reportBorder(context))),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _cell(
            width: 210,
            child: Text(
              row.primary,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
          _cell(
            width: 290,
            child: Text(
              row.secondary,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          _cell(
            width: 170,
            child: Text(
              row.detail,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          if (showStatusColumn)
            _cell(
              width: 150,
              child: Align(
                alignment: Alignment.centerLeft,
                child: DashboardStatusChip(
                  label: row.status,
                  color: _statusColor(row.status),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                ),
              ),
            ),
          _cell(
            width: 140,
            child: Text(
              row.activity,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          _cell(
            width: 160,
            child: Align(
              alignment: Alignment.centerLeft,
              child: DashboardActionGhostButton(
                label: row.actionLabel,
                icon: Icons.open_in_new_rounded,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _cell({required double width, required Widget child}) {
    return SizedBox(width: width, child: child);
  }

  Color _statusColor(String status) {
    final normalized = status.toLowerCase();
    if (normalized.contains('activo') ||
        normalized.contains('activa') ||
        normalized.contains('completado') ||
        normalized.contains('validado')) {
      return dashboardSoftGreen;
    }
    if (normalized.contains('pendiente') ||
        normalized.contains('revision') ||
        normalized.contains('pausada') ||
        normalized.contains('vencida')) {
      return dashboardAccentOrange;
    }
    return dashboardBrandGreen;
  }
}

class _EmptyTableState extends StatelessWidget {
  const _EmptyTableState();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.search_off_rounded,
              size: 36,
              color: _isDarkMode(context)
                  ? dashboardSupportGreen
                  : const Color(0xFF5F746B),
            ),
            const SizedBox(height: 12),
            Text(
              'No hay registros para ese filtro o busqueda.',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ],
        ),
      ),
    );
  }
}

class _ReportLoadingState extends StatelessWidget {
  const _ReportLoadingState();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(28),
      child: Center(child: CircularProgressIndicator()),
    );
  }
}

class _PaginationBar extends StatelessWidget {
  const _PaginationBar({
    required this.filteredCount,
    required this.visibleCount,
    required this.currentPage,
    required this.pageCount,
    required this.pageSize,
    required this.onPreviousPage,
    required this.onNextPage,
  });

  final int filteredCount;
  final int visibleCount;
  final int currentPage;
  final int pageCount;
  final int pageSize;
  final VoidCallback onPreviousPage;
  final VoidCallback onNextPage;

  @override
  Widget build(BuildContext context) {
    final start = filteredCount == 0 ? 0 : (currentPage * pageSize) + 1;
    final end = filteredCount == 0 ? 0 : start + visibleCount - 1;

    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      runSpacing: 12,
      spacing: 12,
      children: [
        Text(
          'Mostrando $start-$end de $filteredCount registros',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            DashboardActionGhostButton(
              label: 'Anterior',
              icon: Icons.chevron_left_rounded,
              onTap: currentPage == 0 ? null : onPreviousPage,
            ),
            const SizedBox(width: 10),
            DashboardStatusChip(
              label: '${currentPage + 1} / $pageCount',
              color: _isDarkMode(context)
                  ? dashboardSupportGreen
                  : const Color(0xFF17392D),
              backgroundColor: _isDarkMode(context)
                  ? const Color(0xFF17352A)
                  : const Color(0xFFF1F4F2),
            ),
            const SizedBox(width: 10),
            DashboardActionGhostButton(
              label: 'Siguiente',
              icon: Icons.chevron_right_rounded,
              onTap: currentPage >= pageCount - 1 ? null : onNextPage,
            ),
          ],
        ),
      ],
    );
  }
}
