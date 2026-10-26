import 'package:flutter_riverpod/flutter_riverpod.dart';

class OrdinaryMemory {
  const OrdinaryMemory(this.day, this.title, this.checklist);
  final int day;
  final String title;
  final bool checklist;
}

// UI fixtures only. No vault data or secret content belongs in this source.
const demoMemories = [
  OrdinaryMemory(5, 'A slow morning', false),
  OrdinaryMemory(12, 'Small things to do', true),
  OrdinaryMemory(22, 'An evening walk', false)
];
final selectedDateProvider = StateProvider<DateTime>((ref) => DateTime.now());
