class PlanConfig {
  static const trial = 'trial';
  static const basic = 'basic';
  static const professional = 'professional';
  static const enterprise = 'enterprise';

  // Compatibilidade com Master
  static const plus = 'plus';
  static const pro = 'pro';
  static const unlimited = 'unlimited';

  static const List<String> plans = [
    trial,
    basic,
    professional,
    enterprise,
  ];

  static int maxProfessionals(String? plan) {
    if (plan == null || plan.isEmpty) return 2;
    switch (plan) {
      case trial:
      case basic:
        return 2;
      case professional:
      case plus:
        return 4;
      case enterprise:
      case pro:
        return 6;
      case unlimited:
        return 999999;
      default:
        return 2;
    }
  }

  static int maxServices(String? plan) {
    if (plan == null || plan.isEmpty) return 15;
    switch (plan) {
      case trial:
      case basic:
        return 15;
      case professional:
      case plus:
        return 30;
      case enterprise:
      case pro:
        return 45;
      case unlimited:
        return 999999;
      default:
        return 15;
    }
  }

  static int trialDays(String? plan) {
    if (plan == null || plan.isEmpty) return 0;
    return plan == trial ? 30 : 0;
  }

  static double? price(String? plan) {
    if (plan == null || plan.isEmpty) return null;
    switch (plan) {
      case basic:
        return 29.99;
      case professional:
        return 39.99;
      case enterprise:
        return 59.99;
      default:
        return null;
    }
  }
}
