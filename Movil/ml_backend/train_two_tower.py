from __future__ import annotations

import argparse
import json
import math
import os
import random
from collections import Counter, defaultdict
from dataclasses import dataclass
from datetime import UTC, datetime
from pathlib import Path
from typing import Any


PROJECT_ROOT = Path(__file__).resolve().parents[1]
ARTIFACTS_DIR = PROJECT_ROOT / "ml_backend" / "artifacts"
COLLECTION_USERS = "users"
COLLECTION_ROUTES = "routes"
COLLECTION_SAVED = "saved_public_routes"


def _now_utc() -> datetime:
    return datetime.now(UTC)


def _as_datetime(value: Any) -> datetime | None:
    if value is None:
        return None
    if isinstance(value, datetime):
        if value.tzinfo is None:
            return value.replace(tzinfo=UTC)
        return value.astimezone(UTC)
    if hasattr(value, "to_datetime"):
        converted = value.to_datetime()
        if converted.tzinfo is None:
            return converted.replace(tzinfo=UTC)
        return converted.astimezone(UTC)
    return None


def _safe_float(value: Any) -> float:
    if value is None:
        return 0.0
    if isinstance(value, bool):
        return float(value)
    if isinstance(value, (int, float)):
        return float(value)
    try:
        return float(str(value).strip())
    except (TypeError, ValueError):
        return 0.0


def _normalize_activity(value: Any) -> str:
    raw = str(value or "").strip().lower()
    mapping = {
        "senderismo": "hiking",
        "hiking": "hiking",
        "ciclismo": "cycling",
        "cycling": "cycling",
        "running": "running",
        "correr": "running",
    }
    return mapping.get(raw, "unknown")


def _extract_region(*labels: str | None) -> str:
    for label in labels:
        if not label:
            continue
        parts = [part.strip().lower() for part in str(label).split(",") if part.strip()]
        if parts:
            return parts[-1]
    return "unknown"


def _compute_age_years(birth_date: datetime | None, reference: datetime | None = None) -> float:
    if birth_date is None:
        return 0.0
    current = reference or _now_utc()
    delta_days = max((current - birth_date).days, 0)
    return delta_days / 365.25


@dataclass(slots=True)
class UserRecord:
    uid: str
    favorite_activity: str
    region: str
    km_counter: float
    completed_routes: float
    age_years: float

    @classmethod
    def from_firestore(cls, doc_id: str, data: dict[str, Any]) -> "UserRecord":
        return cls(
            uid=doc_id,
            favorite_activity=_normalize_activity(data.get("favoriteActivity")),
            region=_extract_region(data.get("address")),
            km_counter=_safe_float(data.get("km_counter")),
            completed_routes=_safe_float(data.get("completed_routes")),
            age_years=_compute_age_years(_as_datetime(data.get("birth_date"))),
        )


@dataclass(slots=True)
class RouteRecord:
    route_id: str
    owner_id: str
    activity: str
    region: str
    distance_km: float
    duration_min: float
    elevation_gain: float
    visibility: str

    @classmethod
    def from_firestore(cls, doc_id: str, data: dict[str, Any]) -> "RouteRecord":
        start = data.get("start") or {}
        end = data.get("end") or {}
        return cls(
            route_id=doc_id,
            owner_id=str(data.get("ownerId") or "").strip(),
            activity=_normalize_activity(data.get("activityProfile")),
            region=_extract_region(start.get("label"), end.get("label")),
            distance_km=_safe_float(data.get("totalDistanceMeters")) / 1000.0,
            duration_min=_safe_float(data.get("estimatedDurationSeconds")) / 60.0,
            elevation_gain=_safe_float(data.get("elevationGainMeters")),
            visibility=str(data.get("visibility") or "").strip().lower(),
        )


