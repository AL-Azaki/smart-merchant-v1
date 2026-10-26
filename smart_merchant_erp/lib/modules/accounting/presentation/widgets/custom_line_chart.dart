import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Data point for a line chart series.
class ChartDataPoint {
  final String label; // e.g. "10/1", "أكتوبر", "السبت"
  final double value;
  final DateTime? date;

  const ChartDataPoint({required this.label, required this.value, this.date});
}

/// A line series in the chart.
class ChartLineSeries {
  final String name;
  final Color color;
  final List<ChartDataPoint> points;
  final bool showGradientFill;
  final double strokeWidth;

  const ChartLineSeries({
    required this.name,
    required this.color,
    required this.points,
    this.showGradientFill = true,
    this.strokeWidth = 3.0,
  });
}

/// Modern, smooth, interactive Line Chart built with CustomPainter.
/// Zero external dependencies, offline-first, and ultra responsive.
class CustomLineChart extends StatefulWidget {
  final List<ChartLineSeries> seriesList;
  final double height;
  final String? valueSuffix;
  final bool showGrid;
  final bool isCurved;

  const CustomLineChart({
    required this.seriesList,
    super.key,
    this.height = 240,
    this.valueSuffix = 'ر.ي',
    this.showGrid = true,
    this.isCurved = true,
  });

  @override
  State<CustomLineChart> createState() => _CustomLineChartState();
}

class _CustomLineChartState extends State<CustomLineChart> {
  int? _hoveredIndex;
  Offset? _hoverPosition;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final gridColor = isDark
        ? const Color(0xFF334155)
        : const Color(0xFFE2E8F0);
    final labelColor = isDark
        ? const Color(0xFF94A3B8)
        : const Color(0xFF64748B);

    if (widget.seriesList.isEmpty ||
        widget.seriesList.every((s) => s.points.isEmpty)) {
      return Container(
        height: widget.height,
        alignment: Alignment.center,
        child: Text(
          'لا توجد بيانات كافية لعرض المخطط البياني',
          style: TextStyle(
            fontSize: 13,
            color: labelColor,
            fontWeight: FontWeight.w500,
          ),
        ),
      );
    }

    // Determine max and min value across all series
    double maxValue = 0;
    double minValue = 0;
    int maxPoints = 0;

    for (final s in widget.seriesList) {
      if (s.points.length > maxPoints) {
        maxPoints = s.points.length;
      }
      for (final p in s.points) {
        if (p.value > maxValue) maxValue = p.value;
        if (p.value < minValue) minValue = p.value;
      }
    }

