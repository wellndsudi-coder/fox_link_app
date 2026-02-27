import 'package:fox_link_app/modules/auth/domain/entities/invite_entity.dart';

abstract class InviteRepository {
  Future<InviteEntity?> getInviteByEmail(String email);
  Future<void> deleteInvite(String email);
}