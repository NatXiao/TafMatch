import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/task_model.dart';
import 'task_repository.dart';

class FirestoreTaskRepository implements TaskRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _tasksRef(String userId) =>
      _db.collection('users').doc(userId).collection('tasks');

  @override
  Stream<List<Task>> watchTasks(String userId) {
    return _tasksRef(userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
              final data = doc.data();
              final createdAt = data['createdAt'] as Timestamp?;
              return Task.fromMap(
                {...data, 'createdAt': createdAt?.toDate()},
                doc.id,
              );
            }).toList());
  }

  @override
  Future<void> addTask(Task task, String userId) async {
    await _tasksRef(userId).add({
      ...task.toMap(),
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> updateTask(Task task, String userId) async {
    await _tasksRef(userId).doc(task.id).update(task.toMap());
  }

  @override
  Future<void> deleteTask(String taskId, String userId) async {
    await _tasksRef(userId).doc(taskId).delete();
  }
}
