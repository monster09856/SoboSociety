import pytest
from httpx import ASGITransport, AsyncClient
from app.api.deps import get_db
from app.main import app

@pytest.fixture
async def client(db):
    async def override_get_db():
        yield db

    app.dependency_overrides[get_db] = override_get_db
    async with AsyncClient(
        transport=ASGITransport(app=app), base_url="http://test"
    ) as ac:
        yield ac
    app.dependency_overrides.clear()

@pytest.mark.asyncio
async def test_ai_concierge_chat_endpoint(client: AsyncClient):
    res = await client.post("/api/v1/ai/chat", json={"mesaj": "Barre dersi nedir?"})
    assert res.status_code == 200
    data = res.json()
    assert "yanit" in data
    assert "Barre" in data["yanit"]
    assert isinstance(data["oneri_sorular"], list)
