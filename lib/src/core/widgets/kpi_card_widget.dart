import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Configuration for declarative KPI Card widgets.
/// Allows developers to define analytical computations on data models.
class KpiCardConfig {
  final String key;
  final String title;
  final String Function(List<dynamic> items) computeValue;
  final IconData icon;
  final Color color;
  final String? trendSuffix;
  
  /// Dynamic calculation for trend (e.g. comparing last month vs this month,
  /// or comparing active vs inactive).
  final double Function(List<dynamic> items)? computeTrendPercent;

  const KpiCardConfig({
    required this.key,
    required this.title,
    required this.computeValue,
    required this.icon,
    required this.color,
    this.trendSuffix,
    this.computeTrendPercent,
  });
}

/// A highly polished, interactive KPI Metric Card widget designed for modern dashboards.
/// It features:
/// - Smooth micro-animations on hover (scaling, glowing HSL-tailored borders, shadows).
/// - Responsive glassmorphic style layout.
/// - Dynamic Green/Red trend indicators with beautiful micro-badges.
/// - An embedded, smooth cubic-curve custom-painted sparkline with color-themed gradients.
class KpiCardWidget extends StatefulWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final double? trendPercent;
  final String? trendSuffix;
  final List<double>? sparklineData;
  final VoidCallback? onTap;

  const KpiCardWidget({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.trendPercent,
    this.trendSuffix,
    this.sparklineData,
    this.onTap,
  });

  /// Factory constructor to build a [KpiCardWidget] directly from a [KpiCardConfig] and a list of entities.
  factory KpiCardWidget.fromConfig({
    Key? key,
    required KpiCardConfig config,
    required List<dynamic> items,
    List<double>? sparklineData,
    VoidCallback? onTap,
  }) {
    final double? trend = config.computeTrendPercent?.call(items);
    final String val = config.computeValue(items);
    return KpiCardWidget(
      key: key,
      title: config.title,
      value: val,
      icon: config.icon,
      color: config.color,
      trendPercent: trend,
      trendSuffix: config.trendSuffix,
      sparklineData: sparklineData,
      onTap: onTap,
    );
  }

  @override
  State<KpiCardWidget> createState() => _KpiCardWidgetState();
}

class _KpiCardWidgetState extends State<KpiCardWidget> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    final Color cardBgColor = isDark
        ? Color.lerp(Theme.of(context).colorScheme.surface, widget.color, 0.03)!
        : Color.lerp(Colors.white, widget.color, 0.025)!;

    final Color glowColor = widget.color.withOpacity(_isHovered ? 0.35 : 0.1);
    
    final Color borderColor = _isHovered 
        ? widget.color.withOpacity(0.8)
        : widget.color.withOpacity(0.2);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: widget.onTap != null ? SystemMouseCursors.click : SystemMouseCursors.basic,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _isHovered ? 1.025 : 1.0,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOutCubic,
            decoration: BoxDecoration(
              color: cardBgColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: borderColor, width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: glowColor,
                  blurRadius: _isHovered ? 16.0 : 8.0,
                  offset: _isHovered ? const Offset(0, 8) : const Offset(0, 4),
                  spreadRadius: _isHovered ? 2.0 : 0.0,
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Stack(
                children: [
                  // Subtle accent glow in the top-right corner
                  Positioned(
                    right: -24,
                    top: -24,
                    child: Container(
                      width: 96,
                      height: 96,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            widget.color.withOpacity(isDark ? 0.15 : 0.12),
                            widget.color.withOpacity(0.0),
                          ],
                        ),
                      ),
                    ),
                  ),
                  
                  Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Top row: Title and Icon
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                widget.title,
                                style: GoogleFonts.outfit(
                                  textStyle: Theme.of(context).textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: widget.color.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: widget.color.withOpacity(0.3),
                                  width: 1,
                                ),
                              ),
                              child: Icon(
                                widget.icon,
                                color: widget.color,
                                size: 20,
                              ),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // Value Text
                        Text(
                          widget.value,
                          style: GoogleFonts.outfit(
                            textStyle: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                        ),
                        
                        const SizedBox(height: 12),
                        
                        // Bottom row: Trend indicator & Sparkline
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            // Trend Pill
                            if (widget.trendPercent != null)
                              _buildTrendIndicator(context, widget.trendPercent!, widget.trendSuffix)
                            else
                              const SizedBox(height: 24),
                            
                            const SizedBox(width: 16),
                            
                            // Sparkline takes up the remaining horizontal space
                            if (widget.sparklineData != null && widget.sparklineData!.isNotEmpty)
                              Expanded(
                                child: SizedBox(
                                  height: 32,
                                  child: CustomPaint(
                                    painter: _SparklinePainter(
                                      data: widget.sparklineData!,
                                      color: widget.color,
                                      isHovered: _isHovered,
                                    ),
                                  ),
                                ),
                              )
                            else
                              const Spacer(),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTrendIndicator(BuildContext context, double trend, String? suffix) {
    final isPositive = trend >= 0;
    final String prefix = isPositive ? '+' : '';
    final String text = '$prefix${trend.toStringAsFixed(1)}%${suffix != null ? ' $suffix' : ''}';
    
    final Color badgeColor = isPositive ? const Color(0xFF10B981) : const Color(0xFFEF4444); // Green or Red
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: badgeColor.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: badgeColor.withOpacity(0.25),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isPositive ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
            color: badgeColor,
            size: 12,
          ),
          const SizedBox(width: 4),
          Text(
            text,
            style: GoogleFonts.outfit(
              textStyle: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ).copyWith(color: badgeColor),
          ),
        ],
      ),
    );
  }
}

