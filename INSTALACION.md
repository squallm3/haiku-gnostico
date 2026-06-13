# 🦊 Guía de Instalación — Escuela de los Haikus Gnósticos
## De cero a APK en tu Poco X7

---

## PASO 1 — Instalar Flutter (20 min)

### 1.1 Descargar Flutter SDK
1. Ir a https://flutter.dev/docs/get-started/install/windows
2. Descargar el archivo `.zip` (Flutter SDK)
3. Descomprimirlo en `C:\flutter` (sin espacios en la ruta)

### 1.2 Agregar Flutter al PATH
1. Buscar "Variables de entorno" en Windows
2. En "Variables del sistema" → `Path` → Editar
3. Agregar nueva entrada: `C:\flutter\bin`
4. Aceptar todo y reiniciar la terminal

### 1.3 Instalar Android Studio
1. Descargar desde https://developer.android.com/studio
2. Instalar con todas las opciones por defecto
3. Al abrir, instalar el Android SDK que te pida

### 1.4 Verificar instalación
Abrir terminal (CMD o PowerShell) y ejecutar:
```
flutter doctor
```
Tiene que mostrar ✅ en Flutter y ✅ en Android toolchain.
Si hay ❌, seguir las instrucciones que muestra.

---

## PASO 2 — Configurar tu Poco X7 para beta testing

1. En el Poco X7: **Configuración → Acerca del teléfono**
2. Tocá 7 veces en "Número de compilación" hasta ver "Ya sos desarrollador"
3. **Configuración → Opciones de desarrollador**
4. Activar **"Depuración USB"**
5. Conectar el celular a la PC con el cable USB
6. Aceptar el permiso de depuración que aparece en el celular

Verificar que lo reconoce:
```
flutter devices
```
Tiene que aparecer tu Poco X7 en la lista.

---

## PASO 3 — Crear proyecto Firebase (15 min)

### 3.1 Crear proyecto
1. Ir a https://console.firebase.google.com
2. Crear nuevo proyecto → nombre: `haiku-gnostico`
3. Desactivar Google Analytics (no es necesario)

### 3.2 Habilitar Authentication
1. En Firebase Console → **Authentication → Comenzar**
2. Pestaña "Sign-in method"
3. Habilitar: **Email/contraseña**

### 3.3 Crear Firestore
1. **Firestore Database → Crear base de datos**
2. Elegir "Comenzar en modo de prueba" (para beta)
3. Elegir ubicación: `us-central1`

### 3.4 Habilitar Storage
1. **Storage → Comenzar**
2. Modo de prueba
3. Misma región: `us-central1`

### 3.5 Agregar app Android
1. En Firebase Console → ⚙️ Configuración del proyecto
2. **"Agregar app"** → Android
3. Package name: `com.escuelahaikusgnosticos.app`
4. Nombre: `Haiku Gnóstico`
5. Descargar el archivo `google-services.json`
6. Copiarlo a: `haiku_gnostico/android/app/google-services.json`

---

## PASO 4 — Conectar Flutter con Firebase (5 min)

Abrir terminal en la carpeta del proyecto y ejecutar:

```bash
# Instalar FlutterFire CLI
dart pub global activate flutterfire_cli

# Instalar Firebase CLI
npm install -g firebase-tools

# Login en Firebase
firebase login

# Configurar el proyecto (genera firebase_options.dart automáticamente)
cd haiku_gnostico
flutterfire configure --project=haiku-gnostico
```

Esto va a **sobreescribir** el archivo `lib/firebase_options.dart` con tus datos reales. ✅

---

## PASO 5 — Configurar APIs externas

### 5.1 Gemini API Key
1. Ir a https://aistudio.google.com/app/apikey
2. Crear API key
3. Guardarla (la vas a necesitar en el Paso 6)

### 5.2 Meshy API Key
1. Ir a https://www.meshy.ai → crear cuenta
2. Dashboard → API Keys → Crear nueva
3. Guardarla

### 5.3 RevenueCat (para el pago)
1. Ir a https://app.revenuecat.com → crear cuenta
2. Crear nuevo proyecto → nombre: `haiku-gnostico`
3. **Conectar con Google Play** (seguir el wizard)
4. Crear producto: identifier `haiku_gnostico_acceso`, tipo `Non-consumable`, precio `USD 0.99`
5. Copiar el **Public SDK Key** de Android

