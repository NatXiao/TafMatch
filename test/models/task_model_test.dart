import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager/models/task_model.dart';

void main() {
  test('toMap includes the imageUrl', () {
    final task = Task(
      id: '1',
      title: 'T',
      description: 'D',
      isCompleted: false,
      imageUrl: 'https://cdn/pic.jpg',
    );

    expect(task.toMap()['imageUrl'], 'https://cdn/pic.jpg');
  });

  test('fromMap reads the imageUrl', () {
    final task = Task.fromMap(
      {
        'title': 'T',
        'description': 'D',
        'isCompleted': true,
        'imageUrl': 'https://cdn/pic.jpg',
      },
      'doc1',
    );

    expect(task.imageUrl, 'https://cdn/pic.jpg');
  });

  test('fromMap allows a missing imageUrl', () {
    final task = Task.fromMap(
      {'title': 'T', 'description': 'D', 'isCompleted': false},
      'doc1',
    );

    expect(task.imageUrl, isNull);
  });

  test('copyWith updates the imageUrl while keeping other fields', () {
    final task = Task(id: '1', title: 'T', description: 'D', isCompleted: false);

    final updated = task.copyWith(imageUrl: 'https://cdn/new.jpg');

    expect(updated.imageUrl, 'https://cdn/new.jpg');
    expect(updated.id, '1');
    expect(updated.title, 'T');
  });
}
