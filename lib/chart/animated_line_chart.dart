import 'dart:math';

import 'package:fl_animated_linechart/chart/area_line_chart.dart';
import 'package:fl_animated_linechart/chart/datetime_chart_point.dart';
import 'package:fl_animated_linechart/chart/highlight_point.dart';
import 'package:fl_animated_linechart/chart/line_chart.dart';
import 'package:fl_animated_linechart/common/animated_path_util.dart';
import 'package:fl_animated_linechart/common/pair.dart';
import 'package:fl_animated_linechart/common/text_direction_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:intl/intl.dart';
import 'package:path_drawing/path_drawing.dart';

typedef TapText = String Function(String prefix, double y, String unit);

class AnimatedLineChart extends StatefulWidget {
  final LineChart chart;
  final TapText? tapText;
  final TextStyle? textStyle;
  final Color toolTipColor;
  final Color gridColor;
  final List<Legend>? legends;
  final bool? showMarkerLines;
  final List<DateTime>? verticalMarker;
  final Color? verticalMarkerColor;
  final List<Icon>? verticalMarkerIcon;

  const AnimatedLineChart(
    this.chart, {
    Key? key,
    this.tapText,
    this.textStyle,
    required this.gridColor,
    required this.toolTipColor,
    this.legends,
    this.showMarkerLines,
    this.verticalMarker,
    this.verticalMarkerColor,
    this.verticalMarkerIcon,
  }) : super(key: key);

  @override
  _AnimatedLineChartState createState() => _AnimatedLineChartState();
}

class _AnimatedLineChartState extends State<AnimatedLineChart>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  Animation? _animation;

  @override
  void initState() {
    _controller =
        AnimationController(vsync: this, duration: Duration(milliseconds: 700));

    Animation curve =
        CurvedAnimation(parent: _controller, curve: Curves.easeIn);

    _animation =
        Tween(begin: 0.0, end: 1.0).animate(curve as Animation<double>);

    _controller.forward();

    super.initState();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
      widget.chart.initialize(
          constraints.maxWidth, constraints.maxHeight, widget.textStyle);
      return _GestureWrapper(
        widget.chart,
        _animation,
        tapText: widget.tapText,
        gridColor: widget.gridColor,
        textStyle: widget.textStyle,
        toolTipColor: widget.toolTipColor,
        legends: widget.legends,
        showMarkerLines: widget.showMarkerLines,
        verticalMarker: widget.verticalMarker,
        verticalMarkerColor: widget.verticalMarkerColor,
        verticalMarkerIcon: widget.verticalMarkerIcon,
      );
    });
  }
}

//Wrap gestures, to avoid reinitializing the chart model when doing gestures
class _GestureWrapper extends StatefulWidget {
  final LineChart _chart;
  final Animation? _animation;
  final TapText? tapText;
  final TextStyle? textStyle;
  final Color? toolTipColor;
  final Color? gridColor;
  final List<Legend>? legends;
  final bool? showMarkerLines;
  final List<DateTime>? verticalMarker;
  final Color? verticalMarkerColor;
  final List<Icon>? verticalMarkerIcon;

  const _GestureWrapper(
    this._chart,
    this._animation, {
    Key? key,
    this.tapText,
    this.gridColor,
    this.toolTipColor,
    this.textStyle,
    this.legends,
    this.showMarkerLines,
    this.verticalMarker,
    this.verticalMarkerColor,
    this.verticalMarkerIcon,
  }) : super(key: key);

  @override
  _GestureWrapperState createState() => _GestureWrapperState();
}

