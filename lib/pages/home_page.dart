import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:project_master/project.dart';
import 'package:project_master/project_page.dart';

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
  String _searchQuery = ''; // Initialize an empty search query

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home Page'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      labelText: 'Search Projects',
                      prefixIcon: Icon(Icons.search),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                    },
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('users')
                  .doc(_auth.currentUser!.uid)
                  .collection('projects')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                } else if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Text('No projects found.'),
                  );
                }
                final projects = snapshot.data!.docs;

                // Filter projects based on the search query
                final filteredProjects = projects.where((project) {
                  final projectData = project.data() as Map<String, dynamic>;
                  final projectName = projectData['name'] as String;
                  final projectDescription = projectData['description'] as String;

                  return projectName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                      projectDescription.toLowerCase().contains(_searchQuery.toLowerCase());
                }).toList();

                // Display the list of projects
                return ListView.builder(
                  itemCount: filteredProjects.length,
                  itemBuilder: (context, index) {
                    final project = filteredProjects[index].data() as Map<String, dynamic>;
                    final projectName = project['name'];
                    final projectDescription = project['description'];
                    final projectId = filteredProjects[index].id;

                    void deleteProject() async {
                      await _firestore
                          .collection('users')
                          .doc(_auth.currentUser!.uid)
                          .collection('projects')
                          .doc(filteredProjects[index].id)
                          .delete();
                    }

                    return Dismissible(
                      key: UniqueKey(),
                      onDismissed: (direction) {
                        if (direction == DismissDirection.endToStart) {
                          // Show a confirmation dialog before deleting
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: Text('Confirm Delete'),
                              content: Text('Are you sure you want to delete this project?'),
                              actions: [
                                TextButton(
                                  onPressed: () {
                                    // Cancel the delete action and close the dialog
                                    Navigator.of(context).pop();
                                    setState(() {});
                                  },
                                  child: Text('Cancel'),
                                ),
                                TextButton(
                                  onPressed: () {
                                    // Delete the project and close the dialog
                                    deleteProject();
                                    Navigator.of(context).pop();
                                  },
                                  child: Text('Delete'),
                                ),
                              ],
                            ),
                          );
                        }
                      },
                      background: Container(
                        color: Colors.red,
                        alignment: Alignment.centerRight,
                        padding: EdgeInsets.only(right: 20),
                        child: Icon(
                          Icons.delete,
                          color: Colors.white,
                        ),
                      ),
                      child: GestureDetector(
                        onTap: () {
                          // Navigate to the ProjectPage with project details
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => ProjectPage(
                                project: Project(
                                  id: projectId,
                                  name: projectName,
                                  description: projectDescription,
                                ),
                              ),
                            ),
                          );
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: InkWell(
                            child: Container(
                              decoration: BoxDecoration(
                                border: Border.all(
                                    color: Colors.blue),
                                borderRadius: BorderRadius.circular(10.0),
                              ),
                              child: ListTile(
                                title: Text(projectName),
                                subtitle: Text(projectDescription),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
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

  //-------------------add project dialog---------------------------

  Future<void> _showAddProjectDialog(BuildContext context) async {
    return showDialog<void>(
      context: context,
      barrierDismissible:
      false, // Dialog cannot be dismissed by tapping outside
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Add Project'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
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
              onPressed: () async {
                // Get the project name and description from the controllers
                final String projectName = _projectNameController.text;
                final String projectDescription = _projectDescriptionController.text;

                // Check if the project name and description are not empty
                if (projectName.isEmpty || projectDescription.isEmpty) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Project name and description cannot be empty.'),
                    ),
                  );
                  return;
                }

                // Get the current user's UID
                final String userUid = FirebaseAuth.instance.currentUser!.uid;

                // Generate a unique ID for the project
                final String projectId =
                    FirebaseFirestore.instance.collection('projects').doc().id;

                // Create a map with project data
                final Map<String, dynamic> projectData = {
                  'id': projectId,
                  'name': projectName,
                  'description': projectDescription,
                };

                try {
                  // Add the project data to Firestore under the user's UID
                  await FirebaseFirestore.instance
                      .collection('users')
                      .doc(userUid)
                      .collection('projects')
                      .doc(projectId)
                      .set(projectData);

                  // Clear the text controllers
                  _projectNameController.clear();
                  _projectDescriptionController.clear();

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
