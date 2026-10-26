import 'package:flutter/material.dart';

const scheduleSymbols = <String, IconData>{
  'event': Icons.event_outlined,
  'watch': Icons.live_tv_outlined,
  'study': Icons.menu_book_outlined,
  'walk': Icons.directions_walk,
  'food': Icons.restaurant_outlined,
  'work': Icons.work_outline
};
String suggestSymbol(String title) {
  final text = title.toLowerCase();
  if (RegExp(r'watch|nonton|series|movie').hasMatch(text)) return 'watch';
  if (RegExp(r'study|read|belajar|skripsi').hasMatch(text)) return 'study';
  if (RegExp(r'run|walk|jalan|lari').hasMatch(text)) return 'walk';
  if (RegExp(r'food|lunch|makan|dinner').hasMatch(text)) return 'food';
  if (RegExp(r'work|meeting|kerja').hasMatch(text)) return 'work';
  return 'event';
}
