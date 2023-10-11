import 'package:firebase_auth/firebase_auth.dart';
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
  Future<List<Map<String, dynamic>>> _fetchTasks() async {
    final FirebaseAuth auth = FirebaseAuth.instance;
    final User? user = auth.currentUser;

    if (user == null) {
      // Handle the case where the user is not authenticated
      return [];
    }

    try {
      final FirebaseFirestore firestore = FirebaseFirestore.instance;

      // Get a reference to the tasks collection for the current project
      final tasksCollection = firestore
          .collection('users')
          .doc(user.uid)
          .collection('projects')
          .doc(widget.project.id)
          .collection('tasks');

      // Fetch and return the tasks
      final querySnapshot = await tasksCollection.get();
      final tasks = querySnapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();

      return tasks;
    } catch (e) {
      print('Error fetching tasks: $e');
      return [];
    }
  }

  void _showAddTaskDialog(BuildContext context) async {
    // Check if the user is authenticated
    final FirebaseAuth auth = FirebaseAuth.instance;
    final User? user = auth.currentUser;

    if (user == null) {
      // Handle the case where the user is not authenticated
      return;
    }

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
                        onPressed: () async {
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
                              try {
                                // Get a reference to the Firestore instance
                                final FirebaseFirestore firestore = FirebaseFirestore.instance;

                                // Create a new task document
                                final DocumentReference taskRef = await firestore
                                    .collection('users')
                                    .doc(user.uid) // User's UID
                                    .collection('projects')
                                    .doc(widget.project.id) // Project ID
                                    .collection('tasks')
                                    .add({
                                  'name': taskName,
                                  'subtasks': subtaskNames,
                                });

                                // You can now use the taskRef if needed
                                print('Task added with ID: ${taskRef.id}');

                                // Clear the text controllers
                                taskNameController.clear();
                                for (var controller in subtaskControllers) {
                                  controller.clear();
                                }

                                // Close the dialog
                                Navigator.pop(context);
                              } catch (e) {
                                // Handle any errors that occur during Firestore operation
                                print('Error saving task: $e');
                              }
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
        title: Text(widget.project.name), // Display the project name as the title
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
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
                              child: Text('${widget.project.description}'),
                            ),
                          ),
                        ),
                      ],
                    ),
                  )),
              SizedBox(
                height: 10,
              ),
              Text("Tasks:",style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),),
              SizedBox(
                height: 10,
              ),
              //Container to display tasks
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.blue),
                  borderRadius: BorderRadius.circular(10.0),
                  color: Colors.grey[300],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FutureBuilder<List<Map<String, dynamic>>>(
                      future: _fetchTasks(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        } else if (!snapshot.hasData || snapshot.data == null || snapshot.data!.isEmpty) {
                          return const Center(
                            child: Text('No tasks found.'),
                          );
                        }

                        final tasks = snapshot.data;

                        return ListView.builder(
                          shrinkWrap: true,
                          itemCount: tasks?.length ?? 0,
                          itemBuilder: (context, index) {
                            if (tasks == null) {
                              // Return an empty widget or handle the case when tasks is null
                              return SizedBox.shrink();
                            }

                            final taskName = tasks[index]['name'] as String;
                            final subtasks = (tasks![index]['subtasks'] as List<dynamic>).map((subtask) => subtask.toString()).toList();

                            return ListTile(
                              title: Text(taskName),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: subtasks
                                    .map((subtask) => Text('- $subtask'))
                                    .toList(),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ],
                ),
              ),

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
      ),
    );
  }
}
