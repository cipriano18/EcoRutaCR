# Firebase Web Handoff

Este archivo sirve como contexto para otro chat de Codex que vaya a crear una app web administrativa reutilizando el mismo proyecto de Firebase que usa este repositorio.

## Objetivo

Conectar la nueva app web al mismo proyecto de Firebase para:

- usar la misma autenticacion
- usar la misma base de datos de Firestore
- mantener acceso a la coleccion `users` si hace falta leer datos de la app principal
- crear nuevas colecciones dentro del mismo proyecto Firebase
- usar una coleccion nueva llamada `admins` para el acceso administrativo

## Proyecto Firebase actual

- `projectId`: `ecorutacr-940a7`
- `authDomain`: `ecorutacr-940a7.firebaseapp.com`
- `storageBucket`: `ecorutacr-940a7.firebasestorage.app`
- `messagingSenderId`: `755850617671`

## Credenciales Web actuales

Estas son las credenciales web que este proyecto usa en `lib/firebase_options.dart`:

```dart
const firebaseConfig = {
  "apiKey": "AIzaSyAf--HSJj0iEeJ3TGr8Lmg3USbBj_3C7z0",
  "authDomain": "ecorutacr-940a7.firebaseapp.com",
  "projectId": "ecorutacr-940a7",
  "storageBucket": "ecorutacr-940a7.firebasestorage.app",
  "messagingSenderId": "755850617671",
  "appId": "1:755850617671:web:4d2f9ee9e501da8dc56262",
  "measurementId": "G-3PFECE5RE5"
};
```

## Archivos de referencia incluidos en esta carpeta

Como el otro proyecto esta fuera de este repositorio, en esta misma carpeta se adjuntan copias de referencia:

- `current_project_firebase_options.dart`
- `current_project_main.dart`
- `current_project_auth_service.dart`
- `current_project_pubspec.yaml`

## Lo que ya usa este proyecto

Servicios Firebase detectados:

- `Firebase Auth`
- `Cloud Firestore`

Coleccion detectada en uso:

- `users`

Campos observados en documentos de `users/{uid}`:

- `uid`
- `email`
- `fullName`
- `address`
- `avatarId`
- `favoriteActivity`
- `completed_routes`
- `km_counter`
- `streak_started_at`
- `streak_deadline_at`
- `createdAt`

## Inicializacion Flutter Web

Si la nueva app tambien es Flutter Web, inicializar Firebase igual que aqui:

```dart
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: 'AIzaSyAf--HSJj0iEeJ3TGr8Lmg3USbBj_3C7z0',
      appId: '1:755850617671:web:4d2f9ee9e501da8dc56262',
      messagingSenderId: '755850617671',
      projectId: 'ecorutacr-940a7',
      authDomain: 'ecorutacr-940a7.firebaseapp.com',
      storageBucket: 'ecorutacr-940a7.firebasestorage.app',
      measurementId: 'G-3PFECE5RE5',
    ),
  );

  runApp(const MyApp());
}
```

Dependencias minimas:

```yaml
dependencies:
  flutter:
    sdk: flutter
  firebase_core: ^4.7.0
  firebase_auth: ^6.4.0
  cloud_firestore: ^6.3.0
  provider: ^6.1.2
```

## Ejemplo para crear nuevas colecciones en la misma base

Ejemplo en Flutter:

```dart
import 'package:cloud_firestore/cloud_firestore.dart';

final firestore = FirebaseFirestore.instance;

Future<void> createAdminTask() async {
  await firestore.collection('admin_tasks').add({
    'title': 'Revisar usuarios nuevos',
    'status': 'pending',
    'createdAt': FieldValue.serverTimestamp(),
  });
}
```

## Coleccion administrativa nueva

No usar la coleccion `users` para el login administrativo.

Crear una coleccion nueva:

- `admins`

Campos esperados por documento:

- `uid`
- `name`
- `email`
- `role`
- `createdAt`

