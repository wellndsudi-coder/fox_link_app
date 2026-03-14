/// Serviço para verificação de assinatura do tenant.
class SubscriptionService {
  /// Verifica se o tenant está ativo (pode usar a plataforma).
  /// Regras:
  /// - Se trialEnd > now: ativo (em trial)
  /// - Se subscriptionEnd > now: ativo (assinatura paga)
  /// - Se blocked == true: inativo
  /// - Caso contrário: inativo
  bool isTenantActive(TenantSubscriptionState tenant) {
    if (tenant.blocked) return false;
    if (tenant.trialEnd != null && tenant.trialEnd!.isAfter(DateTime.now())) {
      return true;
    }
    if (tenant.subscriptionEnd != null &&
        tenant.subscriptionEnd!.isAfter(DateTime.now())) {
      return true;
    }
    return false;
  }
}

/// Estado de assinatura do tenant para verificação.
class TenantSubscriptionState {
  final bool blocked;
  final DateTime? trialEnd;
  final DateTime? subscriptionEnd;

  const TenantSubscriptionState({
    this.blocked = false,
    this.trialEnd,
    this.subscriptionEnd,
  });
}
