import 'package:fox_link_app/core/database/tenant_firestore.dart';

import '../../domain/entities/service_category.dart';

abstract class ServiceCategoryRemoteDataSource {
  Future<List<ServiceCategory>> getAll(String tenantId);
  Future<void> create(ServiceCategory category);
  Future<void> update(ServiceCategory category);
  Future<void> delete(String id, String tenantId);
}

class ServiceCategoryRemoteDataSourceImpl
    implements ServiceCategoryRemoteDataSource {
  final TenantFirestore firestore;

  ServiceCategoryRemoteDataSourceImpl(this.firestore);

  @override
  Future<List<ServiceCategory>> getAll(String tenantId) async {
    final snapshot = await firestore.collection('service_categories').get();
    return snapshot.docs
        .map((doc) => ServiceCategory(
              id: doc.id,
              tenantId: doc.data()['tenantId'] as String? ?? tenantId,
              name: doc.data()['name'] as String? ?? '',
            ))
        .toList();
  }

  @override
  Future<void> create(ServiceCategory category) async {
    await firestore.collection('service_categories').doc(category.id).set({
      'tenantId': category.tenantId,
      'name': category.name,
    });
  }

  @override
  Future<void> update(ServiceCategory category) async {
    await firestore
        .collection('service_categories')
        .doc(category.id)
        .update({'name': category.name});
  }

  @override
  Future<void> delete(String id, String tenantId) async {
    await firestore.collection('service_categories').doc(id).delete();
  }
}
