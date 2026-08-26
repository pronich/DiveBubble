import 'package:flutter/material.dart';

import '../../../../domain/entities/dive_log_entry.dart';

/// Depth (filled area, primary) + temperature (thin line, secondary scale) over time — the
/// only graph DiveLog shows, deliberately with no interactivity (tooltips, zoom, tap-to-
/// inspect) or axis gridlines beyond the two edge labels; this is a glanceable shape, not an
/// instrument-grade profile viewer. No charting package pulled in for this one graph — same
/// dependency-free posture as core/formatting/date_format.dart's own hand-rolled formatters.
class DiveProfileChart extends StatelessWidget {
  const DiveProfileChart({super.key, required this.samples});

  final List<DiveProfileSample> samples;

  @override
  Widget build(BuildContext context) {
    if (samples.length < 2) return const SizedBox.shrink();
    final theme = Theme.of(context);

    return SizedBox(
      height: 180,
      child: CustomPaint(
        painter: _DiveProfilePainter(
          samples: samples,
          depthColor: theme.colorScheme.primary,
          tempColor: theme.colorScheme.tertiary,
          labelColor: theme.colorScheme.onSurfaceVariant,
          textStyle: theme.textTheme.labelSmall,
        ),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class _DiveProfilePainter extends CustomPainter {
  _DiveProfilePainter({
    required this.samples,
    required this.depthColor,
    required this.tempColor,
    required this.labelColor,
    required this.textStyle,
  });

  final List<DiveProfileSample> samples;
  final Color depthColor;
  final Color tempColor;
  final Color labelColor;
  final TextStyle? textStyle;

  // Left/right padding for the small time-axis labels; top padding so the depth fill has
  // room to breathe above zero rather than touching the very top edge.
  static const _leftPad = 4.0;
  static const _rightPad = 4.0;
  static const _topPad = 8.0;
  static const _bottomPad = 18.0; // room for the time-axis labels

  @override
  void paint(Canvas canvas, Size size) {
    final maxTime = samples.last.offsetSeconds.toDouble();
    final maxDepth = samples.map((s) => s.depthM).reduce((a, b) => a > b ? a : b);
    if (maxTime <= 0 || maxDepth <= 0) return;

    final plotWidth = size.width - _leftPad - _rightPad;
    final plotHeight = size.height - _topPad - _bottomPad;

    Offset depthPoint(DiveProfileSample s) {
      final x = _leftPad + (s.offsetSeconds / maxTime) * plotWidth;
      final y = _topPad + (s.depthM / maxDepth) * plotHeight; // deeper = further down
      return Offset(x, y);
    }

    // Filled depth area, deepest point pulling the line down — reads as a dive profile at a
    // glance the way every dive computer's own app draws it.
    final fillPath = Path()..moveTo(_leftPad, _topPad);
    for (final s in samples) {
      final p = depthPoint(s);
      fillPath.lineTo(p.dx, p.dy);
    }
    fillPath
      ..lineTo(_leftPad + plotWidth, _topPad)
      ..close();
    canvas.drawPath(fillPath, Paint()..color = depthColor.withValues(alpha: 0.15));

    final depthLine = Path()..moveTo(depthPoint(samples.first).dx, depthPoint(samples.first).dy);
    for (final s in samples.skip(1)) {
      final p = depthPoint(s);
      depthLine.lineTo(p.dx, p.dy);
    }
    canvas.drawPath(
      depthLine,
      Paint()
        ..color = depthColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    // Temperature line, only drawn if every sample actually has a reading — a partial line
    // with gaps would misleadingly look like the temperature itself dropped to zero.
    final temps = samples.map((s) => s.temperatureC).toList();
    if (temps.every((t) => t != null)) {
      final values = temps.cast<double>();
      final minT = values.reduce((a, b) => a < b ? a : b);
      final maxT = values.reduce((a, b) => a > b ? a : b);
      final range = (maxT - minT).abs() < 0.5 ? 1.0 : (maxT - minT);

      Offset tempPoint(DiveProfileSample s) {
        final x = _leftPad + (s.offsetSeconds / maxTime) * plotWidth;
        // Inverted like depth so temperature reads top-to-bottom = warm-to-cold, matching
        // the same "down is more" visual language as the depth fill beneath it.
        final normalized = (s.temperatureC! - minT) / range;
        final y = _topPad + (1 - normalized) * plotHeight;
        return Offset(x, y);
      }

      final tempLine = Path()..moveTo(tempPoint(samples.first).dx, tempPoint(samples.first).dy);
      for (final s in samples.skip(1)) {
        final p = tempPoint(s);
        tempLine.lineTo(p.dx, p.dy);
      }
      canvas.drawPath(
        tempLine,
        Paint()
          ..color = tempColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );
    }

    _drawLabel(canvas, '0:00', Offset(_leftPad, size.height - _bottomPad + 2));
    _drawLabel(
      canvas,
      _formatDuration(maxTime.round()),
      Offset(size.width - _rightPad, size.height - _bottomPad + 2),
      alignRight: true,
    );
    _drawLabel(
      canvas,
      '${maxDepth.toStringAsFixed(0)}m',
      Offset(_leftPad, _topPad + plotHeight - 12),
    );
  }

  void _drawLabel(Canvas canvas, String text, Offset position, {bool alignRight = false}) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: textStyle?.copyWith(color: labelColor),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    final offset = alignRight ? Offset(position.dx - painter.width, position.dy) : position;
    painter.paint(canvas, offset);
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '$minutes:${secs.toString().padLeft(2, '0')}';
  }

  @override
  bool shouldRepaint(covariant _DiveProfilePainter oldDelegate) => oldDelegate.samples != samples;
}