@dataclass(slots=True)
class SavedRouteRecord:
    saved_by_user_id: str
    source_route_id: str
    source_owner_id: str
    activity: str
    distance_km: float
    duration_min: float
    elevation_gain: float
    region: str
    saved_at: datetime | None

    @classmethod
    def from_firestore(cls, data: dict[str, Any]) -> "SavedRouteRecord":
        start = data.get("start") or {}
        end = data.get("end") or {}
        return cls(
            saved_by_user_id=str(data.get("savedByUserId") or "").strip(),
            source_route_id=str(data.get("sourceRouteId") or "").strip(),
            source_owner_id=str(data.get("sourceOwnerId") or "").strip(),
            activity=_normalize_activity(data.get("activityProfile")),
            distance_km=_safe_float(data.get("totalDistanceMeters")) / 1000.0,
            duration_min=_safe_float(data.get("estimatedDurationSeconds")) / 60.0,
            elevation_gain=_safe_float(data.get("elevationGainMeters")),
            region=_extract_region(start.get("label"), end.get("label")),
            saved_at=_as_datetime(data.get("savedAt")),
        )


@dataclass(slots=True)
class UserAggregate:
    saved_count: int
    dominant_saved_activity: str
    favorite_saved_region: str
    avg_saved_distance_km: float
    avg_saved_duration_min: float
    avg_saved_elevation_gain: float

    @classmethod
    def empty(cls) -> "UserAggregate":
        return cls(
            saved_count=0,
            dominant_saved_activity="unknown",
            favorite_saved_region="unknown",
            avg_saved_distance_km=0.0,
            avg_saved_duration_min=0.0,
            avg_saved_elevation_gain=0.0,
        )


@dataclass(slots=True)
class TrainingExample:
    user_id: str
    route_id: str
    label: float


class FirestoreRepository:
    def __init__(self) -> None:
        from google.cloud.firestore_v1.base_query import FieldFilter

        self._field_filter_cls = FieldFilter
        self._db = self._initialize_firestore()

    @staticmethod
    def _initialize_firestore():
        try:
            import firebase_admin
            from firebase_admin import credentials, firestore
            from google.auth.exceptions import DefaultCredentialsError
        except ImportError as exc:
            raise RuntimeError(
                "Falta la dependencia 'firebase-admin'. Ejecuta: "
                "pip install -r ml_backend/requirements.txt"
            ) from exc

        if not firebase_admin._apps:
            credential_path = (
                os.getenv("FIREBASE_SERVICE_ACCOUNT_PATH")
                or os.getenv("GOOGLE_APPLICATION_CREDENTIALS")
            )
            if credential_path:
                cred = credentials.Certificate(credential_path)
                firebase_admin.initialize_app(cred)
            else:
                firebase_admin.initialize_app()

        try:
            return firestore.client()
        except DefaultCredentialsError as exc:
            raise RuntimeError(
                "No se encontraron credenciales de admin para Firestore. "
                "Descarga un service account JSON desde Firebase Console y "
                "define FIREBASE_SERVICE_ACCOUNT_PATH o "
                "GOOGLE_APPLICATION_CREDENTIALS apuntando a ese archivo."
            ) from exc

    def fetch_users(self) -> dict[str, UserRecord]:
        documents = self._db.collection(COLLECTION_USERS).stream()
        users: dict[str, UserRecord] = {}
        for doc in documents:
            data = doc.to_dict() or {}
            users[doc.id] = UserRecord.from_firestore(doc.id, data)
        return users

    def fetch_public_routes(self) -> dict[str, RouteRecord]:
        query = self._db.collection(COLLECTION_ROUTES).where(
            filter=self._field_filter_cls("visibility", "==", "public")
        )
        routes: dict[str, RouteRecord] = {}
        for doc in query.stream():
            data = doc.to_dict() or {}
            route = RouteRecord.from_firestore(doc.id, data)
            routes[doc.id] = route
        return routes

    def fetch_saved_public_routes(self) -> list[SavedRouteRecord]:
        documents = self._db.collection(COLLECTION_SAVED).stream()
        saved_routes: list[SavedRouteRecord] = []
        for doc in documents:
            data = doc.to_dict() or {}
            saved_routes.append(SavedRouteRecord.from_firestore(data))
        return saved_routes

    def smoke_test(self) -> dict[str, Any]:
        users = self.fetch_users()
        routes = self.fetch_public_routes()
        saved_routes = self.fetch_saved_public_routes()
        return {
            "project_root": str(PROJECT_ROOT),
            "users_count": len(users),
            "public_routes_count": len(routes),
            "saved_public_routes_count": len(saved_routes),
            "sample_user_ids": sorted(users.keys())[:5],
            "sample_route_ids": sorted(routes.keys())[:5],
            "sample_saved_pairs": [
                {
                    "userId": record.saved_by_user_id,
                    "routeId": record.source_route_id,
                }
                for record in saved_routes[:5]
            ],
        }


