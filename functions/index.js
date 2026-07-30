// functions/index.js
const admin = require('firebase-admin');
admin.initializeApp();

const { generarCarnet } = require('./src/generarCarnet');
const functions = require('firebase-functions');

// ─── Notificaciones push — corre cada minuto ──────────────────────────────────
exports.enviarNotificacionesTareas = functions.pubsub
  .schedule('every 1 minutes')
  .onRun(async () => {
    const db = admin.firestore();
    const now = new Date();

    // Ventana de 1 minuto: desde ahora hasta hace 1 minuto
    const desde = new Date(now.getTime() - 60 * 1000);
    const hasta = new Date(now.getTime());

    try {
      // Buscar todas las misiones con fechaNotificacion en la ventana actual
      const snap = await db.collectionGroup('misiones')
        .where('completada', '==', false)
        .where('fechaNotificacion', '>=', desde)
        .where('fechaNotificacion', '<=', hasta)
        .get();

      if (snap.empty) return null;

      const promesas = snap.docs.map(async (doc) => {
        const mision = doc.data();
        const userId = mision.userId;
        if (!userId) return;

        // Obtener token FCM del usuario
        const userDoc = await db.collection('users').doc(userId).get();
        const fcmToken = userDoc.data()?.fcmToken;
        if (!fcmToken) return;

        // Enviar notificación
        await admin.messaging().send({
          token: fcmToken,
          notification: {
            title: 'HK Tasks ⚡',
            body: mision.titulo || 'Tenés una tarea pendiente',
          },
          android: {
            priority: 'high',
            notification: {
              channelId: 'hk_tasks_channel',
              sound: 'default',
            },
          },
        });

        functions.logger.log(`Notificación enviada para tarea: ${mision.titulo}`);
      });

      await Promise.all(promesas);
    } catch (err) {
      functions.logger.error('Error enviando notificaciones:', err);
    }

    return null;
  });

exports.generarCarnet = generarCarnet;