El registro administrativo debe pedir:

- nombre
- correo electronico
- contrasenia

Flujo sugerido:

1. Crear el usuario en `FirebaseAuth` con correo y contrasenia.
2. Crear su documento en `admins/{uid}`.
3. Guardar como minimo `uid`, `name`, `email`, `role` y `createdAt`.

Ejemplo:

```dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AdminAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<UserCredential> registerAdmin({
    required String name,
    required String email,
    required String password,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password.trim(),
    );

    final user = credential.user;
    if (user == null) {
      throw FirebaseAuthException(
        code: 'user-null',
        message: 'No se pudo crear el admin',
      );
    }

    await _firestore.collection('admins').doc(user.uid).set({
      'uid': user.uid,
      'name': name.trim(),
      'email': email.trim(),
      'role': 'super_admin',
      'createdAt': FieldValue.serverTimestamp(),
    });

    return credential;
  }
}
```

## Admin inicial quemado

El otro chat debe crear un admin inicial quemado para poder entrar de inmediato al login y dashboard.

Credenciales sugeridas:

- correo: `admin@ecoruta.com`
- contrasenia: `Admin12345!`
- nombre: `Administrador General`

Pedirle al otro chat que:

1. cree ese usuario en Firebase Auth si no existe
2. cree su documento en `admins`
3. muestre claramente las credenciales finales que dejo configuradas

Ejemplo en web JS/TS:

```ts
import { addDoc, collection, serverTimestamp } from "firebase/firestore";
import { db } from "./firebase";

export async function createAdminTask() {
  await addDoc(collection(db, "admin_tasks"), {
    title: "Revisar usuarios nuevos",
    status: "pending",
    createdAt: serverTimestamp(),
  });
}
```

## Estructura de carpetas recomendada

Montar una estructura parecida a este proyecto para mantener el mismo orden:

```text
src o lib/
  main
  firebase/
    firebase_options o firebase config
  models/
  navigation/
  providers/
  routes/
  screens/
    auth/
    dashboard/
    users/
    settings/
  services/
    auth_service
    user_service
    admin_service
  theme/
  widgets/
```

Si la nueva app es Flutter, tomar como base esta estructura actual:

- `lib/models`
- `lib/navigation`
- `lib/providers`
- `lib/routes`
- `lib/screens`
- `lib/services`
- `lib/theme`
- `lib/widgets`

## Orden de trabajo sugerido para el otro chat

1. Crear la base del proyecto web.
2. Conectar Firebase con las credenciales de este archivo.
3. Replicar la estructura de carpetas de este proyecto.
4. Crear modulo de autenticacion administrativa con coleccion `admins`.
5. Crear el admin inicial quemado.
6. Verificar que pueda leer y escribir en Firestore.
7. Construir login y dashboard rapido para administracion.

## Advertencias importantes

- Este repositorio no muestra reglas de Firestore ni archivos como `firestore.rules`.
- Antes de desplegar la nueva app, revisar reglas de seguridad en Firebase Console.
- Si la nueva app usa login web con Firebase Auth, asegurarse de autorizar su dominio en Firebase Console.
- Compartir la misma base de datos significa que cualquier escritura afecta el proyecto real `ecorutacr-940a7`.

## Instruccion directa para el otro chat de Codex

Construye una app Flutter Web administrativa conectada al proyecto Firebase `ecorutacr-940a7` usando las credenciales de este archivo. Usa la misma estructura de carpetas de este proyecto actual. No reutilices la coleccion `users` para autenticacion administrativa; crea una coleccion nueva llamada `admins` con registro por nombre, correo electronico y contrasenia, y deja creado un admin inicial quemado. El admin inicial sugerido es `admin@ecoruta.com` con contrasenia `Admin12345!` y nombre `Administrador General`. Crea login y dashboard base, y al final indica claramente las credenciales exactas con las que se puede iniciar sesion.
