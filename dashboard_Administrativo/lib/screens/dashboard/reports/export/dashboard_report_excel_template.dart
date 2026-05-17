import 'dart:typed_data';

import 'package:excel/excel.dart';

import '../../shared/dashboard_mock_ui.dart';
import '../models/report_models.dart';

class DashboardReportExcelTemplate {
  DashboardReportExcelTemplate._();

  static const String _workbookTitle = 'EcoRutaCR';
  static final ExcelColor _brandGreen = ExcelColor.fromHexString('#012D1D');
  static final ExcelColor _softGreen = ExcelColor.fromHexString('#DDEDE6');
  static final ExcelColor _tableHeaderGreen = ExcelColor.fromHexString(
    '#1F5E49',
  );
  static final ExcelColor _rowTint = ExcelColor.fromHexString('#F7FBF9');
  static final ExcelColor _borderColor = ExcelColor.fromHexString('#D7E5DE');
  static final ExcelColor _mutedText = ExcelColor.fromHexString('#60776D');
  static final ExcelColor _white = ExcelColor.fromHexString('#FFFFFF');
  static final Border _thinBorder = Border(
    borderStyle: BorderStyle.Thin,
    borderColorHex: _borderColor,
  );

  static Uint8List buildWorkbook({
    required DashboardReportConfig config,
    required List<DashboardReportRow> rows,
    required bool usesLiveData,
  }) {
    final excel = Excel.createExcel();
    final sheetName = _sanitizeSheetName(config.shortLabel);
    excel.rename('Sheet1', sheetName);
    final sheet = excel[sheetName];

    _configureColumns(sheet);
    _buildHeader(excel, sheet, config, usesLiveData);

    final tableStartRow = _buildMetricSummary(sheet, config.metrics);
    _buildTable(sheet, config, rows, tableStartRow);

    final bytes = excel.encode();
    if (bytes == null) {
      throw Exception('No se pudieron generar los bytes del archivo Excel.');
    }

    return Uint8List.fromList(bytes);
  }

  static void _configureColumns(Sheet sheet) {
    sheet
      ..setColumnWidth(0, 28)
      ..setColumnWidth(1, 38)
      ..setColumnWidth(2, 24)
      ..setColumnWidth(3, 18)
      ..setColumnWidth(4, 18)
      ..setRowHeight(0, 28)
      ..setRowHeight(1, 24)
      ..setRowHeight(2, 24)
      ..setRowHeight(5, 22)
      ..setRowHeight(6, 24)
      ..setRowHeight(7, 22);
  }

  static void _buildHeader(
    Excel excel,
    Sheet sheet,
    DashboardReportConfig config,
    bool usesLiveData,
  ) {
    _mergeStyledRow(
      excel: excel,
      sheet: sheet,
      rowIndex: 0,
      startColumn: 0,
      endColumn: 4,
      value: _workbookTitle,
      style: CellStyle(
        backgroundColorHex: _softGreen,
        fontColorHex: _brandGreen,
        fontFamily: getFontFamily(FontFamily.Cambria),
        fontSize: 24,
        bold: true,
        horizontalAlign: HorizontalAlign.Left,
        verticalAlign: VerticalAlign.Center,
      ),
    );

    _mergeStyledRow(
      excel: excel,
      sheet: sheet,
      rowIndex: 1,
      startColumn: 0,
      endColumn: 4,
      value: config.title,
      style: CellStyle(
        backgroundColorHex: _white,
        fontColorHex: _brandGreen,
        fontFamily: getFontFamily(FontFamily.Cambria),
        fontSize: 18,
        bold: true,
        horizontalAlign: HorizontalAlign.Left,
        verticalAlign: VerticalAlign.Center,
      ),
    );

    _mergeStyledRow(
      excel: excel,
      sheet: sheet,
      rowIndex: 2,
      startColumn: 0,
      endColumn: 4,
      value: config.description,
      style: CellStyle(
        backgroundColorHex: _white,
        fontColorHex: _mutedText,
        fontFamily: getFontFamily(FontFamily.Cambria),
        fontSize: 11,
        horizontalAlign: HorizontalAlign.Left,
        verticalAlign: VerticalAlign.Center,
        textWrapping: TextWrapping.WrapText,
      ),
    );

    _mergeStyledRow(
      excel: excel,
      sheet: sheet,
      rowIndex: 3,
      startColumn: 0,
      endColumn: 4,
      value:
          'Fuente: ${usesLiveData ? 'Firebase' : 'Mockup'}   |   Generado: ${_formatDateTime(DateTime.now())}',
      style: CellStyle(
        backgroundColorHex: _white,
        fontColorHex: _mutedText,
        fontFamily: getFontFamily(FontFamily.Cambria),
        fontSize: 10,
        italic: true,
        horizontalAlign: HorizontalAlign.Left,
        verticalAlign: VerticalAlign.Center,
      ),
    );
  }

