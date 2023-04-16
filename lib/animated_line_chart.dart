import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DataPoint {
  final DateTime x;
  final double y;

  DataPoint({required this.x, required this.y});
}

class AnimatedLineChart extends StatefulWidget {
  final List<DataPoint> data;
  final DateTime dividerX;
  final Color dividerXColor;
  final Color leftChartColor;
  final Color rightChartColor;
  final bool? showXLabel;
  final bool? showYLabel;
  final TextStyle? labelTextStyle;
  final bool? showDotAnimation;
  final bool? showLastData;

  const AnimatedLineChart({
    Key? key,
    required this.data,
    required this.dividerX,
    this.dividerXColor = Colors.grey,
    this.leftChartColor = Colors.blue,
    this.rightChartColor = Colors.red,
    this.showXLabel = true,
    this.showYLabel = true,
    this.labelTextStyle = const TextStyle(color: Colors.grey, fontSize: 12),
    this.showDotAnimation = true,
    this.showLastData = true,
  }) : super(key: key);

  @override
  State<AnimatedLineChart> createState() => _AnimatedLineChartState();
}

class _AnimatedLineChartState extends State<AnimatedLineChart>
    with TickerProviderStateMixin {
  late AnimationController _lineAnimationController;
  late Animation<double> _lineAnimation;
  late AnimationController _dotAnimationController;
  late Animation<double> _dotAnimation;

  bool showDetails = false;
  Offset? tapPosition;

  @override
  void initState() {
    super.initState();

    _lineAnimationController =
        AnimationController(vsync: this, duration: const Duration(seconds: 2));
    _lineAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _lineAnimationController, curve: Curves.ease));

    _dotAnimationController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _dotAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(
        parent: _dotAnimationController, curve: Curves.easeInOut));
    if (widget.showDotAnimation!) {
      _dotAnimationController.repeat(reverse: true);
    }

    _lineAnimationController.forward();
  }

  @override
  void dispose() {
    _lineAnimationController.dispose();
    _dotAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPressStart: (LongPressStartDetails details) {
        setState(() {
          showDetails = true;
          tapPosition = details.localPosition;
        });
      },
      onLongPressMoveUpdate: (LongPressMoveUpdateDetails details) {
        setState(() {
          tapPosition = details.localPosition;
        });
      },
      onLongPressEnd: (LongPressEndDetails details) {
        setState(() {
          showDetails = false;
          tapPosition = null;
        });
      },
      child: AnimatedBuilder(
          animation: Listenable.merge(
              [_lineAnimationController, _dotAnimationController]),
          builder: (context, _) {
            return CustomPaint(
              painter: _LineChartPainter(
                data: widget.data,
                dividedX: widget.dividerX,
                dividerXColor: widget.dividerXColor,
                leftColor: widget.leftChartColor,
                rightColor: widget.rightChartColor,
                lineAnimation: _lineAnimation.value,
                dotAnimation: _dotAnimation.value,
                showXLabel: widget.showXLabel!,
                showYLabel: widget.showYLabel!,
                labelTextStyle: widget.labelTextStyle!,
                showDetails: showDetails,
                tapPosition: tapPosition,
              ),
            );
          }),
    );
  }
}

class _LineChartPainter extends CustomPainter {
  final List<DataPoint> data;
  final DateTime dividedX;
  final Color dividerXColor;
  final Color leftColor;
  final Color rightColor;
  final double lineAnimation;
  final double dotAnimation;
  final bool showXLabel;
  final bool showYLabel;
  final TextStyle labelTextStyle;
  final bool showDetails;
  final Offset? tapPosition;

  _LineChartPainter({
    required this.data,
    required this.dividedX,
    required this.leftColor,
    required this.rightColor,
    required this.lineAnimation,
    required this.dotAnimation,
    required this.showDetails,
    required this.tapPosition,
    required this.dividerXColor,
    required this.showXLabel,
    required this.showYLabel,
    required this.labelTextStyle,
  });

