import 'package:cloud_firestore/cloud_firestore.dart';

class DecryptedDocumentSnapshot {
  final String id;
  final Map<String, dynamic> data;

  DecryptedDocumentSnapshot(this.id, this.data);

  String get documentID => id;

  Map<String, dynamic> get dataMap => data;
}