  static int _buildMetricSummary(
    Sheet sheet,
    List<DashboardMetricData> metrics,
  ) {
    if (metrics.isEmpty) {
      return 6;
    }

    final visibleMetrics = metrics.take(4).toList();
    for (var index = 0; index < visibleMetrics.length; index++) {
      final metric = visibleMetrics[index];
      final titleStyle = CellStyle(
        backgroundColorHex: _softGreen,
        fontColorHex: _brandGreen,
        fontFamily: getFontFamily(FontFamily.Cambria),
        fontSize: 11,
        bold: true,
        horizontalAlign: HorizontalAlign.Left,
        verticalAlign: VerticalAlign.Center,
        leftBorder: _thinBorder,
        rightBorder: _thinBorder,
        topBorder: _thinBorder,
        bottomBorder: _thinBorder,
      );
      final valueStyle = CellStyle(
        backgroundColorHex: _white,
        fontColorHex: _brandGreen,
        fontFamily: getFontFamily(FontFamily.Cambria),
        fontSize: 18,
        bold: true,
        horizontalAlign: HorizontalAlign.Left,
        verticalAlign: VerticalAlign.Center,
        leftBorder: _thinBorder,
        rightBorder: _thinBorder,
        topBorder: _thinBorder,
        bottomBorder: _thinBorder,
      );
      final changeStyle = CellStyle(
        backgroundColorHex: _rowTint,
        fontColorHex: _mutedText,
        fontFamily: getFontFamily(FontFamily.Cambria),
        fontSize: 10,
        horizontalAlign: HorizontalAlign.Left,
        verticalAlign: VerticalAlign.Center,
        textWrapping: TextWrapping.WrapText,
        leftBorder: _thinBorder,
        rightBorder: _thinBorder,
        topBorder: _thinBorder,
        bottomBorder: _thinBorder,
      );

      _writeCell(
        sheet,
        rowIndex: 5,
        columnIndex: index,
        value: TextCellValue(metric.title),
        style: titleStyle,
      );
      _writeCell(
        sheet,
        rowIndex: 6,
        columnIndex: index,
        value: TextCellValue(metric.value),
        style: valueStyle,
      );
      _writeCell(
        sheet,
        rowIndex: 7,
        columnIndex: index,
        value: TextCellValue(metric.changeLabel ?? ''),
        style: changeStyle,
      );
    }

    return 9;
  }

  static void _buildTable(
    Sheet sheet,
    DashboardReportConfig config,
    List<DashboardReportRow> rows,
    int startRow,
  ) {
    final headerStyle = CellStyle(
      backgroundColorHex: _tableHeaderGreen,
      fontColorHex: _white,
      fontFamily: getFontFamily(FontFamily.Cambria),
      fontSize: 12,
      bold: true,
      horizontalAlign: HorizontalAlign.Left,
      verticalAlign: VerticalAlign.Center,
      leftBorder: _thinBorder,
      rightBorder: _thinBorder,
      topBorder: _thinBorder,
      bottomBorder: _thinBorder,
    );

    final headers = [
      config.primaryColumnLabel,
      config.secondaryColumnLabel,
      config.detailColumnLabel,
    ];
    if (config.showStatusColumn) {
      headers.add('Estado');
    }
    headers.add(config.activityColumnLabel);

    for (var index = 0; index < headers.length; index++) {
      _writeCell(
        sheet,
        rowIndex: startRow,
        columnIndex: index,
        value: TextCellValue(headers[index]),
        style: headerStyle,
      );
    }

    if (rows.isEmpty) {
      final emptyStyle = CellStyle(
        backgroundColorHex: _white,
        fontColorHex: _mutedText,
        fontFamily: getFontFamily(FontFamily.Cambria),
        fontSize: 11,
        italic: true,
        horizontalAlign: HorizontalAlign.Left,
        verticalAlign: VerticalAlign.Center,
        leftBorder: _thinBorder,
        rightBorder: _thinBorder,
        topBorder: _thinBorder,
        bottomBorder: _thinBorder,
      );
      _writeCell(
        sheet,
        rowIndex: startRow + 1,
        columnIndex: 0,
        value: TextCellValue('Sin registros para exportar.'),
        style: emptyStyle,
      );
      for (var column = 1; column < headers.length; column++) {
        _writeCell(
          sheet,
          rowIndex: startRow + 1,
          columnIndex: column,
          value: TextCellValue(''),
          style: emptyStyle,
        );
      }
      return;
    }

    for (var index = 0; index < rows.length; index++) {
      final row = rows[index];
      final rowIndex = startRow + 1 + index;
      final baseStyle = _tableRowStyle(index.isEven);
      final primaryStyle = baseStyle.copyWith(
        boldVal: true,
        fontColorHexVal: _brandGreen,
      );

      _writeCell(
        sheet,
        rowIndex: rowIndex,
        columnIndex: 0,
        value: TextCellValue(row.primary),
        style: primaryStyle,
      );
      _writeCell(
        sheet,
        rowIndex: rowIndex,
        columnIndex: 1,
        value: TextCellValue(row.secondary),
        style: baseStyle,
      );
      _writeCell(
        sheet,
        rowIndex: rowIndex,
        columnIndex: 2,
        value: TextCellValue(row.detail),
        style: baseStyle,
      );
      if (config.showStatusColumn) {
        _writeCell(
          sheet,
          rowIndex: rowIndex,
          columnIndex: 3,
          value: TextCellValue(row.status),
          style: _statusStyle(row.status, index.isEven),
        );
        _writeCell(
          sheet,
          rowIndex: rowIndex,
          columnIndex: 4,
          value: TextCellValue(row.activity),
          style: baseStyle,
        );
      } else {
        _writeCell(
          sheet,
          rowIndex: rowIndex,
          columnIndex: 3,
          value: TextCellValue(row.activity),
          style: baseStyle,
        );
      }
    }
  }