class FeatureStore:
    def __init__(
        self,
        users: dict[str, UserRecord],
        routes: dict[str, RouteRecord],
        saved_routes: list[SavedRouteRecord],
        user_activity_vocab: dict[str, int] | None = None,
        route_activity_vocab: dict[str, int] | None = None,
        region_vocab: dict[str, int] | None = None,
    ) -> None:
        self.users = users
        self.routes = routes
        self.saved_routes = saved_routes
        self.user_aggregates = self._build_user_aggregates(saved_routes)
        self.user_activity_vocab = user_activity_vocab or self._build_vocab(
            [user.favorite_activity for user in users.values()]
            + [agg.dominant_saved_activity for agg in self.user_aggregates.values()]
        )
        self.region_vocab = region_vocab or self._build_vocab(
            [user.region for user in users.values()]
            + [route.region for route in routes.values()]
            + [agg.favorite_saved_region for agg in self.user_aggregates.values()]
        )
        self.route_activity_vocab = route_activity_vocab or self._build_vocab(
            [route.activity for route in routes.values()]
        )

    @staticmethod
    def _build_vocab(values: list[str]) -> dict[str, int]:
        normalized = ["unknown"]
        normalized.extend(value for value in values if value)
        ordered = sorted(set(normalized))
        return {value: idx for idx, value in enumerate(ordered)}

    @staticmethod
    def _build_user_aggregates(
        saved_routes: list[SavedRouteRecord],
    ) -> dict[str, UserAggregate]:
        by_user: dict[str, list[SavedRouteRecord]] = defaultdict(list)
        for item in saved_routes:
            if item.saved_by_user_id and item.source_route_id:
                by_user[item.saved_by_user_id].append(item)

        aggregates: dict[str, UserAggregate] = {}
        for user_id, items in by_user.items():
            activities = Counter(item.activity or "unknown" for item in items)
            regions = Counter(item.region or "unknown" for item in items)
            count = len(items)
            aggregates[user_id] = UserAggregate(
                saved_count=count,
                dominant_saved_activity=activities.most_common(1)[0][0],
                favorite_saved_region=regions.most_common(1)[0][0],
                avg_saved_distance_km=sum(item.distance_km for item in items) / count,
                avg_saved_duration_min=sum(item.duration_min for item in items) / count,
                avg_saved_elevation_gain=sum(item.elevation_gain for item in items) / count,
            )
        return aggregates

    def get_user_aggregate(self, user_id: str) -> UserAggregate:
        return self.user_aggregates.get(user_id, UserAggregate.empty())

    @staticmethod
    def _normalize_log(value: float) -> float:
        return math.log1p(max(value, 0.0))

    @staticmethod
    def _normalize_age(value: float) -> float:
        if value <= 0:
            return 0.0
        return min(value / 100.0, 1.0)

    def user_feature_payload(self, user_id: str) -> dict[str, Any]:
        user = self.users[user_id]
        aggregate = self.get_user_aggregate(user_id)
        return {
            "favorite_activity_idx": self.user_activity_vocab.get(
                user.favorite_activity, self.user_activity_vocab["unknown"]
            ),
            "region_idx": self.region_vocab.get(user.region, self.region_vocab["unknown"]),
            "dominant_saved_activity_idx": self.user_activity_vocab.get(
                aggregate.dominant_saved_activity, self.user_activity_vocab["unknown"]
            ),
            "favorite_saved_region_idx": self.region_vocab.get(
                aggregate.favorite_saved_region, self.region_vocab["unknown"]
            ),
            "numeric_features": [
                self._normalize_age(user.age_years),
                self._normalize_log(user.km_counter),
                self._normalize_log(user.completed_routes),
                self._normalize_log(aggregate.saved_count),
                self._normalize_log(aggregate.avg_saved_distance_km),
                self._normalize_log(aggregate.avg_saved_duration_min),
                self._normalize_log(aggregate.avg_saved_elevation_gain),
            ],
        }

    def route_feature_payload(self, route_id: str) -> dict[str, Any]:
        route = self.routes[route_id]
        return {
            "activity_idx": self.route_activity_vocab.get(
                route.activity, self.route_activity_vocab["unknown"]
            ),
            "region_idx": self.region_vocab.get(route.region, self.region_vocab["unknown"]),
            "numeric_features": [
                self._normalize_log(route.distance_km),
                self._normalize_log(route.duration_min),
                self._normalize_log(route.elevation_gain),
            ],
        }

    def build_training_examples(self, negative_samples: int) -> list[TrainingExample]:
        saved_route_ids_by_user: dict[str, set[str]] = defaultdict(set)
        positives: list[TrainingExample] = []
        for record in self.saved_routes:
            if record.saved_by_user_id not in self.users:
                continue
            if record.source_route_id not in self.routes:
                continue
            saved_route_ids_by_user[record.saved_by_user_id].add(record.source_route_id)
            positives.append(
                TrainingExample(
                    user_id=record.saved_by_user_id,
                    route_id=record.source_route_id,
                    label=1.0,
                )
            )

        all_public_route_ids = sorted(self.routes.keys())
        negatives: list[TrainingExample] = []
        rng = random.Random(42)

        for example in positives:
            excluded = saved_route_ids_by_user[example.user_id]
            candidate_ids = [
                route_id for route_id in all_public_route_ids if route_id not in excluded
            ]
            sample_size = min(negative_samples, len(candidate_ids))
            for route_id in rng.sample(candidate_ids, sample_size):
                negatives.append(
                    TrainingExample(
                        user_id=example.user_id,
                        route_id=route_id,
                        label=0.0,
                    )
                )

        combined = positives + negatives
        rng.shuffle(combined)
        return combined

    def metadata(self) -> dict[str, Any]:
        return {
            "user_activity_vocab": self.user_activity_vocab,
            "route_activity_vocab": self.route_activity_vocab,
            "region_vocab": self.region_vocab,
        }