class _GestureWrapperState extends State<_GestureWrapper> {
  bool _horizontalDragActive = false;
  double _horizontalDragPosition = 0.0;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      child: _AnimatedChart(
        widget._chart,
        _horizontalDragActive,
        _horizontalDragPosition,
        animation: widget._animation!,
        tapText: widget.tapText,
        gridColor: widget.gridColor,
        style: widget.textStyle,
        toolTipColor: widget.toolTipColor,
        legends: widget.legends,
        showMarkerLines: widget.showMarkerLines,
        verticalMarker: widget.verticalMarker,
        verticalMarkerColor: widget.verticalMarkerColor,
        verticalMarkerIcon: widget.verticalMarkerIcon,
      ),
      onTapDown: (tap) {
        _horizontalDragActive = true;
        _horizontalDragPosition = tap.globalPosition.dx;
        setState(() {});
      },
      onHorizontalDragStart: (dragStartDetails) {
        _horizontalDragActive = true;
        _horizontalDragPosition = dragStartDetails.globalPosition.dx;
        setState(() {});
      },
      onHorizontalDragUpdate: (dragUpdateDetails) {
        _horizontalDragPosition += dragUpdateDetails.primaryDelta!;
        setState(() {});
      },
      onHorizontalDragEnd: (dragEndDetails) {
        _horizontalDragActive = false;
        _horizontalDragPosition = 0.0;
        setState(() {});
      },
      onTapUp: (tap) {
        _horizontalDragActive = false;
        _horizontalDragPosition = 0.0;
        setState(() {});
      },
    );
  }
}

class _AnimatedChart extends AnimatedWidget {
  final LineChart _chart;
  final bool _horizontalDragActive;
  final double _horizontalDragPosition;
  final TapText? tapText;
  final TextStyle? style;
  final Color? gridColor;
  final Color? toolTipColor;
  final List<Legend>? legends;
  final bool? showMarkerLines;
  final List<DateTime>? verticalMarker;
  final Color? verticalMarkerColor;
  final List<Icon>? verticalMarkerIcon;

  _AnimatedChart(
    this._chart,
    this._horizontalDragActive,
    this._horizontalDragPosition, {
    this.tapText,
    Key? key,
    required Animation animation,
    this.style,
    this.gridColor,
    this.toolTipColor,
    this.legends,
    this.showMarkerLines,
    this.verticalMarker,
    this.verticalMarkerColor,
    this.verticalMarkerIcon,
  }) : super(key: key, listenable: animation);

  @override
  Widget build(BuildContext context) {
    Animation animation = listenable as Animation;

    return CustomPaint(
      painter: ChartPainter(
        animation.value,
        _chart,
        _horizontalDragActive,
        _horizontalDragPosition,
        style,
        tapText: tapText,
        gridColor: gridColor!,
        toolTipColor: toolTipColor!,
        legends: legends,
        showMarkerLines: showMarkerLines,
        verticalMarker: verticalMarker,
        verticalMarkerColor: verticalMarkerColor,
        verticalMarkerIcon: verticalMarkerIcon,
      ),
    );
  }
}

class ChartPainter extends CustomPainter {
  static final double _stepCount = 5;

  final DateFormat _formatMonthDayHoursMinutes = DateFormat('dd/MM kk:mm');

  final Paint _gridPainter = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1;

  Paint _linePainter = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2;

  Paint _fillPainter = Paint()
    ..style = PaintingStyle.fill
    ..strokeWidth = 2;

  Paint _tooltipPainter = Paint()..style = PaintingStyle.fill;

  final double _progress;
  final LineChart _chart;
  final bool _horizontalDragActive;
  final double _horizontalDragPosition;

  final List<Legend>? legends;
  final bool? showMarkerLines;
  final List<DateTime>? verticalMarker;
  final Color? verticalMarkerColor;
  final List<Icon>? verticalMarkerIcon;

  TapText? tapText;
  final TextStyle? style;

  static final TapText _defaultTapText =
      (prefix, y, unit) => '$prefix: ${y.toStringAsFixed(1)} $unit';

  ChartPainter(
    this._progress,
    this._chart,
    this._horizontalDragActive,
    this._horizontalDragPosition,
    this.style, {
    this.tapText,
    required Color gridColor,
    required Color toolTipColor,
    this.legends,
    this.showMarkerLines,
    this.verticalMarker,
    this.verticalMarkerColor,
    this.verticalMarkerIcon,
  }) {
    tapText = tapText ?? _defaultTapText;
    _tooltipPainter.color = toolTipColor;
    _gridPainter.color = gridColor;
    _linePainter.color = gridColor;
  }

  @override
  void paint(Canvas canvas, Size size) {
    _drawGrid(canvas, size);
    _drawUnits(canvas, size, style);
    _drawLines(size, canvas);
    _drawAxisValues(canvas, size);

    if (legends != null && legends!.isNotEmpty) {
      _drawLegends(canvas, size);
    }

    if (verticalMarker != null) {
      _drawVerticalMarkers(size, canvas);
    }

    if (_horizontalDragActive) {
      _drawHighlights(
        size,
        canvas,
        _chart.tapTextFontWeight,
        _tooltipPainter.color,
      );
    }
  }

