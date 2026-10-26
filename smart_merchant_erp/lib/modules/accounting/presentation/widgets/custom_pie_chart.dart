import 'dart:math' as math;
import 'package:flutter/material.dart';

class PieChartDataPoint {
  final String label;
  final double value;
  final Color color;
  final IconData? icon;

  const PieChartDataPoint({
    required this.label,
    required this.value,
    required this.color,
    this.icon,
  });
}

class CustomPieChart extends StatefulWidget {
  final List<PieChartDataPoint> dataPoints;
  final double height;
  final String? centerLabel;
  final String? centerValue;
  final bool isDonut;
  final ValueChanged<int?>? onSegmentSelected;

  const CustomPieChart({
    required this.dataPoints,
    super.key,
    this.height = 240,
    this.centerLabel,
    this.centerValue,
    this.isDonut = true,
    this.onSegmentSelected,
  });

  @override
  State<CustomPieChart> createState() => _CustomPieChartState();
}

class _CustomPieChartState extends State<CustomPieChart>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _animation;
  int? _selectedIndex;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 750),
    );
    _animation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
    );
    _animController.forward();
  }

  @override
  void didUpdateWidget(covariant CustomPieChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.dataPoints != widget.dataPoints) {
      _animController.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  double get _totalValue => widget.dataPoints.fold<double>(
        0.0,
        (acc, p) => acc + p.value,
      );

  void _handleTapDown(TapDownDetails details, Size size) {
    if (_totalValue <= 0) {
      return;
    }
    final center = Offset(size.width / 2, size.height / 2);
    final touchPosition = details.localPosition;
    final dx = touchPosition.dx - center.dx;
    final dy = touchPosition.dy - center.dy;
    final distance = math.sqrt(dx * dx + dy * dy);

    final radius = math.min(size.width, size.height) / 2;
    final innerRadius = widget.isDonut ? radius * 0.58 : 0.0;

    if (distance < innerRadius || distance > radius * 1.1) {
      setState(() => _selectedIndex = null);
      widget.onSegmentSelected?.call(null);
      return;
    }

    // Calculate angle in radians from -pi to pi, shift to 0 to 2pi (starting at top -pi/2)
    var angle = math.atan2(dy, dx);
    // Shift so 0 radians starts at 12 o'clock (-math.pi / 2)
    angle += math.pi / 2;
    if (angle < 0) {
      angle += 2 * math.pi;
    }

    double currentAngle = 0.0;
    for (int i = 0; i < widget.dataPoints.length; i++) {
      final sweep = (widget.dataPoints[i].value / _totalValue) * 2 * math.pi;
      if (angle >= currentAngle && angle <= currentAngle + sweep) {
        setState(() {
          _selectedIndex = (_selectedIndex == i) ? null : i;
        });
        widget.onSegmentSelected?.call(_selectedIndex);
        return;
      }
      currentAngle += sweep;
    }
  }

  @override
  Widget build(BuildContext context) {
    final total = _totalValue;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (total <= 0) {
      return SizedBox(
        height: widget.height,
        child: const Center(
          child: Text(
            'لا توجد بيانات مصروفات متاحة للرسم',
            style: TextStyle(color: Colors.grey, fontSize: 13),
          ),
        ),
      );
    }

    final activePoint = _selectedIndex != null &&
            _selectedIndex! < widget.dataPoints.length
        ? widget.dataPoints[_selectedIndex!]
        : null;

    final displayLabel = activePoint != null
        ? activePoint.label
        : (widget.centerLabel ?? 'إجمالي المصروفات');

    final displayValue = activePoint != null
        ? '${((activePoint.value / total) * 100).toStringAsFixed(1)}%'
        : (widget.centerValue ?? '');

    return LayoutBuilder(
      builder: (context, constraints) {
        final diameter = math.min(
          constraints.maxWidth,
          widget.height,
        );

        return Center(
          child: GestureDetector(
            onTapDown: (details) => _handleTapDown(details, Size(diameter, diameter)),
            child: SizedBox(
              width: diameter,
              height: diameter,
              child: AnimatedBuilder(
                animation: _animation,
                builder: (context, child) {
                  return Stack(
                    alignment: Alignment.center,
                    children: [
                      CustomPaint(
                        size: Size(diameter, diameter),
                        painter: _PieChartPainter(
                          dataPoints: widget.dataPoints,
                          total: total,
                          progress: _animation.value,
                          selectedIndex: _selectedIndex,
                          isDonut: widget.isDonut,
                          isDark: isDark,
                        ),
                      ),
                      if (widget.isDonut)
                        Padding(
                          padding: EdgeInsets.all(diameter * 0.22),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                displayLabel,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: diameter < 200 ? 10.5 : 12,
                                  fontWeight: FontWeight.w600,
                                  color: isDark
                                      ? const Color(0xFF94A3B8)
                                      : const Color(0xFF64748B),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                displayValue,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: diameter < 200 ? 14 : 17,
                                  fontWeight: FontWeight.w900,
                                  color: activePoint != null
                                      ? activePoint.color
                                      : (isDark
                                          ? Colors.white
                                          : const Color(0xFF0F172A)),
                                ),
                              ),
                              if (activePoint != null) ...[
                                const SizedBox(height: 1),
                                Text(
                                  '${activePoint.value.toStringAsFixed(0)} ر.ي',
                                  style: TextStyle(
                                    fontSize: diameter < 200 ? 9.5 : 11,
                                    fontWeight: FontWeight.bold,
                                    color: activePoint.color,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}

class _PieChartPainter extends CustomPainter {
  final List<PieChartDataPoint> dataPoints;
  final double total;
  final double progress;
  final int? selectedIndex;
  final bool isDonut;
  final bool isDark;

  _PieChartPainter({
    required this.dataPoints,
    required this.total,
    required this.progress,
    required this.selectedIndex,
    required this.isDonut,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (total <= 0) {
      return;
    }

    final center = Offset(size.width / 2, size.height / 2);
    final outerRadius = math.min(size.width, size.height) / 2 - 8;
    final innerRadius = isDonut ? outerRadius * 0.58 : 0.0;
    final strokeWidth = outerRadius - innerRadius;

    final paint = Paint()
      ..style = isDonut ? PaintingStyle.stroke : PaintingStyle.fill
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.butt
      ..isAntiAlias = true;

    // Start angle at 12 o'clock (-pi / 2)
    double currentAngle = -math.pi / 2;
    final maxSweep = 2 * math.pi * progress;
    double drawnSweep = 0.0;

    for (int i = 0; i < dataPoints.length; i++) {
      final point = dataPoints[i];
      final itemFraction = point.value / total;
      final itemSweep = itemFraction * 2 * math.pi;

      if (drawnSweep >= maxSweep) {
        break;
      }

      final actualSweep = math.min(itemSweep, maxSweep - drawnSweep);
      final isSelected = selectedIndex == i;

      paint.color = point.color;

      if (isDonut) {
        final currentRadius = isSelected ? outerRadius - (strokeWidth / 2) + 4 : outerRadius - (strokeWidth / 2);
        paint.strokeWidth = isSelected ? strokeWidth + 6 : strokeWidth;

        canvas.drawArc(
          Rect.fromCircle(center: center, radius: currentRadius),
          currentAngle,
          actualSweep,
          false,
          paint,
        );
      } else {
        final currentRadius = isSelected ? outerRadius + 5 : outerRadius;
        canvas.drawArc(
          Rect.fromCircle(center: center, radius: currentRadius),
          currentAngle,
          actualSweep,
          true,
          paint,
        );
      }

      currentAngle += actualSweep;
      drawnSweep += actualSweep;
    }

    // Draw thin separator gaps between slices for modern aesthetics
    if (dataPoints.length > 1 && progress > 0.8) {
      final separatorPaint = Paint()
        ..color = isDark ? const Color(0xFF101115) : Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..isAntiAlias = true;

      double gapAngle = -math.pi / 2;
      for (int i = 0; i < dataPoints.length; i++) {
        final p = dataPoints[i];
        final sweep = (p.value / total) * 2 * math.pi;

        final x1 = center.dx + innerRadius * math.cos(gapAngle);
        final y1 = center.dy + innerRadius * math.sin(gapAngle);
        final x2 = center.dx + (outerRadius + 4) * math.cos(gapAngle);
        final y2 = center.dy + (outerRadius + 4) * math.sin(gapAngle);

        canvas.drawLine(Offset(x1, y1), Offset(x2, y2), separatorPaint);
        gapAngle += sweep;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _PieChartPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.selectedIndex != selectedIndex ||
        oldDelegate.dataPoints != dataPoints ||
        oldDelegate.total != total;
  }
}