/// A premium custom painter that draws a smooth, cubic Bézier sparkline with a gradient fill.
class _SparklinePainter extends CustomPainter {
  final List<double> data;
  final Color color;
  final bool isHovered;

  _SparklinePainter({
    required this.data,
    required this.color,
    required this.isHovered,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (data.length < 2) return;

    final double minVal = data.reduce((a, b) => a < b ? a : b);
    final double maxVal = data.reduce((a, b) => a > b ? a : b);
    final double range = maxVal - minVal == 0 ? 1 : maxVal - minVal;

    final double widthStep = size.width / (data.length - 1);
    
    // Convert points to UI space
    final List<Offset> points = [];
    for (int i = 0; i < data.length; i++) {
      final double x = i * widthStep;
      // Subtracting from height since UI coordinate (0,0) is top-left
      final double y = size.height - ((data[i] - minVal) / range * (size.height - 4) + 2);
      points.add(Offset(x, y));
    }

    // Build smooth cubic path
    final Path path = Path();
    path.moveTo(points.first.dx, points.first.dy);

    for (int i = 0; i < points.length - 1; i++) {
      final p0 = points[i];
      final p1 = points[i + 1];
      
      // Control points for cubic Bézier curve
      final controlPoint1 = Offset(p0.dx + widthStep / 2, p0.dy);
      final controlPoint2 = Offset(p1.dx - widthStep / 2, p1.dy);

      path.cubicTo(
        controlPoint1.dx, controlPoint1.dy,
        controlPoint2.dx, controlPoint2.dy,
        p1.dx, p1.dy,
      );
    }

    // Draw the gradient under-fill
    final Path fillPath = Path.from(path);
    fillPath.lineTo(size.width, size.height);
    fillPath.lineTo(0, size.height);
    fillPath.close();

    final Paint fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          color.withOpacity(isHovered ? 0.25 : 0.15),
          color.withOpacity(0.0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawPath(fillPath, fillPaint);

    // Draw the line
    final Paint linePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = isHovered ? 2.5 : 1.8
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(path, linePaint);
  }

  @override
  bool shouldRepaint(covariant _SparklinePainter oldDelegate) {
    return oldDelegate.isHovered != isHovered || 
           oldDelegate.color != color || 
           oldDelegate.data != data;
  }
}
