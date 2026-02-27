import 'package:cloud_firestore/cloud_firestore.dart';
import '../session/tenant_session.dart';

class TenantFirestore {
  final FirebaseFirestore firestore;
  final TenantSession session;

  TenantFirestore(this.firestore, this.session);

  CollectionReference<Map<String, dynamic>> collection(
      String name,
      ) {
    final tenantId = session.tenantId;
    if (tenantId == null || tenantId.isEmpty) {
      throw Exception('Tenant ID não definido. Verifique se o usuário está autenticado e a sessão inicializada.');
    }

    return firestore
        .collection('tenants')
        .doc(tenantId)
        .collection(name);
  }
}