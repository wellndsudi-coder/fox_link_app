import 'package:cloud_firestore/cloud_firestore.dart';
import '../session/tenant_session.dart';

class TenantFirestore {
  final FirebaseFirestore firestore;
  final TenantSession session;

  TenantFirestore(this.firestore, this.session);

  CollectionReference<Map<String, dynamic>> collection(
      String name,
      ) {
    return firestore
        .collection('tenants')
        .doc(session.tenantId)
        .collection(name);
  }
}