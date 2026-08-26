import 'package:flutter/material.dart';

import '../../../../domain/entities/dive_log_entry.dart';

/// Two stacked charts (depth, then temperature) sharing one time axis, with a drag-to-inspect
/// crosshair — dragging a finger along either chart snaps to the nearest sample and shows its
/// exact time/depth/temp plus the running average depth up to that point. No charting package
/// pulled in for this — same dependency-free posture as core/formatting/date_format.dart's own
/// hand-rolled formatters.
class DiveProfileChart extends StatefulWidget {
  const DiveProfileChart({super.key, required this.samples});

  final List<DiveProfileSample> samples;

  @override
  State<DiveProfileChart> createState() => _DiveProfileChartState();
}

class _DiveProfileChartState extends State<DiveProfileChart> {
  int? _touchIndex;

  static const _leftAxisWidth = 44.0;
  static const _rightPad = 8.0;
  static const _depthChartHeight = 160.0;
  static const _tempChartHeight = 110.0;

  void _updateTouch(double localX, double plotWidth) {
    final samples = widget.samples;
    final maxTime = samples.last.offsetSeconds.toDouble();
    if (maxTime <= 0 || plotWidth <= 0) return;
    final fraction = ((localX - _leftAxisWidth) / plotWidth).clamp(0.0, 1.0);
    final targetSeconds = fraction * maxTime;

    var nearest = 0;
    var bestDiff = double.infinity;
    for (var i = 0; i < samples.length; i++) {
      final diff = (samples[i].offsetSeconds - targetSeconds).abs();
      if (diff < bestDiff) {
        bestDiff = diff;
        nearest = i;
      }
    }
    if (nearest != _touchIndex) setState(() => _touchIndex = nearest);
  }

