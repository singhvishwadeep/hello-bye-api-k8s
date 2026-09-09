from flask import Flask, jsonify
import socket

VERSION = "1.0"

app = Flask(__name__)


@app.get("/health")
def health():
    try:
        return jsonify({
            "status": f"bye-healthy {VERSION}",
            "pod_name": socket.gethostname()
        })

    except Exception as e:
        return jsonify({
            "status": f"bye-unhealthy {VERSION}",
            "pod_name": socket.gethostname(),
            "error": str(e)
        }), 500


@app.get("/bye")
def bye():
    try:
        return jsonify({
            "status": f"bye {VERSION}",
            "pod_name": socket.gethostname()
        })

    except Exception as e:
        return jsonify({
            "status": f"bye-unhealthy {VERSION}",
            "pod_name": socket.gethostname(),
            "error": str(e)
        }), 500


app.run(host="0.0.0.0", port=6000)
