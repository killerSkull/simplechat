const functions = require("firebase-functions");
const admin = require("firebase-admin");
// --- CORRECCIÓN FINAL: Se usa el paquete que indicaste ---
const {RtcTokenBuilder, RtcRole} = require("agora-access-token");

admin.initializeApp();

// --- CREDENCIALES DE AGORA ---
// ¡Mejora de seguridad! Mueve esto a variables de entorno en Firebase.
// Ejecuta estos comandos en tu terminal:
// firebase functions:config:set agora.app_id="TU_APP_ID"
// firebase functions:config:set agora.app_certificate="TU_CERTIFICADO"
const APP_ID = functions.config().agora.app_id;
const APP_CERTIFICATE = functions.config().agora.app_certificate;


// --- FUNCIÓN 1: Para generar tokens de Agora (Mejorada) ---
exports.generateAgoraToken = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError("unauthenticated", "La función debe ser llamada por un usuario autenticado.");
  }
  const channelName = data.channelName;
  if (!channelName) {
    throw new functions.https.HttpsError("invalid-argument", "La función debe ser llamada con un argumento 'channelName'.");
  }

  // --- Comprobación de que las variables de entorno existen ---
  if (!APP_ID || !APP_CERTIFICATE) {
    throw new functions.https.HttpsError(
        "failed-precondition",
        "Las credenciales de Agora (APP_ID y APP_CERTIFICATE) no están configuradas en el entorno.",
    );
  }

  const role = RtcRole.PUBLISHER;
  const expirationTimeInSeconds = 3600;
  const currentTimestamp = Math.floor(Date.now() / 1000);
  const privilegeExpiredTs = currentTimestamp + expirationTimeInSeconds;

  try {
    const token = RtcTokenBuilder.buildTokenWithUid(APP_ID, APP_CERTIFICATE, channelName, 0, role, privilegeExpiredTs);
    return {token: token};
  } catch (error) {
    console.error("Error al generar el token de Agora:", error);
    throw new functions.https.HttpsError("internal", "No se pudo generar el token de Agora.");
  }
});


// --- FUNCIÓN 2: Para notificar llamadas entrantes (Corregida y Unificada) ---
exports.notifyIncomingCall = functions.firestore
    .document("calls/{callId}")
    .onCreate(async (snap, context) => {
      const callData = snap.data();
      if (!callData) return null;

      // --- CORRECCIÓN 2: Se usan los nombres de campo correctos ---
      const receiverId = callData.receiver_id;
      const callerName = callData.caller_name || "Alguien";

      const calleeDoc = await admin.firestore().collection("users").doc(receiverId).get();
      if (!calleeDoc.exists) {
        console.log("No se encontró al usuario receptor:", receiverId);
        return null;
      }

      const fcmToken = calleeDoc.data().fcm_token;
      if (!fcmToken) {
        console.log("El usuario receptor no tiene un FCM token.");
        return null;
      }

      const payload = {
        token: fcmToken,
        notification: {
          title: "Llamada entrante",
          body: `Tienes una llamada de ${callerName}`,
        },
        data: {
          // --- CORRECCIÓN 3: Se envían todos los datos necesarios a la app ---
          type: "incoming_call",
          caller_id: callData.caller_id,
          caller_name: callerName,
          receiver_id: receiverId,
          is_video_call: String(callData.is_video_call),
          channel_name: callData.channel_name,
        },
        android: {
          priority: "high",
        },
        apns: {
          payload: {
            aps: {
              sound: "default",
              "content-available": 1,
            },
          },
        },
      };

      try {
        console.log(`Enviando notificación de llamada a ${receiverId}`);
        await admin.messaging().send(payload);
        console.log("Notificación enviada con éxito.");
        return {success: true};
      } catch (error) {
        console.error("Error al enviar la notificación:", error);
        return {error: error.message};
      }
    });


