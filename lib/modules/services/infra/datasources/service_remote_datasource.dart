import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fox_link_app/core/database/tenant_firestore.dart';

import '../models/service_model.dart';

abstract class ServiceRemoteDataSource {
  Future<void> create(ServiceModel model);
  Future<void> update(ServiceModel model);
  Future<List<ServiceModel>> getAll(String tenantId);
  Future<void> toggleActive({
    required String serviceId,
    required bool isActive,
  });
  Future<void> delete(String serviceId);
}

class ServiceRemoteDataSourceImpl
    implements ServiceRemoteDataSource {

  // ✅ ALTERADO: agora usa injeção
  final TenantFirestore firestore;

  ServiceRemoteDataSourceImpl(this.firestore);

  @override
  Future<void> create(ServiceModel model) async {
    await firestore
        .collection('services') // ✅ ALTERADO
        .doc(model.id)
        .set(model.toMap());
  }

  @override
  Future<void> update(ServiceModel model) async {
    await firestore
        .collection('services') // ✅ ALTERADO
        .doc(model.id)
        .update(model.toMap());
  }

  @override
  Future<List<ServiceModel>> getAll(String tenantId) async {
    // Força leitura no servidor para evitar cache desatualizado no APK
    // quando o salão/serviços foram criados na web.
    final snapshot = await firestore
        .collection('services')
        .get(const GetOptions(source: Source.server));

    return snapshot.docs
        .map((doc) =>
        ServiceModel.fromMap(doc.data(), doc.id, tenantId))
        .toList();
  }

  @override
  Future<void> toggleActive({
    required String serviceId,
    required bool isActive,
  }) async {
    await firestore
        .collection('services') // ✅ ALTERADO
        .doc(serviceId)
        .update({'isActive': isActive});
  }

  @override
  Future<void> delete(String serviceId) async {
    await firestore
        .collection('services') // ✅ ALTERADO
        .doc(serviceId)
        .delete();
  }
}