  double dotRadius = 6.0;
  double dashHeight = 4;
  double gapHeight = 4;

  double lastX = 0;
  double lastY = 0;

  bool leftPathStarted = false;
  bool rightPathStarted = false;

  TextPainter createTextPainter(String text) {
    final span = TextSpan(text: text, style: labelTextStyle);
    final textPainter = TextPainter(
        text: span,
        textAlign: TextAlign.left,
        textDirection: ui.TextDirection.ltr);
    return textPainter;
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    // Calculate X and Y
    final minY = data.reduce((a, b) => a.y < b.y ? a : b).y;
    final maxY = data.reduce((a, b) => a.y > b.y ? a : b).y;
    final minX = data.reduce((a, b) => a.x.isBefore(b.x) ? a : b).x;
    final maxX = data.reduce((a, b) => a.x.isAfter(b.x) ? a : b).x;

    final scaleX = size.width / maxX.difference(minX).inMilliseconds;
    final scaleY = size.height / (maxY - minY);

    var dividedXPosition =
        (dividedX.millisecondsSinceEpoch - minX.millisecondsSinceEpoch) *
            scaleX;

    lastX = 0;
    lastY = 0;

    // Draw line and area
    drawLineArea(
        canvas, size, data, minX, minY, scaleX, scaleY, dividedXPosition);

    // Draw dividing line
    drawDividingLine(canvas, size, dividedXPosition);

    // Draw dot animation
    drawAnimatedDot(
        canvas, size, data, dotAnimation, minX, minY, scaleX, scaleY);

    // Draw label
    drawLabel(canvas, size, showYLabel, showXLabel, minX, minY, maxX, maxY,
        scaleX, scaleY);

    // Draw last Y
    drawLastY(canvas, size, data, rightColor, leftColor);

    // Draw detail box
    drawDetailBox(canvas, size, data);
  }

  @override
  bool shouldRepaint(covariant _LineChartPainter oldDelegate) {
    return oldDelegate.lineAnimation != lineAnimation ||
        oldDelegate.dotAnimation != dotAnimation ||
        showDetails ||
        tapPosition == null;
  }

  void drawDividingLine(Canvas canvas, Size size, double dividedXPosition) {
    final paintDividingLine = Paint()
      ..color = dividerXColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    double startY = 0;

    while (startY < size.height) {
      canvas.drawLine(
        Offset(dividedXPosition, startY),
        Offset(dividedXPosition, startY + dashHeight),
        paintDividingLine,
      );
      startY += dashHeight + gapHeight;
    }
  }