def _lazy_import_torch():
    try:
        import torch
        from torch import nn
        from torch.utils.data import DataLoader, Dataset
    except ImportError as exc:
        raise RuntimeError(
            "Falta la dependencia 'torch'. Ejecuta: "
            "pip install -r ml_backend/requirements.txt"
        ) from exc
    return torch, nn, DataLoader, Dataset


def _build_two_tower_model(feature_store: FeatureStore):
    torch, nn, _, _ = _lazy_import_torch()
    embedding_dim = 8
    hidden_dim = 32
    projection_dim = 16

    class TwoTowerModel(nn.Module):
        def __init__(self, store: FeatureStore) -> None:
            super().__init__()
            self.user_activity_embedding = nn.Embedding(
                len(store.user_activity_vocab), embedding_dim
            )
            self.region_embedding = nn.Embedding(len(store.region_vocab), embedding_dim)
            self.route_activity_embedding = nn.Embedding(
                len(store.route_activity_vocab), embedding_dim
            )

            user_input_dim = (embedding_dim * 4) + 7
            route_input_dim = (embedding_dim * 2) + 3

            self.user_tower = nn.Sequential(
                nn.Linear(user_input_dim, hidden_dim),
                nn.ReLU(),
                nn.Linear(hidden_dim, projection_dim),
            )
            self.route_tower = nn.Sequential(
                nn.Linear(route_input_dim, hidden_dim),
                nn.ReLU(),
                nn.Linear(hidden_dim, projection_dim),
            )

        def encode_user(self, batch: dict[str, Any]):
            favorite_activity = self.user_activity_embedding(batch["favorite_activity_idx"])
            user_region = self.region_embedding(batch["user_region_idx"])
            dominant_saved_activity = self.user_activity_embedding(
                batch["dominant_saved_activity_idx"]
            )
            favorite_saved_region = self.region_embedding(
                batch["favorite_saved_region_idx"]
            )
            user_input = torch.cat(
                [
                    favorite_activity,
                    user_region,
                    dominant_saved_activity,
                    favorite_saved_region,
                    batch["user_numeric"],
                ],
                dim=1,
            )
            return self.user_tower(user_input)

        def encode_route(self, batch: dict[str, Any]):
            route_activity = self.route_activity_embedding(batch["route_activity_idx"])
            route_region = self.region_embedding(batch["route_region_idx"])
            route_input = torch.cat(
                [route_activity, route_region, batch["route_numeric"]], dim=1
            )
            return self.route_tower(route_input)

        def forward(self, batch: dict[str, Any]):
            user_embedding = self.encode_user(batch)
            route_embedding = self.encode_route(batch)
            logits = (user_embedding * route_embedding).sum(dim=1)
            return logits

    return torch, nn, TwoTowerModel(feature_store)


