import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:medicare_app/constants.dart';
import 'package:medicare_app/functions/localNotifications.dart';
import 'package:medicare_app/functions/send.dart';
import 'package:medicare_app/screens/reminder.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final CollectionReference patients = FirebaseFirestore.instance.collection(
    'reminders',
  );
  final String currentUserId = FirebaseAuth.instance.currentUser!.uid;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  void acceptRequest(String patientId, String date) {
    FCMService().sendTopicMessage(
      topics[0],
      'Request accepted',
      '${currentUserId} has accepted ${patientId}',
    );
    DateTime _date = DateTime.parse(date);

    LocalNotificationService.scheduleNotification(
      1,
      "Patient waiting",
      'You have to visit the ${patientId}',
      _date,
    );

    patients.doc(patientId).update({status: true, nurse: currentUserId});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Patient Requests"),
        bottom: TabBar(
          controller: _tabController,
          tabs: [Tab(text: "Pending"), Tab(text: "Accepted")],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Pending Patients Tab
          StreamBuilder(
            stream: patients.snapshots(),
            builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
              if (!snapshot.hasData)
                return Center(child: CircularProgressIndicator());

              final pendingPatients =
                  snapshot.data!.docs
                      .where((doc) => doc[status] == false)
                      .toList();

              return ListView.builder(
                itemCount: pendingPatients.length,
                itemBuilder: (context, index) {
                  var doc = pendingPatients[index];
                  return ListTile(
                    title: Text(doc[name]),
                    subtitle: Text("Medication: ${doc[notes]}"),
                    trailing: ElevatedButton(
                      onPressed: () => acceptRequest(doc.id, doc[date]),
                      child: Text("Accept"),
                    ),
                  );
                },
              );
            },
          ),

          // History Tab
          StreamBuilder(
            stream: patients.snapshots(),
            builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
              if (!snapshot.hasData)
                return Center(child: CircularProgressIndicator());

              final historyPatients =
                  snapshot.data!.docs
                      .where((doc) => doc[status] == true)
                      .toList();

              return ListView.builder(
                itemCount: historyPatients.length,
                itemBuilder: (context, index) {
                  var doc = historyPatients[index];
                  return ListTile(
                    title: Text(doc[name]),
                    subtitle: Text("Taken by: ${doc[nurse]}"),
                  );
                },
              );
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (context) => AddReminderScreen()));
        },
        child: Icon(Icons.add),
      ),
    );
  }
}
