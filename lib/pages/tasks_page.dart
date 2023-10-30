import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class TasksPage extends StatefulWidget {
  const TasksPage({Key? key}) : super(key: key);

  @override
  State<TasksPage> createState() => _TasksPageState();
}

class _TasksPageState extends State<TasksPage> {
  int _currentIndex = 0; // Initially, display the content for "Today"

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: AnimatedTextKit(
          animatedTexts: [
            WavyAnimatedText('Project Master:Task',
              speed: const Duration(milliseconds: 200),
              textStyle: GoogleFonts.lobster(
                  textStyle: TextStyle(
                    letterSpacing: 2,
                    fontWeight: FontWeight.bold,
                  )
              ),
            ),
          ],
          repeatForever: true,
        ),
      ),
      body: _buildPageContent(_currentIndex), // Display content based on the selected index
      bottomNavigationBar: BottomNavigationBar(
        selectedItemColor: Colors.blue, // Set the selected item color
        unselectedItemColor: Colors.grey, // Set the unselected item color
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.today),
            label: 'Today',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_view_week),
            label: 'This Week',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            label: 'This Month',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.event_busy),
            label: 'No Date',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.assignment_late_outlined),
            label: 'Over Due',
          ),
        ],
        currentIndex: _currentIndex,
        onTap: (int index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
    );
  }

  Widget _buildPageContent(int index) {
    // Implement your content based on the selected index here
    switch (index) {
      case 0:
        return _buildTodayContent();
      case 1:
        return _buildThisWeekContent();
      case 2:
        return _buildThisMonthContent();
      case 3:
        return _buildNoDateContent();
      case 4:
        return _buildOverDueContent();
      default:
        return Container(); // Default content (today) or you can show an error message
    }
  }

  Widget _buildTodayContent() {
    final now = DateTime.now();
    final startOfToday = DateTime(now.year, now.month, now.day);
    final endOfToday = startOfToday.add(Duration(days: 1));

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(FirebaseAuth.instance.currentUser!.uid)
          .collection('projects')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        }

        final projects = snapshot.data;

        if (projects == null|| projects.docs.isEmpty) {
          return Center(
              child: Text('No projects found.',style: TextStyle(fontWeight: FontWeight.bold),)
          );
        }

        return ListView.builder(
          itemCount: projects.docs.length,
          itemBuilder: (context, index) {
            final project = projects.docs[index];

            return StreamBuilder<QuerySnapshot>(
              stream: project.reference
                  .collection('tasks')
                  .where('tasksdeadline', isGreaterThanOrEqualTo: startOfToday)
                  .where('tasksdeadline', isLessThan: endOfToday)
                  .snapshots(),
              builder: (context, taskSnapshot) {
                if (taskSnapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }

                if (taskSnapshot.hasError) {
                  return Text('Error: ${taskSnapshot.error}');
                }

                final tasks = taskSnapshot.data;

                if (tasks == null) {
                  return Text('No tasks found for today.');
                }

                return tasks.docs.isNotEmpty ? Container(
                  margin: EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.black12,
                    border: Border.all(color: Colors.blue),
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      StreamBuilder<DocumentSnapshot>(
                        stream: project.reference.snapshots(),
                        builder: (context, projectSnapshot) {
                          if (projectSnapshot.connectionState == ConnectionState.waiting) {
                            return Center(child: CircularProgressIndicator());
                          }

                          if (projectSnapshot.hasError) {
                            return Text('Error: ${projectSnapshot.error}');
                          }

                          final projectName = projectSnapshot.data?['name'] as String;

                          return Padding(
                            padding: const EdgeInsets.all(10.0),
                            child: Text(
                              'Project Name: $projectName',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          );
                        },
                      ),
                      ...tasks.docs.map((taskDoc) {
                        final taskData = taskDoc.data() as Map<String, dynamic>;
                        final taskName = taskData['name'] as String;
                        final subtasks = taskData['subtasks'] as List<dynamic>;
                        final deadlineTimestamp = taskData['tasksdeadline'] as Timestamp?;

                        final isOverdue =
                            deadlineTimestamp != null && deadlineTimestamp.toDate().isBefore(DateTime.now());

                        final deadline = deadlineTimestamp != null
                            ? DateFormat('yyyy-MM-dd HH:mm').format(deadlineTimestamp.toDate())
                            : 'No deadline specified';

                        final borderColor = isOverdue ? Colors.red : Colors.green;

                        return Container(
                          margin: EdgeInsets.all(10),
                          padding: EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            border: Border.all(color: borderColor),
                            borderRadius: BorderRadius.circular(10.0),
                          ),
                          child: ListTile(
                            title: Text('Task Name: $taskName'),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Deadline: $deadline', style: TextStyle(color: borderColor)),
                                if (subtasks != null && subtasks.isNotEmpty)
                                  Text('Subtasks: ${subtasks.join(", ")}'),
                                if (isOverdue) Text('The task is overdue', style: TextStyle(color: borderColor)),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ],
                  ),
                ) : Container(
                  margin: EdgeInsets.all(10),
                  padding: EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.blue),
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  child: ListTile(
                    title: StreamBuilder<DocumentSnapshot>(
                      stream: project.reference.snapshots(),
                      builder: (context, projectSnapshot) {
                        if (projectSnapshot.connectionState == ConnectionState.waiting) {
                          return Center(child: CircularProgressIndicator());
                        }

                        if (projectSnapshot.hasError) {
                          return Text('Error: ${projectSnapshot.error}');
                        }

                        final projectName = projectSnapshot.data?['name'] as String;

                        return Text('Project Name: $projectName', style: TextStyle(fontWeight: FontWeight.bold));
                      },
                    ),
                    subtitle: Text('No tasks due today'),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildThisWeekContent() {
    final today = DateTime.now();
    final startOfWeek = today.subtract(Duration(days: today.weekday - 1));
    final endOfWeek = startOfWeek.add(Duration(days: 7));

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(FirebaseAuth.instance.currentUser!.uid)
          .collection('projects')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        }

        final projects = snapshot.data;

        if (projects == null|| projects.docs.isEmpty) {
          return Center(
              child: Text('No projects found.',style: TextStyle(
                fontWeight: FontWeight.bold,
              ),)
          );
        }

        return ListView.builder(
          itemCount: projects.docs.length,
          itemBuilder: (context, index) {
            final project = projects.docs[index];

            return StreamBuilder<QuerySnapshot>(
              stream: project.reference
                  .collection('tasks')
                  .where('tasksdeadline', isGreaterThanOrEqualTo: startOfWeek)
                  .where('tasksdeadline', isLessThan: endOfWeek)
                  .snapshots(),
              builder: (context, taskSnapshot) {
                if (taskSnapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }

                if (taskSnapshot.hasError) {
                  return Text('Error: ${taskSnapshot.error}');
                }

                final tasks = taskSnapshot.data;

                if (tasks == null) {
                  return Text('No tasks found for this week.');
                }

                return tasks.docs.isNotEmpty ? Container(
                  margin: EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.black12,
                    border: Border.all(color: Colors.blue),
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      StreamBuilder<DocumentSnapshot>(
                        stream: project.reference.snapshots(),
                        builder: (context, projectSnapshot) {
                          if (projectSnapshot.connectionState == ConnectionState.waiting) {
                            return Center(child: CircularProgressIndicator());
                          }

                          if (projectSnapshot.hasError) {
                            return Text('Error: ${projectSnapshot.error}');
                          }

                          final projectName = projectSnapshot.data?['name'] as String;

                          return Padding(
                            padding: const EdgeInsets.all(10.0),
                            child: Text(
                              'Project Name: $projectName',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          );
                        },
                      ),
                      ...tasks.docs.map((taskDoc) {
                        final taskData = taskDoc.data() as Map<String, dynamic>;
                        final taskName = taskData['name'] as String;
                        final subtasks = taskData['subtasks'] as List<dynamic>;
                        final deadlineTimestamp = taskData['tasksdeadline'] as Timestamp?;

                        final isOverdue =
                            deadlineTimestamp != null && deadlineTimestamp.toDate().isBefore(DateTime.now());

                        final deadline = deadlineTimestamp != null
                            ? DateFormat('yyyy-MM-dd HH:mm').format(deadlineTimestamp.toDate())
                            : 'No deadline specified';

                        final borderColor = isOverdue ? Colors.red : Colors.green;

                        return Container(
                          margin: EdgeInsets.all(10),
                          padding: EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            border: Border.all(color: borderColor),
                            borderRadius: BorderRadius.circular(10.0),
                          ),
                          child: ListTile(
                            title: Text('Task Name: $taskName'),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Deadline: $deadline', style: TextStyle(color: borderColor)),
                                if (subtasks != null && subtasks.isNotEmpty)
                                  Text('Subtasks: ${subtasks.join(", ")}'),
                                if (isOverdue) Text('The task is overdue', style: TextStyle(color: borderColor)),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ],
                  ),
                ) : Container(
                  margin: EdgeInsets.all(10),
                  padding: EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.blue),
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  child: ListTile(
                    title: StreamBuilder<DocumentSnapshot>(
                      stream: project.reference.snapshots(),
                      builder: (context, projectSnapshot) {
                        if (projectSnapshot.connectionState == ConnectionState.waiting) {
                          return Center(child: CircularProgressIndicator());
                        }

                        if (projectSnapshot.hasError) {
                          return Text('Error: ${projectSnapshot.error}');
                        }

                        final projectName = projectSnapshot.data?['name'] as String;

                        return Text('Project Name: $projectName', style: TextStyle(fontWeight: FontWeight.bold));
                      },
                    ),
                    subtitle: Text('No tasks due this week'),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildThisMonthContent() {
    final today = DateTime.now();
    final startOfMonth = DateTime(today.year, today.month, 1);
    final endOfMonth = DateTime(today.year, today.month + 1, 0);

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(FirebaseAuth.instance.currentUser!.uid)
          .collection('projects')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        }

        final projects = snapshot.data;

        if (projects == null|| projects.docs.isEmpty) {
          return Center(child: Text('No projects found.',style: TextStyle(fontWeight: FontWeight.bold),));
        }

        return ListView.builder(
          itemCount: projects.docs.length,
          itemBuilder: (context, index) {
            final project = projects.docs[index];

            return StreamBuilder<QuerySnapshot>(
              stream: project.reference
                  .collection('tasks')
                  .where('tasksdeadline', isGreaterThanOrEqualTo: startOfMonth)
                  .where('tasksdeadline', isLessThan: endOfMonth)
                  .snapshots(),
              builder: (context, taskSnapshot) {
                if (taskSnapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }

                if (taskSnapshot.hasError) {
                  return Text('Error: ${taskSnapshot.error}');
                }

                final tasks = taskSnapshot.data;

                if (tasks == null) {
                  return Text('No tasks found for this month.');
                }

                return tasks.docs.isNotEmpty ? Container(
                  margin: EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.black12,
                    border: Border.all(color: Colors.blue),
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      StreamBuilder<DocumentSnapshot>(
                        stream: project.reference.snapshots(),
                        builder: (context, projectSnapshot) {
                          if (projectSnapshot.connectionState == ConnectionState.waiting) {
                            return Center(child: CircularProgressIndicator());
                          }

                          if (projectSnapshot.hasError) {
                            return Text('Error: ${projectSnapshot.error}');
                          }

                          final projectName = projectSnapshot.data?['name'] as String;

                          return Padding(
                            padding: const EdgeInsets.all(10.0),
                            child: Text(
                              'Project Name: $projectName',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          );
                        },
                      ),
                      ...tasks.docs.map((taskDoc) {
                        final taskData = taskDoc.data() as Map<String, dynamic>;
                        final taskName = taskData['name'] as String;
                        final subtasks = taskData['subtasks'] as List<dynamic>;
                        final deadlineTimestamp = taskData['tasksdeadline'] as Timestamp?;

                        final isOverdue =
                            deadlineTimestamp != null && deadlineTimestamp.toDate().isBefore(DateTime.now());

                        final deadline = deadlineTimestamp != null
                            ? DateFormat('yyyy-MM-dd HH:mm').format(deadlineTimestamp.toDate())
                            : 'No deadline specified';

                        final borderColor = isOverdue ? Colors.red : Colors.green;

                        return Container(
                          margin: EdgeInsets.all(10),
                          padding: EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            border: Border.all(color: borderColor),
                            borderRadius: BorderRadius.circular(10.0),
                          ),
                          child: ListTile(
                            title: Text('Task Name: $taskName'),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Deadline: $deadline', style: TextStyle(color: borderColor)),
                                if (subtasks != null && subtasks.isNotEmpty)
                                  Text('Subtasks: ${subtasks.join(", ")}'),
                                if (isOverdue) Text('The task is overdue', style: TextStyle(color: borderColor)),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ],
                  ),
                ) : Container(
                  margin: EdgeInsets.all(10),
                  padding: EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.blue),
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  child: ListTile(
                    title: StreamBuilder<DocumentSnapshot>(
                      stream: project.reference.snapshots(),
                      builder: (context, projectSnapshot) {
                        if (projectSnapshot.connectionState == ConnectionState.waiting) {
                          return Center(child: CircularProgressIndicator());
                        }

                        if (projectSnapshot.hasError) {
                          return Text('Error: ${projectSnapshot.error}');
                        }

                        final projectName = projectSnapshot.data?['name'] as String;

                        return Text('Project Name: $projectName', style: TextStyle(fontWeight: FontWeight.bold));
                      },
                    ),
                    subtitle: Text('No tasks due this month'),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildNoDateContent() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(FirebaseAuth.instance.currentUser!.uid)
          .collection('projects')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        }

        final projects = snapshot.data;

        if (projects == null|| projects.docs.isEmpty) {
          return Center(child: Text('No projects found. ',style: TextStyle(fontWeight: FontWeight.bold),));
        }

        return ListView.builder(
          itemCount: projects.docs.length,
          itemBuilder: (context, index) {
            final project = projects.docs[index];

            return StreamBuilder<QuerySnapshot>(
              stream: project.reference
                  .collection('tasks')
                  .where('tasksdeadline', isNull: true)
                  .snapshots(),
              builder: (context, taskSnapshot) {
                if (taskSnapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }

                if (taskSnapshot.hasError) {
                  return Text('Error: ${taskSnapshot.error}');
                }

                final tasks = taskSnapshot.data;

                if (tasks == null) {
                  return Text('No tasks found with no date.');
                }

                return tasks.docs.isNotEmpty
                    ? Container(
                  margin: EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.black12,
                    border: Border.all(color: Colors.blue),
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      StreamBuilder<DocumentSnapshot>(
                        stream: project.reference.snapshots(),
                        builder: (context, projectSnapshot) {
                          if (projectSnapshot.connectionState == ConnectionState.waiting) {
                            return Center(child: CircularProgressIndicator());
                          }

                          if (projectSnapshot.hasError) {
                            return Text('Error: ${projectSnapshot.error}');
                          }

                          final projectName = projectSnapshot.data?['name'] as String;

                          return Padding(
                            padding: const EdgeInsets.all(10.0),
                            child: Text(
                              'Project Name: $projectName',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          );
                        },
                      ),
                      ...tasks.docs.map((taskDoc) {
                        final taskData = taskDoc.data() as Map<String, dynamic>;
                        final taskName = taskData['name'] as String;
                        final subtasks = taskData['subtasks'] as List<dynamic>;

                        return Container(
                          margin: EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.blue),
                            borderRadius: BorderRadius.circular(10.0),
                          ),
                          child: ListTile(
                            title: Text('Task Name: $taskName'),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Deadline: No date'),
                                if (subtasks != null && subtasks.isNotEmpty)
                                  Text('Subtasks: ${subtasks.join(", ")}'),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ],
                  ),
                )
                    : Container(
                  margin: EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.blue),
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  child: ListTile(
                    title: StreamBuilder<DocumentSnapshot>(
                      stream: project.reference.snapshots(),
                      builder: (context, projectSnapshot) {
                        if (projectSnapshot.connectionState == ConnectionState.waiting) {
                          return Center(child: CircularProgressIndicator());
                        }

                        if (projectSnapshot.hasError) {
                          return Text('Error: ${projectSnapshot.error}');
                        }

                        final projectName = projectSnapshot.data?['name'] as String;

                        return Text('Project Name: $projectName', style: TextStyle(fontWeight: FontWeight.bold));
                      },
                    ),
                    subtitle: Text('No tasks with no date'),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildOverDueContent() {
    final now = DateTime.now();

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(FirebaseAuth.instance.currentUser!.uid)
          .collection('projects')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        }


        final projects = snapshot.data;

        if (projects == null|| projects.docs.isEmpty) {
          return Center(child: Text('No projects found.',style: TextStyle(fontWeight: FontWeight.bold),));
        }

        return ListView.builder(
          itemCount: projects.docs.length,
          itemBuilder: (context, index) {
            final project = projects.docs[index];

            return StreamBuilder<QuerySnapshot>(
              stream: project.reference
                  .collection('tasks')
                  .where('tasksdeadline', isLessThan: now)
                  .snapshots(),
              builder: (context, taskSnapshot) {
                if (taskSnapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }

                if (taskSnapshot.hasError) {
                  return Text('Error: ${taskSnapshot.error}');
                }

                final tasks = taskSnapshot.data;

                return tasks!.docs.isNotEmpty ? Container(
                  margin: EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.black12,
                    border: Border.all(color: Colors.blue),
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      StreamBuilder<DocumentSnapshot>(
                        stream: project.reference.snapshots(),
                        builder: (context, projectSnapshot) {
                          if (projectSnapshot.connectionState == ConnectionState.waiting) {
                            return Center(child: CircularProgressIndicator());
                          }

                          if (projectSnapshot.hasError) {
                            return Text('Error: ${projectSnapshot.error}');
                          }

                          final projectName = projectSnapshot.data?['name'] as String;

                          return Padding(
                            padding: const EdgeInsets.all(10.0),
                            child: Text(
                              'Project Name: $projectName',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          );
                        },
                      ),
                      ...tasks.docs.map((taskDoc) {
                        final taskData = taskDoc.data() as Map<String, dynamic>;
                        final taskName = taskData['name'] as String;
                        final subtasks = taskData['subtasks'] as List<dynamic>;
                        final deadlineTimestamp = taskData['tasksdeadline'] as Timestamp;

                        final deadline = deadlineTimestamp != null
                            ? DateFormat('yyyy-MM-dd HH:mm').format(deadlineTimestamp.toDate())
                            : 'No deadline specified';

                        return Container(
                          margin: EdgeInsets.all(10),
                          padding: EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.blue),
                            borderRadius: BorderRadius.circular(10.0),
                          ),
                          child: ListTile(
                            title: Text('Task Name: $taskName'),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Deadline: $deadline', style: TextStyle(color: Colors.red)),
                                if (subtasks != null && subtasks.isNotEmpty)
                                  Text('Subtasks: ${subtasks.join(", ")}'),
                                Text('Overdue', style: TextStyle(color: Colors.red)),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ],
                  ),
                ) : Container(
                  margin: EdgeInsets.all(10),
                  padding: EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.blue),
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  child: ListTile(
                    title: StreamBuilder<DocumentSnapshot>(
                      stream: project.reference.snapshots(),
                      builder: (context, projectSnapshot) {
                        if (projectSnapshot.connectionState == ConnectionState.waiting) {
                          return Center(child: CircularProgressIndicator());
                        }

                        if (projectSnapshot.hasError) {
                          return Text('Error: ${projectSnapshot.error}');
                        }

                        final projectName = projectSnapshot.data?['name'] as String;

                        return Text('Project Name: $projectName', style: TextStyle(fontWeight: FontWeight.bold));
                      },
                    ),
                    subtitle: Text('No overdue tasks'),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }



}
