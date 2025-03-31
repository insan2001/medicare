import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:medicare_app/constants.dart';
import 'package:medicare_app/functions/request.dart';

class DetailsScreen extends StatefulWidget {
  final String docId;

  const DetailsScreen({super.key, required this.docId});

  @override
  _DetailsScreenState createState() => _DetailsScreenState();
}

class _DetailsScreenState extends State<DetailsScreen> {
  String? selectedStatus;
  final List<String> statuses = [
    "Completed",
    "Requires Follow-up",
    "Not Attended",
    "Not Set",
  ];

  final TextEditingController _noteController = TextEditingController();

  void submitStatus() async {
    if (selectedStatus != null) {
      await FirebaseFirestore.instance
          .collection(reminders)
          .doc(widget.docId)
          .update({
            statusOptions: statuses.indexOf(selectedStatus!),
            remarks: _noteController.text.trim(),
          });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("✅ Details updated successfully!")),
      );

      Navigator.canPop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blueGrey[50], // Light background
      appBar: AppBar(
        title: Text("Request Details"),
        backgroundColor: Colors.blueAccent,
        elevation: 5,
      ),
      body: FutureBuilder(
        future:
            FirebaseFirestore.instance
                .collection(reminders)
                .doc(widget.docId)
                .get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          Map<String, dynamic>? data = snapshot.data!.data();
          _noteController.text = data![notes];
          selectedStatus = statuses[data[statusOptions]];
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Card(
              elevation: 5,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Icon(
                        data[status] ? Icons.history : Icons.pending_actions,
                        color: data[status] ? Colors.green : Colors.orange,
                        size: 50,
                      ),
                    ),
                    SizedBox(height: 10),
                    Center(
                      child: Text(
                        data[status] ? "Past Request" : "Pending Request",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Divider(),
                    SizedBox(height: 10),
                    _buildInfoRow("👤 Patient", data[patientName]),
                    _buildInfoRow("📌 Medications", data[notes]),
                    _buildInfoRow(
                      "⏰ Date & Time",
                      DateTime.parse(data[date]).toString(),
                    ),
                    _buildInfoRow(
                      "Nurse",
                      data[status] == false ? "Not accepted" : data[nurse],
                    ),

                    // Show dropdown only for history tab
                    if (data[status] &&
                        data[nurseId] ==
                            FirebaseAuth.instance.currentUser!.uid) ...[
                      Text(
                        "📝 Select Status:",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      DropdownButton<String>(
                        value: selectedStatus,
                        isExpanded: true,
                        items:
                            statuses.map((String status) {
                              return DropdownMenuItem<String>(
                                value: status,
                                child: Text(status),
                              );
                            }).toList(),
                        onChanged: (value) {
                          setState(() {
                            selectedStatus = value;
                          });
                        },
                      ),
                      SizedBox(height: 20),
                      data[nurseId] == FirebaseAuth.instance.currentUser!.uid
                          ? TextField(
                            controller: _noteController,
                            decoration: InputDecoration(
                              hintText: "Enter your note here...",
                              border: OutlineInputBorder(),
                            ),
                            maxLines: 3,
                          )
                          : Text(data[remarks]),
                      SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: submitStatus,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueAccent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: Text("Submit", style: TextStyle(fontSize: 16)),
                      ),
                    ],
                    if (data[status] &&
                        data[nurseId] !=
                            FirebaseAuth.instance.currentUser!.uid) ...[
                      _buildInfoRow("Status", statuses[data[statusOptions]]),
                      _buildInfoRow("Notes", data[notes]),
                    ],

                    if (!data[status] &&
                        data[nurseId] !=
                            FirebaseAuth.instance.currentUser!.uid) ...[
                      Center(
                        child: ElevatedButton(
                          onPressed: () {
                            acceptRequest(
                              data[patientName],
                              data[date],
                              data[id],
                              widget.docId,
                            );

                            if (Navigator.canPop(context)) {
                              Navigator.pop(context);
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blueAccent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            padding: EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: Text("Accept", style: TextStyle(fontSize: 16)),
                        ),
                      ),
                    ],
                    if (!data[status] &&
                        data[nurseId] ==
                            FirebaseAuth.instance.currentUser!.uid) ...[
                      Center(
                        child: ElevatedButton(
                          onPressed: () async {
                            await deleteRequest(docId);
                            if (Navigator.canPop(context)) {
                              Navigator.pop(context);
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            padding: EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: Text("Delete", style: TextStyle(fontSize: 16)),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        children: [
          Text(
            title,
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              value,
              style: TextStyle(fontSize: 16, color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }
}
