import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:medicare_app/constants.dart';

class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen({super.key});

  @override
  _UserProfileScreenState createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isLoading = true;
  Map<String, dynamic>? _userData;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  void _loadUserData() async {
    User? user = _auth.currentUser;
    if (user != null) {
      DocumentSnapshot userDoc =
          await _firestore.collection(users).doc(user.uid).get();

      if (userDoc.exists) {
        setState(() {
          _userData = userDoc.data() as Map<String, dynamic>;
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _updateUserData(String field, String newValue) async {
    User? user = _auth.currentUser;
    if (user != null) {
      if (field == userName) {
        FirebaseAuth.instance.currentUser!.updateDisplayName(newValue);
      }
      await _firestore.collection(users).doc(user.uid).update({
        field: newValue,
      });
      setState(() {
        _userData?[field] = newValue;
      });
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
                    SizedBox(height: 20),

                    _buildUserInfoTile(
                      "Name",
                      _userData?[userName] ?? "",
                      userName,
                    ),
                    _buildUserInfoTile("Email", _userData?[email] ?? "", email),
                    _buildUserInfoTile(
                      "Contact",
                      _userData?[phone] ?? "",
                      phone,
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
