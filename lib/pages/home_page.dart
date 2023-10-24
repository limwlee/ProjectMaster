import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:project_master/project.dart';
import 'package:project_master/project_page.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';

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
  DateTime _selectedDeadline = DateTime.now(); // Initialize with the current date and time
  QuerySnapshot? _snapshot; // Define a variable to store the Firestore data

  @override
  void initState() {
    super.initState();
    // Fetch the Firestore data and assign it to the 'snapshot' variable
    _firestore
        .collection('users')
        .doc(_auth.currentUser!.uid)
        .collection('projects')
        .get()
        .then((QuerySnapshot querySnapshot) {
      setState(() {
        _snapshot = querySnapshot;
      });
    });
  }

  List<Appointment> getCalendarAppointments(QuerySnapshot projectSnapshot) {
    final List<Appointment> appointments = [];

    for (final project in projectSnapshot.docs) {
      final projectData = project.data() as Map<String, dynamic>;
      final projectName = projectData['name'];
      final projectDeadlineTimestamp = projectData['deadline']; // Firestore Timestamp

      // Convert the Firestore Timestamp to DateTime
      final projectDeadline = projectDeadlineTimestamp.toDate();

      // Set the startTime and endTime based on the project deadline DateTime
      appointments.add(
        Appointment(
          startTime: projectDeadline,
          endTime: projectDeadline, // Set the end time the same as the start time
          subject: projectName, // Project name
          color: Colors.blue, // Event color
        ),
      );
    }

    return appointments;
  }


  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Home Page'),
          actions: [],
          bottom: TabBar(
            tabs: [
              Tab(text: 'List View'),
              Tab(text: 'Calendar View'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            Column(
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
                              if (direction == DismissDirection.endToStart || direction == DismissDirection.startToEnd) {
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
                                        deadline: _selectedDeadline, tasks: [],

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
            // Second Column: Calendar ViewColumn(
            Column(
              children: [
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                      stream: _firestore
                          .collection('users')
                          .doc(_auth.currentUser!.uid)
                          .collection('projects')
                          .snapshots(),
                    builder: (context,snapshot) {
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

                      // Create a list of appointments from the projects
                      final appointments = projects.map((project) {
                        final projectData = project.data() as Map<String, dynamic>;
                        final projectName = projectData['name'];
                        final projectDeadlineTimestamp = projectData['deadline'];
                        final projectDeadline = projectDeadlineTimestamp.toDate();

                        return Appointment(
                          startTime: projectDeadline,
                          endTime: projectDeadline,
                          subject: projectName,
                          color: Colors.blue,
                        );
                      }).toList();

                      return SfCalendar(
                        view: CalendarView.month,
                        monthViewSettings: MonthViewSettings(
                          showAgenda: true,
                        ),
                        dataSource: MyCalendarDataSource(appointments),
                        appointmentBuilder: (BuildContext context, CalendarAppointmentDetails details) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: details.appointments.map((appointment) {
                              final projectName = appointment.subject;
                              final projectDeadline = DateFormat('yyyy-MM-dd HH:mm').format(appointment.startTime);

                              return Container(
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  color: appointment.color, // Use the event color if needed
                                  borderRadius: BorderRadius.circular(8.0),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(projectName),
                                      Text('Deadline: $projectDeadline'),
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                          );
                        },
                      );
                    }
                  ),
                ),
              ],
            )

          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            _showAddProjectDialog(context);
          },
          child: Icon(Icons.add),
          tooltip: 'Add Project',
        ),
      ),
    );
  }

  //-------------------add project dialog---------------------------

  Future<void> _showAddProjectDialog(BuildContext context) async {
    //DateTime selectedDeadline = DateTime.now(); // Initialize with the current date and time

    return showDialog<void>(
      context: context,
      barrierDismissible: false, // Dialog cannot be dismissed by tapping outside
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Add Project'),
          content: StatefulBuilder(
              builder: (context,setState) {
                return Column(
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
                    Row(
                      children: [
                        Text('Select Deadline:'),
                        TextButton(
                          onPressed: () async {
                            final selectedDate = await showDatePicker(
                              context: context,
                              initialDate: _selectedDeadline,
                              firstDate: DateTime.now(),
                              lastDate: DateTime(2101),
                            );

                            if (selectedDate != null) {
                              final selectedTime = await showTimePicker(
                                context: context,
                                initialTime: TimeOfDay.fromDateTime(_selectedDeadline),
                              );

                              if (selectedTime != null) {
                                setState(() {
                                  _selectedDeadline = DateTime(
                                    selectedDate.year,
                                    selectedDate.month,
                                    selectedDate.day,
                                    selectedTime.hour,
                                    selectedTime.minute,
                                  );
                                });
                              }
                            }
                          },
                          child: Text('Choose Deadline'),
                        ),
                      ],
                    ),
                    Text('Selected Deadline: ${_selectedDeadline.toString()}'),
                  ],
                );
              }
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
                  'deadline': _selectedDeadline, // Add the selected deadline
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
                  setState(() {
                    _selectedDeadline = DateTime.now();
                  });



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

class MyCalendarDataSource extends CalendarDataSource {
  MyCalendarDataSource(List<Appointment> source) {
    appointments = source;
  }
}