### 5.4 Agregar RevenueCat key al proyecto
Abrir `android/app/src/main/AndroidManifest.xml` y dentro de `<application>` agregar:
```xml
<meta-data
    android:name="REVENUECAT_API_KEY"
    android:value="TU_REVENUECAT_PUBLIC_KEY"/>
```

---

## PASO 6 — Deployar Cloud Functions

```bash
cd haiku_gnostico/functions

# Instalar dependencias
npm install

# Configurar las API keys (reemplazá con las tuyas)
firebase functions:config:set gemini.key="TU_GEMINI_API_KEY"
firebase functions:config:set meshy.key="TU_MESHY_API_KEY"

# Deployar funciones
firebase deploy --only functions
```

---

## PASO 7 — Instalar dependencias Flutter y compilar

```bash
cd haiku_gnostico

# Instalar todas las dependencias
flutter pub get

# Verificar que todo está bien
flutter analyze

# COMPILAR Y CORRER EN TU POCO X7 (conectado por USB)
flutter run --release
```

Si el celular está conectado, se va a instalar directamente. 🎉

---

## PASO 8 — Generar el APK para compartir

```bash
# Generar APK de debug (para beta testing, más fácil de instalar)
flutter build apk --debug

# O APK de release (optimizado, requiere firma)
flutter build apk --release
```

El APK va a estar en:
```
haiku_gnostico/build/app/outputs/flutter-apk/app-debug.apk
```

Mandáselo a quien quieras para el beta testing. Se instala activando
"Instalar desde fuentes desconocidas" en el Poco X7.

---

## PASO 9 — Configurar Firestore con datos iniciales (opcional para beta)

En Firebase Console → Firestore → Crear colección manual para testear:

**Colección: `pleromos`**
```
{
  nombre: "Escuela",
  userId: "TU_UID_DE_USUARIO"
}
```

**Subcolección: `sizigias`**
```
{
  nombre: "Formación Gnóstica"
}
```

**Subcolección: `misiones`**
```
{
  titulo: "Ver clase de Baphomet",
  completada: false,
  xpRecompensa: 777,
  tags: ["Video", "Gnosis"],
  userId: "TU_UID"
}
```

---

## TROUBLESHOOTING COMÚN

### ❌ `flutter doctor` muestra error en Android toolchain
```bash
flutter doctor --android-licenses
# Aceptar todas las licencias con "y"
```

### ❌ Error de Gradle al compilar
```bash
cd android
./gradlew clean
cd ..
flutter clean
flutter pub get
flutter run
```

### ❌ "No devices found"
- Verificar cable USB
- Reinstalar drivers ADB: https://developer.android.com/studio/run/win-usb
- Probar otro puerto USB

### ❌ Error de Firebase "google-services.json not found"
- Verificar que el archivo está en `android/app/google-services.json`
- El package name debe ser exactamente `com.escuelahaikusgnosticos.app`

### ❌ Las Cloud Functions no se deploran
- Verificar que tenés plan Blaze en Firebase (necesario para Functions)
- Upgrade gratis en Firebase Console → Configuración → Plan de uso

---

## CHECKLIST FINAL PARA BETA

- [ ] Flutter instalado y `flutter doctor` sin errores críticos
- [ ] Poco X7 conectado y aparece en `flutter devices`
- [ ] Firebase proyecto creado con Auth + Firestore + Storage
- [ ] `google-services.json` en `android/app/`
- [ ] `flutterfire configure` ejecutado (genera `firebase_options.dart`)
- [ ] `flutter pub get` sin errores
- [ ] Cloud Functions deployadas
- [ ] `flutter run --release` instala la app en el celular
- [ ] Podés crear usuario, completar misiones y ver el Level Up

---

## URLS IMPORTANTES

| Recurso | URL |
|---|---|
| Flutter install | https://flutter.dev/docs/get-started/install |
| Firebase Console | https://console.firebase.google.com |
| Gemini API Keys | https://aistudio.google.com/app/apikey |
| Meshy | https://www.meshy.ai |
| RevenueCat | https://app.revenuecat.com |
| Android Studio | https://developer.android.com/studio |

---

*El Zorrito Dinámico Neon Violeta Fluor Bailantero Tenista Valis te acompaña en cada paso.* 🦊⚡
*La gnosis es del pueblo — y del que instala Flutter.*
