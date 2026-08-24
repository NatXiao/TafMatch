import 'package:flutter/material.dart';
import '../widgets/task_form.dart';

class AddTaskScreen extends StatelessWidget {
  const AddTaskScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Task'),
      ),
      body: const Padding(
        padding: EdgeInsets.all(16.0),
        child: TaskForm(),
      ),
    );
  }
}
