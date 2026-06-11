from qdrant_client import QdrantClient
from qdrant_client.http.exceptions import UnexpectedResponse
from qdrant_client.models import (
    Distance,
    FieldCondition,
    Filter,
    MatchValue,
    PointIdsList,
    PointStruct,
    VectorParams,
)

from app.core.config import Settings, get_settings
from app.models.career import Career
from app.services.embedding_service import build_career_embedding_text, text_to_embedding


class QdrantService:
    def __init__(self, settings: Settings | None = None) -> None:
        self.settings = settings or get_settings()

    def get_client(self) -> QdrantClient:
        return QdrantClient(
            host=self.settings.qdrant_host,
            port=self.settings.qdrant_port,
            api_key=self.settings.qdrant_api_key or None,
        )

    def is_available(self) -> bool:
        try:
            self.get_client().get_collections()
            return True
        except Exception:
            return False

    def ensure_collection(self) -> None:
        client = self.get_client()
        collection_name = self.settings.qdrant_collection_careers
        existing = {item.name for item in client.get_collections().collections}

        if collection_name not in existing:
            client.create_collection(
                collection_name=collection_name,
                vectors_config=VectorParams(
                    size=self.settings.qdrant_vector_size,
                    distance=Distance.COSINE,
                ),
            )

    def recreate_collection(self) -> None:
        client = self.get_client()
        collection_name = self.settings.qdrant_collection_careers
        try:
            client.delete_collection(collection_name=collection_name)
        except (UnexpectedResponse, Exception):
            pass
        self.ensure_collection()

    def upsert_careers(self, careers: list[Career]) -> int:
        if not careers:
            return 0

        client = self.get_client()
        collection_name = self.settings.qdrant_collection_careers
        points = [
            PointStruct(
                id=career.id,
                vector=text_to_embedding(build_career_embedding_text(career)),
                payload={
                    "career_id": career.id,
                    "name": career.name,
                    "area": career.area,
                    "riasec_profile": career.riasec_profile,
                    "degree_type": career.degree_type.value,
                    "institution_type": career.institution_type.value,
                    "status": career.status.value,
                },
            )
            for career in careers
        ]
        client.upsert(collection_name=collection_name, points=points)
        return len(points)

    def delete_career_points(self, career_ids: list[int]) -> None:
        if not career_ids:
            return

        client = self.get_client()
        collection_name = self.settings.qdrant_collection_careers
        client.delete(
            collection_name=collection_name,
            points_selector=PointIdsList(points=career_ids),
        )

    def search_careers(
        self,
        query_text: str,
        *,
        limit: int = 10,
    ) -> list[dict]:
        client = self.get_client()
        collection_name = self.settings.qdrant_collection_careers
        query_vector = text_to_embedding(query_text)

        results = client.search(
            collection_name=collection_name,
            query_vector=query_vector,
            limit=limit,
            query_filter=Filter(
                must=[
                    FieldCondition(
                        key="status",
                        match=MatchValue(value="ACTIVE"),
                    )
                ]
            ),
        )

        items: list[dict] = []
        for hit in results:
            payload = hit.payload or {}
            items.append(
                {
                    "career_id": int(payload.get("career_id", hit.id)),
                    "name": payload.get("name", ""),
                    "area": payload.get("area", ""),
                    "riasec_profile": payload.get("riasec_profile", ""),
                    "degree_type": payload.get("degree_type", ""),
                    "institution_type": payload.get("institution_type", ""),
                    "score": float(hit.score or 0.0),
                    "qdrant_score": round(max(float(hit.score or 0.0), 0.0) * 100, 2),
                    "source": "qdrant",
                }
            )
        return items
