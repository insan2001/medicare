import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:medicare_app/constants.dart';
import 'package:medicare_app/functions/localNotifications.dart';
import 'package:medicare_app/functions/send.dart';

final CollectionReference patients = FirebaseFirestore.instance.collection(
  reminders,
);

void acceptRequest(String patientName, String date, int id, String docId) {
  String currentName =
      FirebaseAuth.instance.currentUser!.displayName ?? 'Unknown';
  FCMService().sendTopicMessage(
    topics[0],
    'Request accepted',
    '$currentName has accepted $patientName',
    docId,
  );
  DateTime convertedDate = DateTime.parse(date);

  NotificationService.scheduleNotification(
    id,
    "Patient waiting",
    'You have to visit the $patientName',
    convertedDate,
    docId,
  );

  patients.doc(docId).update({
    status: true,
    nurse: currentName,
    nurseId: FirebaseAuth.instance.currentUser!.uid,
  });
}

void createRequest(String patientName, String date, String docId) {
  String currentName =
      FirebaseAuth.instance.currentUser!.displayName ?? 'Unknown';
  FCMService().sendTopicMessage(
    topics[1],
    'New request from $currentName',
    '$currentName requested to attend $patientName',
    docId,
  );
}

Future<void> deleteRequest(String docId) async {
  await FirebaseFirestore.instance.collection(reminders).doc(docId).delete();
}
