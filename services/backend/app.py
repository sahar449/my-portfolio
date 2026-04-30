from flask import Flask, jsonify
import pymysql
import os
import time
import traceback

app = Flask(__name__)

SECRET_PATH = "/mnt/rds-secret"
DB_PORT = 3306
DB_HOST = DB_USER = DB_PASS = DB_NAME = None


def wait_for_secrets(timeout=60):
    required = ["host", "username", "password", "dbname"]
    start = time.time()
    while time.time() - start < timeout:
        if all(os.path.exists(os.path.join(SECRET_PATH, f)) for f in required):
            return True
        print(f"Waiting for secrets... ({int(time.time() - start)}s)")
        time.sleep(2)
    raise FileNotFoundError(f"Secrets not found in {SECRET_PATH} after {timeout}s")


def init_with_db():
    global DB_HOST, DB_USER, DB_PASS, DB_NAME
    if not os.path.exists(SECRET_PATH):
        print("Secret path not found - running without DB")
        return False
    try:
        wait_for_secrets()
        DB_HOST = open(os.path.join(SECRET_PATH, "host")).read().strip()
        DB_USER = open(os.path.join(SECRET_PATH, "username")).read().strip()
        DB_PASS = open(os.path.join(SECRET_PATH, "password")).read().strip()
        DB_NAME = open(os.path.join(SECRET_PATH, "dbname")).read().strip()
        print(f"Connecting to RDS: {DB_USER}@{DB_HOST}/{DB_NAME}")
        try:
            init_db()
        except Exception as e:
            print(f"DB init failed: {e}")
            traceback.print_exc()
        return True
    except Exception as e:
        print(f"Failed to initialize DB: {e}")
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
                    'DevOps Engineer with experience in AWS, Kubernetes, and Terraform.',
                    'https://github.com/sahar449',
                    'https://www.linkedin.com/in/sahar-bittman-007343115/',
                    'me.jpg')
            ON DUPLICATE KEY UPDATE
                linkedin_url = VALUES(linkedin_url)
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
    app.run(host="0.0.0.0", port=5002, debug=True)
