import 'package:flutter/foundation.dart';
import '../../domain/entities/subscription_entity.dart';
import '../../domain/usecases/get_subscriptions_usecase.dart';

class SubscriptionController extends ChangeNotifier {
  final GetSubscriptionsUseCase getSubscriptions;

  SubscriptionController({required this.getSubscriptions});

  bool _loading = false;
  bool get loading => _loading;

  List<SubscriptionEntity> _subscriptions = [];
  List<SubscriptionEntity> get subscriptions => _subscriptions;

  Future<void> loadSubscriptions() async {
    _loading = true;
    notifyListeners();
    try {
      _subscriptions = await getSubscriptions();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }
}
