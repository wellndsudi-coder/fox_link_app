import 'package:cloud_firestore/cloud_firestore.dart';

class InviteRemoteDataSource {

  final FirebaseFirestore firestore;

  InviteRemoteDataSource(this.firestore);

  Future<Map<String, dynamic>?> getInvite(String email) async {
    final doc = await firestore
        .collection('users_pending')
        .doc(email)
        .get();

    if (!doc.exists) return null;

    return doc.data();
  }

  Future<void> deleteInvite(String email) async {
    await firestore
        .collection('users_pending')
        .doc(email)
        .delete();
  }
}