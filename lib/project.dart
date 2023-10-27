import 'package:firebase_storage/firebase_storage.dart';
class Project {
  String id;
  String name;
  String description;
  DateTime deadline;
  List<Task> tasks;// Add a list of tasks
  String note;
  //bool isSelected;

  Project({
    required this.id,
    required this.name,
    required this.description,
    required this.deadline,
    required this.tasks, // Include tasks in the constructor
    this.note = '',
    //this.isSelected = false,
  });
}


