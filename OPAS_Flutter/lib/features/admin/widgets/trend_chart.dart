import 'package:flutter/material.dart';

class TrendChartData {
  final List<double> values;
  final List<String> labels;
  final String? title;
  final String? unit;

  TrendChartData({
    required this.values,
    required this.labels,
    this.title,
    this.unit,
  });
}

class TrendChart extends StatelessWidget {
  final TrendChartData data;
  final Color lineColor;
  final Color fillColor;
  final bool isLoading;

  const TrendChart({
    Key? key,
    required this.data,
    this.lineColor = const Color(0xFF2196F3),
    this.fillColor = const Color(0xFF2196F3),
    this.isLoading = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: isLoading
            ? const Center(
                child: CircularProgressIndicator(),
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (data.title != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(
                        data.title!,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  SizedBox(
                    height: 200,
                    child: CustomPaint(
                      painter: _TrendChartPainter(
                        values: data.values,
                        lineColor: lineColor,
                        fillColor: fillColor,
                      ),
                      size: Size.infinite,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 40,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: data.labels.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (context, index) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            data.labels[index],
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey[700],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  if (data.values.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Min: ${data.values.reduce((a, b) => a < b ? a : b).toStringAsFixed(2)}',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey[600],
                            ),
                          ),
                          Text(
                            'Avg: ${(data.values.fold(0.0, (a, b) => a + b) / data.values.length).toStringAsFixed(2)}',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey[600],
                            ),
                          ),
                          Text(
                            'Max: ${data.values.reduce((a, b) => a > b ? a : b).toStringAsFixed(2)}',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
      ),
    );
  }
}

class _TrendChartPainter extends CustomPainter {
  final List<double> values;
  final Color lineColor;
  final Color fillColor;

  _TrendChartPainter({
    required this.values,
    required this.lineColor,
    required this.fillColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;

    final paint = Paint()
      ..color = lineColor
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final fillPaint = Paint()
      ..color = fillColor.withOpacity(0.1)
      ..style = PaintingStyle.fill;

    final maxValue =
        values.reduce((a, b) => a > b ? a : b);
    final minValue =
        values.reduce((a, b) => a < b ? a : b);
    final range = maxValue - minValue;

    final xStep = size.width / (values.length - 1);
    final points = <Offset>[];

    for (int i = 0; i < values.length; i++) {
      final y = size.height -
          ((values[i] - minValue) / range) * size.height;
      points.add(Offset(i * xStep, y));
    }

    if (points.length > 1) {
      // Draw filled area
      final pathFill = Path()
        ..moveTo(0, size.height);

      for (var point in points) {
        pathFill.lineTo(point.dx, point.dy);
      }

      pathFill.lineTo(size.width, size.height);
      pathFill.close();

      canvas.drawPath(pathFill, fillPaint);

      // Draw line
      for (int i = 0; i < points.length - 1; i++) {
        canvas.drawLine(points[i], points[i + 1], paint);
      }

      // Draw points
      final pointPaint = Paint()
        ..color = lineColor
        ..strokeWidth = 4;

      for (var point in points) {
        canvas.drawCircle(point, 3, pointPaint);
      }
    }
  }

  @override
  bool shouldRepaint(_TrendChartPainter oldDelegate) {
    return values != oldDelegate.values;
  }
}