  var brightness =
      SchedulerBinding.instance.platformDispatcher.platformBrightness;

  void _drawHighlights(Size size, Canvas canvas, FontWeight? tapTextFontWeight,
      Color onTapLineColor) {
    _linePainter.color = onTapLineColor;

    if (_horizontalDragPosition > LineChart.axisOffsetPX &&
        _horizontalDragPosition < size.width) {
      canvas.drawLine(
          Offset(_horizontalDragPosition, 0),
          Offset(_horizontalDragPosition, size.height - LineChart.axisOffsetPX),
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2
            ..color = brightness == Brightness.dark
                ? Colors.grey
                : _gridPainter.color);
    }

    List<HighlightPoint> highlights =
        _chart.getClosetHighlightPoints(_horizontalDragPosition);

    List<TextPainter> textPainters = [];
    int index = 0;
    double minHighlightX = highlights[0].chartPoint.x;
    double minHighlightY = highlights[0].chartPoint.y;
    double maxWidth = 0;

    highlights.forEach((highlight) {
      if (highlight.chartPoint.x < minHighlightX) {
        minHighlightX = highlight.chartPoint.x;
      }
      if (highlight.chartPoint.y < minHighlightY) {
        minHighlightY = highlight.chartPoint.y;
      }
    });

    highlights.forEach((highlight) {
      if (_chart.lines[index].isMarkerLine != true) {
        canvas.drawCircle(
            Offset(highlight.chartPoint.x, highlight.chartPoint.y),
            5,
            _linePainter);
      }

      String prefix = '';

      if (highlight.chartPoint is DateTimeChartPoint) {
        DateTimeChartPoint dateTimeChartPoint =
            highlight.chartPoint as DateTimeChartPoint;
        prefix =
            _formatMonthDayHoursMinutes.format(dateTimeChartPoint.dateTime);
      }

      TextSpan span = TextSpan(
          style: style,
          text: tapText!(
            prefix,
            highlight.yValue,
            _chart.lines[index].unit,
          ));
      TextPainter tp = TextPainter(
          text: span,
          textAlign: TextAlign.right,
          textDirection: TextDirectionHelper.getDirection());

      tp.layout();

      if (tp.width > maxWidth) {
        maxWidth = tp.width;
      }

      if (_chart.lines[index].isMarkerLine !=
          true) // do not show threshold values in highlight box
      {
        textPainters.add(tp);
      }

      index++;
    });

    minHighlightX += 12; //make room for the chart points
    double tooltipHeight = textPainters[0].height * textPainters.length + 16;

    if ((minHighlightX + maxWidth + 16) > size.width) {
      minHighlightX -= maxWidth;
      minHighlightX -= 34;
    }

    if (minHighlightY + tooltipHeight >
        size.height - _chart.axisOffSetWithPadding!) {
      minHighlightY =
          size.height - _chart.axisOffSetWithPadding! - tooltipHeight;
    }

    //Draw highlight bordered box:
    Rect tooltipRect = Rect.fromLTWH(
        minHighlightX - 5, minHighlightY - 5, maxWidth + 20, tooltipHeight);
    canvas.drawRect(tooltipRect, _tooltipPainter);
    canvas.drawRect(tooltipRect, _gridPainter);

    //Draw the actual highlights:
    textPainters.forEach((tp) {
      tp.paint(canvas, Offset(minHighlightX + 5, minHighlightY));
      minHighlightY += 17;
    });
  }