def train_model(feature_store: FeatureStore, examples: list[TrainingExample], epochs: int) -> dict[str, Any]:
    torch, nn, DataLoader, Dataset = _lazy_import_torch()

    class InteractionDataset(Dataset):
        def __init__(self, store: FeatureStore, rows: list[TrainingExample]) -> None:
            self.store = store
            self.rows = rows

        def __len__(self) -> int:
            return len(self.rows)

        def __getitem__(self, index: int) -> dict[str, Any]:
            row = self.rows[index]
            user_features = self.store.user_feature_payload(row.user_id)
            route_features = self.store.route_feature_payload(row.route_id)
            return {
                "favorite_activity_idx": user_features["favorite_activity_idx"],
                "user_region_idx": user_features["region_idx"],
                "dominant_saved_activity_idx": user_features["dominant_saved_activity_idx"],
                "favorite_saved_region_idx": user_features["favorite_saved_region_idx"],
                "user_numeric": user_features["numeric_features"],
                "route_activity_idx": route_features["activity_idx"],
                "route_region_idx": route_features["region_idx"],
                "route_numeric": route_features["numeric_features"],
                "label": row.label,
            }

    def collate(items: list[dict[str, Any]]) -> dict[str, Any]:
        return {
            "favorite_activity_idx": torch.tensor(
                [item["favorite_activity_idx"] for item in items], dtype=torch.long
            ),
            "user_region_idx": torch.tensor(
                [item["user_region_idx"] for item in items], dtype=torch.long
            ),
            "dominant_saved_activity_idx": torch.tensor(
                [item["dominant_saved_activity_idx"] for item in items], dtype=torch.long
            ),
            "favorite_saved_region_idx": torch.tensor(
                [item["favorite_saved_region_idx"] for item in items], dtype=torch.long
            ),
            "user_numeric": torch.tensor(
                [item["user_numeric"] for item in items], dtype=torch.float32
            ),
            "route_activity_idx": torch.tensor(
                [item["route_activity_idx"] for item in items], dtype=torch.long
            ),
            "route_region_idx": torch.tensor(
                [item["route_region_idx"] for item in items], dtype=torch.long
            ),
            "route_numeric": torch.tensor(
                [item["route_numeric"] for item in items], dtype=torch.float32
            ),
            "label": torch.tensor([item["label"] for item in items], dtype=torch.float32),
        }

    dataset = InteractionDataset(feature_store, examples)
    dataloader = DataLoader(dataset, batch_size=min(32, max(len(dataset), 1)), shuffle=True, collate_fn=collate)

    _, _, model = _build_two_tower_model(feature_store)
    optimizer = torch.optim.Adam(model.parameters(), lr=1e-3)
    loss_fn = nn.BCEWithLogitsLoss()

    history: list[float] = []
    model.train()
    for epoch in range(epochs):
        epoch_loss = 0.0
        batches = 0
        for batch in dataloader:
            optimizer.zero_grad()
            logits = model(batch)
            loss = loss_fn(logits, batch["label"])
            loss.backward()
            optimizer.step()
            epoch_loss += float(loss.detach().item())
            batches += 1
        average_loss = epoch_loss / max(batches, 1)
        history.append(average_loss)
        print(f"[train] epoch={epoch + 1}/{epochs} loss={average_loss:.4f}")

    ARTIFACTS_DIR.mkdir(parents=True, exist_ok=True)
    state_path = ARTIFACTS_DIR / "two_tower_state.pt"
    metadata_path = ARTIFACTS_DIR / "two_tower_metadata.json"

    torch.save(model.state_dict(), state_path)
    metadata = {
        "trainedAt": _now_utc().isoformat(),
        "epochs": epochs,
        "exampleCount": len(examples),
        "lossHistory": history,
        **feature_store.metadata(),
    }
    metadata_path.write_text(json.dumps(metadata, indent=2), encoding="utf-8")

    return {
        "state_path": str(state_path),
        "metadata_path": str(metadata_path),
        "history": history,
    }


