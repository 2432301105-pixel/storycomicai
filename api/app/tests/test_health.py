"""Health endpoint tests."""

from fastapi.testclient import TestClient


def test_liveness(client: TestClient) -> None:
    response = client.get("/v1/health/live")
    assert response.status_code == 200
    payload = response.json()
    assert payload["error"] is None
    assert payload["data"]["status"] == "ok"
    assert "request_id" in payload