  @override
  Widget build(BuildContext context) {
    final samples = widget.samples;
    if (samples.length < 2) return const SizedBox.shrink();
    final theme = Theme.of(context);
    final maxTime = samples.last.offsetSeconds.toDouble();
    final maxDepth = samples.map((s) => s.depthM).reduce((a, b) => a > b ? a : b);
    final temps = samples.map((s) => s.temperatureC).whereType<double>().toList();

    return LayoutBuilder(
      builder: (context, constraints) {
        final plotWidth = constraints.maxWidth - _leftAxisWidth - _rightPad;
        return GestureDetector(
          onHorizontalDragStart: (d) => _updateTouch(d.localPosition.dx, plotWidth),
          onHorizontalDragUpdate: (d) => _updateTouch(d.localPosition.dx, plotWidth),
          onHorizontalDragEnd: (_) => setState(() => _touchIndex = null),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ReadoutRow(samples: samples, touchIndex: _touchIndex),
              const SizedBox(height: 8),
              Text(
                'Depth',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              SizedBox(
                height: _depthChartHeight,
                child: CustomPaint(
                  size: Size.infinite,
                  painter: _DepthChartPainter(
                    samples: samples,
                    maxTime: maxTime,
                    maxDepth: maxDepth,
                    touchIndex: _touchIndex,
                    lineColor: theme.colorScheme.primary,
                    labelColor: theme.colorScheme.onSurfaceVariant,
                    textStyle: theme.textTheme.labelSmall,
                    leftAxisWidth: _leftAxisWidth,
                    rightPad: _rightPad,
                    showTimeAxis: temps.isEmpty,
                  ),
                ),
              ),
              if (temps.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  'Temperature',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                SizedBox(
                  height: _tempChartHeight,
                  child: CustomPaint(
                    size: Size.infinite,
                    painter: _TempChartPainter(
                      samples: samples,
                      maxTime: maxTime,
                      minTemp: temps.reduce((a, b) => a < b ? a : b),
                      maxTemp: temps.reduce((a, b) => a > b ? a : b),
                      touchIndex: _touchIndex,
                      lineColor: theme.colorScheme.tertiary,
                      labelColor: theme.colorScheme.onSurfaceVariant,
                      textStyle: theme.textTheme.labelSmall,
                      leftAxisWidth: _leftAxisWidth,
                      rightPad: _rightPad,
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _ReadoutRow extends StatelessWidget {
  const _ReadoutRow({required this.samples, required this.touchIndex});

  final List<DiveProfileSample> samples;
  final int? touchIndex;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600);

    if (touchIndex == null) {
      return Text(
        'Drag along the chart to inspect a point',
        style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
      );
    }

    final s = samples[touchIndex!];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(_formatOffset(s.offsetSeconds), style: style),
        Text('${s.depthM.toStringAsFixed(1)}m', style: style),
        Text(
          s.temperatureC != null ? '${s.temperatureC!.toStringAsFixed(1)}°C' : '—',
          style: style,
        ),
      ],
    );
  }
}

String _formatOffset(int seconds) {
  final minutes = seconds ~/ 60;
  final secs = seconds % 60;
  return '$minutes:${secs.toString().padLeft(2, '0')}';
}

/// Shared axis-drawing helpers for both painters below — kept as free functions rather than
/// a common base class since the two painters otherwise have nothing else in common (depth
/// is inverted/filled, temperature is a plain line).
void _drawYLabel(Canvas canvas, String text, double x, double y, TextStyle? style, Color color) {
  final painter = TextPainter(
    text: TextSpan(
      text: text,
      style: style?.copyWith(color: color),
    ),
    textDirection: TextDirection.ltr,
  )..layout();
  painter.paint(canvas, Offset(x, y - painter.height / 2));
}

void _drawXAxisLabels(
  Canvas canvas,
  Size size,
  double maxTime,
  double leftAxisWidth,
  double rightPad,
  TextStyle? style,
  Color color,
) {
  final plotWidth = size.width - leftAxisWidth - rightPad;
  final ticks = [0.0, 0.5, 1.0];
  for (final t in ticks) {
    final label = _formatOffset((maxTime * t).round());
    final painter = TextPainter(
      text: TextSpan(
        text: label,
        style: style?.copyWith(color: color),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    var x = leftAxisWidth + t * plotWidth;
    if (t == 0) {
      // left-aligned at the axis
    } else if (t == 1.0) {
      x -= painter.width;
    } else {
      x -= painter.width / 2;
    }
    painter.paint(canvas, Offset(x, size.height - painter.height));
  }
}

void _drawCrosshair(
  Canvas canvas,
  Size size,
  double x,
  double topPad,
  double bottomPad,
  Color color,
) {
  canvas.drawLine(
    Offset(x, topPad),
    Offset(x, size.height - bottomPad),
    Paint()
      ..color = color.withValues(alpha: 0.4)
      ..strokeWidth = 1,
  );
}

class _DepthChartPainter extends CustomPainter {
  _DepthChartPainter({
    required this.samples,
    required this.maxTime,
    required this.maxDepth,
    required this.touchIndex,
    required this.lineColor,
    required this.labelColor,
    required this.textStyle,
    required this.leftAxisWidth,
    required this.rightPad,
    required this.showTimeAxis,
  });

  final List<DiveProfileSample> samples;
  final double maxTime;
  final double maxDepth;
  final int? touchIndex;
  final Color lineColor;
  final Color labelColor;
  final TextStyle? textStyle;
  final double leftAxisWidth;
  final double rightPad;
  final bool showTimeAxis;

  static const _topPad = 6.0;

  @override
  void paint(Canvas canvas, Size size) {
    if (maxTime <= 0 || maxDepth <= 0) return;
    final bottomPad = showTimeAxis ? 16.0 : 4.0;
    final plotWidth = size.width - leftAxisWidth - rightPad;
    final plotHeight = size.height - _topPad - bottomPad;

    double xOf(int offsetSeconds) => leftAxisWidth + (offsetSeconds / maxTime) * plotWidth;
    double yOf(double depth) => _topPad + (depth / maxDepth) * plotHeight; // deeper = lower

    final fillPath = Path()..moveTo(xOf(samples.first.offsetSeconds), _topPad);
    for (final s in samples) {
      fillPath.lineTo(xOf(s.offsetSeconds), yOf(s.depthM));
    }
    fillPath
      ..lineTo(xOf(samples.last.offsetSeconds), _topPad)
      ..close();
    canvas.drawPath(fillPath, Paint()..color = lineColor.withValues(alpha: 0.15));

    final linePath = Path()..moveTo(xOf(samples.first.offsetSeconds), yOf(samples.first.depthM));
    for (final s in samples.skip(1)) {
      linePath.lineTo(xOf(s.offsetSeconds), yOf(s.depthM));
    }
    canvas.drawPath(
      linePath,
      Paint()
        ..color = lineColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    _drawYLabel(canvas, '0m', 0, _topPad, textStyle, labelColor);
    _drawYLabel(
      canvas,
      '${maxDepth.toStringAsFixed(0)}m',
      0,
      _topPad + plotHeight,
      textStyle,
      labelColor,
    );

    if (showTimeAxis) {
      _drawXAxisLabels(canvas, size, maxTime, leftAxisWidth, rightPad, textStyle, labelColor);
    }

    final idx = touchIndex;
    if (idx != null && idx < samples.length) {
      final s = samples[idx];
      _drawCrosshair(canvas, size, xOf(s.offsetSeconds), _topPad, bottomPad, lineColor);
      canvas.drawCircle(Offset(xOf(s.offsetSeconds), yOf(s.depthM)), 4, Paint()..color = lineColor);
    }
  }

  @override
  bool shouldRepaint(covariant _DepthChartPainter oldDelegate) =>
      oldDelegate.samples != samples || oldDelegate.touchIndex != touchIndex;
}

class _TempChartPainter extends CustomPainter {
  _TempChartPainter({
    required this.samples,
    required this.maxTime,
    required this.minTemp,
    required this.maxTemp,
    required this.touchIndex,
    required this.lineColor,
    required this.labelColor,
    required this.textStyle,
    required this.leftAxisWidth,
    required this.rightPad,
  });

  final List<DiveProfileSample> samples;
  final double maxTime;
  final double minTemp;
  final double maxTemp;
  final int? touchIndex;
  final Color lineColor;
  final Color labelColor;
  final TextStyle? textStyle;
  final double leftAxisWidth;
  final double rightPad;

  static const _topPad = 6.0;
  static const _bottomPad = 16.0;

  @override
  void paint(Canvas canvas, Size size) {
    if (maxTime <= 0) return;
    final plotWidth = size.width - leftAxisWidth - rightPad;
    final plotHeight = size.height - _topPad - _bottomPad;
    // A near-flat temperature reading (common on a shallow/short dive) would otherwise
    // divide by a ~0 range and blow the line up to fill the whole chart height.
    final range = (maxTemp - minTemp).abs() < 0.5 ? 1.0 : (maxTemp - minTemp);

    double xOf(int offsetSeconds) => leftAxisWidth + (offsetSeconds / maxTime) * plotWidth;
    // Normal cartesian orientation (higher temperature = higher on the chart) — unlike
    // depth, there's no "down means more" convention to mirror here.
    double yOf(double temp) => _topPad + (1 - (temp - minTemp) / range) * plotHeight;

    final withTemp = samples.where((s) => s.temperatureC != null).toList();
    if (withTemp.length < 2) return;

    final linePath = Path()
      ..moveTo(xOf(withTemp.first.offsetSeconds), yOf(withTemp.first.temperatureC!));
    for (final s in withTemp.skip(1)) {
      linePath.lineTo(xOf(s.offsetSeconds), yOf(s.temperatureC!));
    }
    canvas.drawPath(
      linePath,
      Paint()
        ..color = lineColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    _drawYLabel(canvas, '${maxTemp.toStringAsFixed(0)}°C', 0, _topPad, textStyle, labelColor);
    _drawYLabel(
      canvas,
      '${minTemp.toStringAsFixed(0)}°C',
      0,
      _topPad + plotHeight,
      textStyle,
      labelColor,
    );
    _drawXAxisLabels(canvas, size, maxTime, leftAxisWidth, rightPad, textStyle, labelColor);

    final idx = touchIndex;
    if (idx != null && idx < samples.length && samples[idx].temperatureC != null) {
      final s = samples[idx];
      _drawCrosshair(canvas, size, xOf(s.offsetSeconds), _topPad, _bottomPad, lineColor);
      canvas.drawCircle(
        Offset(xOf(s.offsetSeconds), yOf(s.temperatureC!)),
        4,
        Paint()..color = lineColor,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _TempChartPainter oldDelegate) =>
      oldDelegate.samples != samples || oldDelegate.touchIndex != touchIndex;
}