def recommend_routes(
    feature_store: FeatureStore,
    user_id: str,
    top_k: int,
    state_path: Path | None = None,
) -> dict[str, Any]:
    if user_id not in feature_store.users:
        raise RuntimeError(f"El usuario '{user_id}' no existe en la colección users.")

    torch, _, model = _build_two_tower_model(feature_store)
    selected_state_path = state_path or (ARTIFACTS_DIR / "two_tower_state.pt")
    if not selected_state_path.exists():
        raise RuntimeError(
            f"No se encontró el modelo entrenado en '{selected_state_path}'. "
            "Ejecuta primero --train."
        )

    model.load_state_dict(torch.load(selected_state_path, map_location="cpu"))
    model.eval()

    saved_route_ids = {
        record.source_route_id
        for record in feature_store.saved_routes
        if record.saved_by_user_id == user_id
    }
    own_user_id = user_id

    user_features = feature_store.user_feature_payload(user_id)
    user_batch = {
        "favorite_activity_idx": torch.tensor(
            [user_features["favorite_activity_idx"]], dtype=torch.long
        ),
        "user_region_idx": torch.tensor([user_features["region_idx"]], dtype=torch.long),
        "dominant_saved_activity_idx": torch.tensor(
            [user_features["dominant_saved_activity_idx"]], dtype=torch.long
        ),
        "favorite_saved_region_idx": torch.tensor(
            [user_features["favorite_saved_region_idx"]], dtype=torch.long
        ),
        "user_numeric": torch.tensor(
            [user_features["numeric_features"]], dtype=torch.float32
        ),
    }

    with torch.no_grad():
        user_embedding = model.encode_user(user_batch)
        recommendations: list[dict[str, Any]] = []
        for route_id, route in feature_store.routes.items():
            if route.owner_id == own_user_id:
                continue
            if route_id in saved_route_ids:
                continue
            route_features = feature_store.route_feature_payload(route_id)
            route_batch = {
                "route_activity_idx": torch.tensor(
                    [route_features["activity_idx"]], dtype=torch.long
                ),
                "route_region_idx": torch.tensor(
                    [route_features["region_idx"]], dtype=torch.long
                ),
                "route_numeric": torch.tensor(
                    [route_features["numeric_features"]], dtype=torch.float32
                ),
            }
            route_embedding = model.encode_route(route_batch)
            score = float((user_embedding * route_embedding).sum(dim=1).item())
            recommendations.append(
                {
                    "routeId": route_id,
                    "ownerId": route.owner_id,
                    "activityProfile": route.activity,
                    "region": route.region,
                    "distanceKm": round(route.distance_km, 3),
                    "durationMin": round(route.duration_min, 1),
                    "elevationGainMeters": round(route.elevation_gain, 1),
                    "score": round(score, 6),
                }
            )

    recommendations.sort(key=lambda item: item["score"], reverse=True)
    return {
        "userId": user_id,
        "savedRouteCount": len(saved_route_ids),
        "candidateCount": len(recommendations),
        "topRecommendations": recommendations[:top_k],
    }


