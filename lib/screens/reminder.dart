import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:medicare_app/constants.dart';
import 'package:medicare_app/functions/request.dart';
import 'package:uuid/uuid.dart';

class AddReminderScreen extends StatefulWidget {
  const AddReminderScreen({super.key});

  @override
  _AddReminderScreenState createState() => _AddReminderScreenState();
}

class _AddReminderScreenState extends State<AddReminderScreen> {
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  final TextEditingController _patientNameController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  // Function to pick a date
  Future<void> _pickDate(BuildContext context) async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(), // Prevents selecting past dates
      lastDate: DateTime(2101),
    );

    if (pickedDate != null) {
      setState(() {
        _selectedDate = pickedDate;
      });
    }
  }

  // Function to pick a time
  Future<void> _pickTime(BuildContext context) async {
    TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (pickedTime != null) {
      setState(() {
        _selectedTime = pickedTime;
      });
    }
  }

  // Function to save medication data
  void _saveMedication() async {
    if (_selectedDate != null &&
        _selectedTime != null &&
        _patientNameController.text.isNotEmpty &&
        _notesController.text.isNotEmpty) {
      DateTime formatedDate = DateTime(
        _selectedDate!.year,
        _selectedDate!.month,
        _selectedDate!.day,
        _selectedTime!.hour,
        _selectedTime!.minute,
      );

      final doc = await FirebaseFirestore.instance.collection(reminders).add({
        patientName: _patientNameController.text,
        notes: _notesController.text,
        date: formatedDate.toIso8601String(),
        status: false,
        nurse: '',
        remarks: '',
        nurseId: FirebaseAuth.instance.currentUser?.uid,
        statusOptions: 3,
        id: Uuid().v4().hashCode.abs(),
      });

      Navigator.pop(context);
      createRequest(_patientNameController.text, date, doc.id);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Medication Scheduled for ${_patientNameController.text}!",
          ),
        ),
      );

      // Clear fields after saving
      _patientNameController.clear();
      _notesController.clear();
      setState(() {
        _selectedDate = null;
        _selectedTime = null;
      });
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Please fill all fields!")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Add Medication")),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Patient Name Input
            TextField(
              controller: _patientNameController,
              decoration: InputDecoration(labelText: "Patient Name"),
            ),
            SizedBox(height: 10),

            // Date Picker
            Text(
              "Select Date:",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Row(
              children: [
                Text(
                  _selectedDate == null
                      ? "No date chosen!"
                      : "${_selectedDate!.toLocal()}".split(' ')[0],
                  style: TextStyle(fontSize: 16),
                ),
                IconButton(
                  icon: Icon(Icons.calendar_today),
                  onPressed: () => _pickDate(context),
                ),
              ],
            ),
            SizedBox(height: 10),

            // Time Picker
            Text(
              "Select Time:",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Row(
              children: [
                Text(
                  _selectedTime == null
                      ? "No time chosen!"
                      : _selectedTime!.format(context),
                  style: TextStyle(fontSize: 16),
                ),
                IconButton(
                  icon: Icon(Icons.access_time),
                  onPressed: () => _pickTime(context),
                ),
              ],
            ),
            SizedBox(height: 10),

            // Notes Input
            TextField(
              controller: _notesController,
              decoration: InputDecoration(
                labelText: "Notes (Medication Details)",
              ),
              maxLines: 3,
            ),
            SizedBox(height: 20),

            // Save Button
            Center(
              child: ElevatedButton(
                onPressed: _saveMedication,
                child: Text("Save Medication"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
