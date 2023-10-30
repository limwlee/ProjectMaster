import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_ml_kit/google_ml_kit.dart';
//import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';
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
  DateTime? taskDeadline;
  TextEditingController noteController = TextEditingController();
  String existingNote = ''; // To store the existing note content

  @override
  void initState() {
    super.initState();
    // Fetch the project's deadline from Firestore
    _fetchProjectDeadline();
    _fetchNoteData();

    projectDeadlineController = TextEditingController(
      text: _projectDeadline != null
          ? DateFormat('yyyy-MM-dd HH:mm').format(_projectDeadline!)
          : 'Update Deadline',
    );
  }

  void _fetchNoteData() async {
    final userUid = FirebaseAuth.instance.currentUser!.uid;
    final projectDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(userUid)
        .collection('projects')
        .doc(widget.project.id)
        .get();

    if (projectDoc.exists) {
      final projectData = projectDoc.data() as Map<String, dynamic>;
      final note = projectData['note'] as String?;
      if (note != null) {
        setState(() {
          existingNote = note;
        });
      }
    }
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

                    // Check if the selected task deadline is after the project deadline
                    if (_projectDeadline != null && selectedTaskDeadline!.isAfter(_projectDeadline!)) {
                      // Show an error message to the user
                      showDialog(
                        context: context,
                        builder: (context) {
                          return AlertDialog(
                            title: Text('Warning',style: TextStyle(color: Colors.red),),
                            content: Text('Your task deadline is after the project deadline.'),
                            actions: <Widget>[
                              TextButton(
                                child: Text('OK'),
                                onPressed: () {
                                  Navigator.of(context).pop();
                                },
                              ),
                            ],
                          );
                        },
                      );
                    } else {
                      setState(() {
                        selectedTaskDeadline = selectedTaskDeadline;
                      });
                    }
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
                                  'isComplete' : false,// Default the task not complete
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

  void _editTask(BuildContext context, String taskName, List<String> subtasks, String taskId, DateTime? taskDeadline,) {
    TextEditingController taskNameController = TextEditingController(text: taskName);
    List<TextEditingController> subtaskControllers =
    subtasks.map((subtask) => TextEditingController(text: subtask)).toList();
    DateTime? selectedTaskDeadline = taskDeadline;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            // Function to add a new subtask input field
            void _addSubtask() {
              setState(() {
                subtaskControllers.add(TextEditingController());
              });
            }
            // Function to remove a subtask
            void _removeSubtask(int index) {
              showDialog(
                context: context,
                builder: (context) {
                  return AlertDialog(
                    title: Text('Confirm Deletion'),
                    content: Text('Are you sure you want to delete this subtask?'),
                    actions: <Widget>[
                      TextButton(
                        child: Text('Cancel'),
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                      ),
                      TextButton(
                        child: Text('Delete'),
                        onPressed: () {
                          setState(() {
                            subtaskControllers.removeAt(index);
                          });
                          Navigator.of(context).pop();
                        },
                      ),
                    ],
                  );
                },
              );
            }


            void _pickTaskDeadline(BuildContext context) async {
              final selectedDate = await showDatePicker(
                context: context,
                initialDate: selectedTaskDeadline ?? DateTime.now(),
                firstDate: DateTime.now(),
                lastDate: DateTime(2101),
              );

              if (selectedDate != null) {
                final selectedTime = await showTimePicker(
                  context: context,
                  initialTime: TimeOfDay.fromDateTime(
                      selectedTaskDeadline ?? DateTime.now()),
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
              title: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Edit Task'),
                  IconButton(
                    icon: Icon(Icons.delete), // Add the delete task button here
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) {
                          return AlertDialog(
                            title: Text('Delete Task'),
                            content: Text('Are you sure you want to delete this task?'),
                            actions: <Widget>[
                              TextButton(
                                child: Text('Cancel'),
                                onPressed: () {
                                  Navigator.of(context).pop();
                                },
                              ),
                              TextButton(
                                child: Text('Delete'),
                                onPressed: () {
                                  // Delete the task and close the dialog
                                  _deleteTask(taskId);
                                  Navigator.of(context).pop();
                                  Navigator.of(context).pop();
                                  // You might also want to navigate back or update the UI.
                                },
                              ),
                            ],
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    TextField(
                      controller: taskNameController,
                      decoration: InputDecoration(labelText: 'Task Name'),
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
                                ),
                              ),
                            ),
                            IconButton(
                              icon: Icon(Icons.remove),
                              onPressed: () {
                                _removeSubtask(i);
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
                      'Task Deadline: ${selectedTaskDeadline != null ? DateFormat('yyyy-MM-dd HH:mm').format(selectedTaskDeadline!) : 'Update Deadline'}',
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
                      child: Text(' Update Task Deadline'),
                    ),
                    ElevatedButton(
                      onPressed: () async {
                        // Get the updated task name from the controller
                        final String updatedTaskName = taskNameController.text;

                        // Get the updated subtask names from the controllers
                        final List<String> updatedSubtaskNames =
                        subtaskControllers.map((controller) => controller.text).toList();

                        // Update the task details in Firestore
                        await FirebaseFirestore.instance
                            .collection('users')
                            .doc(FirebaseAuth.instance.currentUser!.uid)
                            .collection('projects')
                            .doc(widget.project.id)
                            .collection('tasks')
                            .doc(taskId)
                            .update({
                          'name': updatedTaskName,
                          'subtasks': updatedSubtaskNames,
                          'tasksdeadline': selectedTaskDeadline, // Update the task deadline
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
      },
    );
  }

  void _deleteTask(String taskId) {
    try {
      // Get a reference to the Firestore instance
      final FirebaseFirestore firestore = FirebaseFirestore.instance;

      // Delete the task document from Firestore
      firestore
          .collection('users')
          .doc(FirebaseAuth.instance.currentUser!.uid)
          .collection('projects')
          .doc(widget.project.id)
          .collection('tasks')
          .doc(taskId)
          .delete();

      // Optionally, you can update the UI or take other actions as needed
    } catch (e) {
      // Handle any errors that occur during Firestore operation
      print('Error deleting task: $e');
    }
  }

  void _openNoteDrawer(BuildContext context) {
    noteController.text = existingNote; // Set the text field with existing note content

    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Edit Note',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              TextField(
                controller: noteController,
                maxLines: 5, // Adjust the number of lines as needed
                decoration: InputDecoration(
                  hintText: 'Type your note here...',
                ),
              ),
              SizedBox(height: 10),
              ElevatedButton(
                onPressed: () async {
                  // Save the updated note content to Firestore
                  String noteContent = noteController.text;

                  try {
                    await FirebaseFirestore.instance
                        .collection('users')
                        .doc(FirebaseAuth.instance.currentUser!.uid)
                        .collection('projects')
                        .doc(widget.project.id)
                        .update({'note': noteContent});

                    setState(() {
                      existingNote = noteContent;
                    });

                    // Close the bottom sheet
                    Navigator.of(context).pop();
                  } catch (e) {
                    // Handle any errors that occur during Firestore operation
                    print('Error saving note: $e');
                  }
                },
                child: Text('Save Note'),
              ),
              ElevatedButton(
                onPressed: () {
                  _textScanner();
                },
                child: Text('Text Scanner'),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _textScanner() async {
    // Create an instance of the image picker
    final picker = ImagePicker();

    // Show a dialog to let the user choose between taking a photo or selecting from the gallery
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Choose an option'),
        content: Text('Take a photo or select from the gallery?'),
        actions: <Widget>[
          TextButton(
            child: Text('Take a Photo'),
            onPressed: () async {
              Navigator.of(context).pop();
              final pickedFile = await picker.pickImage(source: ImageSource.camera);
              if (pickedFile != null) {
                // Perform text recognition on the taken photo
                _processImage(pickedFile.path);
              }
            },
          ),
          TextButton(
            child: Text('Select from Gallery'),
            onPressed: () async {
              Navigator.of(context).pop();
              final pickedFile = await picker.pickImage(source: ImageSource.gallery);
              if (pickedFile != null) {
                // Perform text recognition on the selected image
               _processImage(pickedFile.path);
              }
            },
          ),
        ],
      ),
    );
  }
// Function to perform text recognition on an image
  Future<void> _processImage(String imagePath) async {
    final textRecognizer = GoogleMlKit.vision.textRecognizer();

    try {
      final inputImage = InputImage.fromFilePath(imagePath);
      final RecognizedText recognizedText = await textRecognizer.processImage(inputImage);

      String detectedText = recognizedText.text;

      print('Detected Text: $detectedText');

      // You can handle the detected text as needed, for example, display it in a dialog or update the UI
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Detected Text'),
          content: Text(detectedText),
          actions: [
            TextButton(
              onPressed: () {
                // User chose to paste
                Navigator.of(context).pop(); // Close the dialog
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                // User chose to paste
                Navigator.of(context).pop(); // Close the dialog.

                String value = noteController.text + "\n" + detectedText;
                noteController.text = value;
              },
              child: Text('Paste'),
            ),
          ],
        ),
      );
    } catch (e) {
      print('Error recognizing text: $e');
    } finally {
      textRecognizer.close();
    }
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
          IconButton(
            icon: Icon(Icons.content_copy), // Add the Duplicate Project icon here
            onPressed: () {
              _duplicateProject();
            },
          ),
          IconButton(
            icon: Icon(Icons.edit_note),
            onPressed: (){
              _openNoteDrawer(context); // User can write down the the note
            },
          ),
        ],
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
                          onLongPress: () {
                            _editTask(context, taskName, subtasks.cast<String>(), taskDoc.id, taskDeadline);
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