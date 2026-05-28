from __future__ import annotations

from datetime import UTC, datetime
from pathlib import Path
from typing import Any

from fastapi import FastAPI, HTTPException, Query
from fastapi.middleware.cors import CORSMiddleware

try:
    from ml_backend.train_two_tower import (
        ARTIFACTS_DIR,
        COLLECTION_ROUTES,
        COLLECTION_SAVED,
        COLLECTION_USERS,
        FirestoreRepository,
        load_feature_store_for_inference,
        recommend_routes,
    )
except ModuleNotFoundError:
    from train_two_tower import (
        ARTIFACTS_DIR,
        COLLECTION_ROUTES,
        COLLECTION_SAVED,
        COLLECTION_USERS,
        FirestoreRepository,
        load_feature_store_for_inference,
        recommend_routes,
    )


APP_VERSION = "0.1.0"
DEFAULT_TOP_K = 5

app = FastAPI(
    title="EcoRuta Two-Tower API",
    version=APP_VERSION,
    description="API local de recomendaciones para rutas públicas.",
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=[],
    allow_origin_regex=r"^https?://(localhost|127\.0\.0\.1)(:\d+)?$",
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


def _now_iso() -> str:
    return datetime.now(UTC).isoformat()


def _resolve_state_path(state_path: str | None) -> Path:
    return Path(state_path) if state_path else ARTIFACTS_DIR / "two_tower_state.pt"


def _load_feature_store() -> tuple[FirestoreRepository, Any]:
    repository = FirestoreRepository()
    users = repository.fetch_users()
    routes = repository.fetch_public_routes()
    saved_routes = repository.fetch_saved_public_routes()
    feature_store = load_feature_store_for_inference(
        users=users,
        routes=routes,
        saved_routes=saved_routes,
        metadata_path=ARTIFACTS_DIR / "two_tower_metadata.json",
    )
    return repository, feature_store


@app.get("/health")
def health() -> dict[str, Any]:
    state_path = ARTIFACTS_DIR / "two_tower_state.pt"
    metadata_path = ARTIFACTS_DIR / "two_tower_metadata.json"
    return {
        "status": "ok",
        "service": "ecoruta-two-tower-api",
        "version": APP_VERSION,
        "timestamp": _now_iso(),
        "modelStateExists": state_path.exists(),
        "metadataExists": metadata_path.exists(),
    }


@app.get("/dataset/summary")
def dataset_summary() -> dict[str, Any]:
    try:
        repository = FirestoreRepository()
        summary = repository.smoke_test()
    except Exception as exc:
        raise HTTPException(status_code=500, detail=str(exc)) from exc

    return {
        "generatedAt": _now_iso(),
        "collections": {
            "users": COLLECTION_USERS,
            "routes": COLLECTION_ROUTES,
            "savedPublicRoutes": COLLECTION_SAVED,
        },
        **summary,
    }


@app.get("/recommendations/{user_id}")
def get_recommendations(
    user_id: str,
    top_k: int = Query(default=DEFAULT_TOP_K, ge=1, le=50),
    state_path: str | None = Query(default=None),
) -> dict[str, Any]:
    try:
        _, feature_store = _load_feature_store()
        result = recommend_routes(
            feature_store=feature_store,
            user_id=user_id,
            top_k=top_k,
            state_path=_resolve_state_path(state_path),
        )
    except RuntimeError as exc:
        raise HTTPException(status_code=400, detail=str(exc)) from exc
    except Exception as exc:
        raise HTTPException(status_code=500, detail=str(exc)) from exc

    return {
        "generatedAt": _now_iso(),
        "modelStatePath": str(_resolve_state_path(state_path)),
        **result,
    }
