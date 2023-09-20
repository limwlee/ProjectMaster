import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:project_master/project.dart';


class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController _projectNameController = TextEditingController();
  final TextEditingController _projectDescriptionController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<Project> selectedProjects = []; // Add a list to store selected projects

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home Page'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection('users')
            .doc(_auth.currentUser!.uid)
            .collection('projects')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const CircularProgressIndicator();
          } else if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text('No projects found.'),
            );
          }
          final projects = snapshot.data!.docs;

          // Method to toggle the selection of a project
          void toggleProjectSelection(Project project) {
            setState(() {
              if (selectedProjects.contains(project)) {
                selectedProjects.remove(project);
              } else {
                selectedProjects.add(project);
              }
            });
          }


          // Display the list of projects
          return ListView.builder(
            itemCount: projects.length,
            itemBuilder: (context, index) {
              final project = projects[index].data() as Map<String, dynamic>;
              final projectName = project['name'];
              final projectDescription = project['description'];
              final projectItem = Project(
                id: projects[index].id,
                name: projectName,
                description: projectDescription,
                isSelected: selectedProjects.contains(project),
              );

              void deleteProject() async {
                await _firestore
                    .collection('users')
                    .doc(_auth.currentUser!.uid)
                    .collection('projects')
                    .doc(projects[index].id)
                    .delete();
              }

              // Add a LongPressGestureRecognizer for deletion
              final longPressGestureRecognizer = LongPressGestureRecognizer()
                ..onLongPress = () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: Text('Delete Project'),
                      content: Text('Are you sure you want to delete this project?'),
                      actions: [
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pop(); // Close the dialog
                          },
                          child: Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () {
                            deleteProject(); // Call the delete function
                            Navigator.of(context).pop(); // Close the dialog
                          },
                          child: Text('Delete'),
                        ),
                      ],
                    ),
                  );
                };

              return Padding(
                padding: const EdgeInsets.all(8.0),
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.blue), // Customize border properties
                    borderRadius: BorderRadius.circular(10.0), // Customize border radius
                    // Add more BoxDecoration properties as needed
                  ),
                  child: ListTile(
                    title: Text(projectName),
                    subtitle: Text(projectDescription),
                    onLongPress: longPressGestureRecognizer.onLongPress,
                    // Add more widgets for project details or actions
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showAddProjectDialog(context);
        },
        child: Icon(Icons.add),
        tooltip: 'Add Project',
      ),
    );
  }

  Future<void> _showAddProjectDialog(BuildContext context) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // Dialog cannot be dismissed by tapping outside
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Add Project'),
          content: Column(
            mainAxisSize: MainAxisSize.max,
            children: [
              TextField(
                controller: _projectNameController,
                decoration: InputDecoration(labelText: 'Project Name'),
              ),
              TextField(
                controller: _projectDescriptionController,
                decoration: InputDecoration(labelText: 'Project Description'),
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
            ),
            TextButton(
              child: Text('Save'),
              onPressed: () async{
                // Get the project name and description from the controllers
                final String projectName = _projectNameController.text;
                final String projectDescription = _projectDescriptionController.text;

                // Get the current user's UID
                final String userUid = FirebaseAuth.instance.currentUser!.uid;

                // Generate a unique ID for the project
                final String projectId = FirebaseFirestore.instance.collection('projects').doc().id;

                // Create a map with project data
                final Map<String, dynamic> projectData = {
                  'id': projectId,
                  'name': projectName,
                  'description': projectDescription,
                };

                try {
                  // Add the project data to Firestore under the user's UID
                  await FirebaseFirestore.instance.collection('users').doc(userUid).collection('projects').doc(projectId).set(projectData);

                  // Close the dialog
                  Navigator.of(context).pop();

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Project saved successfully.'),
                    ),
                  );
                } catch (e) {
                  print('Project save error: $e');
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Project save failed. Please try again.'),
                    ),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    // Dispose of the controllers when the widget is disposed
    _projectNameController.dispose();
    _projectDescriptionController.dispose();
    super.dispose();
  }
}



