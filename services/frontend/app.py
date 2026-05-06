from flask import Flask, render_template, send_file, jsonify
from werkzeug.middleware.proxy_fix import ProxyFix
import os

app = Flask(__name__)
app.wsgi_app = ProxyFix(app.wsgi_app, x_for=1)

IMAGES_DIR = os.path.dirname(__file__)


@app.route("/health")
def health():
    return jsonify({"status": "ok"})


@app.route("/")
def index():
    return render_template("index.html")


@app.route("/images/<filename>")
def get_image(filename):
    filepath = os.path.join(IMAGES_DIR, filename)
    if not os.path.exists(filepath):
        return jsonify({"error": "Image not found"}), 404
    return send_file(filepath)


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000, debug=False)