def load_feature_store_for_inference(
    users: dict[str, UserRecord],
    routes: dict[str, RouteRecord],
    saved_routes: list[SavedRouteRecord],
    metadata_path: Path | None = None,
) -> FeatureStore:
    selected_metadata_path = metadata_path or (ARTIFACTS_DIR / "two_tower_metadata.json")
    if not selected_metadata_path.exists():
        return FeatureStore(users, routes, saved_routes)

    metadata = json.loads(selected_metadata_path.read_text(encoding="utf-8"))
    return FeatureStore(
        users,
        routes,
        saved_routes,
        user_activity_vocab={
            str(key): int(value)
            for key, value in (metadata.get("user_activity_vocab") or {}).items()
        },
        route_activity_vocab={
            str(key): int(value)
            for key, value in (metadata.get("route_activity_vocab") or {}).items()
        },
        region_vocab={
            str(key): int(value)
            for key, value in (metadata.get("region_vocab") or {}).items()
        },
    )


def _parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Entrena un recomendador two-tower con Firestore."
    )
    parser.add_argument("--smoke-test", action="store_true", help="Solo prueba conexión y conteos.")
    parser.add_argument("--train", action="store_true", help="Entrena el modelo.")
    parser.add_argument("--recommend", action="store_true", help="Genera recomendaciones para un usuario.")
    parser.add_argument("--epochs", type=int, default=20, help="Cantidad de épocas.")
    parser.add_argument(
        "--negative-samples",
        type=int,
        default=3,
        help="Cantidad de rutas negativas muestreadas por positivo.",
    )
    parser.add_argument("--user-id", type=str, help="UID del usuario a recomendar.")
    parser.add_argument("--top-k", type=int, default=5, help="Cantidad de rutas a recomendar.")
    parser.add_argument(
        "--state-path",
        type=str,
        help="Ruta opcional al archivo .pt del modelo entrenado.",
    )
    return parser.parse_args()


def main() -> int:
    args = _parse_args()
    if not args.smoke_test and not args.train and not args.recommend:
        print("Usa --smoke-test, --train o --recommend.")
        return 1

    repository = FirestoreRepository()

    if args.smoke_test:
        result = repository.smoke_test()
        print(json.dumps(result, indent=2, ensure_ascii=False))
        return 0

    users = repository.fetch_users()
    routes = repository.fetch_public_routes()
    saved_routes = repository.fetch_saved_public_routes()

    if args.recommend:
        if not args.user_id:
            print("Debes indicar --user-id para usar --recommend.")
            return 1
        feature_store = load_feature_store_for_inference(users, routes, saved_routes)
        result = recommend_routes(
            feature_store,
            args.user_id,
            args.top_k,
            Path(args.state_path) if args.state_path else None,
        )
        print(json.dumps(result, indent=2, ensure_ascii=False))
        return 0

    feature_store = FeatureStore(users, routes, saved_routes)
    examples = feature_store.build_training_examples(args.negative_samples)
    if not examples:
        print(
            "No hay suficientes ejemplos de entrenamiento. "
            "Asegúrate de tener documentos en 'saved_public_routes'."
        )
        return 1

    result = train_model(feature_store, examples, args.epochs)
    print(json.dumps(result, indent=2, ensure_ascii=False))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
