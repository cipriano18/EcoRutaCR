# Two-Tower Training Backend

Backend local en Python para entrenar un recomendador `two-tower` con las colecciones actuales de EcoRuta:

- `users`
- `routes`
- `saved_public_routes`

## Requisitos

1. Python 3.12 o compatible
2. Dependencias:

```bash
pip install -r ml_backend/requirements.txt
```

3. Credencial de admin para Firestore

Este backend necesita leer datos de varios usuarios, por lo que no alcanza con el API key de Flutter ni con un login normal de Firebase. Necesitas un `service account JSON`.

Variables aceptadas:

- `FIREBASE_SERVICE_ACCOUNT_PATH`
- `GOOGLE_APPLICATION_CREDENTIALS`

Ejemplo en PowerShell:

```powershell
$env:FIREBASE_SERVICE_ACCOUNT_PATH="C:\ruta\a\serviceAccountKey.json"
```

## Probar conexión

```bash
python ml_backend/train_two_tower.py --smoke-test
```

Esto:

- inicializa Firestore
- cuenta usuarios
- cuenta rutas públicas
- cuenta relaciones en `saved_public_routes`
- imprime una muestra corta para confirmar que la base carga

## Entrenar el modelo

```bash
python ml_backend/train_two_tower.py --train --epochs 25 --negative-samples 3
```

## Pedir recomendaciones

```bash
python ml_backend/train_two_tower.py --recommend --user-id TU_UID --top-k 5
```

Ejemplo:

```bash
python ml_backend/train_two_tower.py --recommend --user-id 2rZLSzbRTdbFGj72oftI910UNN22 --top-k 5
```

## Levantar API local con FastAPI

Instala dependencias:

```bash
pip install -r ml_backend/requirements.txt
```

Levanta el servidor desde la raíz del proyecto:

```bash
uvicorn ml_backend.predict_api:app --reload
```

Si estás parado dentro de la carpeta `ml_backend`, usa:

```bash
uvicorn predict_api:app --reload
```

Endpoints:

- `GET /health`
- `GET /dataset/summary`
- `GET /recommendations/{userId}?top_k=5`

Ejemplo:

```bash
http://127.0.0.1:8000/recommendations/2rZLSzbRTdbFGj72oftI910UNN22?top_k=5
```

Desde Flutter:

- Android emulator: `http://10.0.2.2:8000`
- iOS simulator / desktop: `http://127.0.0.1:8000`
- celular físico en la misma red: `http://IP_DE_TU_PC:8000`

Archivos generados:

- `ml_backend/artifacts/two_tower_state.pt`
- `ml_backend/artifacts/two_tower_metadata.json`

## Qué aprende este modelo

### User tower

Usa señales del perfil y de las rutas públicas guardadas por el usuario:

- `favoriteActivity`
- región derivada de `address`
- edad aproximada desde `birth_date`
- `km_counter`
- `completed_routes`
- actividad dominante entre rutas guardadas
- distancia, duración y elevación promedio de rutas guardadas
- cantidad de rutas públicas guardadas

### Route tower

Usa atributos propios de la ruta pública:

- `activityProfile`
- región derivada de `start.label` / `end.label`
- distancia
- duración
- elevación

### Positivos y negativos

- positivos: documentos reales de `saved_public_routes`
- negativos: rutas públicas que ese usuario no ha guardado

## Notas

- El script no toca tu base de datos; solo lee para entrenar.
- `--smoke-test` no necesita `torch` en tiempo de ejecución, pero `--train` sí.
