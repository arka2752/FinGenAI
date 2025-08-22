import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class PieChartWidget extends StatefulWidget {
  final Map<String, double> data;
  final double? size;
  final bool showLegend;
  final bool showPercentages;
  final bool enableTouch;
  final double radius;
  final double centerSpaceRadius;
  final List<Color>? colors;
  final TextStyle? titleStyle;
  final String? centerText;
  final TextStyle? centerTextStyle;
  final Function(String section, double value)? onSectionTap;

  const PieChartWidget({
    Key? key,
    required this.data,
    this.size,
    this.showLegend = true,
    this.showPercentages = true,
    this.enableTouch = true,
    this.radius = 80,
    this.centerSpaceRadius = 40,
    this.colors,
    this.titleStyle,
    this.centerText,
    this.centerTextStyle,
    this.onSectionTap,
  }) : super(key: key);

  @override
  State<PieChartWidget> createState() => _PieChartWidgetState();
}

class _PieChartWidgetState extends State<PieChartWidget> {
  int touchedIndex = -1;

  // Default color palette
  static const List<Color> _defaultColors = [
    Color(0xFF0293EE),
    Color(0xFFF8B250),
    Color(0xFF845EC2),
    Color(0xFF4E9F3D),
    Color(0xFFFF6B6B),
    Color(0xFF4ECDC4),
    Color(0xFF45B7D1),
    Color(0xFF96CEB4),
    Color(0xFFFECEA8),
    Color(0xFFFF9AA2),
    Color(0xFFFFB7B2),
    Color(0xFFFFDAB9),
  ];

  @override
  void initState() {
    super.initState();
  }

  double get _total => widget.data.values.fold(0.0, (sum, value) => sum + value);

  List<Color> get _colors => widget.colors ?? _defaultColors;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (widget.data.isEmpty) {
      return Container(
        height: widget.size ?? 300,
        child: Center(
          child: Text(
            'No data available',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          height: widget.size ?? 300,
          child: Stack(
            children: [
              PieChart(
                PieChartData(
                  pieTouchData: PieTouchData(
                    enabled: widget.enableTouch,
                    touchCallback: (FlTouchEvent event, pieTouchResponse) {
                      setState(() {
                        if (!event.isInterestedForInteractions ||
                            pieTouchResponse == null ||
                            pieTouchResponse.touchedSection == null) {
                          touchedIndex = -1;
                          return;
                        }
                        touchedIndex = pieTouchResponse
                            .touchedSection!.touchedSectionIndex;
                      });

                      // Handle tap callback
                      if (event is FlTapUpEvent &&
                          widget.onSectionTap != null &&
                          pieTouchResponse?.touchedSection != null) {
                        final index = pieTouchResponse!
                            .touchedSection!.touchedSectionIndex;
                        final entry = widget.data.entries.elementAt(index);
                        widget.onSectionTap!(entry.key, entry.value);
                      }
                    },
                  ),
                  borderData: FlBorderData(show: false),
                  sectionsSpace: 2,
                  centerSpaceRadius: widget.centerSpaceRadius,
                  sections: _buildSections(),
                  startDegreeOffset: -90,
                ),
              ),
              if (widget.centerText != null)
                Positioned.fill(
                  child: Center(
                    child: Text(
                      widget.centerText!,
                      style: widget.centerTextStyle ??
                          Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
        ),
        if (widget.showLegend) ...[
          const SizedBox(height: 16),
          _buildLegend(colorScheme),
        ],
      ],
    );
  }

  List<PieChartSectionData> _buildSections() {
    return widget.data.entries.map((entry) {
      final index = widget.data.keys.toList().indexOf(entry.key);
      final isTouched = index == touchedIndex;
      final double radius = isTouched ? widget.radius + 6 : widget.radius;

      final percentage = (entry.value / _total * 100);

      return PieChartSectionData(
        color: _colors[index % _colors.length],
        value: entry.value,
        title: widget.showPercentages ? '${percentage.toStringAsFixed(1)}%' : '',
        radius: radius,
        titleStyle: widget.titleStyle ??
            TextStyle(
              fontSize: isTouched ? 15 : 13,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              shadows: [
                Shadow(
                  color: Colors.black87,
                  offset: Offset(1, 1),
                  blurRadius: 4,
                ),
              ],
            ),
        titlePositionPercentageOffset: 0.6,
      );
    }).toList();
  }

  Widget _buildLegend(ColorScheme colorScheme) {
    return Wrap(
      spacing: 16,
      runSpacing: 8,
      children: widget.data.entries.map((entry) {
        final index = widget.data.keys.toList().indexOf(entry.key);
        final percentage = (entry.value / _total * 100);

        return GestureDetector(
          onTap: () {
            if (widget.onSectionTap != null) {
              widget.onSectionTap!(entry.key, entry.value);
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: touchedIndex == index
                  ? _colors[index % _colors.length].withOpacity(0.08)
                  : Colors.transparent,
              border: Border.all(
                color: touchedIndex == index
                    ? _colors[index % _colors.length]
                    : colorScheme.outline.withOpacity(0.12),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: _colors[index % _colors.length],
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: _colors[index % _colors.length].withOpacity(0.3),
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      entry.key,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    Text(
                      '${entry.value.toStringAsFixed(1)} (${percentage.toStringAsFixed(1)}%)',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}