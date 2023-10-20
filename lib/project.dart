import 'package:firebase_storage/firebase_storage.dart';

class Project {
  final String id;
  final String name;
  final String description;
  final DateTime deadline;
  final List<Task> tasks; // Add a list of tasks
  //bool isSelected;

  Project({
    required this.id,
    required this.name,
    required this.description,
    required this.deadline,
    required this.tasks, // Include tasks in the constructor
    //this.isSelected = false,
  });
}