  void _drawAxisValues(Canvas canvas, Size size) {
    //TODO: calculate and cache

    //Draw main axis, should always be available:
    for (int c = 0; c <= (_stepCount + 1); c++) {
      TextPainter tp = _chart.yAxisTexts(0)![c];
      tp.paint(
          canvas,
          Offset(
              _chart.axisOffSetWithPadding! - tp.width,
              (size.height - 6) -
                  (c * _chart.heightStepSize!) -
                  LineChart.axisOffsetPX));
    }

    if (_chart.yAxisCount == 2) {
      for (int c = 0; c <= (_stepCount + 1); c++) {
        TextPainter tp = _chart.yAxisTexts(1)![c];
        tp.paint(
            canvas,
            Offset(
                LineChart.axisMargin + size.width - _chart.xAxisOffsetPXright,
                (size.height - 6) -
                    (c * _chart.heightStepSize!) -
                    LineChart.axisOffsetPX));
      }
    }

    //TODO: calculate and cache
    for (int c = 0; c <= (_stepCount + 1); c++) {
      _drawRotatedText(
          canvas,
          _chart.xAxisTexts![c],
          _chart.axisOffSetWithPadding! + (c * _chart.widthStepSize!),
          size.height - (LineChart.axisOffsetPX - 5),
          pi * 1.5);
    }
  }

  double xValueToPixel(DateTime xValue, Size size) {
    // Set the minimum and maximum DateTime values for the x-axis
    final minX = _chart.fromTo.min!;
    final maxX = _chart.fromTo.max!;

    // Calculate the range of the x-axis
    final xRange = maxX.millisecondsSinceEpoch - minX.millisecondsSinceEpoch;

    // Calculate the pixel vaule of the xValue
    double xPixel =
        (xValue.millisecondsSinceEpoch - minX.millisecondsSinceEpoch) *
            size.width /
            xRange;
    return xPixel.roundToDouble();
  }

  void _drawLines(Size size, Canvas canvas) {
    int index = 0;

    _chart.lines.forEach((chartLine) {
      _linePainter.color = chartLine.color;
      Path? path;

      List<HighlightPoint> points = _chart.seriesMap?[index] ?? [];

      bool drawCircles = points.length < 100;

      if (_progress < 1.0) {
        path = AnimatedPathUtil.createAnimatedPath(
            _chart.getPathCache(index)!, _progress);
      } else {
        path = _chart.getPathCache(index);

        if (drawCircles && chartLine.isMarkerLine != true) {
          points.forEach((p) {
            canvas.drawCircle(
                Offset(p.chartPoint.x, p.chartPoint.y), 2, _linePainter);
          });
        }
      }

      if (chartLine.isMarkerLine == true && showMarkerLines == true) {
        canvas.drawPath(
            dashPath(
              path!,
              dashArray: CircularIntervalList<double>(<double>[15.0, 5.0]),
            ),
            Paint()
              ..style = PaintingStyle.stroke
              ..color = _linePainter.color
              ..strokeWidth = 1);
      } else {
        canvas.drawPath(path!, _linePainter);
      }

      if (_chart is AreaLineChart) {
        AreaLineChart areaLineChart = _chart as AreaLineChart;

        if (areaLineChart.gradients != null) {
          Pair<Color, Color> gradient = areaLineChart.gradients![index];

          _fillPainter.shader = LinearGradient(stops: [
            0.0,
            0.6
          ], colors: [
            gradient.left.withAlpha((220 * _progress).round()),
            gradient.right.withAlpha((220 * _progress).round())
          ], begin: Alignment.bottomCenter, end: Alignment.topCenter)
              .createShader(Rect.fromLTWH(0, 0, size.width, size.height));
        } else {
          _fillPainter.color =
              chartLine.color.withAlpha((200 * _progress).round());
        }

        Path areaPathCache = areaLineChart.getAreaPathCache(index)!;

        canvas.drawPath(areaPathCache, _fillPainter);
      }

      index++;
    });
  }

