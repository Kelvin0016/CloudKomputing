from flask import Flask
app = Flask(__name__)

@app.route("/")
def hello():
    return "Hello from my Dockerized Flask app, Kelvin! Now IMDSv2-enforced and encrypted 🔒, and configured auto Docker install."

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)
