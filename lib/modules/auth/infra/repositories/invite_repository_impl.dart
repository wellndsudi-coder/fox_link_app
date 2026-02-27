import 'package:fox_link_app/modules/auth/domain/entities/invite_entity.dart';
import 'package:fox_link_app/modules/auth/domain/repositories/invite_repository.dart';
import 'package:fox_link_app/modules/auth/infra/datasources/invite_remote_datasource.dart';

class InviteRepositoryImpl implements InviteRepository {

  final InviteRemoteDataSource remote;

  InviteRepositoryImpl(this.remote);

  @override
  Future<InviteEntity?> getInviteByEmail(String email) async {
    final data = await remote.getInvite(email);

    if (data == null) return null;

    return InviteEntity(
      tenantId: data['tenantId'],
      role: data['role'],
      name: data['name'],
    );
  }

  @override
  Future<void> deleteInvite(String email) async {
    await remote.deleteInvite(email);
  }
}