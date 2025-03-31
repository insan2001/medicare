import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:medicare_app/constants.dart';
import 'package:medicare_app/functions/request.dart';
import 'package:medicare_app/screens/details.dart';
import 'package:medicare_app/screens/login.dart';
import 'package:medicare_app/screens/profile.dart';
import 'package:medicare_app/screens/reminder.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final CollectionReference patients = FirebaseFirestore.instance.collection(
    reminders,
  );
  final String currentUserId = FirebaseAuth.instance.currentUser!.uid;
  TextEditingController remarksController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Patient Requests"),
        actions: [
          IconButton(
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (context) => LoginScreen()));
            },
            icon: Icon(Icons.logout),
          ),
        ],
        leading: IconButton(
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => UserProfileScreen()),
            );
          },
          icon: Icon(Icons.person, color: Colors.blue),
        ),
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
              if (!snapshot.hasData) {
                return Center(child: CircularProgressIndicator());
              }

              final pendingPatients =
                  snapshot.data!.docs.where((doc) {
                    return doc[status] == false;
                  }).toList();

              pendingPatients.sort(
                (a, b) =>
                    DateTime.parse(a[date]).compareTo(DateTime.parse(b[date])),
              );

              return ListView.builder(
                itemCount: pendingPatients.length,
                itemBuilder: (context, index) {
                  var doc = pendingPatients[index];

                  return Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: ListTile(
                      title: Text(doc[patientName]),
                      subtitle: Text(
                        "Time: ${DateTime.parse(doc[date]).toString()}",
                      ),
                      onTap:
                          () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder:
                                  (context) => DetailsScreen(docId: doc.id),
                            ),
                          ),
                      trailing: ElevatedButton(
                        onPressed:
                            () => acceptRequest(
                              doc[patientName],
                              doc[date],
                              doc[id],
                              doc.id,
                            ),
                        child: Text("Accept"),
                      ),
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
              if (!snapshot.hasData) {
                return Center(child: CircularProgressIndicator());
              }

              final historyPatients =
                  snapshot.data!.docs.where((doc) {
                    return (doc[status] == true);
                  }).toList();

              historyPatients.sort(
                (a, b) =>
                    DateTime.parse(a[date]).compareTo(DateTime.parse(b[date])),
              );

              return ListView.builder(
                itemCount: historyPatients.length,
                itemBuilder: (context, index) {
                  var doc = historyPatients[index];
                  return Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: ListTile(
                      title: Text(doc[patientName]),
                      subtitle: Text("Taken by: ${doc[nurse]}"),
                      onTap:
                          () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder:
                                  (context) => DetailsScreen(docId: doc.id),
                            ),
                          ),
                      shape: RoundedRectangleBorder(
                        side: BorderSide(
                          width: 1,
                          color:
                              doc[nurseId] == currentUserId
                                  ? Colors.blue
                                  : Colors.red,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
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
