EcoRutaCR
Aplicación móvil desarrollada con Flutter para exploración y recomendación de rutas ecológicas.


ARCHIVO README
Instrucciones básicas de ejecución


1. Requisitos

- Flutter instalado y configurado
- Android Studio o VS Code
- Un dispositivo Android o emulador Android
- Conexión a internet

--------------------------------------------------

2. Entrar al proyecto

Desde la terminal:

cd EcoRutaCR
cd Movil

--------------------------------------------------

3. Instalar dependencias

flutter pub get

--------------------------------------------------

4. Ejecutar la aplicación

flutter run

Si existen varios dispositivos conectados:

flutter devices
flutter run -d <device_id>

--------------------------------------------------

5. Backend de recomendaciones

La aplicación puede conectarse a un backend usando:

RECOMMENDATION_API_BASE_URL

Ejemplo:

flutter run --dart-define=RECOMMENDATION_API_BASE_URL=https://ecorutacr-7bpb.onrender.com

--------------------------------------------------

6. Compilar APK

flutter build apk

El APK generado se encontrará en:

build/app/outputs/flutter-apk/

--------------------------------------------------

7. Notas

- Todos los comandos de Flutter deben ejecutarse dentro de la carpeta "Movil".
- El proyecto ya incluye configuración de Firebase para Android.
- Se requiere conexión a internet para mapas, rutas y recomendaciones.
- El backend en Python es opcional si ya existe una URL disponible.
