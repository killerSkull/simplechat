const functions = require("firebase-functions");
const admin = require("firebase-admin");
const { RtcTokenBuilder, RtcRole } = require("agora-access-token");

admin.initializeApp();

// --- CREDENCIALES DE AGORA ---
// Asegúrate de que estas credenciales son las correctas
const APP_ID = "77d636faa353436a99029acd0095cefa";
const APP_CERTIFICATE = "093b54f788cf462aae36c23b6430d1de";

// --- FUNCIÓN 1: Para generar tokens de Agora ---
exports.generateAgoraToken = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError("unauthenticated", "La función debe ser llamada por un usuario autenticado.");
  }
  const channelName = data.channelName;
  if (!channelName) {
    throw new functions.https.HttpsError("invalid-argument", "La función debe ser llamada con un argumento 'channelName'.");
  }
  const role = RtcRole.PUBLISHER;
  const expirationTimeInSeconds = 3600;
  const currentTimestamp = Math.floor(Date.now() / 1000);
  const privilegeExpiredTs = currentTimestamp + expirationTimeInSeconds;

  try {
    const token = RtcTokenBuilder.buildTokenWithUid(APP_ID, APP_CERTIFICATE, channelName, 0, role, privilegeExpiredTs);
    return { token: token };
  } catch (error) {
    console.error("Error al generar el token de Agora:", error);
    throw new functions.https.HttpsError("internal", "No se pudo generar el token de Agora.");
  }
});

// --- FUNCIÓN 2: Para notificar llamadas entrantes ---
exports.sendCallNotification = functions.firestore
    .document("calls/{callId}")
    .onCreate(async (snap, context) => {
      const callData = snap.data();
      if (!callData) return null;

      const callerId = callData.callerId;
      const calleeId = callData.calleeId;
      const callType = callData.isVideoCall ? "videollamada" : "llamada de voz";

      const callerDoc = await admin.firestore().collection("users").doc(callerId).get();
      if (!callerDoc.exists) return null;
      const callerName = callerDoc.data().display_name || "Alguien";

      const calleeDoc = await admin.firestore().collection("users").doc(calleeId).get();
      if (!calleeDoc.exists) return null;
      const calleeToken = calleeDoc.data().fcm_token;
      if (!calleeToken) return null;

      const payload = {
        token: calleeToken,
        notification: {
          title: `Llamada entrante de ${callerName}`,
          body: `Tienes una nueva ${callType}.`,
        },
        android: {
          priority: "high",
          notification: { sound: "default" },
        },
        apns: {
          payload: {
            aps: {
              sound: "default",
              "content-available": 1,
            },
          },
        },
        data: {
          "click_action": "FLUTTER_NOTIFICATION_CLICK",
          type: "incoming_call",
          callId: context.params.callId,
          callerName: callerName,
        },
      };

      try {
        console.log(`Enviando notificación de llamada a ${calleeId}`);
        return await admin.messaging().send(payload);
      } catch (error) {
        console.error("Error al enviar notificación de llamada:", error);
        return null;
      }
    });

// --- FUNCIÓN 3: Para notificar mensajes de chat ---
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

// --- FUNCIÓN 4: Para notificar reacciones ---
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

