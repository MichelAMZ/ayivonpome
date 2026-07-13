import 'package:flutter/material.dart';

class LogoSizeSelector extends StatelessWidget {
  const LogoSizeSelector({
    super.key,
    required this.desktop,
    required this.tablet,
    required this.mobile,
    required this.onDesktopChanged,
    required this.onTabletChanged,
    required this.onMobileChanged,
  });

  final double desktop;
  final double tablet;
  final double mobile;
  final ValueChanged<double> onDesktopChanged;
  final ValueChanged<double> onTabletChanged;
  final ValueChanged<double> onMobileChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _SliderRow(
          label: 'Desktop',
          value: desktop,
          min: 64,
          max: 160,
          onChanged: onDesktopChanged,
        ),
        _SliderRow(
          label: 'Tablette',
          value: tablet,
          min: 48,
          max: 110,
          onChanged: onTabletChanged,
        ),
        _SliderRow(
          label: 'Mobile',
          value: mobile,
          min: 36,
          max: 72,
          onChanged: onMobileChanged,
        ),
      ],
    );
  }
}

class _SliderRow extends StatelessWidget {
  const _SliderRow({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  final String label;
  final double value;
  final double min;
  final double max;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(width: 76, child: Text(label)),
        Expanded(
          child: Slider(
            value: value.clamp(min, max).toDouble(),
            min: min,
            max: max,
            divisions: (max - min).round(),
            label: '${value.round()} px',
            onChanged: onChanged,
          ),
        ),
        SizedBox(
          width: 56,
          child: Text('${value.round()} px', textAlign: TextAlign.end),
        ),
      ],
    );
  }
}
