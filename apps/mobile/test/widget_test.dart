import 'package:flutter_test/flutter_test.dart';

import 'package:pa_app/services/note_builder.dart';

void main() {
  test('NoteBuilder extracts action items as todos', () {
    final note = NoteBuilder.build(
      'We met about the budget. I need to call the vendor tomorrow. '
      'Remember to pay the electricity bill.',
    );
    expect(note.todos.isNotEmpty, true);
    expect(note.transcript.isNotEmpty, true);
    expect(note.mindMap.children.isNotEmpty, true);
  });
}
