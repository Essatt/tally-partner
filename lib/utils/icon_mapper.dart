import 'package:flutter/material.dart';

const Map<String, IconData> tallyIconMap = {
  'star': Icons.star,
  'favorite': Icons.favorite,
  'thumb_up': Icons.thumb_up,
  'thumb_down': Icons.thumb_down,
  'check': Icons.check_circle,
  'close': Icons.cancel,
  'water_drop': Icons.water_drop,
  'coffee': Icons.coffee,
  'fitness': Icons.fitness_center,
  'book': Icons.book,
  'work': Icons.work,
};

IconData getIconData(String? iconName) {
  return tallyIconMap[iconName] ?? Icons.event;
}
