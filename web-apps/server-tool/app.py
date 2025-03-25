from flask import Flask, jsonify, request, make_response, send_from_directory

app = Flask(__name__)
VALID_TOKEN = "secret_token"

def require_auth(f):
    def decorator(*args, **kwargs):
        token = request.headers.get('Authorization')
        if token != VALID_TOKEN:
            return make_response(jsonify({'error': 'Unauthorized'}), 401)
        return f(*args, **kwargs)
    return decorator

@app.route('/')
def home():
    return send_from_directory('.', 'index.html')

@app.route('/api/data', methods=['GET'])
@require_auth
def get_data():
    data = {"key": "value"}
    return jsonify(data)