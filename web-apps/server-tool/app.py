from flask import Flask, jsonify, request, make_response, send_from_directory
import json
from datetime import datetime, timezone, timedelta
import boto3
from botocore.exceptions import ClientError
import jwt
import os
# from functools import wraps


app = Flask(__name__)

# Global dictionary
store = {}
# Get the region from the environment variable
AWS_REGION = os.environ.get('AWS_REGION', 'us-east-1')  # Default to 'us-east-1' if not set


def init():
    project_id = os.environ.get('PROJECT_ID')
    parameter_name = f'/{project_id}/info'
    project_info = get_project_info(parameter_name)
    store['project_info'] = project_info
    print('Got project_info from Param Store')

def get_project_info(parameter_name):
    # Create the SSM client with the specified region
    ssm_client = boto3.client('ssm', region_name=AWS_REGION)    
    try:
        response = ssm_client.get_parameter(Name=parameter_name, WithDecryption=True)
        parameter_value = response['Parameter']['Value']
        info = json.loads(parameter_value)
        return info
    except ssm_client.exceptions.ParameterNotFound:
        print(f"Parameter {parameter_name} not found")
    except json.JSONDecodeError:
        print("Failed to parse JSON from parameter value")
    except Exception as e:
        print(f"An error occurred: {str(e)}")
    return None

def require_auth(f):
    # @wraps(f)
    def decorator(*args, **kwargs):
        # Check for token in Authorization header
        token = request.headers.get('Authorization')
        print(f'Bearer token: {token}')
        auth_pwd = store['project_info']['serverToolPassword']
        if token == f'Bearer {auth_pwd}':
            return f(*args, **kwargs)
        
        # Check for JWT in cookie
        jwt_token = request.cookies.get('token')
        if jwt_token:
            try:
                # Verify and decode the JWT
                JWT_SECRET = store['project_info']['serverToolJwtSecret']
                jwt.decode(jwt_token, JWT_SECRET, algorithms=["HS256"])
                return f(*args, **kwargs)
            except jwt.ExpiredSignatureError:
                return make_response(jsonify({'error': 'Token has expired'}), 401)
            except jwt.InvalidTokenError:
                return make_response(jsonify({'error': 'Invalid token'}), 401)
        
        # If neither token nor JWT is valid
        return make_response(jsonify({'error': 'Unauthorized'}), 401)
    
    return decorator


@app.route('/')
def home():
    return send_from_directory('.', 'index.html')

@app.route('/login', methods=['POST'])
def login():
    # Get the password from the request data
    data = request.get_json()
    password = data.get('password')

    # Check if the password is correct
    if password == store['project_info']['serverToolPassword']:
        payload = {
            'password': password,
            'iat': datetime.utcnow()
        }
        JWT_SECRET = store['project_info']['serverToolJwtSecret']
        token = jwt.encode(payload, JWT_SECRET, algorithm='HS256')
        resp = make_response(jsonify({'message': 'Logged in successfully', 'token': token}))
        return resp
    else:
        return make_response(jsonify({'error': 'Invalid credentials'}), 401)



@app.route('/api/data', methods=['GET'])
@require_auth
def get_data():
    data = {"key": "value"}
    return jsonify(data)



init()
