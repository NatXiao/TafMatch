import '../models/task_model.dart';

abstract class TaskRepository {
  Stream<List<Task>> watchTasks(String userId);
  Future<void> addTask(Task task, String userId);
  Future<void> updateTask(Task task, String userId);
  Future<void> deleteTask(String taskId, String userId);
}
