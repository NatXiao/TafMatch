import 'package:flutter/material.dart';
import '../models/task_model.dart';
import '../widgets/task_form.dart';

class TaskDetailScreen extends StatelessWidget {
  final Task task;

  const TaskDetailScreen({super.key, required this.task});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Task Detail'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: TaskForm(task: task),
      ),
    );
  }
}
