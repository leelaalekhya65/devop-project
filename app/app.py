"""Small demo service used by the DevOps platform.

Exposes:
  /            - JSON hello
  /healthz     - liveness probe
  /readyz      - readiness probe
  /work        - simulates work (random latency, occasional errors) so dashboards have data
  /metrics     - Prometheus metrics
Logs are written as JSON lines to stdout so Promtail/Loki can parse them.
"""
import json
import logging
import os
import random
import sys
import time

from flask import Flask, Response, jsonify, request
from prometheus_client import CONTENT_TYPE_LATEST, Counter, Histogram, generate_latest

APP_VERSION = os.getenv("APP_VERSION", "dev")
APP_ENV = os.getenv("APP_ENV", "local")


class JsonFormatter(logging.Formatter):
    def format(self, record):
        payload = {
            "ts": self.formatTime(record, "%Y-%m-%dT%H:%M:%S%z"),
            "level": record.levelname,
            "msg": record.getMessage(),
            "service": "webapp",
            "version": APP_VERSION,
            "env": APP_ENV,
        }
        payload.update(getattr(record, "extra_fields", {}))
        return json.dumps(payload)


handler = logging.StreamHandler(sys.stdout)
handler.setFormatter(JsonFormatter())
log = logging.getLogger("webapp")
log.setLevel(logging.INFO)
log.addHandler(handler)
log.propagate = False

app = Flask(__name__)

REQUESTS = Counter("http_requests_total", "Total HTTP requests", ["method", "path", "status"])
LATENCY = Histogram("http_request_duration_seconds", "Request latency", ["path"])


@app.before_request
def _start_timer():
    request._start = time.time()


@app.after_request
def _record(resp):
    elapsed = time.time() - getattr(request, "_start", time.time())
    if request.path != "/metrics":
        REQUESTS.labels(request.method, request.path, resp.status_code).inc()
        LATENCY.labels(request.path).observe(elapsed)
        log.info(
            "request",
            extra={"extra_fields": {
                "method": request.method,
                "path": request.path,
                "status": resp.status_code,
                "duration_ms": round(elapsed * 1000, 2),
            }},
        )
    return resp


@app.get("/")
def index():
    return jsonify(message="Hello from the DevOps platform", version=APP_VERSION, env=APP_ENV)


@app.get("/healthz")
def healthz():
    return jsonify(status="ok")


@app.get("/readyz")
def readyz():
    return jsonify(status="ready")


@app.get("/work")
def work():
    time.sleep(random.uniform(0.01, 0.4))
    if random.random() < 0.1:
        log.error("simulated failure", extra={"extra_fields": {"path": "/work"}})
        return jsonify(error="simulated failure"), 500
    return jsonify(result="done")


@app.get("/metrics")
def metrics():
    return Response(generate_latest(), mimetype=CONTENT_TYPE_LATEST)


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=int(os.getenv("PORT", "8080")))
