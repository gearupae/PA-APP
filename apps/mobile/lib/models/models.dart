/// Plain data models with JSON helpers for local persistence.

class SmsItem {
  SmsItem({
    required this.id,
    required this.address,
    required this.body,
    required this.date,
    required this.read,
  });

  final String id;
  final String address;
  final String body;
  final DateTime date;
  final bool read;

  factory SmsItem.fromChannel(Map<dynamic, dynamic> m) => SmsItem(
        id: (m['id'] ?? '').toString(),
        address: (m['address'] ?? '').toString(),
        body: (m['body'] ?? '').toString(),
        date: DateTime.fromMillisecondsSinceEpoch(
            (m['date'] as num?)?.toInt() ?? 0),
        read: m['read'] == true,
      );
}

class Txn {
  Txn({
    required this.id,
    required this.amount,
    required this.category,
    required this.merchant,
    required this.date,
    required this.isIncome,
    this.manual = false,
    this.raw,
  });

  final String id;
  final double amount;
  String category;
  final String merchant;
  final DateTime date;
  final bool isIncome;
  final bool manual;
  final String? raw;

  Map<String, dynamic> toJson() => {
        'id': id,
        'amount': amount,
        'category': category,
        'merchant': merchant,
        'date': date.toIso8601String(),
        'isIncome': isIncome,
        'manual': manual,
        'raw': raw,
      };

  factory Txn.fromJson(Map<String, dynamic> j) => Txn(
        id: j['id'] as String,
        amount: (j['amount'] as num).toDouble(),
        category: j['category'] as String,
        merchant: j['merchant'] as String,
        date: DateTime.parse(j['date'] as String),
        isIncome: j['isIncome'] as bool? ?? false,
        manual: j['manual'] as bool? ?? false,
        raw: j['raw'] as String?,
      );
}

class Todo {
  Todo({required this.text, this.done = false});
  String text;
  bool done;

  Map<String, dynamic> toJson() => {'text': text, 'done': done};
  factory Todo.fromJson(Map<String, dynamic> j) =>
      Todo(text: j['text'] as String, done: j['done'] as bool? ?? false);
}

/// Mind-map node (simple tree; rendered radially).
class MapNode {
  MapNode({required this.label, this.children = const []});
  final String label;
  final List<MapNode> children;

  Map<String, dynamic> toJson() =>
      {'label': label, 'children': children.map((c) => c.toJson()).toList()};
  factory MapNode.fromJson(Map<String, dynamic> j) => MapNode(
        label: j['label'] as String,
        children: (j['children'] as List<dynamic>? ?? [])
            .map((c) => MapNode.fromJson(c as Map<String, dynamic>))
            .toList(),
      );
}

class Note {
  Note({
    required this.id,
    required this.title,
    required this.transcript,
    required this.todos,
    required this.mindMap,
    required this.createdAt,
  });

  final String id;
  String title;
  String transcript;
  List<Todo> todos;
  MapNode mindMap;
  final DateTime createdAt;

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'transcript': transcript,
        'todos': todos.map((t) => t.toJson()).toList(),
        'mindMap': mindMap.toJson(),
        'createdAt': createdAt.toIso8601String(),
      };

  factory Note.fromJson(Map<String, dynamic> j) => Note(
        id: j['id'] as String,
        title: j['title'] as String,
        transcript: j['transcript'] as String,
        todos: (j['todos'] as List<dynamic>? ?? [])
            .map((t) => Todo.fromJson(t as Map<String, dynamic>))
            .toList(),
        mindMap: MapNode.fromJson(j['mindMap'] as Map<String, dynamic>),
        createdAt: DateTime.parse(j['createdAt'] as String),
      );
}

enum ReminderKind { payment, meeting, general }

class Reminder {
  Reminder({
    required this.id,
    required this.title,
    required this.dueAt,
    required this.kind,
    this.done = false,
  });

  final String id;
  String title;
  DateTime dueAt;
  ReminderKind kind;
  bool done;

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'dueAt': dueAt.toIso8601String(),
        'kind': kind.name,
        'done': done,
      };

  factory Reminder.fromJson(Map<String, dynamic> j) => Reminder(
        id: j['id'] as String,
        title: j['title'] as String,
        dueAt: DateTime.parse(j['dueAt'] as String),
        kind: ReminderKind.values.firstWhere(
          (k) => k.name == j['kind'],
          orElse: () => ReminderKind.general,
        ),
        done: j['done'] as bool? ?? false,
      );
}
