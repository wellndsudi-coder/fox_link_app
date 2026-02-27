import 'package:cloud_firestore/cloud_firestore.dart';
import '../../injection/injection.dart';
import '../session/tenant_session.dart';
import '../../../../core/firestore/tenant_firestore.dart';

class TenantFirestore {
  static CollectionReference<Map<String, dynamic>> collection(
      String collectionName,
      ) {
    final session = getIt<TenantSession>();

    if (session.tenantId == null) {
      throw Exception('Tenant não definido na sessão.');
    }

    return FirebaseFirestore.instance
        .collection('tenants')
        .doc(session.tenantId)
        .collection(collectionName);
  }
}