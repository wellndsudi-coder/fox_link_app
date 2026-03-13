import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import 'package:fox_link_app/injection/injection.dart';

import '../../domain/entities/service.dart';
import '../../domain/entities/service_category.dart';
import '../../domain/usecases/create_service.dart';
import '../../domain/usecases/update_service.dart';
import '../../domain/usecases/get_services.dart';
import '../../domain/usecases/get_service_categories_usecase.dart';
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
  final GetServiceCategoriesUseCase _getCategories =
      getIt<GetServiceCategoriesUseCase>();

  final TenantSession _session = getIt<TenantSession>();

  List<Service> services = [];
  List<ServiceCategory> categories = [];

  bool isLoading = false;
  String? error;

  /// 🔄 Buscar categorias
  Future<void> loadCategories() async {
    try {
      final tenantId = _session.tenantId;
      if (tenantId == null) return;
      categories = await _getCategories(tenantId);
      notifyListeners();
    } catch (_) {}
  }

  /// 🔄 Buscar todos os serviços
  Future<void> loadServices() async {
    try {
      isLoading = true;
      error = null;
      notifyListeners();

      services = await _getServices(_session.tenantId!);
      await loadCategories();
    } catch (e) {
      error = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  /// ➕ Criar addon (adicional) standalone - pode ser vinculado a vários serviços depois
  Future<void> createAddon({
    required String name,
    required double price,
    required int duration,
    List<String>? linkToBaseServiceIds,
  }) async {
    final ids = linkToBaseServiceIds ?? [];
    await create(
      name: name,
      price: price,
      duration: duration,
      allowChangePrice: false,
      allowChangeDuration: false,
      parentId: null,
      isAddon: true,
      linkedBaseServiceIds: ids,
    );
  }

  /// ➕ Criar serviço
  Future<void> create({
    required String name,
    required double price,
    required int duration,
    required bool allowChangePrice,
    required bool allowChangeDuration,
    String? parentId,
    bool isAddon = false,
    List<String>? linkedBaseServiceIds,
    String? category,
    String? categoryId,
    String? description,
    int? color,
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
        parentId: parentId?.isEmpty == true ? null : parentId,
        linkedBaseServiceIds: linkedBaseServiceIds ??
            (parentId != null && parentId.isNotEmpty ? [parentId!] : []),
        isAddon: isAddon || (parentId != null && parentId.isNotEmpty),
        category: category?.isEmpty == true ? null : category,
        categoryId: categoryId?.isEmpty == true ? null : categoryId,
        description: description?.isEmpty == true ? null : description,
        color: color,
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

  /// 🔗 Desvincular addon de um serviço base (addon continua existindo)
  Future<void> unlinkAddonFromService(Service addon, String baseServiceId) async {
    final wasInLinked = addon.linkedBaseServiceIds.contains(baseServiceId);
    final wasParent = addon.parentId == baseServiceId;
    if (!wasInLinked && !wasParent) return;
    final ids = List<String>.from(addon.linkedBaseServiceIds)
      ..remove(baseServiceId);
    await update(addon.copyWith(
      parentId: wasParent ? null : addon.parentId,
      linkedBaseServiceIds: ids,
    ));
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