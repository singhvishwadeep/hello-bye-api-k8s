from flask import Flask, jsonify, request
import socket
import logging
import json
from datetime import datetime, timezone

VERSION = "4.0"

app = Flask(__name__)

# --------------------------------------------------
# Logging configuration
# --------------------------------------------------

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s %(levelname)s %(message)s"
)

logger = logging.getLogger("bye-api")

HOSTNAME = socket.gethostname()


# --------------------------------------------------
# Helper function for structured logs
# --------------------------------------------------

def log_event(level, event, message, **kwargs):
    log_data = {
        "timestamp": datetime.now(timezone.utc).isoformat(),
        "service": "bye-api",
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

@app.get("/bye-health")
def bye_health():

    log_event(
        "INFO",
        "health_check",
        "Bye API health check request received",
        method=request.method,
        path=request.path,
        remote_addr=request.remote_addr
    )

    try:

        log_event(
            "INFO",
            "health_check_success",
            "Bye API health check successful",
            method=request.method,
            path=request.path
        )

        return api_response(
            200,
            "healthy",
            "Bye API is healthy"
        )

    except Exception as e:

        log_event(
            "ERROR",
            "health_check_error",
            "Bye API health check failed",
            method=request.method,
            path=request.path,
            error=str(e)
        )

        return api_response(
            500,
            "unhealthy",
            "Bye API health check failed",
            error=str(e)
        )


# --------------------------------------------------
# Bye API
# --------------------------------------------------

@app.get("/bye")
def bye():

    log_event(
        "INFO",
        "bye_request",
        "Bye request received",
        method=request.method,
        path=request.path,
        remote_addr=request.remote_addr
    )

    try:

        log_event(
            "INFO",
            "bye_success",
            "Bye request processed successfully",
            method=request.method,
            path=request.path
        )

        return api_response(
            200,
            "success",
            "Bye from bye-api"
        )

    except Exception as e:

        log_event(
            "ERROR",
            "bye_error",
            "Bye request processing failed",
            method=request.method,
            path=request.path,
            error=str(e)
        )

        return api_response(
            500,
            "error",
            "Failed to process bye request",
            error=str(e)
        )


# --------------------------------------------------
# Start application
# --------------------------------------------------

if __name__ == "__main__":

    log_event(
        "INFO",
        "application_start",
        "Bye API application starting",
        host="0.0.0.0",
        port=6000
    )

    app.run(
        host="0.0.0.0",
        port=6000
    )
