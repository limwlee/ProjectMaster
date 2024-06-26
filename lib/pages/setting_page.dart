import 'dart:io';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:project_master/login_page.dart';


class SettingPage extends StatefulWidget {
  const SettingPage({super.key});

  @override
  _SettingPageState createState() => _SettingPageState();
}

class _SettingPageState extends State<SettingPage> {
  User? _user;
  String? _newIntroduction = '';
  String? _newPosition = 'Student'; // Default value
  String? _newAwayMode = 'Online'; // Default value


  @override
  void initState(){
    // Fetch the user data when the page is initialized
    _fetchUserData();
    super.initState();
  }

  Future<void> _fetchUserData() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      try {
        final userData = await FirebaseFirestore.instance
            .collection('users')  // Replace 'users' with the appropriate Firestore collection name
            .doc(user.uid)
            .get();

        if (userData.exists) {
          // Get the user data from Firestore
          final data = userData.data() as Map<String, dynamic>;
          setState(() {
            _user = user;
            _newIntroduction = data['introduction'] ?? '';  // Assuming 'introduction' is a field in Firestore
            _newPosition = data['Position'] ?? 'Student';    // Assuming 'Position' is a field in Firestore
            _newAwayMode = data['awaymode'] ?? 'Online';    // Assuming 'awaymode' is a field in Firestore
          });
        } else {
          setState(() {
            _user = user;
            _newIntroduction = '';
            _newPosition = 'Student';
            _newAwayMode = 'Online';
          });
        }
      } catch (e) {
        print('Error fetching user data from Firestore: $e');
      }
    } else {
      print('User is not authenticated.');
    }
  }


  Future<void> _changeProfilePicture() async {
    final ImagePicker _picker = ImagePicker();
    final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      final File file = File(pickedFile.path);

      // Generate a unique storage path for the user's profile picture using their UID
      final String uid = _user!.uid;
      final String storagePath = 'profile_pictures/$uid.jpg';

      // Upload the image to Firebase Storage
      final FirebaseStorage storage = FirebaseStorage.instance;
      final Reference storageReference = storage.ref().child(storagePath);

      if (!file.path.endsWith('.jpg') && !file.path.endsWith('.jpeg') && !file.path.endsWith('.png')) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Only image files (JPEG or PNG) are allowed.'),
          ),
        );
        return;
      }


      try {
        final UploadTask uploadTask = storageReference.putFile(file);
        await uploadTask.whenComplete(() async {
          // Get the download URL of the uploaded image
          final String downloadURL = await storageReference.getDownloadURL();

          // Update the user's profile picture URL in Firebase Authentication
          await _user?.updatePhotoURL(downloadURL);

          // Fetch user data again to reflect the updated profile picture
          await _fetchUserData();

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Profile picture uploaded successfully.'),
            ),
          );
        });
      } on FirebaseException catch (e) {
        print('Firebase Storage Error: $e');

        // Handle different Firebase Storage error codes
        if (e.code == 'canceled') {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Upload canceled by the user.'),
            ),
          );
        } else if (e.code == 'unknown') {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('An unknown error occurred. Please try again later.'),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error uploading profile picture: ${e.message}'),
            ),
          );
        }
      } catch (e) {
        print('Image upload error: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Image upload failed. Please try again.'),
          ),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Image selection canceled.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: AnimatedTextKit(
          animatedTexts: [
            WavyAnimatedText('Project Master:Profile',
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
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, // Align content to the left

          children: [
            // Display the user's profile picture
            if (_user != null && _user!.photoURL != null)
              Container(
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10.0),
                    border: Border.all(color: Colors.blue)
                ),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 60, // Adjust the size as needed
                        backgroundImage: NetworkImage(_user!.photoURL!),
                      ),
                      SizedBox(width: 5,),
                      Column(
                        children: [
                          ElevatedButton(
                            onPressed: () {
                              _changeProfilePicture();
                            },
                            child: Text('Change Profile Picture'),
                          ),
                          ElevatedButton(
                            onPressed: (){
                              _showEditDialog(context);
                            },
                            child: Text('Edit'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            SizedBox(height: 16),
            // Display the user's profile data
            if (_user != null)
              Container(
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10.0),
                    border: Border.all(color: Colors.blue)
                ),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Name: ${_user!.displayName ?? 'N/A'}'),
                      Divider(),
                      Text('Introduction: ${_newIntroduction ?? 'N/A'}'),
                      Divider(),
                      Text('Email: ${_user!.email ?? 'N/A'}'),
                      Divider(),
                      Text('Away Mode: ${_newAwayMode ?? 'N/A'}'),
                      Divider(),
                      Text('Position: ${_newPosition ?? 'N/A'}'),
                      Divider(),
                      Text('UID: ${_user!.uid}'),
                      Divider(),
                      // Display email verification status
                      if (_user!.emailVerified)
                        Text('Email Verified', style: TextStyle(color: Colors.green)),
                      if (!_user!.emailVerified)
                        Text('Email Not Verified', style: TextStyle(color: Colors.red)),
                      //
                      // You can display more user data as needed
                    ],
                  ),
                ),
              ),
            Divider(),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      _confirmLogout(context);
                    },
                    child: Text('Logout'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _handleLogout(BuildContext context) async {
    try {
      await FirebaseAuth.instance.signOut();
      // After successful logout,navigate to the login page
      Navigator.of(context).pushReplacement(MaterialPageRoute(
        builder: (context)=>LoginPage(),
      )); // Replace with your login route
    } catch (e) {
      print('Logout error: $e');
      // Handle logout error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Logout failed. Please try again.'),
        ),
      );
    }
  }
  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text('Confirm Logout'),
          content: Text('Are you sure you want to log out?'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(); // Close the dialog
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                _handleLogout(context); // Perform the logout
                Navigator.of(dialogContext).pop(); // Close the dialog
              },
              child: Text('Logout'),
            ),
          ],
        );
      },
    );
  }

  void _showEditDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text('Edit Profile'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                onChanged: (value) {
                  _newIntroduction = value;
                },
                decoration: InputDecoration(labelText: 'Introduction'),
              ),
              SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _newAwayMode,
                onChanged: (value) {
                  setState(() {
                    _newAwayMode = value;
                  });
                },
                items: ['Online', 'Away','Sleep']
                    .map((mode) => DropdownMenuItem<String>(
                  value: mode,
                  child: Text(mode),
                ))
                    .toList(),
                decoration: InputDecoration(labelText: 'Away Mode'),
              ),
              SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _newPosition,
                onChanged: (value) {
                  setState(() {
                    _newPosition = value;
                  });
                },
                items: ['Student', 'Worker', 'Lecturer']
                    .map((position) => DropdownMenuItem<String>(
                  value: position,
                  child: Text(position),
                ))
                    .toList(),
                decoration: InputDecoration(labelText: 'Position'),
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(); // Close the dialog
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                final introduction = _newIntroduction;
                final position = _newPosition;
                final away = _newAwayMode;

                // Check if the project name and description are not empty
                if (introduction!.isEmpty) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Introduction cannot be empty.'),
                    ),
                  );
                  return;
                }

                // Get the current user's UID
                final String userUid = FirebaseAuth.instance.currentUser!.uid;

                final Map<String, dynamic> profileData = {
                  'introduction': introduction,
                  'position': position,
                  'awaymode': away,
                };

                try{
                  await FirebaseFirestore.instance
                      .collection('users')
                      .doc(userUid)
                      .set(profileData);


                  Navigator.of(context).pop();

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Project saved successfully.'),
                    ), // Close the dialog

                  );

                }catch(e){
                  print('Data save error: $e');
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Data save failed. Please try again.'),
                    ),
                  );
                }
              } ,
              child: Text('Save'),
            ),
          ],
        );
      },
    );
  }



}


