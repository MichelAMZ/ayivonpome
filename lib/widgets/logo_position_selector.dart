import 'package:flutter/material.dart';

class LogoPositionSelector extends StatelessWidget {
  const LogoPositionSelector({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<String>(
      segments: const [
        ButtonSegment(
          value: 'leftOfTitle',
          icon: Icon(Icons.format_align_left),
          label: Text('Gauche'),
        ),
        ButtonSegment(
          value: 'rightOfTitle',
          icon: Icon(Icons.format_align_right),
          label: Text('Droite'),
        ),
        ButtonSegment(
          value: 'hidden',
          icon: Icon(Icons.visibility_off_outlined),
          label: Text('Masqué'),
        ),
      ],
      selected: {value},
      onSelectionChanged: (selection) => onChanged(selection.first),
    );
  }
}
