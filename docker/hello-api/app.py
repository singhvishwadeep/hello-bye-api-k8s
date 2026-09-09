from flask import Flask, jsonify
import socket

VERSION = "1.0"

app = Flask(__name__)


@app.get("/health")
def health():
    try:
        return jsonify({
            "status": f"hello-healthy {VERSION}",
            "pod_name": socket.gethostname()
        })

    except Exception as e:
        return jsonify({
            "status": f"hello-unhealthy {VERSION}",
            "pod_name": socket.gethostname(),
            "error": str(e)
        }), 500


@app.get("/hello")
def hello():
    try:
        return jsonify({
            "status": f"hello {VERSION}",
            "pod_name": socket.gethostname()
        })

    except Exception as e:
        return jsonify({
            "status": f"hello-unhealthy {VERSION}",
            "pod_name": socket.gethostname(),
            "error": str(e)
        }), 500


app.run(host="0.0.0.0", port=5000)
