"""GeoJSON katman endpoint testleri."""

from fastapi.testclient import TestClient

from main import app

client = TestClient(app)


def test_zoning_geojson_kadikoy():
    r = client.get(
        "/api/layers/zoning/geojson",
        params={
            "min_lng": 29.02,
            "min_lat": 40.98,
            "max_lng": 29.04,
            "max_lat": 41.00,
        },
    )
    assert r.status_code == 200
    data = r.json()
    assert data["type"] == "FeatureCollection"
    assert len(data["features"]) >= 1


def test_unknown_layer():
    r = client.get(
        "/api/layers/unknown/geojson",
        params={"min_lng": 29.0, "min_lat": 40.0, "max_lng": 30.0, "max_lat": 41.0},
    )
    assert r.status_code == 404
