import 'package:flutter/material.dart';
import 'package:project_master/pages/progress_page.dart';
import 'package:project_master/pages/home_page.dart';
import 'package:project_master/pages/tasks_page.dart';
import 'package:project_master/pages/setting_page.dart';

class MainPage extends StatefulWidget {
  @override
  _MainPageState createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _currentIndex = 0;
  final PageController _pageController = PageController();
  final List<Widget> _pages = [
    HomePage(),
    TasksPage(),
    ProgressPage(),
    SettingPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // appBar: AppBar(
      //   title: Text('Project Master'),
      // ),
      body: PageView(
        controller: _pageController,
        onPageChanged: (int index) {
          setState(() {
            _currentIndex = index;
          });
        },
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (int index) {
          setState(() {
            _currentIndex = index;
            _pageController.animateToPage(
              index,
              duration: Duration(milliseconds: 300),
              curve: Curves.ease,
            );
          });
        },
        selectedItemColor: Colors.black,
        unselectedItemColor: Colors.black,
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_max_outlined),
            label: 'Main',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.article_outlined),
            label: 'Tasks',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.align_horizontal_left),
            label: 'Progress',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_applications_outlined),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