  void _drawVerticalMarkers(Size size, Canvas canvas) {
    assert(verticalMarker!.length <= 2);
    // Convert the DateTime value to a pixel value on the x-axis
    final firstVerticalMarkerXValue =
        xValueToPixel(verticalMarker!.first, size);
    final closestPoint =
        _chart.getClosetHighlightPoints(firstVerticalMarkerXValue);

    final firstVerticalMarker = closestPoint.first.chartPoint.x;

    // Set the paint style for the line
    final verticalMarkerPaint = Paint()
      ..color = verticalMarkerColor ?? Colors.blueAccent
      ..strokeWidth = 2;

    // Draw the line
    canvas.drawLine(
        Offset(firstVerticalMarker, 0),
        Offset(firstVerticalMarker, size.height - LineChart.axisOffsetPX),
        verticalMarkerPaint);

    final lastVerticalMarkerXValue = xValueToPixel(verticalMarker!.last, size) +
        6.5; // To distingush when differece between first and last is very small
    final closestPointLastVerticalMarker =
        _chart.getClosetHighlightPoints(lastVerticalMarkerXValue);

    final lastVerticalMarker =
        closestPointLastVerticalMarker.first.chartPoint.x;

    // If there are two x values defined, draw a shaded area between the two vertical lines
    if (verticalMarker?.last != null) {
      canvas.drawLine(
          Offset(lastVerticalMarker, 0),
          Offset(lastVerticalMarker, size.height - LineChart.axisOffsetPX),
          Paint()
            ..color = Colors.grey
            ..strokeWidth = 1);

      Path filledPath = Path();

      filledPath.moveTo(firstVerticalMarker, 0);
      filledPath.lineTo(lastVerticalMarker, 0);
      filledPath.lineTo(
          lastVerticalMarker, size.height - LineChart.axisOffsetPX);
      filledPath.lineTo(
          firstVerticalMarker, size.height - LineChart.axisOffsetPX);

      canvas.drawPath(
        filledPath,
        Paint()..color = verticalMarkerPaint.color.withOpacity(0.3),
      );
    }

    if (verticalMarkerIcon != null && verticalMarkerIcon!.isNotEmpty) {
      assert(verticalMarkerIcon!.length <= 2);
      TextPainter firstIconTp = TextPainter(
        textDirection: TextDirectionHelper.getDirection(),
      );

      firstIconTp.text = TextSpan(
        text: String.fromCharCode(verticalMarkerIcon!.first.icon!.codePoint),
        style: TextStyle(
          fontSize: 17.0,
          fontFamily: verticalMarkerIcon?.first.icon!.fontFamily,
          color: verticalMarkerIcon?.first.color ?? _gridPainter.color,
        ),
      );

      firstIconTp.layout();

      // Setting the background color of the icon
      canvas.drawCircle(
          Offset(
            firstVerticalMarker,
            closestPoint.first.chartPoint.y,
          ),
          6,
          Paint()..color = Colors.white);

      firstIconTp.paint(
        canvas,
        Offset(
          firstVerticalMarker - 9,
          closestPoint.first.chartPoint.y - 9,
        ),
      );
    }

    if (verticalMarkerIcon?.length == 2) {
      TextPainter lastIconTp = TextPainter(
        textDirection: TextDirectionHelper.getDirection(),
      );

      lastIconTp.text = TextSpan(
        text: String.fromCharCode(verticalMarkerIcon!.last.icon!.codePoint),
        style: TextStyle(
          fontSize: 17.0,
          fontFamily: verticalMarkerIcon?.last.icon!.fontFamily,
          color: verticalMarkerIcon?.last.color ?? _gridPainter.color,
        ),
      );

      lastIconTp.layout();

      // Setting the background color of the icon
      canvas.drawCircle(
          Offset(
            lastVerticalMarker,
            closestPointLastVerticalMarker.first.chartPoint.y,
          ),
          6,
          Paint()..color = Colors.white);

      lastIconTp.paint(
        canvas,
        Offset(
          lastVerticalMarker - 9,
          closestPointLastVerticalMarker.first.chartPoint.y - 9,
        ),
      );
    }
  }

  void _drawUnits(Canvas canvas, Size size, TextStyle? style) {
    if (_chart.indexToUnit.length > 0) {
      TextSpan span = TextSpan(
          style: style, text: _chart.yAxisName ?? _chart.indexToUnit[0]); // );
      TextPainter tp = TextPainter(
          text: span,
          textAlign: TextAlign.right,
          textDirection: TextDirectionHelper.getDirection());
      tp.layout();

      tp.paint(canvas, Offset(_chart.xAxisOffsetPX, -20)); //-16
    }

    if (_chart.indexToUnit.length == 2) {
      TextSpan span = TextSpan(style: style, text: _chart.indexToUnit[1]);
      TextPainter tp = TextPainter(
          text: span,
          textAlign: TextAlign.right,
          textDirection: TextDirectionHelper.getDirection());
      tp.layout();

      tp.paint(canvas,
          Offset(size.width - tp.width - _chart.xAxisOffsetPXright, -16));
    }
  }

