import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:project_master/project.dart';

class ProjectPage extends StatefulWidget {
  final Project project;

  const ProjectPage({Key? key, required this.project}) : super(key: key);

  @override
  State<ProjectPage> createState() => _ProjectPageState();
}

class _ProjectPageState extends State<ProjectPage> {

  void _showAddTaskDialog(BuildContext context) {
    // Initialize a list to store subtask controllers
    List<TextEditingController> subtaskControllers = [];

    // Create a text editing controller for the task name
    TextEditingController taskNameController = TextEditingController();

    // Initialize variables to store whether the task name and subtasks are empty or not
    bool validateTaskName = false;
    List<bool> validateSubtasks = [];

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            // Function to add a new subtask input field
            void _addSubtask() {
              setState(() {
                subtaskControllers.add(TextEditingController());
                validateSubtasks.add(false);
              });
            }

            return AlertDialog(
              title: Text('Add Task'),
              content: SingleChildScrollView(
                child: Container(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      TextField(
                        controller: taskNameController,
                        decoration: InputDecoration(
                          labelText: 'Task Name',
                          errorText: validateTaskName ? 'Task name cannot be empty' : null,
                        ),
                      ),
                      SizedBox(height: 20),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Subtasks:',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      SizedBox(height: 10),
                      // List of subtask input fields
                      for (int i = 0; i < subtaskControllers.length; i++)
                        Padding(
                          padding: EdgeInsets.symmetric(vertical: 8.0),
                          child: Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: subtaskControllers[i],
                                  decoration: InputDecoration(
                                    labelText: 'Subtask ${i + 1}',
                                    errorText: validateSubtasks[i] ? 'Subtask cannot be empty' : null,
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: Icon(Icons.remove),
                                onPressed: () {
                                  setState(() {
                                    subtaskControllers.removeAt(i);
                                    validateSubtasks.removeAt(i);
                                  });
                                },
                              ),
                            ],
                          ),
                        ),
                      ElevatedButton(
                        onPressed: () {
                          // Get the task name from the controller
                          final String taskName = taskNameController.text;

                          // Check if the task name is empty
                          if (taskName.isEmpty) {
                            setState(() {
                              validateTaskName = true;
                            });
                          } else {
                            setState(() {
                              validateTaskName = false;
                            });

                            // Get the subtask names from the controllers
                            final List<String> subtaskNames = subtaskControllers
                                .map((controller) => controller.text)
                                .toList();

                            // Check if any subtask is empty
                            bool subtaskValidationFailed = false;
                            for (int i = 0; i < subtaskNames.length; i++) {
                              if (subtaskNames[i].isEmpty) {
                                setState(() {
                                  validateSubtasks[i] = true;
                                });
                                subtaskValidationFailed = true;
                              } else {
                                setState(() {
                                  validateSubtasks[i] = false;
                                });
                              }
                            }

                            if (!subtaskValidationFailed) {

                              // Create a new task document in the Firestore collection for tasks
                              final CollectionReference tasksCollection =
                              FirebaseFirestore.instance.collection('tasks');
                              tasksCollection.add({
                                'project_id': widget.project.id,
                                'task_name': taskName,
                                'subtasks': subtaskNames,
                                // Add any other task-related data as needed
                              });

                              // Clear the text controllers
                              taskNameController.clear();
                              for (var controller in subtaskControllers) {
                                controller.clear();
                              }

                              // Close the dialog
                              Navigator.pop(context);
                            }
                          }
                        },
                        child: Text('Save Task'),
                      ),
                      ElevatedButton(
                        onPressed: _addSubtask,
                        child: Text('Add Subtask'),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:
        Text(widget.project.name), // Display the project name as the title
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          //mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity, // Match parent width
              decoration: BoxDecoration(
                border: Border.all(color: Colors.blue), // Border style
                borderRadius: BorderRadius.circular(10.0), // Border radius
                color: Colors.grey[300], // Background color
              ),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  '${widget.project.name}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 25,
                  ),
                ),
              ),
            ),
            SizedBox(
              height: 10,
            ),
            Container(
                width: double.infinity, // Match parent width
                height: 100, // Set a specific height for the container
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.blue), // Border style
                  borderRadius: BorderRadius.circular(10.0), // Border radius
                  color: Colors.grey[300], // Background color
                ),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Project Description:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      SizedBox(
                        height: 5,
                      ),
                      Expanded(
                        child: SingleChildScrollView(
                          child: Container(
                            child: Text('${widget.project.description}',
                              // maxLines: 3, // Adjust the number of lines to display
                              // overflow: TextOverflow.ellipsis, // Show ellipsis (...) for overflow
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                )),
            // Add more project details here
            // Add Task button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  _showAddTaskDialog(context);
                },
                child: Text('Add Task'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