  void drawLineArea(
      Canvas canvas,
      Size size,
      List<DataPoint> data,
      DateTime minX,
      double minY,
      double scaleX,
      double scaleY,
      double dividedXPosition) {
    final leftGradient = LinearGradient(
      colors: [leftColor.withOpacity(0.5), leftColor.withOpacity(0)],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    );

    final rightGradient = LinearGradient(
      colors: [rightColor.withOpacity(0.5), rightColor.withOpacity(0)],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    );

    final paintLeftFill = Paint()
      ..shader = leftGradient
          .createShader(Rect.fromLTRB(0, 0, size.width, size.height));
    final paintRightFill = Paint()
      ..shader = rightGradient
          .createShader(Rect.fromLTRB(0, 0, size.width, size.height));

    final leftPath = Path();
    final rightPath = Path();

    leftPathStarted = false;
    rightPathStarted = false;

    for (int i = 0; i < data.length; i++) {
      double x =
          (data[i].x.millisecondsSinceEpoch - minX.millisecondsSinceEpoch) *
              scaleX;
      double y = size.height - (data[i].y - minY) * scaleY;

      if (dividedXPosition < 0) dividedXPosition = 0;

      if (x <= dividedXPosition) {
        if (!leftPathStarted) {
          leftPath.moveTo(x, y);
          leftPathStarted = true;
        } else {
          leftPath.lineTo(x, y);
        }
        lastX = x;
        lastY = y;
      } else {
        double rightLineAnimation = max(0, lineAnimation * 2 - 1);

        if (x - dividedXPosition <= size.width * rightLineAnimation) {
          if (!rightPathStarted) {
            rightPath.moveTo(lastX, lastY);
            rightPathStarted = true;
          }
          rightPath.lineTo(x, y);
          lastX = x;
          lastY = y;
        }
      }

      if (x >= size.width * lineAnimation) {
        break;
      }
    }

    late final Paint paintLine = Paint()
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    if (leftPathStarted) {
      paintLine.color = leftColor;
      if (dividedXPosition >= lastX) {
        leftPath.lineTo(lastX, size.height);
      } else {
        leftPath.lineTo(dividedXPosition, size.height);
      }

      canvas.drawPath(leftPath, paintLine);
    }

    if (rightPathStarted) {
      paintLine.color = rightColor;
      rightPath.lineTo(lastX, size.height);

      canvas.drawPath(rightPath, paintLine);
    }

    if (leftPathStarted) {
      leftPath.lineTo(dividedXPosition, size.height);
      leftPath.lineTo(leftPath.getBounds().left, size.height);
      leftPath.close();

      canvas.drawPath(leftPath, paintLeftFill);

      paintLeftFill.color = Colors.transparent;
    }

    if (rightPathStarted) {
      rightPath.lineTo(lastX, size.height);
      rightPath.lineTo(dividedXPosition, size.height);
      rightPath.close();

      canvas.drawPath(rightPath, paintRightFill);
    }
  }

  void drawAnimatedDot(
      Canvas canvas,
      Size size,
      List<DataPoint> data,
      double dotAnimation,
      DateTime minX,
      double minY,
      double scaleX,
      double scaleY) {
    final dotOpacity = dotAnimation;
    final dotPaint = Paint()..color = rightColor.withOpacity(dotOpacity);

    final lastPoint = data[data.length - 1];
    lastX = (lastPoint.x.millisecondsSinceEpoch - minX.millisecondsSinceEpoch) *
        scaleX;
    lastY = size.height - (lastPoint.y - minY) * scaleY;

    if (lastX <= size.width * lineAnimation) {
      canvas.drawCircle(Offset(lastX, lastY), dotRadius, dotPaint);
    }
  }

  void drawLabel(
      Canvas canvas,
      Size size,
      bool showYLabel,
      bool showXLabel,
      DateTime minX,
      double minY,
      DateTime maxX,
      double maxY,
      double scaleX,
      double scaleY) {
    // Draw Y axis labels
    if (showYLabel) {
      for (double y = minY; y <= maxY; y += (maxY - minY) / 5) {
        double yPos = size.height - (y - minY) * scaleY;
        final textPainter = createTextPainter(y.toStringAsFixed(1));
        textPainter.layout();
        textPainter.paint(canvas,
            Offset(-textPainter.width - 10, yPos - textPainter.height / 2));
      }
    }

    // Draw X axis labels
    if (showXLabel) {
      for (DateTime x = minX;
          x.isBefore(maxX);
          x = x.add(maxX.difference(minX) ~/ 5)) {
        double xPos =
            (x.millisecondsSinceEpoch - minX.millisecondsSinceEpoch) * scaleX;
        final textPainter = createTextPainter(DateFormat('MMM dd').format(x));
        textPainter.layout();
        textPainter.paint(
            canvas, Offset(xPos - textPainter.width / 10, size.height + 10));
      }
    }
  }

