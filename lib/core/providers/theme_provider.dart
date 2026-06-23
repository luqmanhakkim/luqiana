import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class ThemeNotifier extends Notifier<Color> {
  static const _boxName = 'settings';
  static const _colorKey = 'themeColor';

  @override
  Color build() {
    final box = Hive.box(_boxName);
    final stored = box.get(_colorKey);
    if (stored is int) return Color(stored);
    return const Color(0xFF1B6CA8);
  }

  void setColor(Color color) {
    Hive.box(_boxName).put(_colorKey, color.value);
    state = color;
  }
}

final themeColorProvider =
    NotifierProvider<ThemeNotifier, Color>(ThemeNotifier.new);

/// Predefined theme palette options shown in the color picker.
const List<({Color color, String label})> kThemePalette = [
  (color: Color(0xFF1B6CA8), label: 'Ocean Blue'),
  (color: Color(0xFFDB2777), label: 'Rose Pink'),
  (color: Color(0xFF7C3AED), label: 'Violet'),
  (color: Color(0xFF059669), label: 'Emerald'),
  (color: Color(0xFFEA580C), label: 'Sunset'),
  (color: Color(0xFF0D9488), label: 'Teal'),
  (color: Color(0xFFE11D48), label: 'Crimson'),
  (color: Color(0xFF0369A1), label: 'Navy'),
];
