import 'dart:convert';

enum NoteKind { journal, checklist, mixed }

class ChecklistItem {
  const ChecklistItem({required this.text, this.done = false});

  final String text;
  final bool done;

  factory ChecklistItem.fromMap(Map<String, dynamic> map) => ChecklistItem(
        text: map['text'] as String? ?? '',
        done: map['done'] as bool? ?? false,
      );

  Map<String, dynamic> toMap() => {'text': text, 'done': done};
}

class OrdinaryNote {
  const OrdinaryNote({
    required this.id,
    required this.date,
    required this.kind,
    required this.title,
    required this.body,
    required this.checklist,
    required this.createdAt,
    required this.updatedAt,
    this.bold = false,
    this.italic = false,
    this.underline = false,
    this.fontSize = 15,
    this.stickers = const [],
    this.category = 'To-do',
  });

  final bool bold, italic, underline;
  final double fontSize;
  final List<String> stickers;
  final String category;
  final String id;
  final DateTime date;
  final NoteKind kind;
  final String title;
  final String body;
  final List<ChecklistItem> checklist;
  final DateTime createdAt;
  final DateTime updatedAt;

  OrdinaryNote withChecklist(List<ChecklistItem> items) => OrdinaryNote(
      id: id,
      date: date,
      kind: kind,
      title: title,
      body: body,
      checklist: items,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
      bold: bold,
      italic: italic,
      underline: underline,
      fontSize: fontSize,
      stickers: stickers,
      category: category);

  bool get hasChecklist => checklist.isNotEmpty;

  factory OrdinaryNote.fromMap(Map<String, dynamic> map) {
    final rawKind = map['kind'] as String? ?? 'journal';
    return OrdinaryNote(
      bold: map['bold'] == true,
      italic: map['italic'] == true,
      underline: map['underline'] == true,
      fontSize: (map['fontSize'] as num?)?.toDouble().clamp(12, 24) ?? 15,
      stickers: (map['stickers'] as List<dynamic>? ?? [])
          .whereType<String>()
          .take(12)
          .toList(),
      category: map['category'] as String? ?? 'To-do',
      id: map['id'] as String? ??
          base64Url.encode(utf8.encode(DateTime.now().toIso8601String())),
      date: DateTime.parse(
          map['date'] as String? ?? DateTime.now().toIso8601String()),
      kind: NoteKind.values.firstWhere((kind) => kind.name == rawKind,
          orElse: () => NoteKind.journal),
      title: map['title'] as String? ?? '',
      body: map['body'] as String? ?? '',
      checklist: ((map['checklist'] as List<dynamic>? ?? const [])
          .map((item) => ChecklistItem.fromMap(item as Map<String, dynamic>))
          .toList()),
      createdAt: DateTime.parse(
          map['createdAt'] as String? ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(
          map['updatedAt'] as String? ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toMap() => {
        'bold': bold,
        'italic': italic,
        'underline': underline,
        'fontSize': fontSize,
        'stickers': stickers,
        'category': category,
        'id': id,
        'date': date.toIso8601String(),
        'kind': kind.name,
        'title': title,
        'body': body,
        'checklist': checklist.map((item) => item.toMap()).toList(),
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };
}
