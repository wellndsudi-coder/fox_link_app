class PlanConfig {
  static const trial = 'trial';
  static const basic = 'basic';
  static const plus = 'plus';
  static const pro = 'pro';
  static const unlimited = 'unlimited';

  static int maxProfessionals(String plan) {
    switch (plan) {
      case trial:
        return 1;
      case basic:
        return 2;
      case plus:
        return 3;
      case pro:
        return 4;
      case unlimited:
        return 999999;
      default:
        return 0;
    }
  }

  static int maxServices(String plan) {
    switch (plan) {
      case trial:
        return 10;
      case basic:
        return 20;
      case plus:
        return 30;
      case pro:
        return 40;
      case unlimited:
        return 999999;
      default:
        return 0;
    }
  }
}