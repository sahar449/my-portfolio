from flask import Flask, jsonify
from werkzeug.middleware.proxy_fix import ProxyFix
import pymysql
import os
import traceback

app = Flask(__name__)
app.wsgi_app = ProxyFix(app.wsgi_app, x_for=1)

DB_HOST = os.environ.get("DB_HOST")
DB_USER = os.environ.get("DB_USER")
DB_PASS = os.environ.get("DB_PASS")
DB_NAME = os.environ.get("DB_NAME")
DB_PORT = int(os.environ.get("DB_PORT", 3306))


def init_with_db():
    if not all([DB_HOST, DB_USER, DB_PASS, DB_NAME]):
        print("DB env vars not set - running without DB")
        return False
    try:
        print(f"Connecting to RDS: {DB_USER}@{DB_HOST}/{DB_NAME}")
        init_db()
        return True
    except Exception as e:
        print(f"DB init failed: {e}")
        traceback.print_exc()
        return False


def get_db():
    return pymysql.connect(
        host=DB_HOST,
        user=DB_USER,
        password=DB_PASS,
        database=DB_NAME,
        port=DB_PORT,
        connect_timeout=10,
        charset="utf8mb4",
        cursorclass=pymysql.cursors.DictCursor,
    )


def init_db():
    conn = get_db()
    with conn.cursor() as cur:
        cur.execute("""
            CREATE TABLE IF NOT EXISTS profile (
                id           INT PRIMARY KEY DEFAULT 1,
                name         VARCHAR(100),
                title        VARCHAR(100),
                bio          TEXT,
                github_url   VARCHAR(200),
                linkedin_url VARCHAR(200),
                photo_filename VARCHAR(100)
            )
        """)
        cur.execute("""
            CREATE TABLE IF NOT EXISTS certificates (
                id               INT AUTO_INCREMENT PRIMARY KEY,
                name             VARCHAR(100),
                issuer           VARCHAR(100),
                category         VARCHAR(50),
                verification_url VARCHAR(300),
                image_filename   VARCHAR(100)
            )
        """)
        cur.execute("""
            INSERT INTO profile (id, name, title, bio, github_url, linkedin_url, photo_filename)
            VALUES (1, 'Sahar', 'DevOps Engineer',
                    'DevOps & DevSecOps Engineer with experience in AWS, Kubernetes, Terraform, Helm, Docker, ArgoCD, and Trivy for infrastructure security scanning.',
                    'https://github.com/sahar449',
                    'https://www.linkedin.com/in/sahar-bittman-007343115/',
                    'me.jpg')
            ON DUPLICATE KEY UPDATE
                linkedin_url = VALUES(linkedin_url),
                bio          = VALUES(bio)
        """)
        cur.execute("SELECT COUNT(*) as cnt FROM certificates")
        if cur.fetchone()["cnt"] == 0:
            cur.executemany("""
                INSERT INTO certificates (name, issuer, category, verification_url, image_filename)
                VALUES (%s, %s, %s, %s, %s)
            """, [
                ("HashiCorp Terraform Associate", "HashiCorp", "Cloud & IaC",
                 "https://www.credly.com/badges/34824123-8ee9-4f3b-b24c-0043907fba7d/linked_in_profile",
                 "tf.png"),
                ("LPIC-1 Linux Administrator", "Linux Professional Institute", "Linux",
                 "https://cs.lpi.org/caf/Xamman/certification/verify/LPI000495419/tmwjm3h7bb",
                 "linux.png"),
                ("B.Sc. Software Engineering", "HIT - Holon Institute of Technology", "Academic",
                 None, "hit.jpeg"),
            ])
        else:
            cur.execute("UPDATE certificates SET image_filename='tf.png' WHERE name='HashiCorp Terraform Associate'")
            cur.execute("UPDATE certificates SET image_filename='linux.png' WHERE name='LPIC-1 Linux Administrator'")
        conn.commit()
    conn.close()


DB_AVAILABLE = init_with_db()


@app.route("/health")
def health():
    return jsonify({"status": "ok"})


@app.route("/health/db")
def health_db():
    if not DB_AVAILABLE:
        return jsonify({"status": "error", "db": "not configured"}), 503
    try:
        conn = get_db()
        conn.ping()
        conn.close()
        return jsonify({"status": "ok", "db": "connected"})
    except Exception as e:
        return jsonify({"status": "error", "db": str(e)}), 503


def get_profile_data():
    if not DB_AVAILABLE:
        return jsonify({"status": "error", "db": "not configured"}), 503
    conn = get_db()
    with conn.cursor() as cur:
        cur.execute("SELECT * FROM profile WHERE id = 1")
        row = cur.fetchone()
    conn.close()
    return jsonify(row)


def get_certificates_data():
    if not DB_AVAILABLE:
        return jsonify({"status": "error", "db": "not configured"}), 503
    conn = get_db()
    with conn.cursor() as cur:
        cur.execute("SELECT * FROM certificates ORDER BY id")
        rows = cur.fetchall()
    conn.close()
    return jsonify(rows)


@app.route("/profile")
@app.route("/api/backend/profile")
def profile():
    return get_profile_data()


@app.route("/certificates")
@app.route("/api/backend/certificates")
def certificates():
    return get_certificates_data()


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5002, debug=False)
