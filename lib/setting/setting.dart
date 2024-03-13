import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../constant/style.dart';
import 'firebase_setting_page.dart';
import 'package:image_picker/image_picker.dart';

class SettingPage extends StatefulWidget {
  const SettingPage({Key? key}) : super(key: key);

  @override
  _SettingPageState createState() => _SettingPageState();
}

class _SettingPageState extends State<SettingPage> {
  User? _user;
  String? _avatarURL;

  @override
  void initState() {
    super.initState();
    getUserProfile();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Center(
          child: Column(
            children: [
              const SizedBox(height: 50),
              Container(
                child: GestureDetector(
                  onTap: () {},
                  child: Card(
                    color: Colors.transparent,
                    child: Container(
                      decoration: CustomCardDecoration.cardDecoration,
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                        CircleAvatar(
                        radius: 50,
                        backgroundImage: _avatarURL != null
                            ? NetworkImage(_avatarURL!)
                            : _user?.photoURL != null
                            ? NetworkImage(_user!.photoURL!)
                            : AssetImage('assets/default_avatar.png') as ImageProvider,
                      ),
                          const SizedBox(height: 20),
                          Text(
                            _user?.displayName ?? '',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            _user?.email ?? '',
                            style:
                                TextStyle(fontSize: 18, color: Colors.grey[300]),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ), // Profile

              const SizedBox(height: 20),
              Container(
                child: GestureDetector(
                  onTap: () {
                    changeUsername();
                  },
                  child: Card(
                    color: Colors.blue[500],
                    child: Container(
                      decoration: CustomCardDecoration.cardDecoration,
                      padding: const EdgeInsets.all(16.0),
                      child: const Row(
                        children: [
                          Icon(Icons.drive_file_rename_outline,
                              color: Colors.white),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Change username',
                              style: TextStyle(fontSize: 20, color: Colors.white),
                            ),
                          ),
                          Icon(Icons.arrow_forward_ios, color: Colors.white),
                        ],
                      ),
                    ),
                  ),
                ),
              ), // Change username

              const SizedBox(height: 20),
              Container(
                child: GestureDetector(
                  onTap: () {
                    changeAvatar();
                  },
                  child: Card(
                    color: Colors.blue[500],
                    child: Container(
                      decoration: CustomCardDecoration.cardDecoration,
                      padding: const EdgeInsets.all(16.0),
                      child: const Row(
                        children: [
                          Icon(Icons.image, color: Colors.white),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Change avatar',
                              style: TextStyle(fontSize: 20, color: Colors.white),
                            ),
                          ),
                          Icon(Icons.arrow_forward_ios, color: Colors.white),
                        ],
                      ),
                    ),
                  ),
                ),
              ), // Change avatar

              const SizedBox(height: 20),
              Container(
                child: GestureDetector(
                  onTap: () {
                    changePassword();
                  },
                  child: Card(
                    color: Colors.blue[500],
                    child: Container(
                      decoration: CustomCardDecoration.cardDecoration,
                      padding: const EdgeInsets.all(16.0),
                      child: const Row(
                        children: [
                          Icon(Icons.lock, color: Colors.white),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Change password',
                              style: TextStyle(fontSize: 20, color: Colors.white),
                            ),
                          ),
                          Icon(Icons.arrow_forward_ios, color: Colors.white),
                        ],
                      ),
                    ),
                  ),
                ),
              ), // Change password
            ],
          ),
        ),
      ),
      floatingActionButton: Container(
        margin: const EdgeInsets.only(bottom: 50),
        child: FloatingActionButton(
          backgroundColor: Colors.blue,
          onPressed: () {
            logout();
          },
          child: const Icon(
            Icons.logout,
            color: Colors.white,
            size: 30,
          ),
        ),
      ),
    );
  }

  Future<void> getUserProfile() async {
    FirebaseAuth auth = FirebaseAuth.instance;
    User? user = auth.currentUser;
    if (user != null) {
      FirebaseFirestore firestore = FirebaseFirestore.instance;
      DocumentSnapshot userSnapshot = await firestore.collection('users').doc(user.uid).get();
      setState(() {
        _user = user;
        Map<String, dynamic>? userData = userSnapshot.data() as Map<String, dynamic>?;
        _avatarURL = userData?['avatarURL']; // Retrieve avatar URL from Firestore
      });
    }
  }

  Future<String?> _showUsernameInputDialog() async {
    TextEditingController _usernameController = TextEditingController();

    return showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Enter New Username'),
          content: TextField(
            controller: _usernameController,
            onChanged: (value) {},
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(null);
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(_usernameController.text);
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void changeUsername() async {
    String? newUsername = await _showUsernameInputDialog();

    if (newUsername != null && newUsername.isNotEmpty) {
      try {
        await FirebaseAuth.instance.currentUser!.updateDisplayName(newUsername);
        await FirebaseFirestore.instance
            .collection('users')
            .doc(FirebaseAuth.instance.currentUser?.uid)
            .update({'displayName': newUsername});
        await getUserProfile();
        showToast("Username updated successfully.");
      } catch (e) {
        print("Error updating username: $e");
        showToast("Error updating username: $e");
      }
    } else {
      showToast("Error: Invalid username or canceled");
    }
  }

  void changeAvatar() async {
    try {
      final ImagePicker _picker = ImagePicker();
      final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);

      if (pickedFile != null) {
        String imagePath = pickedFile.path;

        String newAvatarURL = await updateAvatar(_user!, imagePath);
        showToast('Avatar updated successfully.');

        setState(() {
          _avatarURL = newAvatarURL;
        });
      } else {
        showToast('No image selected.');
      }
    } catch (e) {
      print('Error changing avatar: $e');
      showToast('Error changing avatar: $e');
    }
  }

  Future<String?> _showPasswordInputDialog() async {
    TextEditingController _passwordController = TextEditingController();

    return showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Enter New Password'),
          content: TextField(
            controller: _passwordController,
            onChanged: (value) {},
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(null);
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(_passwordController.text);
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void changePassword() async {
    String? newPassword = await _showPasswordInputDialog();
    if (newPassword != null && newPassword.isNotEmpty) {
      try {
        await FirebaseAuth.instance.currentUser!.updatePassword(newPassword);
        showToast("Password updated successfully.");
      } catch (e) {
        showToast("Error updating password: $e");
      }
    } else {
      showToast("Error: Invalid password or canceled");
    }
  }

  void logout() async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
  }

  void showToast(String message) {
    Fluttertoast.showToast(
        msg: message,
    );
  }
}