  void drawLastY(Canvas canvas, Size size, List<DataPoint> data,
      Color rightColor, Color leftColor) {
    final selectedDotPosition = Offset(lastX, lastY);
    final lastDataPoint = data.last;

    final textSpan = TextSpan(
      text: lastDataPoint.y.toStringAsFixed(2),
      style: TextStyle(
        color: rightPathStarted ? rightColor : leftColor,
        fontWeight: FontWeight.bold,
        fontSize: 12,
      ),
    );

    final textPainter = TextPainter(
      text: textSpan,
      textAlign: TextAlign.center,
      textDirection: ui.TextDirection.ltr,
    )..layout();

    final xPos = selectedDotPosition.dx - textPainter.width / 2;
    final yPos = selectedDotPosition.dy - 20.0;

    textPainter.paint(canvas, Offset(xPos, yPos));
  }

  void drawDetailBox(ui.Canvas canvas, ui.Size size, List<DataPoint> data) {
    // Draw detail box
    Color detailBoxTextColor = Colors.white;
    DataPoint? selectedDataPoint;
    if (showDetails) {
      double x = tapPosition!.dx;
      final minX = data.reduce((a, b) => a.x.isBefore(b.x) ? a : b).x;
      final maxX = data.reduce((a, b) => a.x.isAfter(b.x) ? a : b).x;
      final dividedXPosition =
          (dividedX.millisecondsSinceEpoch - minX.millisecondsSinceEpoch) *
              (size.width / maxX.difference(minX).inMilliseconds);

      double tappedTime =
          (x / size.width) * maxX.difference(minX).inMilliseconds +
              minX.millisecondsSinceEpoch;

      double smallestDiff = double.infinity;
      for (DataPoint point in data) {
        double diff = (point.x.millisecondsSinceEpoch - tappedTime).abs();
        if (diff < smallestDiff) {
          smallestDiff = diff;
          selectedDataPoint = point;
        }
      }

      if (x <= dividedXPosition) {
        detailBoxTextColor = leftColor;
      } else {
        detailBoxTextColor = rightColor;
      }
    }
    if (showDetails && tapPosition != null && selectedDataPoint != null) {
      final textSpan = TextSpan(
        text:
            'Date: ${DateFormat('MMM dd, yyyy').format(selectedDataPoint.x)}\nValue: ${selectedDataPoint.y.toStringAsFixed(2)}',
        style: TextStyle(
          color: detailBoxTextColor,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      );
      final textPainter = TextPainter(
        text: textSpan,
        textAlign: TextAlign.center,
        textDirection: ui.TextDirection.ltr,
      )..layout();

      // Define box dimensions and position
      final double boxWidth = textPainter.width + 20;
      final double boxHeight = textPainter.height + 20;
      final double xPosition = tapPosition!.dx - boxWidth / 2;
      final double yPosition = tapPosition!.dy - boxHeight - 20;

      // Draw lines
      final linePaint = Paint()
        ..color = dividerXColor
        ..strokeWidth = 1;

      // Draw line from data point to x-axis
      double crossX = 0;
      while (crossX < size.height) {
        canvas.drawLine(
          Offset(xPosition + boxWidth / 2, crossX),
          Offset(xPosition + boxWidth / 2, crossX + dashHeight),
          linePaint,
        );
        crossX += dashHeight + gapHeight;
      }

      // Draw line from data point to y-axis
      double crossY = 0;
      while (crossY < size.width) {
        canvas.drawLine(
          Offset(crossY, yPosition + boxHeight / 2),
          Offset(crossY + dashHeight, yPosition + boxHeight / 2),
          linePaint,
        );
        crossY += dashHeight + gapHeight;
      }

      // Draw box
      final boxPaint = Paint()
        ..color = detailBoxTextColor.withOpacity(0.1)
        ..strokeWidth = 1
        ..style = PaintingStyle.fill;
      final boxPath = Path()
        ..moveTo(xPosition, yPosition)
        ..lineTo(xPosition + boxWidth, yPosition)
        ..lineTo(xPosition + boxWidth, yPosition + boxHeight)
        ..lineTo(xPosition, yPosition + boxHeight)
        ..close();
      canvas.drawPath(boxPath, boxPaint);

      // Draw text
      textPainter.paint(canvas, Offset(xPosition + 10, yPosition + 10));
    }
  }
}
