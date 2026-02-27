import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import 'package:fox_link_app/injection/injection.dart';

import '../../domain/entities/availability.dart';
import '../../domain/usecases/save_availability.dart';
import '../../domain/usecases/get_professional_availability.dart';

class AvailabilityController extends ChangeNotifier {

  final SaveAvailability _save =
  getIt<SaveAvailability>();

  final GetProfessionalAvailability _get =
  getIt<GetProfessionalAvailability>();

  List<Availability> availabilityList = [];

  bool isLoading = false;

  Future<void> load(String professionalId) async {
    isLoading = true;
    notifyListeners();

    availabilityList =
    await _get(professionalId);

    isLoading = false;
    notifyListeners();
  }

  Future<void> save({
    required String professionalId,
    required int weekday,
    required int startMinutes,
    required int endMinutes,
    int? breakStart,
    int? breakEnd,
  }) async {

    final availability = Availability(
      id: const Uuid().v4(),
      professionalId: professionalId,
      weekday: weekday,
      startMinutes: startMinutes,
      endMinutes: endMinutes,
      breakStartMinutes: breakStart,
      breakEndMinutes: breakEnd,
    );

    await _save(availability);

    await load(professionalId);
  }
}