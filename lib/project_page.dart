import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:project_master/pages/home_page.dart';
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
  DateTime? selectedTaskDeadline;
  late TextEditingController projectDeadlineController;

  @override
  void initState() {
    super.initState();
    // Fetch the project's deadline from Firestore
    _fetchProjectDeadline();

    projectDeadlineController = TextEditingController(
      text: _projectDeadline != null
          ? DateFormat('yyyy-MM-dd HH:mm').format(_projectDeadline!)
          : 'Update Deadline',
    );
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

            void _pickTaskDeadline(BuildContext context) async {
              final selectedDate = await showDatePicker(
                context: context,
                initialDate: DateTime.now(),
                firstDate: DateTime.now(),
                lastDate: DateTime(2101),
              );

              if (selectedDate != null) {
                final selectedTime = await showTimePicker(
                  context: context,
                  initialTime: TimeOfDay.fromDateTime(selectedDate),
                );

                if (selectedTime != null) {
                  setState(() {
                    selectedTaskDeadline = DateTime(
                      selectedDate.year,
                      selectedDate.month,
                      selectedDate.day,
                      selectedTime.hour,
                      selectedTime.minute,
                    );
                  });
                }
              }
            }

            return AlertDialog(
              title: Text('Add Task'),
              content: SingleChildScrollView(
                child: Container(
                  padding: EdgeInsets.all(5),
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
                      Text(
                        'Task Deadline: ${selectedTaskDeadline != null ? DateFormat('yyyy-MM-dd HH:mm').format(selectedTaskDeadline!) : 'Not set'}',
                      ),
                      TextButton(
                        onPressed: () {
                          setState(() {
                            selectedTaskDeadline = null;
                          });
                        },
                        child: Text('Cancel Deadline'),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          _pickTaskDeadline(context);
                        },
                        child: Text('Task Deadline'),
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
                                  'tasksdeadline': selectedTaskDeadline, // Store the selected task deadline
                                });

                                // You can now use the taskRef if needed
                                print('Task added with ID: ${taskRef.id}');

                                // Clear the text controllers
                                taskNameController.clear();
                                for (var controller in subtaskControllers) {
                                  controller.clear();
                                }
                                setState(() {
                                  selectedTaskDeadline = null;
                                });

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

  void updateProjectDetails(String newName, String newDescription, DateTime? newDeadline) {
    setState(() {
      widget.project.name = newName;
      widget.project.description = newDescription;
      _projectDeadline = newDeadline;
    });
  }
  // Function to open the edit project details dialog
  void _showEditProjectDialog(BuildContext context) {
    // Initialize controllers with the current project details
    TextEditingController projectNameController = TextEditingController(text: widget.project.name);
    TextEditingController projectDescriptionController = TextEditingController(text: widget.project.description);
    DateTime? selectedProjectDeadline = _projectDeadline;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Edit Project'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                TextField(
                  controller: projectNameController,
                  decoration: InputDecoration(labelText: 'Project Name'),
                ),
                TextField(
                  controller: projectDescriptionController,
                  decoration: InputDecoration(labelText: 'Project Description'),
                ),
                TextField(
                  controller: projectDeadlineController,
                  decoration: InputDecoration(labelText: 'Project Deadline'),
                  enabled: false,
                ),
                IconButton(
                  icon: Icon(Icons.edit),
                  onPressed: () async {
                    final newDeadline = await _pickProjectDeadline(context, selectedProjectDeadline);
                    if (newDeadline != null) {
                      setState(() {
                        selectedProjectDeadline = newDeadline;
                        projectDeadlineController.text = DateFormat('yyyy-MM-dd HH:mm').format(newDeadline);
                      });
                    }
                  },
                ),
                ElevatedButton(
                  onPressed: () async {
                    final updatedName = projectNameController.text;
                    final updatedDescription = projectDescriptionController.text;

                    // Update the project details in Firestore
                    await FirebaseFirestore.instance
                        .collection('users')
                        .doc(FirebaseAuth.instance.currentUser!.uid)
                        .collection('projects')
                        .doc(widget.project.id)
                        .update({
                      'name': updatedName,
                      'description': updatedDescription,
                      'deadline': selectedProjectDeadline,
                    });

                    // Update the local project object and deadline
                    setState(() {
                      widget.project.name = updatedName;
                      widget.project.description = updatedDescription;
                      _projectDeadline = selectedProjectDeadline;
                    });

                    // Close the dialog
                    Navigator.pop(context);
                  },
                  child: Text('Save Changes'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _editTask(BuildContext context, String initialTaskName, List<String> initialSubtasks, String taskId) {
    List<TextEditingController> subtaskControllers = [];

    // Initialize subtask controllers with the initial subtask values
    for (int i = 0; i < initialSubtasks.length; i++) {
      subtaskControllers.add(TextEditingController(text: initialSubtasks[i]));
    }

    TextEditingController taskNameController = TextEditingController(text: initialTaskName);

    // Initialize variables to store whether the task name, subtasks are empty or not
    bool validateTaskName = false;
    List<bool> validateSubtasks = List.generate(initialSubtasks.length, (index) => false);

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
              title: Text('Edit Task'),
              content: SingleChildScrollView(
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
                        final String updatedTaskName = taskNameController.text;

                        // Check if the task name is empty
                        if (updatedTaskName.isEmpty) {
                          setState(() {
                            validateTaskName = true;
                          });
                        } else {
                          setState(() {
                            validateTaskName = false;
                          });

                          // Get the subtask names from the controllers
                          final List<String> updatedSubtaskNames = subtaskControllers
                              .map((controller) => controller.text)
                              .toList();

                          // Check if any subtask is empty
                          bool subtaskValidationFailed = false;
                          for (int i = 0; i < updatedSubtaskNames.length; i++) {
                            if (updatedSubtaskNames[i].isEmpty) {
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
                              // Update the task document in Firestore
                              FirebaseFirestore.instance
                                  .collection('users')
                                  .doc(FirebaseAuth.instance.currentUser!.uid)
                                  .collection('projects')
                                  .doc(widget.project.id)
                                  .collection('tasks')
                                  .doc(taskId) // Update the specific task
                                  .update({
                                'name': updatedTaskName,
                                'subtasks': updatedSubtaskNames,
                              });

                              // Close the dialog
                              Navigator.pop(context);
                            } catch (e) {
                              // Handle any errors that occur during Firestore operation
                              print('Error updating task: $e');
                            }
                          }
                        }
                      },
                      child: Text('Save Changes'),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<DateTime?> _pickProjectDeadline(BuildContext context, DateTime? initialDate) async {
    DateTime currentDate = DateTime.now();
    DateTime initial = initialDate ?? currentDate;

    final selectedDate = await showDatePicker(
      context: context,
      initialDate: initial.isBefore(currentDate) ? currentDate : initial,
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
    );

    if (selectedDate != null) {
      final selectedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(initial),
      );

      if (selectedTime != null) {
        return DateTime(
          selectedDate.year,
          selectedDate.month,
          selectedDate.day,
          selectedTime.hour,
          selectedTime.minute,
        );


      }
    }

    return null;
  }

  Future<void> _duplicateProject() async {
    final userUid = FirebaseAuth.instance.currentUser!.uid;

    // Fetch the existing project data
    final projectDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(userUid)
        .collection('projects')
        .doc(widget.project.id)
        .get();

    if (projectDoc.exists) {
      final projectData = projectDoc.data() as Map<String, dynamic>;

      // Show a confirmation dialog
      bool duplicateConfirmed = await showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Duplicate Project'),
            content: Text('Are you sure you want to duplicate this project?'),
            actions: <Widget>[
              TextButton(
                child: Text('Cancel'),
                onPressed: () {
                  Navigator.of(context).pop(false);
                },
              ),
              TextButton(
                child: Text('Duplicate'),
                onPressed: () {
                  Navigator.of(context).pop(true);
                },
              ),
            ],
          );
        },
      );

      if (duplicateConfirmed == true) {
        // Create a new project with similar details and tasks
        final newProjectRef = await FirebaseFirestore.instance
            .collection('users')
            .doc(userUid)
            .collection('projects')
            .add({
          'name': projectData['name'] + ' (Copy)', // Update the project name
          'description': projectData['description'],
          'deadline': projectData['deadline'],
          // You may need to duplicate the tasks as well
          // Implement logic to duplicate tasks here
        });

        // Optionally navigate to the duplicated project's page
        Navigator.of(context).pop(); // Close the current page
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => HomePage())); // Navigate to the home page
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:
        Text(widget.project.name),
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.edit),
            onPressed: () {
              _showEditProjectDialog(context);
            },
          ),
          IconButton(icon: Icon(Icons.content_copy), // Add the Duplicate Project icon here
            onPressed: () {
              _duplicateProject();
            },)
        ],// Display the project name as the title
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
              Row(
                children: [
                  Text(
                    "Tasks:",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                ],
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
                      final isComplete = taskData['isComplete'] ?? false; // Default to false if not set in Firestore



                      return Container(
                        margin: EdgeInsets.only(bottom: 10.0),
                        width: double.infinity,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.blue),
                          borderRadius: BorderRadius.circular(10.0),
                          color: Colors.grey[300],
                        ),
                        child: GestureDetector(
                          onLongPress: (){
                            // Call the _editTask function here, passing the task details
                            _editTask(
                              context,
                              taskName, // Task name
                              List<String>.from(subtasks), // Subtasks as a List
                              taskDoc.id, // Task ID
                            );
                          },
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ListTile(
                                title: Row(
                                  children: [
                                    Checkbox(
                                      value: isComplete,
                                      onChanged: (bool? newValue) {
                                        // When the checkbox is changed, update the 'isComplete' property in Firestore
                                        FirebaseFirestore.instance
                                            .collection('users')
                                            .doc(FirebaseAuth.instance.currentUser!.uid)
                                            .collection('projects')
                                            .doc(widget.project.id)
                                            .collection('tasks')
                                            .doc(taskDoc.id) // Get the specific task document
                                            .update({'isComplete': newValue});
                                      },
                                    ),
                                    Text(
                                      'Task: $taskName',
                                      style: TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                  ],
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
