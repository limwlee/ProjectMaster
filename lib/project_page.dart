import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:project_master/project.dart';

class ProjectPage extends StatefulWidget {
  final Project project;

  const ProjectPage({Key? key, required this.project}) : super(key: key);

  @override
  State<ProjectPage> createState() => _ProjectPageState();
}

class _ProjectPageState extends State<ProjectPage> {
  // Define a variable to keep track of which task is expanded
  Set<int> expandedTaskIndices = {};
  ScrollController _scrollController = ScrollController();
  DateTime? _projectDeadline; // Add this property to store the project's deadline

  @override
  void initState() {
    super.initState();
    // Fetch the project's deadline from Firestore
    _fetchProjectDeadline();
  }

  void _fetchProjectDeadline() async {
    final userUid = FirebaseAuth.instance.currentUser!.uid;
    final projectDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(userUid)
        .collection('projects')
        .doc(widget.project.id)
        .get();

    if (projectDoc.exists) {
      final projectData = projectDoc.data() as Map<String, dynamic>;
      final projectDeadlineTimestamp = projectData['deadline'] as Timestamp?;

      if (projectDeadlineTimestamp != null) {
        _projectDeadline = projectDeadlineTimestamp.toDate();
        setState(() {});
      }
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

    List<TextEditingController> subtaskControllers = [];// Initialize a list to store subtask controllers
    TextEditingController taskNameController = TextEditingController(); // Create a text editing controller for the task name

    // Initialize variables to store whether the task name,subtasks are empty or not
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
                          errorText: validateTaskName
                              ? 'Task name cannot be empty'
                              : null,
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
                                    errorText: validateSubtasks[i]
                                        ? 'Subtask cannot be empty'
                                        : null,
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
                        onPressed: _addSubtask,
                        child: Text('Add Subtask'),
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
                                final FirebaseFirestore firestore =  FirebaseFirestore.instance;

                                // Create a new task document
                                final DocumentReference taskRef =
                                    await firestore
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

                                // Auto-refresh the task list by calling setState
                                setState(() {});

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
      body: SingleChildScrollView(
        controller: _scrollController,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
              8.0, 8.0, 8.0, 70.0), // Add 80.0 padding at the bottom
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
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.blue),
                  borderRadius: BorderRadius.circular(10.0),
                  color: Colors.grey[300],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Project Deadline:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 5),
                      Text(
                        _projectDeadline != null
                            ? DateFormat('yyyy-MM-dd HH:mm').format(_projectDeadline!)
                            : 'N/A', // Provide a default value or message if the deadline is null
                      )

                    ],
                  ),
                ),
              ),
              SizedBox(
                height: 10,
              ),
              Text(
                "Tasks:",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
              SizedBox(
                height: 10,
              ),
              //Display tasks
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .doc(FirebaseAuth.instance.currentUser!.uid)
                    .collection('projects')
                    .doc(widget.project.id)
                    .collection('tasks')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return CircularProgressIndicator();
                  } else if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Text('No tasks found for this project.');
                  }
                  final tasks = snapshot.data!.docs;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: List.generate(tasks.length, (index) {
                      final taskDoc = tasks[index];
                      final taskData = taskDoc.data() as Map<String, dynamic>;
                      final taskName = taskData['name'];
                      final subtasks = taskData['subtasks'] as List<dynamic>;

                      return Container(
                        margin: EdgeInsets.only(bottom: 10.0),
                        width: double.infinity,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.blue),
                          borderRadius: BorderRadius.circular(10.0),
                          color: Colors.grey[300],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ListTile(
                              title: Text(
                                'Task: $taskName',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              trailing: subtasks.isNotEmpty
                                  ? Icon(
                                expandedTaskIndices.contains(index)
                                    ? Icons.keyboard_arrow_up
                                    : Icons.keyboard_arrow_down,
                              )
                                  : null, // If no subtasks, set trailing to null
                              onTap: (){
                                setState(() {
                                  if (expandedTaskIndices.contains(index)) {
                                    expandedTaskIndices.remove(index);
                                  } else {
                                    expandedTaskIndices.add(index);
                                  }
                                });

                                // Calculate the position to scroll to based on the item's index
                                final itemHeight = 100.0; // Change this to match your item height
                                final itemPosition = index * itemHeight;

                                // Scroll to the tapped item without jumping to the top
                                _scrollController.animateTo(
                                  itemPosition,
                                  duration: Duration(milliseconds: 300),
                                  curve: Curves.easeInOut,
                                );
                              },
                            ),

                            if (expandedTaskIndices.contains(index))
                              Column(
                                children: subtasks.map((subtask) => Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Row(
                                    children: [
                                      SizedBox(width: 16.0),
                                      Text('- '),
                                      Text(subtask),
                                    ],
                                  ),
                                )).toList(),
                              ),
                          ],
                        ),
                      );
                    }),
                  );
                },
              ),
            ],
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: Container(
        padding: EdgeInsets.all(16),
        width: double.infinity,
        child: FloatingActionButton.extended(
          onPressed: () {
            _showAddTaskDialog(context);
          },
          label: Text('Add Task'),
          icon: Icon(Icons.add),
          // shape: RoundedRectangleBorder(
          //   borderRadius: BorderRadius.all(Radius.circular(10.0)), // Adjust the radius to make it rectangular
          // ),
        ),
      ),
    );
  }
}
