from flask import Flask, jsonify, request
import socket
import logging
import json
from datetime import datetime, timezone

VERSION = "1.0"

app = Flask(__name__)

# --------------------------------------------------
# Logging configuration
# --------------------------------------------------

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s %(levelname)s %(message)s"
)

logger = logging.getLogger("hello-api")

HOSTNAME = socket.gethostname()


# --------------------------------------------------
# Helper function for structured logs
# --------------------------------------------------

def log_event(level, event, message, **kwargs):
    log_data = {
        "timestamp": datetime.now(timezone.utc).isoformat(),
        "service": "hello-api",
        "version": VERSION,
        "pod_name": HOSTNAME,
        "event": event,
        "message": message,
        **kwargs
    }

    log_message = json.dumps(log_data)

    if level == "INFO":
        logger.info(log_message)

    elif level == "WARNING":
        logger.warning(log_message)

    elif level == "ERROR":
        logger.error(log_message)


# --------------------------------------------------
# Helper function for API responses
# --------------------------------------------------

def api_response(http_code, status, message, **kwargs):
    response = {
        "http_code": http_code,
        "status": status,
        "message": message,
        "version": VERSION,
        "pod_name": HOSTNAME,
        "timestamp": datetime.now(timezone.utc).isoformat(),
        **kwargs
    }

    return jsonify(response), http_code


# --------------------------------------------------
# Health API
# --------------------------------------------------

@app.get("/hello-health")
def hello_health():

    log_event(
        "INFO",
        "health_check",
        "Hello API health check request received",
        method=request.method,
        path=request.path,
        remote_addr=request.remote_addr
    )

    try:

        log_event(
            "INFO",
            "health_check_success",
            "Hello API health check successful",
            method=request.method,
            path=request.path
        )

        return api_response(
            200,
            "healthy",
            "Hello API is healthy"
        )

    except Exception as e:

        log_event(
            "ERROR",
            "health_check_error",
            "Hello API health check failed",
            method=request.method,
            path=request.path,
            error=str(e)
        )

        return api_response(
            500,
            "unhealthy",
            "Hello API health check failed",
            error=str(e)
        )

# --------------------------------------------------
# Hello API
# --------------------------------------------------

@app.get("/hello")
def hello():

    log_event(
        "INFO",
        "hello_request",
        "Hello request received",
        method=request.method,
        path=request.path,
        remote_addr=request.remote_addr
    )

    try:

        log_event(
            "INFO",
            "hello_success",
            "Hello request processed successfully",
            method=request.method,
            path=request.path
        )

        return api_response(
            200,
            "success",
            "Hello from hello-api"
        )

    except Exception as e:

        log_event(
            "ERROR",
            "hello_error",
            "Hello request processing failed",
            method=request.method,
            path=request.path,
            error=str(e)
        )

        return api_response(
            500,
            "error",
            "Failed to process hello request",
            error=str(e)
        )


# --------------------------------------------------
# Start application
# --------------------------------------------------

if __name__ == "__main__":

    log_event(
        "INFO",
        "application_start",
        "Hello API application starting",
        host="0.0.0.0",
        port=5000
    )

    app.run(
        host="0.0.0.0",
        port=5000
    )
