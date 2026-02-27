import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import 'package:fox_link_app/injection/injection.dart';

import '../../domain/entities/service.dart';
import '../../domain/usecases/create_service.dart';
import '../../domain/usecases/update_service.dart';
import '../../domain/usecases/get_services.dart';
import '../../domain/usecases/toggle_service_active.dart';
import '../../domain/usecases/delete_service.dart';

import '../../domain/value_objects/service_name.dart';
import '../../domain/value_objects/money.dart';
import '../../domain/value_objects/service_duration.dart';

import '../../../../core/session/tenant_session.dart';

class ServiceController extends ChangeNotifier {

  final CreateService _createService = getIt<CreateService>();
  final UpdateService _updateService = getIt<UpdateService>();
  final GetServices _getServices = getIt<GetServices>();
  final ToggleServiceActive _toggleService =
  getIt<ToggleServiceActive>();
  final DeleteService _deleteService =
  getIt<DeleteService>();

  final TenantSession _session = getIt<TenantSession>();

  List<Service> services = [];

  bool isLoading = false;
  String? error;

  /// 🔄 Buscar todos os serviços
  Future<void> loadServices() async {
    try {
      isLoading = true;
      error = null;
      notifyListeners();

      services =
      await _getServices(_session.tenantId!);

    } catch (e) {
      error = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  /// ➕ Criar serviço
  Future<void> create({
    required String name,
    required double price,
    required int duration,
    required bool allowChangePrice,
    required bool allowChangeDuration,
  }) async {
    try {
      isLoading = true;
      error = null;
      notifyListeners();

      final service = Service(
        id: const Uuid().v4(),
        tenantId: _session.tenantId!,
        name: ServiceName(name),
        basePrice: Money(price),
        baseDuration: ServiceDuration(duration),
        allowProfessionalChangePrice: allowChangePrice,
        allowProfessionalChangeDuration:
        allowChangeDuration,
        isActive: true,
      );

      await _createService(service);

      await loadServices();

    } catch (e) {
      error = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  /// ✏ Atualizar serviço
  Future<void> update(Service service) async {
    try {
      isLoading = true;
      error = null;
      notifyListeners();

      await _updateService(service);

      await loadServices();

    } catch (e) {
      error = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  /// 🔁 Ativar / Desativar
  Future<void> toggle(Service service) async {
    try {
      await _toggleService(
        serviceId: service.id,
        tenantId: service.tenantId,
        isActive: !service.isActive,
      );

      await loadServices();

    } catch (e) {
      error = e.toString();
      notifyListeners();
    }
  }

  /// 🗑 Excluir serviço
  Future<void> delete(Service service) async {
    try {
      await _deleteService(
        serviceId: service.id,
        tenantId: service.tenantId,
      );

      await loadServices();

    } catch (e) {
      error = e.toString();
      notifyListeners();
    }
  }
}