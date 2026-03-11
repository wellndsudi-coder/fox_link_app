import { onDocumentUpdated } from "firebase-functions/v2/firestore";
import { initializeApp } from "firebase-admin/app";
import { getFirestore } from "firebase-admin/firestore";
import { getMessaging } from "firebase-admin/messaging";

initializeApp();

/**
 * Envia push notification ao cliente quando o profissional solicita reagendamento.
 * Dispara quando o documento de appointment é atualizado e status muda para rescheduleRequested.
 * Path: tenants/{tenantId}/appointments/{appointmentId}
 */
export const notifyClientOnReschedule = onDocumentUpdated(
  { document: "tenants/{tenantId}/appointments/{appointmentId}" },
  async (event) => {
    const before = event.data?.before?.data();
    const after = event.data?.after?.data();

    if (!before || !after) return;

    const beforeStatus = before.status;
    const afterStatus = after.status;

    if (beforeStatus === afterStatus) return;
    if (afterStatus !== "rescheduleRequested") return;

    const clientId = after.clientId;
    if (!clientId) return;

    const proposedStart = after.proposedStart?.toDate?.() ?? after.proposedStart;
    const proposedDate = proposedStart
      ? new Date(proposedStart).toLocaleDateString("pt-BR", {
          day: "2-digit",
          month: "2-digit",
          hour: "2-digit",
          minute: "2-digit",
        })
      : "novo horário";

    const db = getFirestore();

    const userDoc = await db.collection("users").doc(clientId).get();
    const fcmToken = userDoc?.data?.()?.fcmToken;

    if (!fcmToken) return;

    const messaging = getMessaging();
    await messaging.send({
      token: fcmToken,
      notification: {
        title: "Reagendamento solicitado",
        body: `O profissional propôs ${proposedDate} como novo horário. Toque para aceitar ou recusar.`,
      },
      data: {
        type: "reschedule_requested",
        appointmentId: event.params.appointmentId ?? "",
      },
    });
  }
);
