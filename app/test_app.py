from app import app


def client():
    app.config["TESTING"] = True
    return app.test_client()


def test_index():
    r = client().get("/")
    assert r.status_code == 200
    assert "message" in r.get_json()


def test_health_and_ready():
    c = client()
    assert c.get("/healthz").status_code == 200
    assert c.get("/readyz").status_code == 200


def test_metrics_exposed():
    c = client()
    c.get("/")
    body = c.get("/metrics").get_data(as_text=True)
    assert "http_requests_total" in body
    assert "http_request_duration_seconds" in body