// --- FUNCIÓN 3: Para notificar mensajes de chat (Sin cambios) ---
exports.sendChatNotification = functions.firestore
    .document("chats/{chatId}/messages/{messageId}")
    .onCreate(async (snap, context) => {
      const message = snap.data();
      if (!message) return null;
      const senderId = message.sender_uid;
      const recipientId = message.recipient_uid;
      const chatId = context.params.chatId;

      if (senderId === recipientId) return null;

      const recipientDoc = await admin.firestore().collection("users").doc(recipientId).get();
      if (!recipientDoc.exists) return null;

      const recipientData = recipientDoc.data();
      if (recipientData.current_chat_id === chatId) return null;

      const recipientToken = recipientData.fcm_token;
      if (!recipientToken) return null;

      const senderDoc = await admin.firestore().collection("users").doc(senderId).get();
      if (!senderDoc.exists) return null;
      const senderName = senderDoc.data().display_name || "Alguien";

      let notificationBody = "Te ha enviado un mensaje.";
      if (message.text) notificationBody = message.text;
      else if (message.image_url) notificationBody = "📷 Foto";
      else if (message.video_url) notificationBody = "▶️ Video";
      else if (message.audio_url) notificationBody = "🎤 Mensaje de voz";

      const payload = {
        token: recipientToken,
        notification: { title: senderName, body: notificationBody },
        android: { notification: { sound: "default" } },
        apns: { payload: { aps: { sound: "default" } } },
        data: {
          "click_action": "FLUTTER_NOTIFICATION_CLICK",
          chatId: chatId,
          senderId: senderId,
          senderName: senderName,
        },
      };

      try {
        return await admin.messaging().send(payload);
      } catch (error) {
        console.error("Error al enviar notificación de mensaje:", error);
        return null;
      }
    });


// --- FUNCIÓN 4: Para notificar reacciones (Sin cambios) ---
exports.sendReactionNotification = functions.firestore
    .document("chats/{chatId}/messages/{messageId}")
    .onUpdate(async (change, context) => {
        const beforeData = change.before.data();
        const afterData = change.after.data();

        if (JSON.stringify(beforeData.reactions) === JSON.stringify(afterData.reactions)) {
            return null;
        }

        const beforeReactions = beforeData.reactions || {};
        const afterReactions = afterData.reactions || {};
        let reactorId;
        let reactionEmoji;

        for (const emoji in afterReactions) {
            const afterUsers = afterReactions[emoji] || [];
            const beforeUsers = beforeReactions[emoji] || [];
            if (afterUsers.length > beforeUsers.length) {
                reactorId = afterUsers.find((user) => !beforeUsers.includes(user));
                reactionEmoji = emoji;
                break;
            }
        }

        if (!reactorId || !reactionEmoji) {
            return null;
        }

        const messageAuthorId = afterData.sender_uid;
        if (reactorId === messageAuthorId) {
            return null;
        }

        const recipientDoc = await admin.firestore().collection("users").doc(messageAuthorId).get();
        if (!recipientDoc.exists) return null;

        const recipientData = recipientDoc.data();
        if (recipientData.current_chat_id === context.params.chatId) {
            return null;
        }

        const recipientToken = recipientData.fcm_token;
        if (!recipientToken) return null;

        const reactorDoc = await admin.firestore().collection("users").doc(reactorId).get();
        if (!reactorDoc.exists) return null;
        const reactorName = reactorDoc.data().display_name || "Alguien";

        const payload = {
            token: recipientToken,
            notification: {
                title: reactorName,
                body: `Reaccionó con ${reactionEmoji} a tu mensaje.`,
            },
            android: { notification: { sound: "default" } },
            apns: { payload: { aps: { sound: "default" } } },
            data: {
                "click_action": "FLUTTER_NOTIFICATION_CLICK",
                chatId: context.params.chatId,
                senderId: reactorId,
                senderName: reactorName,
            },
        };

        try {
            return await admin.messaging().send(payload);
        } catch (error) {
            console.error("Error al enviar notificación de reacción:", error);
            return null;
        }
    });
