import 'package:fox_link_app/core/database/tenant_firestore.dart';
import '../../domain/entities/manual_block.dart';
import '../../domain/repositories/manual_block_repository.dart';
import '../models/manual_block_model.dart';

class ManualBlockRepositoryImpl implements ManualBlockRepository {
  final TenantFirestore firestore;

  ManualBlockRepositoryImpl(this.firestore);

  @override
  Future<void> save(ManualBlock block) async {
    final model = ManualBlockModel.fromEntity(block);
    await firestore
        .collection('manual_blocks')
        .doc(model.id)
        .set(model.toMap());
  }

  @override
  Future<void> delete(String blockId) async {
    await firestore.collection('manual_blocks').doc(blockId).delete();
  }

  @override
  Future<List<ManualBlock>> getByProfessionalAndPeriod({
    required String professionalId,
    required DateTime start,
    required DateTime end,
  }) async {
    final snapshot = await firestore
        .collection('manual_blocks')
        .where('professionalId', isEqualTo: professionalId)
        .where('start', isGreaterThanOrEqualTo: start)
        .where('start', isLessThan: end)
        .get();

    return snapshot.docs
        .map((doc) => ManualBlockModel.fromMap(doc.data(), doc.id))
        .toList();
  }
}
