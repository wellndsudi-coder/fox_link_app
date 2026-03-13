# Compatibilidade APK vs Web - Fox Link

Este documento descreve as diferenças de comportamento entre APK (mobile) e Web, e as correções implementadas.

---

## 1. APK trava na splash

### Problema
- APK instalado abre mas fica preso na tela de splash (logo Flutter branco)
- Causa provável: FlutterSecureStorage no path de inicialização pode travar em alguns dispositivos Android

### Correção aplicada
- SessionCheckScreen passou a usar `validateSessionForWeb()` (Firebase Auth + Firestore) em **ambas** as plataformas
- Remove FlutterSecureStorage do path crítico de abertura do app
- Timeout de 8s e try/catch para sempre redirecionar para login em caso de erro

---

## 2. Cliente no APK não vê serviços (salão criado na web)

### Problema
- Salão criado na web + cliente criado no APK → não vê serviços
- Salão criado no APK + serviços na web → funciona
- Causa: cache do Firestore no Android retorna dados vazios/antigos

### Correção aplicada
- **GetOptions(source: Source.server)** nas leituras críticas: serviços, usuário, tenant, lista de salões
- `ServiceRemoteDataSource.getAll` — força servidor
- `UserRemoteDataSource.getUser` — força servidor
- `TenantRemoteDataSource.getTenant` e `getTenantByInviteCode` — força servidor
- `JoinSalonPage` e `SelectTenantPage` — lista de tenants do servidor
- CreateAppointmentPage/ClientShell: refresh de sessão quando tenantId null

---

## 3. Fluxo de sessão (SessionCheck)

### Problema
- **Web:** Pulava validação de sessão e ia direto para login (evitando FlutterSecureStorage que pode travar na web)
- **APK:** Restaurava sessão do FlutterSecureStorage (TokenManager), podendo usar `tenantId` desatualizado ou incorreto

### Correção aplicada
- **APK:** SessionManager agora busca `tenantId` e `roles` no **Firestore** ao restaurar, usando o documento do usuário como fonte da verdade (já implementado anteriormente)
- **Web:** Adicionado `validateSessionForWeb()` que usa Firebase Auth + Firestore diretamente (sem FlutterSecureStorage) para restaurar sessão quando o usuário está logado

### Resultado
- Web e APK usam Firestore como fonte da verdade para tenantId
- Sincronização de dados (serviços, blocos, agendamentos) funciona em ambas as plataformas

---

## 4. Marcação de horário na agenda não sincroniza

### Causa
- Mesma raiz: `tenantId` ou `professionalId` incorretos no APK
- Manual blocks e appointments usam TenantFirestore (session.tenantId) e professionalId

### Correção
- Com tenantId vindo do Firestore na restauração, os blocos manuais e agendamentos são gravados e lidos do tenant correto
- Agenda (ProfessionalAgendaPage, ProfessionalAvailabilityPage) usa o mesmo repositório e Firestore

---

## 4b. Agenda do owner em modo professional não mostra agendamentos

### Problema
- Admin/owner que alterna para modo professional não vê agendamentos na "Minha Agenda"
- Pendentes não aparecem na agenda professional (só concluídos); na agenda admin (Multiprofissional) aparecem

### Correção aplicada
- **Source.server** em getProfessionalByUid e nas queries de appointments por professionalId
- **ProfessionalShell**: refresh de sessão quando tenantId ou professionalId é null (garante professionalId ao entrar no modo professional)
- **getProfessionals**: Source.server para consistência APK/Web

### Problema adicional: agenda profissional na web não mostra pendentes/confirmados (só concluídos)
- **Causa:** No Firestore web, o listener `snapshots()` usa cache por padrão (ListenSource.defaultSource). A primeira emissão vem do cache (vazio ou desatualizado) e sobrescreve os dados do servidor.
- **Correção:**
  - `getByProfessionalAndPeriod` usa `Source.server` para leituras sempre frescas.
  - `GetWeeklyTimeGridUseCase.stream()` faz primeiro um `getByProfessionalAndPeriod` (servidor) e emite; depois o stream em tempo real. A primeira emissão do stream é ignorada se tiver menos itens que o fetch inicial (evita sobrescrever com cache vazio).

---

## 5. Upload de logo (Firebase Storage)

### Problema
- **Web:** `dart:io` (File) não existe na web; `putFile(File)` falha
- **APK:** Usava `File` e `putFile` normalmente

### Correção aplicada
- `TenantRemoteDataSource.uploadLogo` passou a aceitar `Uint8List bytes` em vez de `File`
- Uso de `ref.putData(bytes, SettableMetadata(contentType: 'image/jpeg'))` — funciona em Web e APK
- `create_salon_page`, `edit_tenant_page` e `appearance_page` usam `XFile.readAsBytes()` e removem `dart:io`

### Resultado
- Troca de logo funciona em Web e APK; mesmo logo gravado em uma plataforma aparece na outra

---

## 6. Armazenamento (Storage)

| Componente                  | Web                          | APK                                |
|----------------------------|------------------------------|------------------------------------|
| TokenManager               | Não usado na restauração     | FlutterSecureStorage               |
| Session (tenantId, roles)  | Firebase Auth + Firestore    | Firestore (refresh na restauração) |
| SharedPreferences          | LocalStorage / IndexedDB     | SharedPreferences nativo           |
| AcknowledgedCancellations  | Por dispositivo/navegador    | Por dispositivo                    |

---

## 7. Diferenças conhecidas (comportamento esperado)

- **Lembrar sessão:** Na web, ao fechar o navegador e reabrir, a sessão pode ser restaurada via Firebase Auth (se `validateSessionForWeb` encontrar usuário logado). No APK, usa TokenManager + Firestore.
- **FCM (notificações):** Push funciona no APK; na web depende de suporte do navegador.
- **ImagePicker:** Pode ter diferenças de permissão entre plataformas.

---

## 8. Pontos de verificação para futuras features

Ao adicionar novas funcionalidades, verificar:
- Uso de `TenantSession.tenantId` e `professionalId` — devem vir de sessão restaurada corretamente
- Escrita/leitura em Firestore — path usa `tenants/{tenantId}/...`
- Evitar `dart:io` (File, Directory) em código compartilhado; preferir `Uint8List` ou `XFile.readAsBytes()` para uploads
- Evitar lógica diferente para `kIsWeb` exceto quando necessário (ex: FlutterSecureStorage)
- Testar fluxo em ambas as plataformas após login e após reabrir app
