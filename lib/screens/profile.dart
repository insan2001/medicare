import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'package:medicare_app/constants.dart';
// web_code.dart
import 'dart:html' as html;

class UserProfileScreen extends StatefulWidget {
  @override
  _UserProfileScreenState createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  bool _isLoading = true;
  Map<String, dynamic>? _userData;
  String? _profilePicUrl;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  void _loadUserData() async {
    User? user = _auth.currentUser;
    if (user != null) {
      DocumentSnapshot userDoc =
          await _firestore.collection('users').doc(user.uid).get();

      if (userDoc.exists) {
        setState(() {
          _userData = userDoc.data() as Map<String, dynamic>;
          _profilePicUrl = _userData?['profilePic'] ?? "";
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _updateUserData(String field, String newValue) async {
    User? user = _auth.currentUser;
    if (user != null) {
      await _firestore.collection('users').doc(user.uid).update({
        field: newValue,
      });
      setState(() {
        _userData?[field] = newValue;
      });
      print("Updated info : $field , $newValue");
    }
  }

  Future<void> uploadProfilePicture() async {
    try {
      XFile? pickedFile;
      late final String url;
      if (kIsWeb) {
        // Web: Use HTML input to pick file
        html.FileUploadInputElement uploadInput = html.FileUploadInputElement();
        uploadInput.accept = 'image/*';
        uploadInput.click();

        await uploadInput.onChange.first;
        final file = uploadInput.files?.first;
        if (file == null) return null;

        final reader = html.FileReader();
        reader.readAsArrayBuffer(file);
        await reader.onLoad.first;
        Uint8List fileBytes = reader.result as Uint8List;

        // Upload to Firebase Storage
        Reference ref = _storage.ref().child(
          "profile_pics/${_auth.currentUser?.uid}.jpg",
        );
        UploadTask uploadTask = ref.putData(fileBytes);
        TaskSnapshot snapshot = await uploadTask;
        url = await snapshot.ref.getDownloadURL();
      } else {
        // Mobile: Use Image Picker
        pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
        if (pickedFile == null) return null;

        Reference ref = FirebaseStorage.instance.ref().child(
          "profile/${_auth.currentUser?.uid}.jpg",
        );
        UploadTask uploadTask = ref.putFile(File(pickedFile.path));
        TaskSnapshot snapshot = await uploadTask;
        url = await snapshot.ref.getDownloadURL();
      }
      _updateUserData(profilePic, url);
    } catch (e) {
      print("Error uploading profile picture: $e");
      return null;
    }
  }

  void _showEditPopup(String field, String currentValue) {
    TextEditingController controller = TextEditingController(
      text: currentValue,
    );

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text("Edit $field"),
            content: TextField(
              controller: controller,
              decoration: InputDecoration(labelText: "Enter new $field"),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text("Cancel"),
              ),
              TextButton(
                onPressed: () {
                  _updateUserData(field, controller.text.trim());
                  Navigator.pop(context);
                },
                child: Text("Save"),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("User Profile")),
      body:
          _isLoading
              ? Center(child: CircularProgressIndicator())
              : Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Stack(
                      children: [
                        CircleAvatar(
                          radius: 50,
                          backgroundImage:
                              _profilePicUrl != null &&
                                      _profilePicUrl!.isNotEmpty
                                  ? NetworkImage(_profilePicUrl!)
                                  : AssetImage("assets/profile.jpg")
                                      as ImageProvider,
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: GestureDetector(
                            onTap: () => uploadProfilePicture(),
                            child: Container(
                              decoration: BoxDecoration(
                                color:
                                    Colors
                                        .blue, // Background color of edit icon
                                shape: BoxShape.circle,
                              ),
                              padding: EdgeInsets.all(6),
                              child: Icon(
                                Icons.edit,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 20),

                    _buildUserInfoTile(
                      "Name",
                      _userData?['name'] ?? "",
                      "name",
                    ),
                    _buildUserInfoTile(
                      "Email",
                      _userData?['email'] ?? "",
                      "email",
                    ),
                    _buildUserInfoTile(
                      "Contact",
                      _userData?['contact'] ?? "",
                      "contact",
                    ),
                  ],
                ),
              ),
    );
  }

  Widget _buildUserInfoTile(String label, String value, String field) {
    return ListTile(
      title: Text(label),
      subtitle: Text(value),
      trailing: IconButton(
        icon: Icon(Icons.edit),
        onPressed: () => _showEditPopup(field, value),
      ),
    );
  }
}
