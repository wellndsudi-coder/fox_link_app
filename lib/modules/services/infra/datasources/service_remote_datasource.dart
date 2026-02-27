import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/firestore/tenant_firestore.dart';
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

  @override
  Future<void> create(ServiceModel model) async {
    await TenantFirestore
        .collection('services')
        .doc(model.id)
        .set(model.toMap());
  }

  @override
  Future<void> update(ServiceModel model) async {
    await TenantFirestore
        .collection('services')
        .doc(model.id)
        .update(model.toMap());
  }

  @override
  Future<List<ServiceModel>> getAll(String tenantId) async {
    final snapshot = await TenantFirestore
        .collection('services')
        .where('tenantId', isEqualTo: tenantId)
        .get();

    return snapshot.docs
        .map((doc) =>
        ServiceModel.fromMap(doc.data(), doc.id))
        .toList();
  }

  @override
  Future<void> toggleActive({
    required String serviceId,
    required bool isActive,
  }) async {
    await TenantFirestore
        .collection('services')
        .doc(serviceId)
        .update({'isActive': isActive});
  }

  @override
  Future<void> delete(String serviceId) async {
    await TenantFirestore
        .collection('services')
        .doc(serviceId)
        .delete();
  }
}