  void _drawGrid(Canvas canvas, Size size) {
    canvas.drawRect(
        Rect.fromLTWH(
            _chart.xAxisOffsetPX,
            0,
            size.width - _chart.xAxisOffsetPX - _chart.xAxisOffsetPXright,
            size.height - LineChart.axisOffsetPX),
        _gridPainter);

    for (double c = 1; c <= _stepCount; c++) {
      canvas.drawLine(
          Offset(_chart.xAxisOffsetPX, c * _chart.heightStepSize!),
          Offset(size.width - _chart.xAxisOffsetPXright,
              c * _chart.heightStepSize!),
          _gridPainter);
      canvas.drawLine(
          Offset(c * _chart.widthStepSize! + _chart.xAxisOffsetPX, 0),
          Offset(c * _chart.widthStepSize! + _chart.xAxisOffsetPX,
              size.height - LineChart.axisOffsetPX),
          _gridPainter);
    }
  }

  void _drawRotatedText(Canvas canvas, TextPainter tp, double x, double y,
      double angleRotationInRadians) {
    canvas.save();
    canvas.translate(x, y + tp.width);

    canvas.rotate(angleRotationInRadians);
    tp.paint(canvas, Offset(0.0, 0.0));
    canvas.restore();
  }

  void _drawLegends(Canvas canvas, Size size) {
    final textStyle = TextStyle(
      color: style?.color,
      fontSize: 12,
      overflow: TextOverflow.clip,
    );
    final textSpan = TextSpan(
      text: legends![0].title,
      style: textStyle,
    );
    final textPainter = TextPainter(
      text: textSpan,
      textAlign: TextAlign.left,
      textDirection: TextDirectionHelper.getDirection(),
    );

    final iconPainter = TextPainter(
      textAlign: TextAlign.left,
      textDirection: TextDirectionHelper.getDirection(),
    );

    if (legends![0].icon != null) {
      iconPainter.text = TextSpan(
        text: String.fromCharCode(legends![0].icon!.icon!.codePoint),
        style: TextStyle(
            fontSize: 20.0,
            fontFamily: legends![0].icon!.icon!.fontFamily,
            color: legends![0].color),
      );
      iconPainter.layout();
    }

    textPainter.layout(
      minWidth: 0,
      maxWidth: 120,
    );

    final warningTextSpan = TextSpan(
      text: legends![1].title,
      style: textStyle,
    );
    final warningTextPainter = TextPainter(
      text: warningTextSpan,
      textAlign: TextAlign.right,
      textDirection: TextDirectionHelper.getDirection(),
    );

    final warningIconPainter = TextPainter(
      textAlign: TextAlign.right,
      textDirection: TextDirectionHelper.getDirection(),
    );
    if (legends![1].icon != null) {
      warningIconPainter.text = TextSpan(
        text: String.fromCharCode(legends![1].icon!.icon!.codePoint),
        style: TextStyle(
            fontSize: 20.0,
            fontFamily: legends![1].icon!.icon!.fontFamily,
            color: legends![1].color),
      );

      warningIconPainter.layout();
    }
    warningTextPainter.layout(
      minWidth: 0,
      maxWidth: 120,
    );

    double width = size.width;
    final offset = Offset(width * 0.25, size.height - 8);
    if (legends![0].icon == null) {
      canvas.drawLine(
          Offset(width * 0.20, size.height),
          Offset(width * 0.23, size.height),
          Paint()
            ..color = legends![0].color ?? Colors.black
            ..style = PaintingStyle.stroke
            ..strokeWidth = 3);
    } else {
      iconPainter.paint(canvas, Offset(width * 0.20 - 3, size.height - 12));
    }

    textPainter.paint(canvas, offset);

    warningTextPainter.paint(canvas, Offset(width * 0.65, size.height - 8));

    if (legends![1].icon == null) {
      canvas.drawLine(
          Offset(width * 0.60, size.height),
          Offset(width * 0.63, size.height),
          Paint()
            ..color = legends![1].color ?? Colors.black
            ..style = PaintingStyle.stroke
            ..strokeWidth = 3);
    } else {
      warningIconPainter.paint(
          canvas, Offset(width * 0.60 - 3, size.height - 12));
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return true;
  }
}

class Legend {
  final String? title;
  final Color? color;
  final Icon? icon;

  Legend({this.title, this.color, this.icon});
}