    if (maxValue == 0 && minValue == 0) {
      maxValue = 100;
    } else {
      maxValue = maxValue * 1.15; // 15% top margin for aesthetics
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Series Legend
            Wrap(
              spacing: 16,
              runSpacing: 8,
              alignment: WrapAlignment.end,
              children: widget.seriesList.map((s) {
                final lastVal = s.points.isNotEmpty ? s.points.last.value : 0.0;
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 14,
                      height: 4,
                      decoration: BoxDecoration(
                        color: s.color,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      s.name,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? const Color(0xFFCBD5E1)
                            : const Color(0xFF334155),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '(${_formatValue(lastVal)} ${widget.valueSuffix ?? ''})',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: s.color,
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
            const SizedBox(height: 12),

            // Canvas & Interaction
            SizedBox(
              height: widget.height,
              child: GestureDetector(
                onTapDown: (details) => _handleTouch(
                  details.localPosition,
                  constraints.maxWidth,
                  maxPoints,
                ),
                onPanUpdate: (details) => _handleTouch(
                  details.localPosition,
                  constraints.maxWidth,
                  maxPoints,
                ),
                onPanEnd: (_) => setState(() => _hoveredIndex = null),
                child: MouseRegion(
                  onHover: (event) => _handleTouch(
                    event.localPosition,
                    constraints.maxWidth,
                    maxPoints,
                  ),
                  onExit: (_) => setState(() => _hoveredIndex = null),
                  child: Stack(
                    children: [
                      CustomPaint(
                        size: Size(constraints.maxWidth, widget.height),
                        painter: _LineChartPainter(
                          seriesList: widget.seriesList,
                          maxValue: maxValue,
                          minValue: minValue,
                          gridColor: gridColor,
                          labelColor: labelColor,
                          isCurved: widget.isCurved,
                          hoveredIndex: _hoveredIndex,
                        ),
                      ),
                      if (_hoveredIndex != null && _hoverPosition != null)
                        _buildTooltipBadge(
                          context,
                          isDark,
                          constraints.maxWidth,
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _handleTouch(Offset localPos, double totalWidth, int maxPoints) {
    if (maxPoints <= 1) return;
    final leftPadding = totalWidth < 500 ? 36.0 : 48.0;
    const rightPadding = 14.0;
    final chartWidth = totalWidth - leftPadding - rightPadding;
    if (chartWidth <= 0) return;

    final xRelative = localPos.dx - leftPadding;
    final stepWidth = chartWidth / (maxPoints - 1);
    int index = (xRelative / stepWidth).round();
    if (index < 0) index = 0;
    if (index >= maxPoints) index = maxPoints - 1;

    setState(() {
      _hoveredIndex = index;
      _hoverPosition = localPos;
    });
  }

  Widget _buildTooltipBadge(
    BuildContext context,
    bool isDark,
    double totalWidth,
  ) {
    if (_hoveredIndex == null) return const SizedBox.shrink();

    final seriesPoints = <String, double>{};
    String label = '';

    for (final s in widget.seriesList) {
      if (_hoveredIndex! < s.points.length) {
        final p = s.points[_hoveredIndex!];
        label = p.label;
        seriesPoints[s.name] = p.value;
      }
    }

    final tooltipX = (_hoverPosition?.dx ?? 100).clamp(
      60.0,
      totalWidth - 140.0,
    );

    return Positioned(
      left: tooltipX - 60,
      top: 10,
      child: Material(
        elevation: 8,
        borderRadius: BorderRadius.circular(10),
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        shadowColor: Colors.black.withValues(alpha: 0.3),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 4),
              ...widget.seriesList.map((s) {
                final val = seriesPoints[s.name] ?? 0.0;
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: s.color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${s.name}: ${_formatValue(val)} ${widget.valueSuffix ?? ''}',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? const Color(0xFFE2E8F0)
                            : const Color(0xFF1E293B),
                      ),
                    ),
                  ],
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  String _formatValue(double val) {
    if (val >= 1000000) {
      return '${(val / 1000000).toStringAsFixed(1)}M';
    } else if (val >= 1000) {
      return '${(val / 1000).toStringAsFixed(1)}K';
    }
    return val.toStringAsFixed(0);
  }
}

class _LineChartPainter extends CustomPainter {
  final List<ChartLineSeries> seriesList;
  final double maxValue;
  final double minValue;
  final Color gridColor;
  final Color labelColor;
  final bool isCurved;
  final int? hoveredIndex;

  _LineChartPainter({
    required this.seriesList,
    required this.maxValue,
    required this.minValue,
    required this.gridColor,
    required this.labelColor,
    required this.isCurved,
    this.hoveredIndex,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final leftPad = size.width < 500 ? 36.0 : 48.0;
    const rightPad = 14.0;
    const topPad = 14.0;
    const bottomPad = 26.0;

    final chartWidth = size.width - leftPad - rightPad;
    final chartHeight = size.height - topPad - bottomPad;

    if (chartWidth <= 0 || chartHeight <= 0) return;

    final gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 1.0;

    final textStyle = TextStyle(
      fontSize: size.width < 500 ? 9 : 10,
      fontWeight: FontWeight.w500,
      color: labelColor,
      fontFamily: 'Cairo',
      fontFamilyFallback: const ['Cairo', 'Roboto', 'Arial', 'sans-serif'],
    );

    // ── 1. Draw Horizontal Grid Lines & Y-Axis Labels ──
    const divisions = 4;
    final valRange = (maxValue - minValue).abs();
    final stepVal = valRange / divisions;

    for (int i = 0; i <= divisions; i++) {
      final y = topPad + chartHeight - (i * chartHeight / divisions);
      final val = minValue + (i * stepVal);

      // Dash line
      canvas.drawLine(
        Offset(leftPad, y),
        Offset(size.width - rightPad, y),
        gridPaint,
      );

      // Label
      final labelText = _formatShort(val);
      final textSpan = TextSpan(text: labelText, style: textStyle);
      final textPainter = TextPainter(
        text: textSpan,
        textAlign: TextAlign.left,
        textDirection: TextDirection.ltr,
      )..layout();

      textPainter.paint(
        canvas,
        Offset(leftPad - textPainter.width - 4, y - textPainter.height / 2),
      );
    }

    // ── 2. Draw X-Axis Labels ──
    int maxPoints = 0;
    List<String> xLabels = [];
    for (final s in seriesList) {
      if (s.points.length > maxPoints) {
        maxPoints = s.points.length;
        xLabels = s.points.map((p) => p.label).toList();
      }
    }

    if (maxPoints > 0) {
      final stepX = maxPoints > 1
          ? chartWidth / (maxPoints - 1)
          : chartWidth / 2;

      // Smart stride to ensure labels never overlap on small screens
      final maxVisibleLabels = (chartWidth / (size.width < 500 ? 56 : 46))
          .floor()
          .clamp(3, 8);
      final stride = (maxPoints / maxVisibleLabels).ceil().clamp(1, maxPoints);

      for (int i = 0; i < maxPoints; i++) {
        if (i % stride != 0 && i != maxPoints - 1) continue;

        final x = leftPad + (i * stepX);
        final label = xLabels[i];

        final textSpan = TextSpan(text: label, style: textStyle);
        final textPainter = TextPainter(
          text: textSpan,
          textAlign: TextAlign.center,
          textDirection: TextDirection.ltr,
        )..layout();

        textPainter.paint(
          canvas,
          Offset(x - textPainter.width / 2, size.height - bottomPad + 6),
        );
      }
    }

    // ── 3. Draw Series Lines and Areas ──
    for (final series in seriesList) {
      if (series.points.isEmpty) continue;

      final points = series.points;
      final stepX = points.length > 1
          ? chartWidth / (points.length - 1)
          : chartWidth / 2;

      final offsets = <Offset>[];
      for (int i = 0; i < points.length; i++) {
        final x = leftPad + (i * stepX);
        final normalizedY = valRange > 0
            ? (points[i].value - minValue) / valRange
            : 0.0;
        final y = topPad + chartHeight - (normalizedY * chartHeight);
        offsets.add(Offset(x, y.clamp(topPad, topPad + chartHeight)));
      }

      // Build path
      final path = Path();
      path.moveTo(offsets.first.dx, offsets.first.dy);

      if (isCurved && offsets.length > 2) {
        for (int i = 0; i < offsets.length - 1; i++) {
          final p0 = offsets[i];
          final p1 = offsets[i + 1];
          final controlX = (p0.dx + p1.dx) / 2;
          path.cubicTo(controlX, p0.dy, controlX, p1.dy, p1.dx, p1.dy);
        }
      } else {
        for (int i = 1; i < offsets.length; i++) {
          path.lineTo(offsets[i].dx, offsets[i].dy);
        }
      }

      // Draw Gradient Area under Line
      if (series.showGradientFill && offsets.isNotEmpty) {
        final areaPath = Path.from(path);
        areaPath.lineTo(offsets.last.dx, topPad + chartHeight);
        areaPath.lineTo(offsets.first.dx, topPad + chartHeight);
        areaPath.close();

        final fillPaint = Paint()
          ..shader =
              LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  series.color.withValues(alpha: 0.28),
                  series.color.withValues(alpha: 0.01),
                ],
              ).createShader(
                Rect.fromLTWH(leftPad, topPad, chartWidth, chartHeight),
              );

        canvas.drawPath(areaPath, fillPaint);
      }

      // Draw Stroke Line
      final linePaint = Paint()
        ..color = series.color
        ..strokeWidth = series.strokeWidth
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;

      canvas.drawPath(path, linePaint);

      // Draw Data Point Circles
      final circlePaint = Paint()
        ..color = series.color
        ..style = PaintingStyle.fill;

      final innerWhitePaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill;

      for (int i = 0; i < offsets.length; i++) {
        final isHovered = hoveredIndex == i;
        final radius = isHovered ? 6.0 : 3.5;

        canvas.drawCircle(offsets[i], radius, circlePaint);
        canvas.drawCircle(offsets[i], radius - 1.5, innerWhitePaint);
      }
    }

    // ── 4. Draw Hover Vertical Cursor Line ──
    if (hoveredIndex != null && maxPoints > 0 && hoveredIndex! < maxPoints) {
      final stepX = maxPoints > 1
          ? chartWidth / (maxPoints - 1)
          : chartWidth / 2;
      final hoverX = leftPad + (hoveredIndex! * stepX);

      final hoverLinePaint = Paint()
        ..color = labelColor.withValues(alpha: 0.6)
        ..strokeWidth = 1.2
        ..style = PaintingStyle.stroke;

      // Draw vertical dash
      double curY = topPad;
      while (curY < topPad + chartHeight) {
        canvas.drawLine(
          Offset(hoverX, curY),
          Offset(hoverX, math.min(curY + 4, topPad + chartHeight)),
          hoverLinePaint,
        );
        curY += 7;
      }
    }
  }

  String _formatShort(double val) {
    if (val >= 1000000) {
      return '${(val / 1000000).toStringAsFixed(1)}M';
    } else if (val >= 1000) {
      return '${(val / 1000).toStringAsFixed(0)}k';
    }
    return val.toStringAsFixed(0);
  }

  @override
  bool shouldRepaint(covariant _LineChartPainter oldDelegate) {
    return oldDelegate.seriesList != seriesList ||
        oldDelegate.hoveredIndex != hoveredIndex ||
        oldDelegate.maxValue != maxValue;
  }
}
