import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

class ProgressPage extends StatefulWidget {
  const ProgressPage({Key? key}) : super(key: key);

  @override
  State<ProgressPage> createState() => _ProgressPageState();
}

class _ProgressPageState extends State<ProgressPage> {
  bool isSecondRowVisible = false; // Initially, the second row is not visible
  List<bool> isRowVisible = []; // List to track visibility for each project

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: AnimatedTextKit(
          animatedTexts: [
            WavyAnimatedText('Project Master: Status',
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
      body: StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(FirebaseAuth.instance.currentUser!.uid)
            .collection('projects')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text('No projects found.'));
          } else {
            final projects = snapshot.data!.docs;

            return ListView.builder(
              itemCount: projects.length,
              itemBuilder: (context, index) {
                final project = projects[index];
                final projectName = project['name']; // Adjust this to match your Firestore data structure
                // Initialize isRowVisible list for each project
                if (index >= isRowVisible.length) {
                  isRowVisible.add(false);
                }

                return FutureBuilder(
                  future: _getProjectTaskCount(project.reference),
                  builder: (context, taskCountSnapshot) {
                    if (taskCountSnapshot.connectionState == ConnectionState.waiting) {
                      return Center(child: CircularProgressIndicator());
                    } else {
                      final taskCount = taskCountSnapshot.data as Map<String, dynamic>;
                      final totalTasks = taskCount['total'];
                      final completedTasks = taskCount['completed'];
                      final incompleteTasks = taskCount['incomplete'];
                      final completionPercentage = totalTasks == 0 ? 0.0 : (completedTasks / totalTasks * 100).toDouble();

                      return Container(
                        margin: EdgeInsets.all(10),
                        padding: EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.blue),
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Project: $projectName'
                                      ,style: TextStyle(
                                        fontWeight: FontWeight.bold
                                      ),
                                    ),
                                    Text('Total Tasks: $totalTasks'),
                                    Text('Completed Tasks: $completedTasks'),
                                    Text('Incomplete Tasks: $incompleteTasks'),
                                    Text('Completion Percentage:'),
                                    Text('${completionPercentage.toStringAsFixed(2)}% completed'),
                                    SizedBox(height: 10),
                                  ],
                                ),
                                Container (
                                  width: 100,  // Set the desired width
                                  height: 100,
                                  decoration: BoxDecoration(
                                    color: Colors.blueGrey,
                                    borderRadius: BorderRadius.circular(20.0),
                                  ),// Set the desired height
                                  child: SfCircularChart(
                                    series: <DoughnutSeries<_ChartData, String>>[
                                      DoughnutSeries<_ChartData, String>(
                                        dataSource: <_ChartData>[
                                          _ChartData('Completed', completedTasks),
                                          _ChartData('Incomplete', incompleteTasks),
                                        ],
                                        xValueMapper: (_ChartData data, _) => data.x,
                                        yValueMapper: (_ChartData data, _) => data.y,
                                        dataLabelMapper: (_ChartData data, _) =>
                                        '${(data.y / totalTasks * 100).toStringAsFixed(2)}%',
                                        dataLabelSettings: DataLabelSettings(
                                          isVisible: true, // Set to true to show labels
                                          labelPosition: ChartDataLabelPosition.inside, // Adjust the position
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 10,),
                            Visibility(
                              visible: isRowVisible[index], // Use the state for this specific project,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Container(
                                    width: 160,
                                    height: 150, // Adjust the height as needed
                                    child: Container(
                                      decoration: BoxDecoration(
                                          color: Colors.grey,
                                          borderRadius: BorderRadius.circular(10.0)
                                      ),
                                      child: SfCartesianChart(
                                        primaryXAxis: CategoryAxis(),
                                        primaryYAxis: NumericAxis(),
                                        series: <LineSeries<_ChartData, String>>[
                                          LineSeries<_ChartData, String>(
                                            dataSource: <_ChartData>[
                                              _ChartData('Done', completedTasks),
                                              _ChartData('Not Done', incompleteTasks),
                                            ],
                                            xValueMapper: (_ChartData data, _) => data.x,
                                            yValueMapper: (_ChartData data, _) => data.y,
                                            markerSettings: MarkerSettings(isVisible: true),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  Container(
                                    width: 150,
                                    height: 150,
                                    decoration: BoxDecoration(
                                        color: Colors.grey,
                                        borderRadius: BorderRadius.circular(10.0)
                                    ),
                                    child: SfCartesianChart(
                                      primaryXAxis: CategoryAxis(),
                                      primaryYAxis: NumericAxis(),
                                      series: <BarSeries<_ChartData, String>>[
                                        BarSeries<_ChartData, String>(
                                          dataSource: <_ChartData>[
                                            _ChartData('Completed', completedTasks),
                                            _ChartData('Incomplete', incompleteTasks),
                                          ],
                                          xValueMapper: (_ChartData data, _) => data.x,
                                          yValueMapper: (_ChartData data, _) => data.y,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              onPressed: () {
                                setState(() {
                                  isRowVisible[index] = !isRowVisible[index];
                                });
                              },
                              icon: Icon(isRowVisible[index] ? Icons.expand_less : Icons.expand_more),
                            ),
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

class _ChartData {
  _ChartData(this.x, this.y);
  final String x;
  final int y;
}