  static void _mergeStyledRow({
    required Excel excel,
    required Sheet sheet,
    required int rowIndex,
    required int startColumn,
    required int endColumn,
    required String value,
    required CellStyle style,
  }) {
    for (var column = startColumn; column <= endColumn; column++) {
      _writeCell(
        sheet,
        rowIndex: rowIndex,
        columnIndex: column,
        value: TextCellValue(''),
        style: style,
      );
    }

    _writeCell(
      sheet,
      rowIndex: rowIndex,
      columnIndex: startColumn,
      value: TextCellValue(value),
      style: style,
    );

    excel.merge(
      sheet.sheetName,
      CellIndex.indexByColumnRow(columnIndex: startColumn, rowIndex: rowIndex),
      CellIndex.indexByColumnRow(columnIndex: endColumn, rowIndex: rowIndex),
    );
  }

  static void _writeCell(
    Sheet sheet, {
    required int rowIndex,
    required int columnIndex,
    required CellValue value,
    required CellStyle style,
  }) {
    sheet.updateCell(
      CellIndex.indexByColumnRow(columnIndex: columnIndex, rowIndex: rowIndex),
      value,
      cellStyle: style,
    );
  }

  static CellStyle _tableRowStyle(bool tinted) {
    return CellStyle(
      backgroundColorHex: tinted ? _rowTint : _white,
      fontColorHex: _brandGreen,
      fontFamily: getFontFamily(FontFamily.Cambria),
      fontSize: 11,
      horizontalAlign: HorizontalAlign.Left,
      verticalAlign: VerticalAlign.Center,
      textWrapping: TextWrapping.WrapText,
      leftBorder: _thinBorder,
      rightBorder: _thinBorder,
      topBorder: _thinBorder,
      bottomBorder: _thinBorder,
    );
  }

  static CellStyle _statusStyle(String status, bool tinted) {
    final normalized = status.trim().toLowerCase();
    var background = tinted ? _rowTint : _white;
    var text = _brandGreen;

    if (normalized.contains('activo')) {
      background = ExcelColor.fromHexString('#DCEFE5');
      text = ExcelColor.fromHexString('#2C7A5C');
    } else if (normalized.contains('pendiente')) {
      background = ExcelColor.fromHexString('#F9E7DE');
      text = ExcelColor.fromHexString('#F9733A');
    } else if (normalized.contains('revision')) {
      background = ExcelColor.fromHexString('#E7F1EC');
      text = ExcelColor.fromHexString('#386D5A');
    } else if (normalized.contains('pausad') ||
        normalized.contains('inactiv')) {
      background = ExcelColor.fromHexString('#ECEFF0');
      text = ExcelColor.fromHexString('#5A6B65');
    }

    return CellStyle(
      backgroundColorHex: background,
      fontColorHex: text,
      fontFamily: getFontFamily(FontFamily.Cambria),
      fontSize: 11,
      bold: true,
      horizontalAlign: HorizontalAlign.Center,
      verticalAlign: VerticalAlign.Center,
      leftBorder: _thinBorder,
      rightBorder: _thinBorder,
      topBorder: _thinBorder,
      bottomBorder: _thinBorder,
    );
  }

  static String _sanitizeSheetName(String value) {
    final sanitized = value.replaceAll(RegExp(r'[\[\]\*:/\\?]'), ' ').trim();
    if (sanitized.isEmpty) {
      return 'Reporte';
    }
    return sanitized.length > 31 ? sanitized.substring(0, 31) : sanitized;
  }

  static String _formatDateTime(DateTime value) {
    final day = value.day.toString().padLeft(2, '0');
    final month = value.month.toString().padLeft(2, '0');
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');
    return '$day/$month/${value.year} $hour:$minute';
  }
}
