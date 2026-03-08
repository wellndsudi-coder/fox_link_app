import 'package:flutter/foundation.dart';

import '../../../services/domain/entities/service.dart';

/// Controller for premium scheduling UI.
/// Manages base service, add-ons, professional, date, time and loading state.
class ScheduleController extends ChangeNotifier {
  Service? _baseService;
  final List<Service> _selectedAddons = [];
  String? _selectedProfessionalId;
  String? _selectedProfessionalName;
  DateTime? _selectedDate;
  DateTime? _selectedTime;
  List<DateTime> _availableSlots = [];
  bool _loadingSlots = false;
  bool _submitting = false;

  Service? get baseService => _baseService;
  List<Service> get selectedAddons => List.unmodifiable(_selectedAddons);
  List<Service> get selectedServices {
    if (_baseService == null) return [];
    return [_baseService!, ..._selectedAddons];
  }
  String? get selectedProfessionalId => _selectedProfessionalId;
  String? get selectedProfessionalName => _selectedProfessionalName;
  DateTime? get selectedDate => _selectedDate;
  DateTime? get selectedTime => _selectedTime;
  List<DateTime> get availableSlots => List.unmodifiable(_availableSlots);
  bool get loadingSlots => _loadingSlots;
  bool get submitting => _submitting;

  int get totalDurationMinutes =>
      selectedServices.fold(0, (sum, s) => sum + s.baseDuration.minutes);
  double get totalPrice =>
      selectedServices.fold(0.0, (sum, s) => sum + s.basePrice.value);

  bool get canContinue =>
      _selectedProfessionalId != null && _baseService != null;

  bool get canConfirm =>
      _baseService != null &&
      _selectedProfessionalId != null &&
      _selectedDate != null &&
      _selectedTime != null;

  void setBaseService(Service? service) {
    if (_baseService?.id == service?.id) return;
    _baseService = service;
    _selectedAddons.clear();
    _selectedTime = null;
    _availableSlots = [];
    notifyListeners();
  }

  void toggleAddon(Service addon) {
    final idx = _selectedAddons.indexWhere((s) => s.id == addon.id);
    if (idx >= 0) {
      _selectedAddons.removeAt(idx);
    } else {
      _selectedAddons.add(addon);
    }
    _selectedTime = null;
    _availableSlots = [];
    notifyListeners();
  }

  void toggleService(Service service) {
    if (service.isBase) {
      setBaseService(service);
    } else {
      toggleAddon(service);
    }
  }

  void setSelectedServices(List<Service> value) {
    final base = value.where((s) => s.isBase).firstOrNull;
    final addons = value.where((s) => !s.isBase).toList();
    _baseService = base;
    _selectedAddons.clear();
    _selectedAddons.addAll(addons);
    _selectedTime = null;
    _availableSlots = [];
    notifyListeners();
  }

  void setSelectedProfessional(String? id, String? name) {
    if (_selectedProfessionalId == id) return;
    _selectedProfessionalId = id;
    _selectedProfessionalName = name;
    _selectedTime = null;
    _availableSlots = [];
    notifyListeners();
  }

  void setSelectedDate(DateTime? value) {
    if (_selectedDate == value) return;
    _selectedDate = value;
    _selectedTime = null;
    _availableSlots = [];
    notifyListeners();
  }

  void setSelectedTime(DateTime? value) {
    if (_selectedTime == value) return;
    _selectedTime = value;
    notifyListeners();
  }

  void setAvailableSlots(List<DateTime> slots) {
    _availableSlots = List.from(slots);
    _selectedTime = null;
    notifyListeners();
  }

  void setLoadingSlots(bool value) {
    if (_loadingSlots == value) return;
    _loadingSlots = value;
    notifyListeners();
  }

  void setSubmitting(bool value) {
    if (_submitting == value) return;
    _submitting = value;
    notifyListeners();
  }

  void clearTimeSelection() {
    _selectedTime = null;
    notifyListeners();
  }
}
