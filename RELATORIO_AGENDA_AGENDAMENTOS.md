# Relatório de Análise - Sistema de Agenda e Agendamentos

**Data:** 13/03/2026  
**Objetivo:** Garantir funcionamento correto, eliminar duplicidades e código desnecessário.

---

## 1. Arquivos e Componentes Mapeados

### 1.1 Agenda (exibição)
| Arquivo | Descrição |
|---------|-----------|
| `professional_agenda_page.dart` | Agenda do profissional (Minha Agenda) |
| `professional_agenda_page_temp.dart` | **CÓDIGO MORTO** – backup/temp, não importado |
| `multi_professional_agenda_page.dart` | Agenda multiprofissional (admin) |
| `admin_agenda_page.dart` | Extends MultiProfessionalAgendaPage – wrapper simples |

### 1.2 Agendamentos (lista/gestão)
| Arquivo | Descrição |
|---------|-----------|
| `professional_appointments_page.dart` | Lista de agendamentos do profissional (Confirmados, Pendentes, Concluídos) |
| `client_appointments_page.dart` | Agendamentos do cliente |
| `client_appointment_detail_page.dart` | Detalhes do agendamento do cliente |
| `create_appointment_page.dart` | Fluxo cliente: serviço → profissional → data → horário |
| `create_appointment_for_client_page.dart` | Admin cria para cliente |
| `agenda_create_appointment_sheet.dart` | Sheet para criar na agenda (cliente + serviço) |

### 1.3 Use Cases / Domain
| Use Case | Função |
|----------|--------|
| `CreateAppointmentUseCase` | Criar agendamento (valida conflitos) |
| `GetAvailableSlotsUseCase` | Slots disponíveis (considera disponibilidade, manual blocks, tenant) |
| `GetWeeklyTimeGridUseCase` | Blocks para exibir na agenda |
| `GetWeeklyScheduleUseCase` | Apenas aprovados por semana |
| `GetWeeklyAppointmentsUseCase` | Contagem por dia (admin dashboard) |
| `GetTodayAgendaUseCase` | Agenda do dia (admin) |
| `GetMonthlyAgendaStatsUseCase` | Stats mensais da agenda |
| `UpdateAppointmentTimeUseCase` | Mover horário (valida conflitos) |
| `RequestRescheduleUseCase` | Solicitar reagendamento |
| `AcceptRescheduleUseCase` | Cliente aceita reagendamento |
| `CancelAppointmentUseCase`, `ApproveAppointmentUseCase`, `RejectAppointmentUseCase`, `CompleteAppointmentUseCase` | Ações de status |

### 1.4 Horário de funcionamento
| Local | Entidade/Fonte |
|-------|----------------|
| **Profissional** | `Availability` (shifts, breakTimes, slotInterval) – `availability_repository` |
| **Tenant/Salão** | `TenantConfig.openingHours` – `get_tenant_config_usecase` |
| **Bloqueios** | `ManualBlock` – `manual_block_repository` |
| **Datas bloqueadas** | `BlockedDate` – `availability_repository` |
| **Override diário** | `DailyOverride` – `availability_repository` |

### 1.5 Validações de conflito
| Local | Escopo |
|-------|--------|
| `CreateAppointmentUseCase` | approved, pending, rescheduleRequested |
| `UpdateAppointmentTimeUseCase` | **Só approved** (pendentes ignorados) – **BUG** |
| `GetAvailableSlotsUseCase` + `SlotGenerator` | approved, pending, rescheduleRequested + manual blocks + breaks |

---

## 2. Fluxo Completo Mapeado

```
Cliente/Admin/Profissional
    ↓
[Escolher serviço + profissional + data] → GetAvailableSlotsUseCase (slots válidos)
    OU
[Agenda: toque na grade] → slot calculado (sem validação prévia)
    ↓
CreateAppointmentUseCase
    - Valida: status=pending, não passado, scheduledEnd > scheduledStart
    - Valida conflito: approved, pending, rescheduleRequested
    - NÃO valida: manual blocks, horário funcionamento
    ↓
SchedulingRepository.create() → Firestore
    ↓
Exibição:
    - Profissional: GetWeeklyTimeGridUseCase (getByProfessionalAndPeriod)
    - Admin: GetWeeklyTimeGridUseCase por profissional
    - Cliente: GetClientAppointmentsDisplayUseCase / streamByClient
```

