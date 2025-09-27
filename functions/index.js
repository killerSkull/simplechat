const functions = require("firebase-functions");
const admin = require("firebase-admin");

admin.initializeApp({
  projectId: "simplechat-4880e",
});

// --- FUNCIÓN 1: Para mensajes nuevos (sin cambios) ---
exports.sendChatNotification = functions.firestore
    .document("chats/{chatId}/messages/{messageId}")
    .onCreate(async (snap, context) => {
        // ... (el código de esta función se mantiene igual)
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

// --- FUNCIÓN 2: NUEVA para notificaciones de reacciones ---
exports.sendReactionNotification = functions.firestore
    .document("chats/{chatId}/messages/{messageId}")
    .onUpdate(async (change, context) => {
      const beforeData = change.before.data();
      const afterData = change.after.data();

      // Comparar las reacciones para ver si algo cambió
      if (JSON.stringify(beforeData.reactions) === JSON.stringify(afterData.reactions)) {
        return null;
      }

      // Identificar quién reaccionó y a qué
      const beforeReactions = beforeData.reactions || {};
      const afterReactions = afterData.reactions || {};
      
      let reactorId;
      let reactionEmoji;

      // Encontrar la nueva reacción
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
        console.log("No se pudo determinar la nueva reacción.");
        return null;
      }
      
      const messageAuthorId = afterData.sender_uid;

      // No notificar si reaccionas a tu propio mensaje
      if (reactorId === messageAuthorId) {
        return null;
      }

      const recipientDoc = await admin.firestore().collection("users").doc(messageAuthorId).get();
      if (!recipientDoc.exists) return null;

      const recipientData = recipientDoc.data();
      // No notificar si el autor del mensaje está en el chat
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
          senderId: reactorId, // El que reacciona es el "remitente" de la notificación
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