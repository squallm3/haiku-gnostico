// functions/src/generarCarnet.js
const functions = require('firebase-functions');
const admin = require('firebase-admin');
const axios = require('axios');

const db = admin.firestore();

// ─── CONFIGURACIÓN — reemplazar con tus API keys ─────────────
const GEMINI_API_KEY = functions.config().gemini?.key || process.env.GEMINI_API_KEY;
const MESHY_API_KEY = functions.config().meshy?.key || process.env.MESHY_API_KEY;

// ─── GENERAR APODO CON GEMINI ────────────────────────────────
async function generarApodo(hobbies) {
  try {
    const prompt = `Sos un generador de identidades gnósticas para la Escuela de los Haikus Gnósticos.
Dado los siguientes hobbies: ${hobbies.join(', ')}
Generá UN SOLO apodo épico, misterioso y único de 2 a 4 palabras en español.
El apodo debe mezclar el lore gnóstico/místico con la personalidad del usuario.
Ejemplos de estilo: "El Tenista Cósmico", "La Bruja del Asfalto", "El Sonidero del Vacío", "El Maestro del LCL".
Respondé SOLO con el apodo, sin comillas, sin explicación, sin puntuación extra.`;

    const response = await axios.post(
      `https://generativelanguage.googleapis.com/v1beta/models/gemini-pro:generateContent?key=${GEMINI_API_KEY}`,
      {
        contents: [{ parts: [{ text: prompt }] }],
        generationConfig: { temperature: 0.9, maxOutputTokens: 50 }
      }
    );

    const apodo = response.data?.candidates?.[0]?.content?.parts?.[0]?.text?.trim();
    return apodo || 'El Iniciado Gnóstico';
  } catch (err) {
    console.error('Error generando apodo:', err.message);
    return 'El Iniciado Gnóstico';
  }
}

// ─── GENERAR IMAGEN CON GEMINI IMAGEN ────────────────────────
async function generarImagenZorrito(apodo) {
  try {
    const prompt = `A mystical glowing violet neon fox deity called "El Zorrito Dinámico Neon Violeta Fluor Bailantero Tenista Valis" interacting joyfully with a gnostic character called "${apodo}". 
    Style: vibrant neon colors, dark mystical background, glowing violet and electric blue aura, psychedelic gnostic art, high detail digital illustration, cinematic lighting.`;

    const response = await axios.post(
      `https://generativelanguage.googleapis.com/v1beta/models/imagen-3.0-generate-002:predict?key=${GEMINI_API_KEY}`,
      {
        instances: [{ prompt }],
        parameters: { sampleCount: 1, aspectRatio: '1:1' }
      }
    );

    const imageData = response.data?.predictions?.[0]?.bytesBase64Encoded;
    return imageData ? `data:image/png;base64,${imageData}` : null;
  } catch (err) {
    console.error('Error generando imagen:', err.message);
    return null;
  }
}

// ─── GENERAR MODELO 3D CON MESHY ─────────────────────────────
async function generarModelo3D(imageBase64, apodo) {
  try {
    // Subir imagen a Firebase Storage primero
    const bucket = admin.storage().bucket();
    const fileName = `avatars/temp_${Date.now()}.png`;
    const base64Data = imageBase64.replace(/^data:image\/\w+;base64,/, '');
    const buffer = Buffer.from(base64Data, 'base64');
    const file = bucket.file(fileName);
    await file.save(buffer, { metadata: { contentType: 'image/png' } });
    await file.makePublic();
    const imageUrl = `https://storage.googleapis.com/${bucket.name}/${fileName}`;

    // Llamar a Meshy API
    const meshyResponse = await axios.post(
      'https://api.meshy.ai/v1/image-to-3d',
      {
        image_url: imageUrl,
        enable_pbr: true,
        ai_model: 'meshy-4',
      },
      { headers: { 'Authorization': `Bearer ${MESHY_API_KEY}`, 'Content-Type': 'application/json' } }
    );

    const taskId = meshyResponse.data?.result;
    if (!taskId) return null;

    // Polling del estado (máximo 5 intentos)
    for (let i = 0; i < 5; i++) {
      await new Promise(r => setTimeout(r, 10000)); // esperar 10s
      const statusResponse = await axios.get(
        `https://api.meshy.ai/v1/image-to-3d/${taskId}`,
        { headers: { 'Authorization': `Bearer ${MESHY_API_KEY}` } }
      );
      if (statusResponse.data?.status === 'SUCCEEDED') {
        return statusResponse.data?.model_urls?.glb || null;
      }
    }
    return null;
  } catch (err) {
    console.error('Error generando 3D:', err.message);
    return null;
  }
}

// ─── GUARDAR IMAGEN EN STORAGE ───────────────────────────────
async function guardarImagenStorage(userId, imageBase64) {
  try {
    const bucket = admin.storage().bucket();
    const fileName = `carnets/${userId}_${Date.now()}.png`;
    const base64Data = imageBase64.replace(/^data:image\/\w+;base64,/, '');
    const buffer = Buffer.from(base64Data, 'base64');
    const file = bucket.file(fileName);
    await file.save(buffer, { metadata: { contentType: 'image/png' } });
    await file.makePublic();
    return `https://storage.googleapis.com/${bucket.name}/${fileName}`;
  } catch (err) {
    console.error('Error guardando imagen:', err.message);
    return null;
  }
}

// ─── CLOUD FUNCTION PRINCIPAL ─────────────────────────────────
exports.generarCarnet = functions
  .runWith({ timeoutSeconds: 300, memory: '512MB' })
  .https.onCall(async (data, context) => {
    if (!context.auth) throw new functions.https.HttpsError('unauthenticated', 'No autenticado');

    const userId = data.userId || context.auth.uid;
    const userRef = db.collection('users').doc(userId);
    const userSnap = await userRef.get();
    if (!userSnap.exists) throw new functions.https.HttpsError('not-found', 'Usuario no encontrado');

    const userData = userSnap.data();
    const hobbies = userData.hobbies || [];

    try {
      // 1. Generar apodo
      console.log('Generando apodo para:', hobbies);
      const apodo = await generarApodo(hobbies);
      console.log('Apodo generado:', apodo);

      // 2. Generar imagen del Zorrito
      console.log('Generando imagen del Zorrito...');
      const imagenBase64 = await generarImagenZorrito(apodo);

      // 3. Guardar imagen en Storage
      let avatarUrl = null;
      let carnetUrl = null;
      if (imagenBase64) {
        avatarUrl = await guardarImagenStorage(userId, imagenBase64);
        carnetUrl = avatarUrl; // misma imagen para carnet y avatar en v1
      }

      // 4. Generar modelo 3D (async, no bloquea)
      let avatar3dUrl = null;
      if (imagenBase64) {
        generarModelo3D(imagenBase64, apodo).then(async (url3d) => {
          if (url3d) await userRef.update({ avatar3dUrl: url3d });
        }).catch(err => console.error('Error 3D async:', err));
      }

      // 5. Actualizar usuario en Firestore
      await userRef.update({
        apodo,
        avatarUrl,
        carnetUrl,
        carnetGeneradoEn: admin.firestore.FieldValue.serverTimestamp(),
      });

      console.log('Carnet generado exitosamente para:', userId);
      return { success: true, apodo, avatarUrl, carnetUrl };

    } catch (err) {
      console.error('Error en generarCarnet:', err);
      // Actualizar con apodo por defecto aunque falle la imagen
      await userRef.update({ apodo: 'El Iniciado Gnóstico' });
      return { success: false, error: err.message };
    }
  });