---

## 3. Bugs Encontrados

### 3.1 Crítico: UpdateAppointmentTimeUseCase não considera pendentes
- **Arquivo:** `update_appointment_time_usecase.dart`
- **Problema:** Usa `getApprovedByProfessionalAndDate` – só aprovados. Agendamentos pendentes e rescheduleRequested são ignorados.
- **Risco:** Mover um agendamento para horário já ocupado por pendente.

### 3.2 Menor: CreateAppointmentUseCase não valida manual blocks
- **Arquivo:** `create_appointment_usecase.dart`
- **Problema:** Não valida bloqueios manuais.
- **Contexto:** Criação via agenda (tap na grade) ou admin pode inserir em horário bloqueado. GetAvailableSlotsUseCase filtra corretamente no fluxo cliente.

---

## 4. Duplicidades e Inconsistências

| Item | Detalhe |
|------|---------|
| `getByProfessionalAndDate` vs `getByProfessionalAndPeriod` | Diferentes – data única vs período. OK. |
| `getByProfessionalAndDateRange` | Delega para `getByProfessionalAndPeriod`. Compatibilidade. |
| Validação de conflito | CreateAppointmentUseCase faz inline; UpdateAppointmentTimeUseCase usa ScheduleValidator. Não duplicado, mas UpdateAppointmentTime falha no escopo (só approved). |
| GetWeeklyScheduleUseCase | Só approved – propósito diferente de GetWeeklyTimeGridUseCase (todos não cancelados). OK. |

---

## 5. Código Desnecessário

| Item | Ação recomendada |
|------|------------------|
| `professional_agenda_page_temp.dart` | **Remover** – não usado em nenhum lugar |
| `debug_log.dart`, `debug_log_web.dart`, `debug_log_stub.dart` | Remover uso em produção; manter ou remover conforme política |
| Debug overlay na `professional_agenda_page` (Uri.base.queryParameters['debug'] == '1') | **Remover** – debug em produção |
| Chamadas `debugLog()` em `professional_agenda_page.dart` | **Remover** |

---

## 6. Sincronização com Banco

- Firestore: collection `appointments`, filtros por `professionalId`, `scheduledStart`, `status`
- Web: `GetOptions(source: Source.server)` em queries críticas para evitar cache
- Índices: necessários para `professionalId + scheduledStart` (compound)

---

## 7. Conflitos de Agendamento

- **Validação antes de salvar:** Sim – CreateAppointmentUseCase e UpdateAppointmentTimeUseCase
- **Validação no banco:** Não há regras/triggers Firestore – apenas app
- **Race condition:** Possível se dois usuários agendarem o mesmo slot ao mesmo tempo (otimistic locking não existe)

---

## 8. Melhorias Sugeridas

1. Corrigir UpdateAppointmentTimeUseCase para incluir pending e rescheduleRequested na validação.
2. Remover `professional_agenda_page_temp.dart`.
3. Remover debug overlay e chamadas debugLog de `professional_agenda_page.dart`.
4. (Opcional) Criar validação de manual blocks em CreateAppointmentUseCase para fluxo agenda/admin.
5. (Opcional) Usar transação Firestore ao criar para mitigar race condition.

---

## 9. Correções Aplicadas

| Correção | Status |
|----------|--------|
| UpdateAppointmentTimeUseCase: incluir pending e rescheduleRequested na validação de conflito | ✅ Aplicado |
| Remoção de `professional_agenda_page_temp.dart` (código morto) | ✅ Aplicado |
| Remoção de debug overlay e debugLog de `professional_agenda_page.dart` | ✅ Aplicado |
