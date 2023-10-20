import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProgressPage extends StatefulWidget {
  const ProgressPage({Key? key}) : super(key: key);

  @override
  State<ProgressPage> createState() => _ProgressPageState();
}

class _ProgressPageState extends State<ProgressPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('ProgressPage'),
      ),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(FirebaseAuth.instance.currentUser!.uid)
            .collection('projects')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return CircularProgressIndicator();
          } else if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text('No projects found.'));
          } else {
            final projects = snapshot.data!.docs;

            return ListView.builder(
              itemCount: projects.length,
              itemBuilder: (context, index) {
                final project = projects[index];
                final projectName = project['name']; // Adjust this to match your Firestore data structure

                return FutureBuilder(
                  future: _getProjectTaskCount(project.reference),
                  builder: (context, taskCountSnapshot) {
                    if (taskCountSnapshot.connectionState == ConnectionState.waiting) {
                      return CircularProgressIndicator();
                    } else {
                      final taskCount = taskCountSnapshot.data as Map<String, dynamic>;
                      final totalTasks = taskCount['total'];
                      final completedTasks = taskCount['completed'];
                      final incompleteTasks = taskCount['incomplete'];
                      final completionPercentage = totalTasks == 0 ? 0.0 : (completedTasks / totalTasks * 100).toStringAsFixed(2);

                      return Container(
                        margin: EdgeInsets.all(10),
                        padding: EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.blue),
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Project: $projectName'),
                            Text('Total Tasks: $totalTasks'),
                            Text('Completed Tasks: $completedTasks'),
                            Text('Incomplete Tasks: $incompleteTasks'),
                            Text('Completion Percentage: $completionPercentage% completed'),
                          ],
                        ),
                      );
                    }
                  },
                );
              },
            );
          }
        },
      ),
    );
  }

  Future<Map<String, dynamic>> _getProjectTaskCount(DocumentReference projectReference) async {
    final taskQuery = await projectReference.collection('tasks').get();
    int totalTasks = taskQuery.docs.length;
    int completedTasks = taskQuery.docs.where((task) => task['isComplete'] == true).length;
    int incompleteTasks = totalTasks - completedTasks;

    return {
      'total': totalTasks,
      'completed': completedTasks,
      'incomplete': incompleteTasks,
    };
  }
}
