import '../models/models.dart';

/// Turns a free-text transcript into a note: a title, action items (todos),
/// and a simple mind map. All on-device heuristics — no network needed.
class NoteBuilder {
  static final _actionTriggers = RegExp(
    r'\b(need to|have to|must|should|remind|call|email|send|buy|pay|book|'
    r'schedule|follow up|follow-up|finish|prepare|share|review|check|confirm|'
    r'order|arrange|fix|update|plan)\b',
    caseSensitive: false,
  );

  static final _stop = <String>{
    'the', 'and', 'for', 'with', 'that', 'this', 'from', 'have', 'will',
    'your', 'you', 'our', 'are', 'was', 'but', 'not', 'can', 'all', 'they',
    'them', 'then', 'than', 'about', 'into', 'just', 'like', 'what', 'when',
    'who', 'how', 'why', 'get', 'got', 'had', 'his', 'her', 'she', 'him',
    'out', 'off', 'per', 'via', 'also', 'any', 'been', 'more', 'some',
  };

  // Commitments the speaker made: "I'll send…", "I will get back…", etc.
  static final _promiseTrigger = RegExp(
    r"\b(i'?ll|i will|i'?m going to|i am going to|i promise|let me|i'?ll get back|"
    r"i'?ll send|i'?ll share|i'?ll call|i'?ll follow up|we'?ll send)\b",
    caseSensitive: false,
  );

  static Note build(String transcript, {DateTime? now}) {
    final created = now ?? DateTime.now();
    final clean = transcript.trim();
    final sentences = clean
        .split(RegExp(r'(?<=[.!?])\s+|\n+'))
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    // Promises — things the speaker committed to.
    final promises = <String>[];
    for (final s in sentences) {
      if (_promiseTrigger.hasMatch(s)) {
        var p = s;
        if (p.length > 100) p = '${p.substring(0, 98)}…';
        promises.add(_capitalise(p));
      }
    }

    // Todos: sentences that look like actions.
    final todos = <Todo>[];
    for (final s in sentences) {
      if (_actionTriggers.hasMatch(s)) {
        var t = s;
        if (t.length > 90) t = '${t.substring(0, 88)}…';
        todos.add(Todo(text: _capitalise(t)));
      }
    }

    // Title: first meaningful sentence, trimmed.
    String title = sentences.isNotEmpty ? sentences.first : 'Voice note';
    if (title.length > 48) title = '${title.substring(0, 46)}…';
    title = _capitalise(title);

    final mindMap = _buildMindMap(sentences, clean);

    return Note(
      id: 'note_${created.millisecondsSinceEpoch}',
      title: title,
      transcript: clean,
      todos: todos,
      mindMap: mindMap,
      createdAt: created,
      promises: promises,
    );
  }

  static MapNode _buildMindMap(List<String> sentences, String full) {
    // Branch 1: Topics — most frequent salient words.
    final freq = <String, int>{};
    for (final w in full.toLowerCase().split(RegExp(r'[^a-z]+'))) {
      if (w.length < 4 || _stop.contains(w)) continue;
      freq[w] = (freq[w] ?? 0) + 1;
    }
    final topics = (freq.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value)))
        .take(5)
        .map((e) => MapNode(label: _capitalise(e.key)))
        .toList();

    // Branch 2: Action items.
    final actions = sentences
        .where((s) => _actionTriggers.hasMatch(s))
        .take(5)
        .map((s) => MapNode(label: _short(s)))
        .toList();

    // Branch 3: Key points — first few sentences not already actions.
    final keyPoints = sentences
        .where((s) => !_actionTriggers.hasMatch(s))
        .take(4)
        .map((s) => MapNode(label: _short(s)))
        .toList();

    final root = MapNode(label: 'Conversation', children: [
      if (topics.isNotEmpty) MapNode(label: 'Topics', children: topics),
      if (actions.isNotEmpty) MapNode(label: 'Action items', children: actions),
      if (keyPoints.isNotEmpty)
        MapNode(label: 'Key points', children: keyPoints),
    ]);
    return root;
  }

  static String _short(String s) =>
      s.length > 42 ? '${_capitalise(s.substring(0, 40))}…' : _capitalise(s);

  static String _capitalise(String s) =>
      s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';
}
